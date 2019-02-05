# Recipe 16-7 - Web Pull Server
#
#  Run on SRV1


# 1. Install the xPSDesiredStateConfiguration module from PS Gallery on srv1, 2:
$SB = {
  Install-Module  -Name xPSDesiredStateConfiguration
}
Invoke-Command -ComputerName SRV1 -ScriptBlock $SB
Invoke-Command -ComputerName SRV3 -ScriptBlock $SB


# 2. Remove existing certificates for SRV1, then create Self-Signed Certificate for SRV1:
Get-ChildItem cert:\LocalMachine\root |
  Where Subject -EQ 'CN=srv1.reskit.org' | 
    Remove-Item -Force
$CHT = @{
    CertStoreLocation = 'CERT:\LocalMachine\MY'
    DnsName           = 'SRV1.Reskit.Org'
}
$DscCert = New-SelfSignedCertificate @CHT

# 3. Copy the cert to the root store on SRV2 and SRV1:
$SB1 = {
  Param ($Rootcert) 
  $C = 'System.Security.Cryptography.X509Certificates.X509Store'
  $Store = New-Object -TypeName $C `
                      -ArgumentList 'Root','LocalMachine'
  $Store.Open('ReadWrite')
  $Store.Add($Rootcert)
  $Store.Close()
}
$ICHT1 = @{
    ScriptBlock  = $SB1 
    ComputerName = 'SRV2.Reskit.Org'
    Verbose      = $True 
    ArgumentList = $DscCert
}
Invoke-Command @ICHT1
#    Also copy it to root on SRV1
$ICHT1.ComputerName = 'SRV1.Reskit.Org'
$ICHT2b = @{
    ScriptBlock  = $SB1 
    ComputerName = 'SRV1.Reskit.Org'
    Verbose      = $True 
    ArgumentList = $DscCert
}
Invoke-Command @ICHT2b

# 4. Check Cert on SRV2:
$SB2 = {
  Get-ChildItem Cert:\LocalMachine\root | 
    Where-Object Subject -Match 'SRV1.Reskit.Org'
}
Invoke-Command -ScriptBlock $SB2 -ComputerName SRV2

# 5. Remove existing DSC configuration on SRV1, SRV2:
$SB3 = {
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
Invoke-Command -ComputerName SRV1 -ScriptBlock $SB3
Invoke-Command -ComputerName SRV2 -ScriptBlock $SB3

# 6. Create DSC Service Configuration block to make SRV1 a pull server
$DP = 'C:\ProgramFiles\WindowsPowerShell\' +
      'DscService\RegistrationKeys.txt'
Configuration WebPullSrv1 {
  Param ([String] $CertThumbPrint)
  Import-DscResource -Module PSDesiredStateConfiguration
  Import-DscResource -Module xPSDesiredStateConfiguration

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
   xDSCWebService WebPullSRV1 {
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

# 7. Create the MOF file to configure SRV1:
$TP = $DscCert.Thumbprint
WebPullSrv1 -OutputPath C:\DSC  -CertThumbPrint $TP |
  Out-Null

# 8. Use DSC to configure SRV1 to host DSC Web Service:
Start-DscConfiguration -Path C:\DSC -Wait -Verbose
$DscCert | Set-Item -Path IIS:\SslBindings\0.0.0.0!8080

# 9. Check on the results!
$Uri = 'https://SRV1.Reskit.Org:8080/PSDSCPullServer.svc/' 
Start-Process -FilePath $Uri

# 10. Create an LCM configuration for SRV2 to make it pull from SRV1 via HTTPS:
[DSCLocalConfigurationManager()]
Configuration SRV2WebPull {
Param ([string] $Guid)
Node SRV2 {
 Settings {
   RefreshMode = 'Pull'
   ConfigurationID = $Guid
   ConfigurationMode = 'ApplyANdAUtoCorrect'
   RefreshFrequencyMins = 30 
   RebootNodeIfNeeded = $true  
 }
 ConfigurationRepositoryWeb DSCPullSrv {
  ServerURL = 'https://SRV1.Reskit.Org:8080/PSDSCPullServer.svc'
 }
 ResourceRepositoryWeb DSCResourceSrv {
  ServerURL = 'https://SRV1.Reskit.Org8080/PSDSCPullServer.svc'
 }
 ReportServerWeb DSCReportSrv {
  ServerURL = 'https://SRV1.Reskit.Org:8080/PSDSCPullServer.svc'
 }
} 
}

# 11. Create MOF to config DSC LCM on SRV2:
Remove-Item C:\DSC\* -Rec -Force 
$Guid = '5d79ee6e-0420-4c98-9cc3-9f696901a816'
SRV2WebPull -Guid $Guid -OutputPath C:\DSC | Out-Null

# 12. Config LCM on SRV2:
$LCMHT = @{
  ComputerName = 'SRV2'
  Path         =  'C:\DSC'
  Verbose      = $True
}
Set-DscLocalConfigurationManager @LCMHT

# 13. Create a partial configuration to ensure the NFS Client is present (on SRV2):
Configuration  TFTPSRV2 {
  Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
  Node SRV2 {
    WindowsFeature TFTPClient {
      Name = 'TFTP-Client'
      Ensure = 'Present'  
    }
  }
}

# 14. Create the MOF file for this configuration and place MOF into the config folder
Remove-Item -Path C:\DSCConfiguration -Rec -Force 
TFTPSRV2 -OutputPath C:\DSCConfiguration |
  Out-Null

# 15. Rename the file and create the checksum:
$RIHT = @{
  Path    = 'C:\DSCConfiguration\SRV2.mof'
  NewName = "C:\DSCConfiguration\$Guid.MOF"
}
Rename-Item @RIHT
New-DscChecksum  -Path C:\DSCConfiguration
Get-ChildItem C:\DSCConfiguration

# 16. Wait a while then review details:
Start-Sleep -Seconds 30*60
$Session = New-CimSession -ComputerName SRV2
Get-DscConfiguration -CimSession $Session

# 17. Check on the feature on SRV2:
Get-WindowsFeature -Name TFTP-Client -ComputerName SRV2