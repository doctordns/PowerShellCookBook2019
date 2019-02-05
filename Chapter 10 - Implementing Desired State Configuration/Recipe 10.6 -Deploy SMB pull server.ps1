#  Recipe 13-6 - Implemeinting an SMB pull servrer
#
#  Run on SRV1


# 1. Ensure that the xSMBShare module is installed on SRV1, 2 and ensure
#    C:\DSC exists
$SB1 = {
  Install-Module xSMBShare -Force |
    Out-Null
}
Invoke-Command -ComputerName SRV1 -ScriptBlock $SB1
Invoke-Command -ComputerName SRV2 -ScriptBlock $SB1

# 2. Remove existing MOF Files on SRV1, SRV2
$SB2 = {
  $RIHT = @{
    Path        = 'C:\Windows\System32\configuration\*.mof'
    ErrorAction = 'SilentlyContinue'
  }
  Get-Childitem @RIHT |
    Remove-Item @RIHT -Force
  $EASC = @{
    ErrorAction = 'SilentlyContinue'
  }
  New-Item -Path c:\DSC -ItemType Directory @EASC | 
    Out-Null
  Remove-DscConfigurationDocument -Stage Current
  }
Invoke-Command -ComputerName SRV1 -ScriptBlock $SB2
Invoke-Command -ComputerName SRV2 -ScriptBlock $SB2

# 3. Create Configuration block to set LCM configuration for SRV2
#    Setup SRV2 to pull from SRV1
$SB3 = {
  # Create config statemehnt for SRV2 
  [DSCLocalConfigurationManager()]
  Configuration SetSRV2PullMode {
    Node localhost {
      Settings  {
        ConfigurationModeFrequencyMins = '30'
        ConfigurationMode              = 'ApplyAndAutoCorrect'
        RebootNodeIfNeeded             = $true
        ActionAfterReboot              = 'ContinueConfiguration'
        RefreshMOde                    = 'Pull'
        RefreshFrequencyMins           = '30'
        AllowModuleOverwrite           = $true
        ConfigurationID                = '5d79ee6e-0420-4c98-'+
                                         '9cc3-9f696901a816'
      }
      ConfigurationRepositoryShare PullServer  {
        SourcePath = '\\SRV1\DSCConfiguration'
      }
      ResourceRepositoryShare ResourceServer {
        SourcePath = '\\SRV1\DSCResource'
      }
    }
  }
  SetSRV2PullMode -OutputPath 'C:\DSC' | 
    Out-Null
  $DHT = @{ 
   Path  = 'C:\DSC'
  }
  Set-DscLocalConfigurationManager -Path C:\DSC
  Get-DscLocalConfigurationManager
}

# 4. Configure SRV2 to Pull from SRV1
Invoke-Command -ScriptBlock $SB3 -ComputerName SRV2

# 5. Create Configuration statement to configure SRV1 as a DSC PUll Server
Configuration PullSrv1 {
  Import-DscResource -ModuleName PSDesiredStateConfiguration
  Import-DscResource -ModuleName xSmbShare
  File ConfigFolder {
    DestinationPath = 'C:\DSCConfiguration'
    Type        = 'Directory'
    Ensure      = 'Present' 
  }
  File ResourceFolder  {
    DestinationPath = 'C:\DscResource'
   Type        = 'Directory'
    Ensure      = 'Present'
  }
  xSmbShare DscConfiguration { 
    Name        = 'DSCConfiguration'
    Path        = 'C:\DscConfiguration\'
    DependsOn   = '[File]ConfigFolder'
        Description = 'DSC Configuration Share'
        Ensure      = 'Present' 
    }
    xSmbShare DscResource {
      Name        = 'DSCResource'
      Path        = 'C:\DscResource'
      DependsOn   = '[File]ResourceFolder'
      Description = 'DSC Resource Share'
      Ensure      = 'Present' }
}

# 6. Create MOF file to configurer SRV1 as pull server
PullSrv1 -OutputPath C:\DSC | 
  Out-Null

# 7. Use DSC to Configure SRV1 as a pull server
Start-DscConfiguration -Path C:\DSC -Wait -Verbose -Force

# 8. Get shares on SRV1
Get-SMBShare -Name DSC*

# 9. Create new configuration for SRV2 to pull
#    Configure SRV2 to have Telnet Server
Configuration  TelnetSRV2
{
  Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
  Node SRV2  
  {
    WindowsFeature TelnetSRV2
    { Name     = 'Telnet-Client'
      Ensure   = 'Present'  }
  }
}

# 10. Create a MOF file for the Configuration of SRV2
TelnetSRV2 -OutputPath C:\DSCConfiguration

# 11. Rename the MOF File with the GUID name
$Guid = '5d79ee6e-0420-4c98-9cc3-9f696901a816'
$RIHT = @{
  Path    = 'C:\DSCConfiguration\SRV2.mof' 
  NewName = "C:\DSCConfiguration\$Guid.MOF"
}
Rename-Item  @RIHT

# 12. Create MOF Checkshum
New-DscChecksum -Path C:\DSCConfiguration

# 13. View MOF and checksum files
Get-ChildItem -Path C:\DSCConfiguration

# 14. VIew Current configuration
Get-WindowsFeature -Name Telnet-Client -ComputerName SRV2

# 15. Sleep for a while and check again
Start-Sleep -Seconds (30*60)
Get-WindowsFeature -Name Telnet-Client -ComputerName SRV2
