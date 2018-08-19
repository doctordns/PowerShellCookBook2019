# Recipe 1.3 - Exploring PowerShellGet
# This recipe looks at what you can get with the tools in the PowerShellGet module
# Run on CL1 and uses DC1, SRV1
# Run as administrator

# 1. Review the commands available in the PowerShellGet module:
Get-Command -Module PowerShellGet

# 2. Update to the latest NuGet to get the PackageManagement module
Install-PackageProvider -Name NuGet -Force -Verbose

# 3. Check the version of the NuGet PackageProvider:
Get-PackageProvider -Name NuGet |
    Select-Object -Property Version

# 4. Update PowerShellGet:
Install-Module -Name PowerShellGet -Force -Verbose

# 5. Check the version of PowerShellGet:
Get-Module -Name PowerShellGet |
    Select-Object -ExpandProperty Version

# 6. View the default PSGallery repository for PowerShellGet:
Get-PSRepository

# 7. Review the various providers in the repository:
Find-PackageProvider |
    Select-Object -Property Name, Source, Summary |
        Format-Table -Wrap -AutoSize
        
# 8. View available providers with packages in PSGallery:
Find-PackageProvider -Source PSGallery |
    Select-Object -Property Name, Summary |
        Format-Table -Wrap -AutoSize

# 9. Use the Get-Command cmdlet to find cmdlets in PowerShellGet:
Get-Command -Module PowerShellGet -Verb Find

# 10. Request all the commands in the PowerShellGet module, store them in a
#     variable, and display the count as well:
$Commands = Find-Command -Module PowerShellGet
$CommandCount = $Commands.Count
"$CommandCount commands available in PowerShellGet"

# 11. Request all the available in the PowerShell Gallery
$Modules = Find-Module 
$ModuleCount=$Modules.Count
"$ModuleCount Modules available in the PowerShell Gallery"
 
# 12. Get available DSC resources
$DSCResources      = Find-DSCResource
$DSCResourcesCount = $DSCResources.Count
"$DSCResourcesCount DSCResources available in PowerShell Gallery"

# 13. Find the available scripts 
$Scripts = Find-Script
$ScriptsCount = $Scripts.Count
"$ScriptsCount Scripts available in PowerShell Gallery"

# 14. When you discover a module you would like to simply install the module. This
#     functionality is similar for Scripts, DSCResources, and so on:
Get-Command -Module PowerShellGet -Verb Install

# 15. Install the TreeSize module, as an example, or choose your own. As this is a
#     public repository, Windows does not trust it by default, so you must approve the
#     installation:
Install-Module -Name TreeSize -Verbose

# 16. If you choose to trust this repository, set the InstallationPolicy to Trusted,
#     and you'll no longer need to confirm each installation: Use at your own risk, you are
#     responsible for all software you install on servers you manage:
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

# 17. Review and test the commands in the module:
Get-Command -Module TreeSize
Get-Help Get-TreeSize -Examples
Get-TreeSize -Path $env:TEMP -Depth 1

# 18. Remove the module just as easily:
Uninstall-Module -Name TreeSize -Verbose

# 19. Inspect inspect the code before installation
$NIHT = @{
  ItemType = 'Directory'
  Path     = "$env:HOMEDRIVE\DownloadedModules"
}
New-Item @NIHT
$Path = "$env:HOMEDRIVE\DownloadedModules" 
Save-Module -Name TreeSize -Path $Path -ErrorAction SilentlyContinue
Get-ChildItem -Path $Path -Recurse

# 20. Import the treesize module:
$ModuleFolder = "$env:HOMEDRIVE\downloadedModules\TreeSize"
Get-ChildItem -Path $ModuleFolder -Filter *.psm1 -Recurse |
    Select-Object -ExpandProperty FullName -First 1 |
        Import-Module -Verbose

# 21. When you are done with discovering the new module, you can remove it from
#     your system:
Remove-Module -Name TreeSize
$ModuleFolder | Remove-Item -Recurse -Force