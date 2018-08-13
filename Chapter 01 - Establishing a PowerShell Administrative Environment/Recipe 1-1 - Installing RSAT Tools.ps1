# Recipe 1-1 - Installing RSAT Tools
#
# Uses: DC1, SRV1, CL1
# Run From CL1

# 1. Get all available PowerShell commands prior to installing RSAT tools
$CommandsBeforeRSAT        = Get-Command 
$CountOfCommandsBeforeRSAT = $CommandsBeforeRSAT.count
"Commands available on [$(hostname)] before RSAT installed: [$CountOfCommandsBeforeRSAT]"

# 2. Examine the types of objects returned by Get-Command:
$CommandsBeforeRSAT | Get-Member |
    Select-Object -ExpandProperty TypeName -Unique

# 3. View commands in Out-GridView:
$CommandsBeforeRSAT |
  Select-Object -Property Name, Source, CommandType |
    Sort-Object -Property Source, Name |
      Out-GridView

# 4. Store the collection of PowerShell modules and a count into variables as well:
$ModulesBeforeRSAT = Get-Module -ListAvailable 
$CountOfModulesBeforeRSAT = $ModulesBeforeRSAT.count
"$CountOfModulesBeforeRSAT modules are installed prior to adding RSAT"

# 5. View modules in Out-GridView:
$ModulesBeforeRSAT |
   Select-Object -Property Name,Description -Unique |
     Sort-Object -Property Name|
       Out-GridView

# 6. Review the RSAT Windows Features available and their installation status:
Get-WindowsFeature -Name RSAT*

# 7. Perform information gathering on DC1, SRV1
$SB = {
    "On Host: [$(hostname)]:"
    $CommandsBefore = Get-Command 
    $CountBefore = $CommandsBefore.count
    "  Commands available before RSAT installed: [$CountBefore]"
    $ModulesBeforeRSAT = Get-Module -ListAvailable 
    $CountOfModulesBeforeRSAT = $ModulesBeforeRSAT.count
    "  $CountOfModulesBeforeRSAT modules are installed prior to adding RSAT"
}
Invoke-Command -ComputerName DC1 -ScriptBlock $SB
"On DC1:"
"On SRV1"



# 7. Install RSAT with sub features and management tools:
Install-WindowsFeature -Name RSAT `
                       -IncludeAllSubFeature `
                       -IncludeManagementTools

# 8. Now that RSAT features are installed, see what commands are available:
$CountOfCommandsAfterRSAT = Get-Command |
   Tee-Object -Variable 'CommandsAfterRSAT' |
     Measure-Object
'{0} commands' -f $CountOfCommandsAfterRSAT.count

# 9. View commands in Out-GridView:
$CommandsAfterRSAT |
   Select-Object -Property Name, Source, CommandType |
     Sort-Object -Property Source, Name |
       Out-GridView
  
# 10. Now check how many modules are available:
$CountOfModulesAfterRSAT = Get-Module -ListAvailable |
   Tee-Object -Variable 'ModulesAfterRSAT' |
     Measure-Object
'{0} commands' -f $CountOfModulesAfterRSAT.count

# 11. View modules in Out-GridView:
$ModulesAfterRSAT | Select-Object -Property Name -Unique |
   Sort-Object -Property Name |
     Out-GridView

# 12. Store the list of commands into an XML file for later research:
$CommandsAfterRSAT |
  Export-Clixml `
    -Path "$env:HOMEPATH\Documents\WS2016Commands.XML"

