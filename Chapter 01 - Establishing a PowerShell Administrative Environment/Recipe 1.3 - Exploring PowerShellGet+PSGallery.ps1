# Recipe 1.3 - Exploring PowerShellGet
# This recipe looks at what you can get with the tools in the PowerShellGet module
# Run on CL1 and uses DC1, SRV1
# Run as administrator

# 0. Before you use this recipe, ensure the NuGet provider has been installed:
Install-PackageProvider -Name NuGet -ForceBootstrap


# 1. Review the commands available in the PowerShellGet module:
Get-Command -Module PowerShellGet


# 2. View the NuGet PackageProvider version:
Get-PackageProvider -Name NuGet |
    Select-Object -Property Version

# 3. View the current version of PowerShellGet
Get-Module -Name PowerShellGet -ListAvailable

# 4. Install PowerShellGet:
Install-Module -Name PowerShellGet -Force

# 5. Check the version of PowerShellGet:
Get-Module -Name PowerShellGet -ListAvailable

# 6. View the default PSGallery repository for PowerShellGet:
Get-PSRepository

# 7. Review the package providers in the PSGallery repository:
Find-PackageProvider -Source PSGallery |
    Select-Object -Property Name, Summary |
        Format-Table -Wrap -autosize

# 8. Use the Get-Command cmdlet to find Find-* cmdlets in PowerShellGet:
Get-Command -Module PowerShellGet -Verb Find

# 9. Request all the commands in the PowerShellGet module 
#    and display the count:
$Commands = Find-Command -Module PowerShellGet
$CommandCount = $Commands.Count

# 10. Request all the available modules in the PowerShell Gallery
$Modules = Find-Module -Name *
$ModuleCount=$Modules.Count
 
# 11. Get DSC resources available in PSGallery
$DSCResources = Find-DSCResource
$DSCResourcesCount = $DSCResources.Count

# 12. Get DSC resources available in PSGallery
"$CommandCount commands available in PowerShellGet"
"$ModuleCount Modules available in the PowerShell Gallery"
"$DSCResourcesCount DSCResources available in PowerShell Gallery"


# 13. Install the TreeSize module, as an example, or choose your own. As this is a
#     public repository, Windows does not trust it by default, so you must approve the
#     installation:
Install-Module -Name TreeSize -Force

# 14. Review and test the commands in the module:
Get-Command -Module TreeSize
Get-TreeSize -Path C:\Windows\System32\Drivers -Depth 1

# 15. Remove the module:
Uninstall-Module -Name TreeSize

# 16. Create a download folder:
$NIHT = @{
  ItemType = 'Directory'
  Path     = "$env:HOMEDRIVE\DownloadedModules"
}
New-Item @NIHT | Out-Null

# 17. Download the module and save it to the folder
$Path = "$env:HOMEDRIVE\DownloadedModules" 
Save-Module -Name TreeSize -Path $Path
Get-ChildItem -Path $Path -Recurse | format-Table Fullname

# 18. Import the treesize module:
$ModuleFolder = "$env:HOMEDRIVE\downloadedModules\TreeSize"
Get-ChildItem -Path $ModuleFolder -Filter *.psm1 -Recurse |
    Select-Object -ExpandProperty FullName -First 1 |
        Import-Module -Verbose
