#  Recipe 13.9 DSC Reporting  - LOG
#  
# Run on SRV2
# AFTER you run steps 1-9 on recipe 13.9


# 0. Remove existing configurations from \\SRV1\DSCConfiguration - just in case
Remove-Item -Path \\srv1\c$\dscconfiguration\*.*

# 1. Create a meta configuration to make SRV2 pull two partial configurations from SRV1 and use the report server
[DSCLocalConfigurationManager()]
Configuration SRV2WebPullPartialReport {
 Node Srv2.Reskit.Org {
   Settings {
      RefreshMode          = 'Pull'
      ConfigurationModeFrequencyMins = 30
      ConfigurationMode    = 'ApplyandAutoCorrect'
      RefreshFrequencyMins = 30 
      RebootNodeIfNeeded   = $true 
      AllowModuleOverwrite = $true 
    }
   ConfigurationRepositoryWeb DSCPullSrv {
     ServerURL = 'https://SRV1.Reskit.Org:8080/PSDSCPullServer.svc'
     RegistrationKey = '5d79ee6e-0420-4c98-9cc3-9f696901a816'
     ConfigurationNames = @('SNMPConfig','WINSConfig')  }
   PartialConfiguration SNMPConfig {  
     Description = 'SNMP Service Configuration'
     Configurationsource = @('[ConfigurationRepositoryWeb]DSCPullSrv')}
   PartialConfiguration WINSConfig {
     Description = 'WINS Server Configuration'
     Configurationsource = @('[ConfigurationRepositoryWeb]DSCPullSrv')
     DependsOn   = '[PartialConfiguration]SNMPConfig'}
   ReportServerWeb SRV2Report {
     ServerURL       = 'https://SRV1.Reskit.Org:8080/PSDSCPUllServer.svc'
     RegistrationKey = '5d79ee6e-0420-4c98-9cc3-9f696901a816'
   }
    } 
}

# 2. Remove existing DSC configuration for SRV2 then create MOF to config DSC LCM on SRV2
$P = 'C:\Windows\System32\Configuration\'
Remove-Item -Path "$P\*.MOF"
SRV2WebPullPartialReport -OutputPath C:\DSC | Out-Null

# 3. Set LCM configuration for SRV2:
$LCMHT  = @{
            ComputerName = 'SRV2.Reskit.Org'
            Path       = 'C:\DSC'
}
Set-DscLocalConfigurationManager @LCMHT | Out-Null

# 4. Create SNMP service partial configuration and build MOF
$Guid = '5d79ee6e-0420-4c98-9cc3-9f696901a816'
$ConfigData = @{
  AllNodes  = @(
    @{ NodeName = '*' ; PsDscAllowPlainTextPassword = $true},
    @{ NodeName = $Guid }
  )
}
Configuration  SNMPConfig {
  Import-DscResource –ModuleName PSDesiredStateConfiguration
  Node $Allnodes.NodeName {
    WindowsFeature SNMPPresent { 
      Name     = 'SNMP-Service'
      Ensure   = 'Present'  
    }    
  }
}
$CHT1 = @{
  ConfigurationData = $ConfigData
  OutputPath        = '\\SRV1\c$\\DSCConfiguration'
}
SNMPConfig @CHT1 | Out-Null
$RIHT = @{
  Path     = "\\SRV1\C$\DSCConfiguration\$Guid.mof"
  Newname  = "\\SRV1\C$\DSCConfiguration\SNMPConfig.MOF"
}
Rename-Item  @RIHT | Out-Null

# 5. Create WINS Service partial configuration and build MOF
$Guid = '5d79ee6e-0420-4c98-9cc3-9f696901a816'
$ConfigData = @{
   AllNodes = @(
      @{ NodeName = '*' ; PsDscAllowPlainTextPassword = $true},
      @{ NodeName = $Guid }
   )
}
Configuration  WINSConfig {
  Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
  Node $AllNodes.NodeName {
  WindowsFeature WinsServer {
    Name   = 'Wins'
    Ensure = 'Present'
  }
}
}
$WSHT = @{
  ConfigurationData = $ConfigData 
  OutputPath        = '\\SRV1\C$\DSCConfiguration\'  
}
WinsConfig @WSHT |  Out-Null
$RIHT =  @{
  Path    = "\\SRV1\C$\DSCConfiguration\$Guid.mof" 
  NewName = "\\SRV1\C$\DSCConfiguration\WINSConfig.MOF"
}
Rename-Item  @RIHT 

# 6. Create MOF checksum files:
Remove-Item -Path "\\SRV1\C$\DSCConfiguration\*.checksum"
New-DscChecksum -Path \\SRV1\C$\DSCConfiguration

xxx

# 7. Wait then test the DSC configuration on SRV2:
Start-DscConfiguration -UseExisting
Test-DSCConfiguration -ComputerName SRV2

# 8. Define a reporting function:
Function Get-DSCReport {
[CmdletBinding()]
Param(
  $AgentId = "$(Throw 'no Agent id provided')", 
  $ServiceURL = 'https://SRV1.Reskit.Org:8080/'+
                'PSDSCPullServer.svc',
  $RequestUri = "$ServiceURL/Nodes(AgentId= '$AgentId')/Reports"
)
$CT = 'application/json;odata=minimalmetadata;' + 
      'streaming=true;charset=utf-8' 
$AHHT = @{
  Accept = "application/json"
  ProtocolVersion = "2.0"
  }
$IWRHT = @{
  Uri          = $RequestUri
  ContentType  = $CT
  UseBasicParsing = $True
  Headers         = $AHHT
  ErrorAction     = 'SilentlyContinue' 
}
$Request = Invoke-WebRequest @IWRHT 
                                                      
$Report = ConvertFrom-Json $Request.Content
return $Report.value
}  #End Get-DSCReport

# 9. Get reports
$AgentId = (Get-DscLocalConfigurationManager).AgentId
$Reports = Get-DSCReport -AgentId $AgentId |
            Select-Object -First 10

# 10. Get one report entry
$Report = $Reports

# 11. View report data
$Report | 
  Format-Table -Property JobID, OperationType, 
                         Refreshmode, EndTime

# 12. Look at resources IN desired state from this report:
($Report.StatusData |ConvertFrom-Json).ResourcesInDesiredState| 
  Format-Table   Modulename, InstanceName, ResourceName, ResourceID


