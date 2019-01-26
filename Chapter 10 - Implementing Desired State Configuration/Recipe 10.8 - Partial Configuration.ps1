# Recipe 13-8  Partial Configuration
# Run on SRV1

# 0. Remove any earlier attempts here and bring state on SRV1 back to 'normal.
Remove-WindowsFeature web-server -IncludeManagementTools 
Remove-Item C:\DSCResource -Force
Remove-Item C:\DSCConfiguration
Remove-Item C:\DSC  -Force -Recurse
Remove-Item C:\inetpub\wwwroot\PSDSCPullServer -Recurse


# 1. Create a Self-Signed Certificate On SRV1, copy to root, and display
#    And put it into the MY certs, then copy to Root
Get-ChildItem Cert:LocalMachine\My | 
    Where-Object Subject -eq 'CN=SRV1' |
        Remove-Item -Force
Get-ChildItem Cert:LocalMachine\root |
    Where-Object Subject -eq 'CN=SRV1' |
        Remove-Item -Force
$CHT = @{
    CertStoreLocation = 'CERT:\LocalMachine\MY'
    DnsName           = 'SRV1' 
}
$DscCert = New-SelfSignedCertificate @CHT
# copy it to Root CA (make the cert 'trusted')       
$C = 'System.Security.Cryptography.X509Certificates.X509Store'
$Store = New-Object -TypeName $C -ArgumentList 'Root','LocalMachine'
$Store.Open('ReadWrite')
$Store.Add($Dsccert)
$Store.Close()
$DscCert

#2. Copy the cert to the root store on SRV2 and ensure it's the only one!
$Sb = {
  Param ($Rootcert) 
  Get-ChildItem Cert:LocalMachine\Root | 
      Where-Object Subject -eq 'CN=SRV1' |
          Remove-Item -Force
  $NOHT  = @{         
  Typename     = 'System.Security.Cryptography.X509Certificates.X509Store'
  ArgumentList = ('Root','LocalMachine')
  }
  $Store = New-Object @NOHT
  $Store.Open('ReadWrite')
  $Store.Add($Rootcert)
  $Store.Close()
} # End script block
$ICHT = @{
ScriptBlock  = $Sb 
ComputerName = 'SRV2 '
Verbose      = $true
ArgumentList = $DscCert
}
Invoke-Command @ICHT

# 3. Check Cert on SRV2
Invoke-Command -ScriptBlock {Get-ChildItem Cert:\LocalMachine\root | 
    Where-Object Subject -Match 'SRV1'} -ComputerName SRV2

# 4. Check that xPsDesiredStateConfiguration module is installed on both 
#    SRV1 and SRV2
$ModPath = Join-Path `
       -Path 'C:\Program Files\WindowsPowerShell\Modules' `
       -ChildPath  ‘xPSDesiredStateConfiguration' 
Copy-Item -Path $ModPath `
       -Destination '\\SRV2\C$\Program Files\WindowsPowerShell\Modules' `
       -Recurse -ErrorAction SilentlyContinue
Get-Module xPSDesiredStateConfiguration -ListAvailable
Invoke-Command -ComputerName SRV2 `
               -ScriptBlock {Get-Module xPSDesiredStateConfiguration `
                                          -ListAvailable}


# 5. Create and compile DSC Service Configuration block for SRV1
Configuration WebPullSrv1 {
Param ([String] $CertThumbPrint)
Import-DscResource -Module PSDesiredStateConfiguration

$Regfile= 'C:\Program Files\WindowsPowerShell\DscService\'+
          ‘RegistrationKeys.txt'
Node SRV1 {
    File DSCConfig-Folder{
        DestinationPath   = 'C:\DSCConfiguration'
        Ensure            = 'Present'
        Type              = 'Directory' }
    File DSCResource-Folder{
        DestinationPath   = 'C:\DSCResource'
        Ensure            = 'Present'
        Type              = 'Directory' }
    WindowsFeature DSCService {
        Ensure               =  'Present'
        Name                 =  'DSC-Service' }
    xDscWebService WebPullSRV1 {
       Ensure                = 'Present'
       EndpointName          = 'PSDSCPullServer'
       Port                  = 8080
       PhysicalPath          = 'C:\inetpub\PSDSCPullServer'
       CertificateThumbPrint = $CertThumbPrint   
       ConfigurationPath     = 'C:\DSCConfiguration'
       ModulePath            = 'C:\DSCResource'
       State                 = 'Started'
       DependsOn             = '[WindowsFeature]DSCService'
       UseSecurityBestPractices = $true  }
    File RegistrationKeyFile {
       Ensure                = 'Present'
       Type                  = 'File'
       DestinationPath       = $Regfile
       Contents              = '5d79ee6e-0420-4c98-9cc3-9f696901a816'  }
  }
}

# 6. Remove existing MOF Files then create MOF file for SRV1
Get-ChildItem -Path C:\DSC -ErrorAction SilentlyContinue | 
    Remove-Item -Force | Out-Null
