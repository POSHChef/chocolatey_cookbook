Chocolatey CHANGELOG

This file is used to list changes made in each version of the Chocolatey cookbook.

0.0.8
-----
- [Russell Seymour] - Modified Chocolatey resource so that the version attribute is actually used.  Update the readme file for the cookbook.
                      Added template for the configuration file for Chocolatey
                      Recipe now uses attributes to determine where to download files to, by default this is the POSHChef cache directory.

0.0.7
-----
- [Russell Seymour] - Renamed the Chocolatey resource after finding bugs in the original version

0.0.5
-----

- [Russell Seymour] - Renamed the DSCResources folder to resources
                      This is so that embedded DSC Resources folders are not copied outside of the tree

0.0.4
-----
- [Russell Seymour] - Modified default recipe.  The parameters have been updated so that there is only
                      'node' as a parameter.  This is to support a breaking change in POSHChef.

                      Updated so that the new Log resource is used so that relevant information is output during
                      runtime. 
                      

0.0.3
-----

- [Russell Seymour] - Modified default recipe.  If the 'InstallFrom' attribute is set then Chocolatey
                      will be copied from that location.  This is to enable the copying of a custom
                      version if required

0.0.2
-----

- [Russell Seymour] - As POSHChef maybe installed on servers that have already been partly configured, the cookbook
                      now checks the registry to see if the package that is to be installed is alrady installed
                      in Windows.

                      If it is then it may not be registered with Chocolatety so this check is required.  It can be
                      turned off and indeed this is the default.  It can be set in a Role and an Environment

0.0.1
-----
- [Russell Seymour] - Initial release of Chocolatey cookbook

- - -
Check the [Markdown Syntax Guide](http://daringfireball.net/projects/markdown/syntax) for help with Markdown.

The [Github Flavored Markdown page](http://github.github.com/github-flavored-markdown/) describes the differences between markdown on github and standard markdown.
