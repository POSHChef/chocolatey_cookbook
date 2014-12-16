
# This file holds default attributes for the cookbook
# Any of these can be overridden using a Role or an Environment

# The format of the file is important due to the necessary interaction with Chef server
# It is a PowerShell based hashtable, but th names of the variables are very crucial
#
# The packages hash conatins the installation name for Chocolatey as well as the pattern to look for 
# in the registry
#
# For example the the following is foe checking that Microsoft Web Deploy 3.0 is installed
#
# @{
#   default = @{
#       Chocolatey = @{
#           Packages = @{
#               msdeploy3 = "Microsoft Web Deploy 3.*"
#           }
#       } 
#   }   
# }


@{

	# Default attributes
	default = @{

        Chocolatey = @{

            # Set the location that Chocolatey can be installed from
            # This is to support the install recipe to allow a customised version of Chocolatey
            # to be installed
            InstallFrom = $null

            # Define hash table of packages that are to be installed
            Packages = @{}

            # Set a flag to state if recipe should check if application is installed in windows before
            # using Chocolatey
            CheckIsInstalled = $false

            # Set configuration
            # The settings in here relate directly to settings that are found in the Chocolatey configuration file
            Settings = @{

                # Set where chocolatey should be installed to.  This is only relevant if using the InstallFrom attribute
                installdir = "C:\ProgramData\Chocolatey"

                # Specify if Chocolatey should automaticially update itself
                AutoUpdate = $false

                config = @{

                    useNugetForSources = $false
                    checksumFiles = $true
                    virusCheck = $false
                    ksMessage = $false
                }
            }
        }
	}
}
