# Recipe 3.4 - Creating a group policy object

# 1. Create Group Policy object
$Pol = 
  New-GPO -Name ITPolicy -Comment "IT GPO" -Domain Reskit.Org

# 2. Ensure just computer settings are enabled
$Pol.GpoStatus = 'UserSettingsDisabled'

# 3. Configure the policy with two settings
$EPHT1= @{
  Name   = 'ITPolicy'
  Key    = 'HKLM\Software\Policies\Microsoft\Windows\PowerShell'
  ValueName = 'ExecutionPolicy'
  Value  = 'Unrestricted' 
  Type   = 'String'
}
Set-GPRegistryValue @EPHT1 | Out-Null
$EPHT2= @{
  Name   = 'ITPolicy'
  Key    = 'HKLM\Software\Policies\Microsoft\Windows\PowerShell'
  ValueName = 'EnableScripts'
  Type   = 'DWord'
  Value  = 1 
}
Set-GPRegistryValue @EPHT2 | Out-Null

# 4. Create a screen saver GPO And set status and a comment
$Pol2 = New-GPO -Name 'Screen Saver Time Out' 
$Pol2.GpoStatus   = 'ComputerSettingsDisabled'
$Pol2.Description = '15 minute timeout'

# 5. Set a registry value
$EPHT3= @{
  Name   = 'Screen Saver Time Out'
  Key    = 'HKCU\Software\Policies\Microsoft\Windows\'+
              'Control Panel\Desktop'
  ValueName = 'ScreenSaveTimeOut'
  Value  = 900 
  Type   = 'DWord'
} 
Set-GPRegistryValue @EPHT3 | Out-Null

# 6. Assign the GPOs to the IT OU
$GPLHT1 = @{
  Name     = 'ITPolicy'
  Target   = 'OU=IT,DC=Reskit,DC=org'
}
New-GPLink @GPLHT1 | Out-Null
$GPLHT2 = @{
  Name     = 'Screen Saver Time Out'
  Target   = 'OU=IT,DC=Reskit,DC=org'
}
New-GPLink @GPLHT2 | Out-Null

# 7. Display the GPOs in the domain
Get-GPO -All -Domain Reskit.Org |
  Sort -Property DisplayName |
    Format-Table -Property Displayname, Description, GpoStatus

# 8. Create and view a GPO Report
$RPath = 'C:\Foo\GPOReport1.HTML'
Get-GPOReport -Name 'ITPolicy' -ReportType Html -Path $RPath
Invoke-Item -Path $RPath



# to undo for testing

Remove-GPLink -Name 'Screen Saver Time Out'  -Target 'OU=IT,DC=Reskit,DC=Org'
Remove-GPLink -Name 'ITPolicy'  -Target 'OU=IT,DC=Reskit,DC=Org'
Get-GPO 'ITPolicy' | Remove-GPO
Get-GPO 'Screen Saver Time Out' | remove-GPO
Get-GPO -Domain 'Reskit.Org' -All |
  Format-Table -Property DisplayName, GPOStatus, Description