# Recipe 16-7 - Web Pull Server
#

# 1. Create Self-Signed Certificate for SRV1 and copy to SRV2
$CHT = @{
    CertStoreLocation = 'CERT:\LocalMachine\MY'
    DnsName           = 'SRV1'
}
$DscCert = New-SelfSignedCertificate @$CHT

#2. Copy the cert to the root store on SRV2:
$Sb = {
  Param ($Rootcert) 
  $C = 'System.Security.Cryptography.X509Certificates.X509Store'
  $Store = New-Object -TypeName $C `
                      -ArgumentList 'Root','LocalMachine'
  $Store.Open('ReadWrite')
  $Store.Add($Rootcert)
  $Store.Close()
}
$ICHT = @{
    ScriptBlock  = $Sb 
    ComputerName = 'SRV2'
    Verbose      = $True 
    ArgumentList = $DscCert
}
Invoke-Command @ICHT

# 3. Check Cert on SRV2
$SB = 
    Get-ChildItem Cert:\LocalMachine\root | 
        Where-Object Subject -Match 'SRV1'
{}
Invoke-Command -ScriptBlock $SB -ComputerName SRV2

# 4. Create DSC Service Configuration block
$DP = 'C:\ProgramFiles\WindowsPowerShell\' +
    'DscService\RegistrationKeys.txt'

Configuration WebPullSrv1 {
    Param ([String] $CertThumbPrint)
    Import-DscResource -Module PSDesiredStateConfiguration
    Node SRV1 {
        File DSCConfig-Folder {
            DestinationPath = 'C:\DSCConfiguration'
            Ensure = 'Present'
            Type = 'Directory' 
        }
        File DSCResource-Folder {
            DestinationPath = 'C:\DSCResource'
            Ensure = 'Present'
            Type = 'Directory' 
        }
        WindowsFeature DSCService {
            Ensure = 'Present'
            Name = 'DSC-Service' 
        }
        xDscWebService WebPullSRV1 {
            Ensure = 'Present'
            EndpointName = 'PSDSCPullServer'
            Port = 8080
            PhysicalPath = 'C:\inetpub\wwwroot\PSDSCPullServer'
            CertificateThumbPrint = $CertThumbPrint   
            ConfigurationPath = 'C:\DSCConfiguration'
            ModulePath = 'C:\DSCResource'
            State = 'Started'
            DependsOn = '[WindowsFeature]DSCService'
            UseSecurityBestPractices = $true  
        }
        File RegistrationKeyFile {
            Ensure = 'Present'
            Type = 'File'
            DestinationPath = $DP
            Contents = '5d79ee6e-0420-4c98-9cc3-9f696901a816'
        }
    }
}

# 5. Remove existing MOF Files then create MOF file
New-Item -Path C:\DSC -ItemType Directory `
    -ErrorAction SilentlyContinue | Out-Null
Get-ChildItem -Path C:\DSC | Remove-Item -Force | Out-Null
Remove-Item -Path 'C:\Windows\System32\configuration\*.mof' `
    -ErrorAction SilentlyContinue
WebPullSrv1 -OutputPath C:\DSC  -CertThumbPrint $DscCert.Thumbprint

# 6. Add Web Service to SRV1
Start-DscConfiguration -Path C:\DSC -Wait -Verbose

# 7. Check on the results!
#  Note this causes an IE error - but just click to bypass
$IE = New-Object -ComObject InterNetExplorer.Application
$Uri = 'https://SRV1:8080/PSDSCPullServer.svc/' 
$IE.Navigate2($Uri)
$IE.Visible = $TRUE

# 8. Create a configuration to make SRV2 pull from SRV1:
[DSCLocalConfigurationManager()]
Configuration SRV2WebPull {
    param ([string] $Guid)
    Node SRV2 {
        Settings {
            RefreshMode = 'Pull'
            ConfigurationID = $Guid
            RefreshFrequencyMins = 30 
            RebootNodeIfNeeded = $true  
        }
        ConfigurationRepositoryWeb DSCPullSrv
        {  ServerURL = 'https://SRV1:8080/PSDSCPullServer.svc'  }
        ResourceRepositoryWeb DSCResourceSrv
        {  ServerURL = 'https://SRV1:8080/PSDSCPullServer.svc' }
        ReportServerWeb DSCReportSrv
        {  ServerURL = 'https://SRV1:8080/PSDSCPullServer.svc'  }
    } 
}

# 9. Create MOF to config DSC LCM on SRV2
Remove-Item C:\DSC\* -Rec -Force 
$Guid = '5d79ee6e-0420-4c98-9cc3-9f696901a816'
SRV2WebPull -Guid $Guid -OutputPath C:\DSC

# 10. Config LCM on SRV2:
Set-DscLocalConfigurationManager -ComputerName SRV2 `
    -Path C:\DSC `
    -Verbose

# 11. Create and compile a config that SRV2 is to pull:
Configuration  TelnetSRV2 {
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    Node SRV2 {
        WindowsFeature TelnetClient {
            Name = 'Telnet-Client'
            Ensure = 'Present'  
        }
    }
}

# 12 Render the MOF file for this configuration
Remove-Item -Path C:\DSCConfiguration -Rec -Force 
TelnetSRV2 -OutputPath C:\DSCConfiguration

#  13. Rename the file and create the checksum
Rename-Item -Path    C:\DSCConfiguration\SRV2.mof `
    -NewName C:\DSCConfiguration\$Guid.MOF
New-DscChecksum  -Path C:\DSCConfiguration
Get-ChildItem C:\DSCConfiguration

#  14  Update it
Update-DscConfiguration -ComputerName SRV2 -Wait -Verbose

#  15. And review details
$Session = New-CimSession -ComputerName SRV2
Get-DscConfiguration -CimSession $Session
