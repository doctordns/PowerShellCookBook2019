#  Recipe 9.1  Install/configure IIS
#
#  Run from SRV1


# 1. Add Web Server feature, sub-features, and tools to SRV1
$FHT = @{
  Name                  = 'Web-Server'
  IncludeAllSubFeature   = $true
  IncludeManagementTools = $true
}
Install-WindowsFeature  @FHT

# 2. See what actual features are installed
Get-WindowsFeature -Name Web*  | Where-Object Installed

# 3. Check the WebAdministration module
$Modules = @('WebAdministration', 'IISAdministration')
Get-Module -Name $Modules -ListAvailable

# 4 Get counts of commands in each module
$C1 = (Get-Command -Module WebAdministration |
        Measure-Object |
          Select-Object -Property Count).Count
$C2 = (Get-Command -Module IISAdministration |
        Measure-Object |
          Select-Object -Property Count).Count
"$C1 commands in WebAdministration Module"
"$C2 commands in IISAdministration Module"

# 5. Look at the IIS provider
Import-Module -Name WebAdministration
Get-PSProvider -PSProvider WebAdministration

# 6. What is in the IIS:
Get-ChildItem -Path IIS:\

# 7. What is in sites folder?
Get-Childitem -Path IIS:\Sites

# 8. Look at the default web site:
$IE  = New-Object -ComObject InterNetExplorer.Application
$URL = 'HTTP://SRV1'
$IE.Navigate2($URL)
$IE.Visible = $true
