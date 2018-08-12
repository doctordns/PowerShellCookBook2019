# 1. Get the collection of PowerShell commands and the number of cmdlets into
# PowerShellvariables before installing the RSAT:
$CountOfCommandsBeforeRSAT = Get-Command |
  Tee-Object -Variable 'CommandsBeforeRSAT' |
    Measure-Object
'{0} commands' -f $CountOfCommandsBeforeRSAT.count

# 2. Examine the objects returned by Get-Command:
$CommandsBeforeRSAT | Get-Member |
    Select-Object -ExpandProperty TypeName -Unique

# 3. Now view commands in Out-GridView:
$CommandsBeforeRSAT |
  Select-Object -Property Name, Source, CommandType |
    Sort-Object -Property Source, Name |
      Out-GridView

# 4. Store the collection of PowerShell modules and a count into variables as well:
$CountOfModulesBeforeRSAT = Get-Module -ListAvailable |
   Tee-Object -Variable 'ModulesBeforeRSAT' |
     Measure-Object
'{0} commands' -f $CountOfModulesBeforeRSAT.count

# 5. View modules in Out-GridView:
$ModulesBeforeRSAT |
   Select-Object -Property Name -Unique |
     Sort-Object -Property Name |
       Out-GridView

# 6. Review the RSAT Windows Features available and their installation status:
Get-WindowsFeature -Name RSAT*

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

