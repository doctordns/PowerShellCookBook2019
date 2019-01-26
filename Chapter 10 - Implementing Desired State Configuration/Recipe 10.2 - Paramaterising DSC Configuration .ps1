#  Recipe 13-2  -  Paramaterize DSC Configuratin

# 1. Check status of DNS on SRV2
Get-WindowsFeature DNS -ComputerName SRV2

# 2. Create configuration
Configuration ProvisionServices
{
 param (
  [Parameter(Mandatory=$true)]  $NodeName,
  [Parameter(Mandatory=$true)]  $FeatureName)
  Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
Node $NodeName
  {
  WindowsFeature $FeatureName
    {
       Name                  = $FeatureName
       Ensure                = 'Present'
       IncludeAllSubFeature  = $true
    }      # End Windows Feature
  }        # End Node configuration
}          # End of Configuration document

# 3. Ensure an empty DSC folder exists, then create MOF file
$NIHT = @{
  Path        = 'C:\DSC '
  ItemType    = 'Directory'
  ErrorAction = 'SilentlyContinue'
}    
New-Item  @NIHT| Out-Null
Get-ChildItem -Path C:\DSC | Remove-Item -Force | Out-Null

# 4. Clear any existing Configuration documents on SRV2
$RIHT =@{
  Path        = '\\SRV2\c$\Windows\System32\configuration\*.mof'
  ErrorAction = 'SilentlyContinue'
}
Get-Childitem '\\SRV2\C$\Windows\System32\configuration\*.MOF' |
  Remove-Item @RIHT -Force

# 5. Now run ProvisionServices to create the MOF to provision DNS on SRV2
$PSHT = @{
  OutputPath  = 'C:\DSC'
  NodeName    = 'SRV2'
  FeatureName = 'DNS'
}
ProvisionServices @PSHT

# 6. Do it...
Start-DscConfiguration -Path C:\DSC -Wait -Verbose

# 7. Check results
Get-Service -Name DNS -ComputerName SRV2
