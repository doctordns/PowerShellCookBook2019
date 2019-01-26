#    RECIPE 13-5 - Configuring Local Configuration Manager

# 1. Create and run the meta-configuration for LCM on SRV2
[DSCLocalConfigurationManager()]
Configuration LCMConfig
{
    Node localhost
    {
        $SG = '5d79ee6e-0420-4c98-9cc3-9f696901a816'
        Settings {
            ConfigurationModeFrequencyMins = '30'
            ConfigurationMode              = 'ApplyAndAutoCorrect'
            RebootNodeIfNeeded             = $true
            ActionAfterReboot              = 'ContinueConfiguration'
            RefreshMOde                    = 'Pull'
            RefreshFrequencyMins           = '45'
            AllowModuleOverwrite           = $true
            ConfigurationID                = $SG
        }
        ConfigurationRepositoryShare PullServer {
            SourcePath = '\\SRV1\DSCConfiguration'
        }
        ResourceRepositoryShare ResourceServer {
            SourcePath = '\\SRV1\DSCResource'
        }
    }
}

# 2. Create the meta-configuration MOF on SRV2:
New-Item -Path c:\DSC -ErrorAction SilentlyContinue
Remove-Item C:\DSC -Recurse | Remove-Item -Force
LCMConfig -OutputPath C:\DSC

# 3. Configure SRV2:
Set-DscLocalConfigurationManager -Path C:\DSC

# 4. Examine LCM configuration:
Get-DscLocalConfigurationManager

# 5. Examine pull server information:
Get-DscLocalConfigurationManager |
    Select-Object -ExpandProperty ConfigurationDownloadManagers
Get-DscLocalConfigurationManager |
    Select-Object -ExpandProperty ResourceModulemanagers