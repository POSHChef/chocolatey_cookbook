Chocolatey Cookbook
===================

This cookbook contains a DSC Resource to install packages from Chocolatey.  It also contains a recipe that will ensure Chocolatey is installed before attempting to install packages.  This same recipe is used to install all packages that are defined in cookbooks, roles and recipes.

Due to the way in which POSHChef converges all the attributes from the different sources the list of packages to be installed for the entire run is known, thus all the packages that are required can be installed with just one recipe.

The attributes that are specified must contain, at least, the name of the chocolatey package to install.  Additionally it can contain the version of the package to install as well as the name of the package when it is installed in Windows.  This latter element enables the default recipe to check if the application has been installed in Windows before Chocolatey and it if has Chocolatey will not attempt to install it.

Installation Package
--------------------

Chocolatey provides a way of installing itself using a one liner in PowerShell, (http://chocolatey.org).  However this installation mechanism uses the PowerShell command ```Write-Host``` which will fail in a DSC run as it is not supported.  The recommended way to get around this is to copy the installation of Choclatey from a machine and put it on a file server.  The recipe will then use the ```node["Chocolatey"]["InstallFrom"]``` and ```node["Chocolatey"]["Settings"]["installdir"]``` to download the unpacked directory from the share and install into the desired location, which is 'C:\ProgramData\Chocolatey'.

Requirements
------------

The cookbook uses core POSHChef resources, it does not have any dependencies on any other cookbook.

Attributes
----------

The following attributes affect how Chocolatey itself is installed, what packages are to be installed and if Chocolatey should auto update.

|         Name        |                               Description                               | Default Value |
|---------------------|-------------------------------------------------------------------------|---------------|
| CheckIsInstalled    | State if the recipe should check if application is installed in Windows | false         |
| InstallFrom         | Path to alternate location of Chocolate installation script             | null          |
| Packages            | Object containing a list of packages to install                         | @{}           |
| Settings.installdir | String denoting the path to install Chocolatey to                       | @{}           |
| Settings.AutoUpdate | Whether Chocolatey should self update itself                            | false         |
| Settings.Config     | Object containing the settings for Chocolatey                           |               |

An example of the Packages object is shown below.  This example would install the specified version of Logstash and install Notepad ++.  The "windows_display_name" is used when the ```CheckIsInstalled``` attribute is set, and then the recipe will check the Windows registry to see if the application is installed before any attempt to do so is performed.

```JSON
{
  "chocolatey": {
    "packages": {
      "logstash": {
        "version": "1.4.2.12102103"
      },
      "notepadplusplus": {
          "windows_display_name": "Notepad++"
      }
    }
  }
}
```

Note:  This example shows the specific JSON to use in a role or environment file.  If specifyin in an cookbook then a PowerShell hashtable should be used.

### Chocolatey Settings

The settings object contains two elements:

| # |    Name    |             Description             |    Type   |          Default          |
|---|------------|-------------------------------------|-----------|---------------------------|
| 1 | InstallDir | Folder to install Chocolatey to     | string    | c:\ProgramData\Chocolatey |
| 2 | config     | Hashtable of configuration settings | hashtable | @{} (See below)           |

The InstallDir is used when Chocolatey is installed via a different method, e.g. an unpacked version of Chocolatey.  

Chocolatey has a configuration file, that by default is located in ```C:\ProgramData\Chocolatey\chocolateyinstall\chocolatey.config```.  This is a simple xml file that defines behaviours in Chocolatey.  

The config object in attributes has the following items, and are directly mapped to the settings that can be specified in the configutation file.

|        Item        |               Description                | Default |
|--------------------|------------------------------------------|---------|
| useNugetForSources | Use sources as defined in Nuget instead  | false   |
| checksumFiles      |                                          | true    |
| virusCheck         |                                          | false   |
| ksMessage          | Display banner about Kickstarter project | false   |

For more information about these settings please refer to the [Chocolatey Wiki](https://github.com/chocolatey/chocolatey/wiki)

Usage
-----
### Chocolatey::default
This recipe is responsible for ensuring chocolately is installed and installing the necessary packages.

Include it in a role or a node run_list and set the packages to be installed,

For example, include the chocolatey recipe in your run_list:

```JSON
{
  "default_attributes": {
    "chocolatey": {
      "packages": {
        "logstash": {
          "version": "1.4.2.12102103"
        },
        "notepadplusplus": {
            "windows_display_name": "Notepad++"
        }
      }
    }
  }
  "name":"Packages",
  "run_list": [
    "recipe[Chocolatey]"
  ]
}
```

Resources
---------

The following resources are shipped with this cookbook.

### Chocolatey Resource

- Fullname:       Turtlesystems_ChocolateyResource
- Friendly Name:  Turtlesystems_Chocolatey

#### Parameters

|       Name       |                           Description                            |          Default          |
|------------------|------------------------------------------------------------------|---------------------------|
| Ensure           | Specify if the package should be installed or removed            |                           |
| Package          | Name of the package to install.                                  |                           |
| Version          | The version to instal                                            | null                      |
| InstallArguments | Arguments to be passed to the native installer, e.g. MSI package | null                      |
| ChocolateyPath   | Path to where chocolatey is installed                            | C:\ProgramData\Chocolatey |

#### Example

This PowerShell snippet will install a specific version of logstash.

```PowerShell
Turtlesystems_Chocolatey "Install Logstash" {
  Ensure = "Present"
  Package = "Logstash"
  Version = "1.4.2.12102103"
}
```

Templates
---------

### chocolatey.config.tmpl

This is a template file for the chocolatey configuration.  It uses the config object in the attributes to build up the necessary XML file.

License and Authors
-------------------
Authors: Russell Seymour (<russell.seymour@turtlesystemsconsulting.co.uk>)

```text
Copyright:: 2010-2014, Turtlesystems Consulting, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
