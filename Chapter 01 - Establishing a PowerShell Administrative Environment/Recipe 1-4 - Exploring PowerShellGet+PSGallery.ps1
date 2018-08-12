# Recipe 1-4 - Exploring PowerShellGet
# This recipe looks at what you can get with the tools in the PowerShellGet module

# 1. Begin by reviewing the commands available in the PowerShellGet module:
Get-Command -Module PowerShellGet

# 2. Before moving on, update to the latest NuGet to get the PackageManagement 
#    module current, then update the PowerShellGet module per the GitHub 
#    instructions at https:/​/​github.​com/​powershell/​powershellget. Note that
#    PowerShellGet has a dependency on PackageManagement, which in turn relies
#    on NuGet. PowerShellGet and PackageMangagement both come with  Windows 10
#    and Windows Server 2016. Updates via Windows Updates are less frequent than
#    releases at the PowerShell gallery. Updating ensures you have the latest versions
#    of all the dependencies. To update NuGet:
Install-PackageProvider -Name NuGet -Force -Verbose

# 3. Close your PowerShell session by running Exit and open a new PowerShell
#    session.

# 4. Check the version of the NuGet PackageProvider:
Get-PackageProvider -Name NuGet |
    Select-Object Version

# 5. Update PowerShellGet:
Install-Module -Name PowerShellGet -Force -Verbose

# 6. Close your PowerShell session by running Exit and reopen it again.

# 7. Check the version of PowerShellGet:
Get-Module -Name PowerShellGet |
    Select-Object -ExpandProperty Version

# 8. View the default PSGallery repository for PowerShellGet:
Get-PSRepository

# 9. Review the various providers in the repository:
Find-PackageProvider |
    Select-Object -Property Name, Source, Summary |
        Format-Table -Wrap -AutoSize
        
# 10. View available providers with packages in PSGallery:
Find-PackageProvider -Source PSGallery |
    Select-Object -Property Name, Summary |
        Format-Table -Wrap -AutoSize

# 11. Use the Get-Command cmdlet to find cmdlets in PowerShellGet:
Get-Command -Module PowerShellGet -Verb Find

# 12. Request all the commands in the PowerShellGet module, store them in a
#     variable, and display the count as well:
$CommandCount = Find-Command |
    Tee-Object -Variable 'Commands' |
        Measure-Object
"{0} commands available in PowerShellGet" `
          -f $CommandCount.Count

# 13. Review the commands in Out-GridView and note the module names:
$Commands | Out-GridView 

# 14. Request all the available PowerShellGet modules, store them in a variable and
#     display the count as well:
$ModuleCount = Find-Module |
    Tee-Object -Variable 'Modules' |
        Measure-Object
"{0} Modules available in PowerShellGet" -f $ModuleCount.Count
 
# 15. Review the modules in Out-GridView:
$Modules | Out-GridView

# 16. Request all available DSC resources, store them in a variable, and view them in
#     Out-GridView:
$DSCResourceCount = Find-DSCResource |
    Tee-Object -Variable 'DSCResources' |
        Measure-Object
"{0} DSCResources available in PowerShellGet" -f `
$DSCResourceCount.Count
$DSCResources | Out-GridView

# 17. Find the available scripts and store them in a variable. Then view them using
#     Out-GridView:
$ScriptCount = Find-Script |
    Tee-Object -Variable 'Scripts' |
        Measure-Object
"{0} Scripts available in PowerShellGet" -f $ScriptCount.Count
$Scripts | Out-GridView

# 18. When you discover a module you would like to simply install the module. This
#     functionality is similar for Scripts, DSCResources, and so on:
Get-Command -Module PowerShellGet -Verb Install

# 19. Install the TreeSize module, as an example, or choose your own. As this is a
#     public repository, Windows does not trust it by default, so you must approve the
#     installation:
Install-Module -Name TreeSize -Verbose

# 20. If you choose to trust this repository, set the InstallationPolicy to Trusted,
#     and you'll no longer need to confirm each installation: Use at your own risk, you are
#     responsible for all software you install on servers you manage:
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

# 21. Review and test the commands in the module:
Get-Command -Module TreeSize
Get-Help Get-TreeSize -Examples
Get-TreeSize -Path $env:TEMP -Depth 1

# 22. Remove the module just as easily:
Uninstall-Module -Name TreeSize -Verbose

# 23. If you would like to inspect the code before installation, download and review
#     the module code:
New-Item -ItemType Directory `
         -Path $env:HOMEDRIVE\DownloadedModules
$Path = "$env:HOMEDRIVE\DownloadedModules"
Save-Module -Name TreeSize `
            -Path $PATH
Get-ChildItem -Path "$env:HOMEDRIVE\DownloadedModules" -Recurse

# 24. Import the downloaded module:
$ModuleFolder = "$env:HOMEDRIVE\downloadedModules\TreeSize"
Get-ChildItem -Path $ModuleFolder -Filter *.psm1 -Recurse |
    Select-Object -ExpandProperty FullName -First 1 |
        Import-Module -Verbose

# 25. When you are done with discovering the new module, you can remove it from
#     your system:
Remove-Module -Name TreeSize
$ModuleFolder | Remove-Item -Recurse -Force
