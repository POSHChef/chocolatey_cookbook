function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

		[parameter(Mandatory = $true)]
		[System.String]
		$Package,

		[System.String]
		$Version,

		[System.String]
		$InstallArguments,

		[System.String]
		$ChocolateyPath = "C:\ProgramData\Chocolatey"
	)

	$returnValue = @{}

	# Determine the current state of the installation
	# Is chocolatey installed?
	if (Test-Path -Path $ChocolateyPath) {

		$returnValue.IsChocolateyInstalled = $true

		# Set the path to the binary files for chocolatey
		# This gets around an issue where the Path may not have been set properly
		$chocolatey_bin_path = "{0}\bin" -f $ChocolateyPath

		# Use string builder to create a string for the command to be run
		$cmd_builder = New-Object System.Text.StringBuilder

		# 1. Ensure chocolatey is in the path
		$cmd_builder.Append(('if (($env:path -split ";") -notcontains "{0}") {{ $env:path += ";{0}" }};' -f $chocolatey_bin_path)) | Out-Null

		# 2. Determine if the package is installed
		$cmd_builder.Append(("choco version -localOnly {0}" -f $package)) | Out-Null

		# Build up the command to run
		$cmd = $cmd_builder.ToString()

		# Check if the package is already installed
		# build up the command to check the version information
		#$cmd = "{0}\chocolateyinstall\chocolatey.ps1 version {1} -localOnly" -f $ChocolateyPath, $package
		Write-Verbose ("Check Chocolatey package installed command: {0}" -f $cmd)
		$version_info = Invoke-Expression $cmd

		# update the return object based on the version_info
		if ([String]::IsNullOrEmpty($version_info)) {
			$returnValue.IsInstalled = $false
		} else {
			$returnValue.IsInstalled = $true
			$returnValue.version = $version_info.found
		}

	} else {

		$returnValue.IsChocolateyInstalled = $false
	}

	$returnValue

}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

		[parameter(Mandatory = $true)]
		[System.String]
		$Package,

		[System.String]
		$Version,

		[System.String]
		$InstallArguments,

		[System.String]
		$ChocolateyPath = "C:\ProgramData\Chocolatey"
	)

	# Determine if Chocolatey is installed
	$current_state = Get-TargetResource @PSBoundParameters

	# if chocolatey is not installed then install it now
	if (!($current_state.IsChocolateyInstalled)) {
		Write-Verbose "ChocolateyResource: Install chocolatey here"
	}

	# Set the path to the binary files for chocolatey
	# This gets around an issue where the Path may not have been set properly
	$chocolatey_bin_path = "{0}\bin" -f $ChocolateyPath

	# Use string builder to create a string for the command to be run
	$cmd_builder = New-Object System.Text.StringBuilder

	# 1. Ensure chocolatey is in the path
	$cmd_builder.Append(('if (($env:path -split ";") -notcontains "{0}") {{ $env:path += ";{0}" }};' -f $chocolatey_bin_path)) | Out-Null

	# perform the most appropriate function based on the ensure variable
	switch ($ensure.ToLower()) {
		"present" {

			Write-Verbose ("Chocolatey: Before installing package '{0}'" -f $package)

			# determine if any install commands need to be passed
			#$argumments = [String]::Empty
			#if (![String]::IsNullOrEmpty($install_arguments)) {
		#		$arguments = "-installArguments '{0}'" -f $InstallArguments
		#	}

			# Use an array list to build up the actual chocolatey install command
			$choco_install_list = New-Object System.Collections.ArrayList

			$choco_install_list.Add("choco install") | Out-Null
			$choco_install_list.Add("-quiet") | Out-Null

			# If a version has been specified add it to the command
			if (![String]::IsNullOrEmpty($Version)) {
				$choco_install_list.Add(("-version {0}" -f $Version)) | Out-Null
			}

			# Add install arguments for the native installer if they have been specified
			if (![String]::IsNullOrEmpty($InstallArguments)) {
				$choco_install_list.Add(("-installArguments {0}" -f $InstallArguments)) | Out-Null	
			}

			# 2. Set the environment variable for chocolatey which is used by some packages
			$cmd_builder.Append(('$env:ChocolateyInstall = "{0}";' -f $ChocolateyPath)) | Out-Null

			# 3. Add the chocolate installation command
			$cmd_builder.Append(($choco_install_list.ToArray() -join " ")) | Out-Null


			# Build up the command to install the package
            # This includes some testing to ensure the path to chocolatey is in the path
            # as this is required by some packages
            # In addition the environment variable ChocolateInstall is required as well
            #$chocolatey_bin_path = "{0}\bin" -f $ChocolateyPath
            #$cmd = 'if (($env:path -split ";") -notcontains "{0}") {{ $env:path += ";{0}" }}' -f $chocolatey_bin_path
            #$cmd = '{0}; $env:ChocolateyInstall = "{1}"' -f $cmd, $ChocolateyPath
			#$cmd = '{0}; chocolatey install -q {1} {2}' -f $cmd, $package, $arguments
			
			# Set the command from the command builder
			$cmd = $cmd_builder.ToString()

			Write-Verbose ("Install command: {0}" -f $cmd)
			$output = Invoke-Expression $cmd

			Write-Verbose ("Chocolatey: After installing package '{0}'" -f $package)

		}

		"absent" {

            # $cmd = 'if (($env:path -split ";") -notcontains "{0}") {{ $env:path += ";{0}" }}' -f $chocolatey_bin_path
			# $cmd = "chocolatey uninstall {0}" -f $package
			$cmd_builder.Append(("choco uninstall {0}" -f $package)) | Out-String

			# create the cmd to run
			$cmd = $cmd_builder.ToString()

			Write-Verbose ("Chocolatey remove package cmd: {0}" -f $cmd)
			Invoke-Expression $cmd
		}
	}	

}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

		[parameter(Mandatory = $true)]
		[System.String]
		$Package,

		[System.String]
		$Version,

		[System.String]
		$InstallArguments,

		[System.String]
		$ChocolateyPath = "C:\ProgramData\Chocolatey"
	)

	# set the default returnValue
	$returnValue = $true

	# Determine if Chocolatey is installed
	$current_state = Get-TargetResource @PSBoundParameters

	# use the current state to determine if 
	# a) Chocolatey is installed
	# b) Package is instaled
	if (!($current_state.IsChocolateyInstalled)) {
		Write-Verbose "Chocolatey is not installed"
		$returnValue = $false
	}

	# determine if package should be installed or not, based on the ensure variable
	switch ($ensure.ToLower()) {
		"present" {

			# if the package is not installed return false
			if ($current_state.IsInstalled -eq $false) {
                Write-Verbose ("{0} is NOT installed, installing ..." -f $package)
				$returnValue = $false
			} else {
                Write-Verbose ("{0} is installed" -f $package)                
            }

		}

		"absent" {

			# if the package is installed return false
			if ($current_state.IsInstalled -eq $true) {
                Write-Verbose ("{0} is installed, removing ..." -f $package)
				$returnValue = $false
			} else {
                Write-Verbose ("{0} is NOT installed" -f $package)
            }
		}
	}

	# return the test boolean returnValue
	$returnValue
}



# Export-ModuleMember -Function *-TargetResource
