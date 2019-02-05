#  Recipe 10.5 - Configuring LCM
#  

# 1. Nuke any Local MOF files and configurations on SRV2, and ensure c:\DSC exists
$RIHT =@{
  Path        = 'C:\Windows\System32\configuration\*.mof'
  ErrorAction = 'SilentlyContinue'
}
Get-Childitem @RIHT |
  Remove-Item @RIHT -Force
$EASC = @{
  ErrorAction = 'SilentlyContinue'}
New-Item -Path c:\DSC -ItemType Directory @EASC | 
  Out-Null

# 2. Get Default settings for LCM:
Get-DscLocalConfigurationManager |
  Format-List -Property ActionafterReboot,
                        AllowModuleOverwrite,
                        Configuration*,
                        LCMState,
                        PartialConfigurations,
                        Reboot*,
                        Refresh*,
                        Report*,
                        Resource*

# 3. Create meta configuration for this host
Configuration SRV2LcmConfig {
  Node Localhost{
    LocalConfigurationManager {
      ConfigurationMode              = 'ApplyOnly'
      RebootNodeIfNeeded             = $true    
    }
  }
}

# 4. Run the config and create the mof
SRV2LcmConfig -OutputPath C:\DSC 

# 5. Set LCM
Set-DscLocalConfigurationManager -Path c:\DSC -Verbose

# 6. and check updated values:

Get-DscLocalConfigurationManager |
  Format-List -Property ActionafterReboot,
                        AllowModuleOverwrite,
                        Configuration*,
                        LCMState,
                        PartialConfigurations,
                        Reboot*,
                        Refresh*,
                        Report*,
                        Resource*




# Reset should u need to

Configuration SRV2LcmConfig {
  Node Localhost{
    LocalConfigurationManager {
      AllowModuleOverwrite           = $false
      ConfigurationModeFrequencyMins = 15
      ConfigurationMode              = 'ApplyAndMOnitor'
      RebootNodeIfNeeded             = $false
    }
  }
}
SRV2LcmConfig -OutputPath c:\dsc
Set-DscLocalConfigurationManager -Path c:\DSC -Verbose

 