Remove-Item -Path 'C:\Windows\System32\configuration\*.mof' `
            -ErrorAction SilentlyContinue
WebPullSrv1 -OutputPath C:\DSC  -CertThumbPrint $DscCert.Thumbprint

# 7. Add Web Service to SRV1
Start-DscConfiguration -Path C:\DSC -Wait -Verbose

# 8. Check on the results!
#  Note this causes an IE error - but just click to bypass
$IE  = New-Object -ComObject InterNetExplorer.Application
$Uri = 'https://SRV1:8080/PSDSCPullServer.svc/' 
$IE.Navigate2($Uri)
$IE.Visible = $true

# 9. Create a meta configuration to make SRV2 pull from SRV1:
[DSCLocalConfigurationManager()]
Configuration SRV2WebPullPartial {
Node Srv2 {
  Settings
      {  RefreshMode          = 'Pull'
         ConfigurationModeFrequencyMins = 30
         ConfigurationMode    = 'ApplyandAutoCorrect'
         RefreshFrequencyMins = 30 
         RebootNodeIfNeeded   = $true 
         AllowModuleOverwrite = $true }
  ConfigurationRepositoryWeb DSCPullSrv
     {   ServerURL = 'https://SRV1:8080/PSDSCPullServer.svc'
         RegistrationKey = '5d79ee6e-0420-4c98-9cc3-9f696901a816'
         ConfigurationNames = @('TelnetConfig','TFTPConfig')  }
  PartialConfiguration TelnetConfig
     {  Description = 'Telnet Client Configuration'
        Configurationsource = @('[ConfigurationRepositoryWeb]DSCPullSrv')}
  PartialConfiguration TFTPConfig {
        Description = 'TFTP Client Configuration'
        Configurationsource = @('[ConfigurationRepositoryWeb]DSCPullSrv')
        DependsOn   = '[PartialConfiguration]TelnetConfig'}
  } 
}

# 10. Create MOF to config DSC LCM on SRV2
Remove-Item C:\DSCConfiguration\* -Rec -Force 
Remove-Item '\\SRV2\C$\Windows\System32\Configuration\*.mof'
SRV2WebPullPartial -OutputPath C:\DSC | Out-Null

# 11.  Config LCM on SRV2:
$CSSrv2 = New-CimSession -ComputerName SRV2
Set-DscLocalConfigurationManager -CimSession $CSSrv2 `
                                 -Path C:\DSC `
                                 -Verbose

# 12. Create/compile the Telnet Client partial configuration, 
#     and build MOF
$Guid = '5d79ee6e-0420-4c98-9cc3-9f696901a816'
$ConfigData = @{
   AllNodes = @(
      @{ NodeName = '*' ; PsDscAllowPlainTextPassword = $true},
      @{ NodeName = $Guid }
   )
}
Configuration  TelnetConfig {
Import-DscResource –ModuleName PSDesiredStateConfiguration
Node $Allnodes.NodeName {
  WindowsFeature TelnetClient
    { Name     = 'Telnet-Client'
      Ensure   = 'Present'  }
    }
}
TelnetConfig -ConfigurationData $ConfigData -OutputPath C:\DSCConfiguration | Out-Null
Rename-Item  -Path "C:\DSCConfiguration\$Guid.mof" -newname 'c:\DSCConfiguration\TelnetConfig.Mof'

# 13. Create and compile the TFTP client partial configuration
$Guid = '5d79ee6e-0420-4c98-9cc3-9f696901a816'
$ConfigData = @{
   AllNodes = @(
      @{ NodeName = '*' ; PsDscAllowPlainTextPassword = $true},
      @{ NodeName = $Guid }
   )
}
Configuration  TFTPConfig {
Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
Node $AllNodes.NodeName {
WindowsFeature TFTPClient
    { Name     = 'TFTP-Client'
      Ensure   = 'Present'  }
    }
}
$TCHT = @{
ConfigurationData = $ConfigData 
OutputPath        = 'C:\DSCConfiguration\'  
}
TFTPConfig @TCHT |  Out-Null
$RIHT =  @{
Path    = "c:\DSCConfiguration\$Guid.mof" 
NewName = 'TFTPConfig.Mof'
}
Rename-Item  @RIHT

# 14. Create Checksums for these two partial configurations
New-DscChecksum -Path C:\DSCConfiguration

# 15. Observe configuration documents and checksum
Get-ChildItem -Path C:\DSCConfiguration

# 16.  Update it on SRV2
Update-DscConfiguration -ComputerName SRV2 -Wait -Verbose
Test-DSCConfiguration -ComputerName SRV2

# 17. Induce configuration drift
$RFHT = @{
Name          = ('tftp-client', 'telnet-client')
ComputerName  = 'SRV2'
}
Remove-WindowsFeature @RFHT

# 18. Test DSC configuration
Test-DscConfiguration -ComputerName SRV2

# 19. Fix
Start-DscConfiguration -UseExisting -Verbose -Wait -ComputerName SRV2

# 20. Test
Get-WindowsFeature -Name Telnet-Client, TFTP-Client -ComputerName SRV2