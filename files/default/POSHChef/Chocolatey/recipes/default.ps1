Configuration Chocolatey_Default {
    
    <#

    .SYNOPSIS
    Install the packages as defined in the resloved attributes

    .DESCRIPTION
    This recipe is responsible for ensuring that Chocolatey is installed and that the named packages in the
    attributes are installed.

    If the 'InstallFrom' flag is not null then it will copy the Chocolatey directory from that location and
    not use the 'install.ps1' script.  This is so that it is possible to have a custom version of Chocolatey.
    For example in certain situations Chocolatey will use Write-Host which is not supported in the DSC host.
    With a custom evrsion it is possible to modify this behaviour and install it withouth the installation
    script.

    After the system has asserted that Chocolatey is installed it will then attempt to install the packages.
    It is possible that POSHChef is installed after a machine has been partially configued.  This means that
    some software may already be installed that is not registered with Chocolatey. To avoid errors when 
    installing a packge that has already been installed, the attribute 'CheckIsInstalled' can be set.

    When this flag is set the system will look in the registry for the package before attempting to install it.
    The packages attribute needs to be populate accordingly.  Please see the README.md for more information.

    #>

    [CmdletBinding()]
    param
    (
        [hashtable]
        [validateScript({
            $_.Contains("Chocolatey") -and
            $_.Chocolatey.Contains("Packages")
        })]
        [Parameter(Mandatory=$true)]
        $node

    )

    # create a chocolatey variable from the node
    $Chocolatey = $node.Chocolatey

    # determine the destination of the copy
    $destination = "{0}\install.ps1" -f $node.POSHChef.cache

    # Define varables that declare where chocolatey should be downloaded to and where it should be unpacked to
    # Specify where the install package should be downloaded to
    $download_path = "{0}\Chocolatey" -f $node.POSHChef.cache
        
    # Specify where choclatey should be unpacked to
    $destination_path = $node.Chocolatey.Settings.installdir

    # determine if should be installed using the script or by copying
    if ([String]::IsNullOrEmpty($Chocolatey.InstallFrom)) {

        Log "Copy_Chocolatey_Install_Script" {
            Message = "Copying Chocolatey installation script"
        }

        # get the the file from the cookbook to a known location on disk
        CookbookFile CookbookFile_ChocolateyInstall {
            Source = "install.ps1"
            Destination = $destination
            Cookbook = "Chocolatey"
            Ensure = "Present"
        }

    } else {

        # if the destination path does not exist then setup to download and install
        if (!(Test-Path -path $destination_path)) {

            Log "Chocolatey_Install_From" {
                Message = ("Chocolatey will be installed from - {0}" -f $Chocolatey.InstallFrom)
            }

            Log "Chocolatey_Download_Path" {
                Message = ("Chocolatey package will be downloaded to: {0}" -f $download_path)
            }

            Log "Chocolatey_Install_Path" {
                Message = ("Chocolatey will be installed in the directory: {0}" -f $destination_path)
            }

            # If the InstallFrom is a directory then check that it has a traling \ appended
            if ((Test-Path -Path $Chocolatey.InstallFrom -PathType container) -and (($Chocolatey.InstallFrom).EndsWith("\") -eq $false)) {
                Log "Chocolatey_Format_Path" {
                    Message = "Appending trailing '\' to path"
                }
                $Chocolatey.InstallFrom += "\"
            }

            # see if the file that has to be downloaded is a zip file
            $is_archive = $false
            if ($Chocolatey.InstallFrom.EndsWith(".zip")) {
                $download_path += ".zip"
                $is_archive = $true
            }

            # use the RemoteFile resource to copy the installation
            POSHChef_RemoteFile "RemoteFile_Chocolatey" {
                Ensure = "Present"
                Source = $Chocolatey.InstallFrom
                Target = $download_path
            }

            # if the download is a zip file then unpack it
            if ($is_archive) {
                Archive "UnpackChocolatey" {
                    Path = $download_path
                    Destination = $destination_path
                    Ensure = 'Present'
                }
            }

            # finally add an environment variable to specify where chocolatey has been installed
            Environment "Chocolatey_Install" {
                Name = "ChocolateyInstall"
                Ensure = "Present"
                Value = $destination_path
            }
        }

        # Add the chocolatey bin path to the path variable
        $chocolatey_bin = "{0}\bin" -f $destination_path
        Environment "Environment_Path" {
            Name = "path"
            Path = $true
            Ensure = "Present"
            Value = $chocolatey_bin
        }
    
    }

    # Set the chocolatey configuration file
    Template "Chocolatey Config" {
        Ensure = "Present"
        Source = "chocolatey.config.tmpl"   
        Destination = ("{0}\chocolateyinstall\chocolatey.config" -f $destination_path)
        Attributes = $node | ConvertTo-Json -Depth 99
        Cookbook = "Chocolatey"
    }

    # Get a list of the packages that are already installed on the machine
    $UninstallKey="SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall" 

    # Create a reference to the HKLM in the registry
    $registry = [microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine', $null)
    $registry_key = $registry.OpenSubKey($UninstallKey)
    $sub_keys = $registry_key.GetSubKeyNames()

    # iterate around the defined packages and check each one is installed
    foreach ($package in $Chocolatey.Packages.keys) {

        $windows_package_name = $Chocolatey.Packages.$package.windows_display_name

        # See if the package that is being installed is already registered with windows
        if ($Chocolatey.CheckIsInstalled -eq $true -and ![String]::IsNullOrEmpty($windows_package_name)) {
            Log ("Chocolatey_Package_{0}_Installed" -f $windows_package_name) {
                Message = ("Checking if '{0}' is already installed in Windows" -f $windows_package_name)    
            }
            $installed = $sub_keys | Where-Object { ($registry.OpenSubKey($UninstallKey+"\\"+$_)).GetValue("DisplayName") -like $windows_package_name } `
                                  | ForEach-Object { ($registry.OpenSubKey($UninstallKey+"\\"+$_)).GetValue("DisplayName") }
        } else {
            $installed = $null
        }

        # Only use chocolatey if installed is null
        if ([String]::IsNullOrEmpty($installed)) {

            Log ("Chocolatey_Installing_{0}" -f $package) {
                Message = ("Attempting to install '{0}' using Chocolatey" -f $package)
            }

            # build up the resource name
            $resource_name = "Chocolatey_{0}" -f $package

            Turtlesystems_Chocolatey $resource_name {
                Ensure = "Present"
                Package = $package
                InstallArguments = $Chocolatey.packages.$package.install_arguments
            }
        } else {
            Log ("Chcolatey_Package_{0}_Installed" -f $installed) {
                Message = ("'{0}' is already installed in Windows" -f $installed)
            }
        }
    }

}