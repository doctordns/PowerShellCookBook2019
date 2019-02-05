# Recipe 13.8  Partial Configuration
#
# Run on SRV1

# 1. Remove existing certificates for SRV1, then create Self-Signed Certificate for SRV1.
Get-ChildItem cert:\LocalMachine\root |
  Where Subject -EQ 'CN=SRV1.Reskit.org' | 
    Remove-Item -Force
Get-ChildItem cert:\LocalMachine\my |
  Where Subject -EQ 'CN=SRV1.Reskit.Org' | 
    Remove-Item -Force
$CHT = @{
  CertStoreLocation = 'CERT:\LocalMachine\MY'
  DnsName           = 'SRV1.Reskit.Org'
}
$DscCert = New-SelfSignedCertificate @CHT

# 2. Copy the cert to the root store on SRV2 and SRV1:
$SB1 = {
  Param ($Rootcert) 
  $C = 'System.Security.Cryptography.X509Certificates.X509Store'
  $NOHT = @{
    TypeName     = $C
    ArgumentList = @('Root','LocalMachine')
  }
  $Store = New-Object @NOHT
  $Store.Open('ReadWrite')
  $Store.Add($Rootcert)
  $Store.Close()
}
$ICHT1 = @{
  ScriptBlock  = $SB1 
  ComputerName = 'SRV2.Reskit.Org'
  ArgumentList = $DscCert
}
# run script block on SRV2
Invoke-Command @ICHT1
# and copy it to root on SRV1
$ICHT2= @{
  ScriptBlock  = $SB1 
  ComputerName = 'SRV1.Reskit.Org'
  Verbose      = $True 
  ArgumentList = $DscCert
}
Invoke-Command @ICHT2

# 3. Check Cert on SRV2
$SB2 = {
  Get-ChildItem Cert:\LocalMachine\root | 
    Where-Object Subject -Match 'SRV1.Reskit.Org' 
}
Invoke-Command -ScriptBlock $SB2 -ComputerName SRV2

# 4. Remove existing configuration on SRV1, SRV2
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

# 5. Check that xPsDesiredStateConfiguration module is installed on both 
#    SRV1 and SRV2
$SB2 = {
  Install-Module -Name xPSDesiredStateConfiguration -Force
}
Invoke-Command -Computer SRV1 -ScriptBlock $SB2
Invoke-Command -Computer SRV2 -ScriptBlock $SB2

# 6. Create and compile DSC Service Configuration block for SRV1
Configuration WebPullSrv1 {
  Param ([String] $CertThumbPrint)
  Import-DscResource -Module PSDesiredStateConfiguration
  Import-DscResource -Module xPSDesiredStateConfiguration
  $Regfile= 'C:\Program Files\WindowsPowerShell\DscService\'+
            ‘RegistrationKeys.txt'
Node SRV1 {
   $Key = '5d79ee6e-0420-4c98-9cc3-9f696901a816'
   WindowsFeature IIS1 {
     Ensure           = 'Present'
     Name             = 'Web-Server'
   }
    File DSCConfig-Folder {
    DestinationPath   = 'C:\DSCConfiguration'
    Ensure            = 'Present'
    Type              = 'Directory' }
  File DSCResource-Folder{
    DestinationPath   = 'C:\DSCResource'
    Ensure            = 'Present'
    Type              = 'Directory' }
  WindowsFeature DSCService {
    DependsOn          =  '[WindowsFeature]IIS1'   
    Ensure             =  'Present'
    Name               =  'DSC-Service' }
  xDscWebService WebPullSRV1 {
    Ensure             = 'Present'
    EndpointName       = 'PSDSCPullServer'
    Port               = 8080
    PhysicalPath       = 'C:\inetpub\PSDSCPullServer'
    CertificateThumbPrint = $CertThumbPrint   
    ConfigurationPath  = 'C:\DSCConfiguration'
    ModulePath         = 'C:\DSCResource'
    State              = 'Started'
    DependsOn          = '[WindowsFeature]DSCService','[WindowsFeature]IIS1'
    UseSecurityBestPractices = $true  }
  File RegistrationKeyFile {
    Ensure                = 'Present'
    Type                  = 'File'
    DestinationPath       = $Regfile
    Contents              = $Key  }
 } # End of Node configuration 
} # End of Confiuration

# 7. Remove any existing MOF Files on SRV1 then create MOF file for SRV1
Get-ChildItem -Path C:\DSC -ErrorAction SilentlyContinue | 
    Remove-Item -Force | Out-Null
WebPullSrv1 -OutputPath C:\DSC  -CertThumbPrint $DscCert.Thumbprint

# 8. Configure SRV1 to host DSC Web Service
Start-DscConfiguration -Path C:\DSC -Wait -Verbose
Import-Module -Name WebAdministration
$DscCert | Set-Item -Path IIS:\SslBindings\0.0.0.0!8080

# 9. Check on the results!
$URI = 'https://SRV1.Reskit.Org:8080/PSDSCPullServer.svc/' 
Start-Process -FilePath $URI

# 10. Create a meta configuration to make SRV2 pull two partial configuration blocks from SRV1:
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
  ConfigurationRepositoryWeb DSCPullSrv {
    ServerURL = 'HTTPS://SRV1.Reskit.Org:8080/PSDSCPullServer.svc'
    RegistrationKey = '5d79ee6e-0420-4c98-9cc3-9f696901a816'
    ConfigurationNames = @('NFSConfig','SMBConfig') }
  PartialConfiguration NFSConfig {
    Description = 'NFS Client Configuration'
    Configurationsource = @('[ConfigurationRepositoryWeb]DSCPullSrv')}
  PartialConfiguration SMBConfig {
    Description = 'FS-SMB1 Client Removal'
    Configurationsource = @('[ConfigurationRepositoryWeb]DSCPullSrv')
    DependsOn   = '[PartialConfiguration]NFSConfig'
  }
 } # End Node 2 Configuration 
}

# 11. Create MOF to config DSC LCM on SRV2
SRV2WebPullPartial -OutputPath C:\DSC | Out-Null

# 12.  Config LCM on SRV2:
$CSSrv2 = New-CimSession -ComputerName SRV2
$LCMHT = @{
  CimSession = $CSSrv2
  Path       = 'C:\DSC'
  Verbose    = $true
}
Set-DscLocalConfigurationManager @LCMHT

# 13. Create/compile the NFS Client partial configuration, 
#     and build MOF
$Guid = '5d79ee6e-0420-4c98-9cc3-9f696901a816'
$ConfigData = @{
  AllNodes  = @(
    @{ NodeName = '*' ; PsDscAllowPlainTextPassword = $true},
    @{ NodeName = $Guid }
  )
}
Configuration  NFSConfig {
  Import-DscResource –ModuleName PSDesiredStateConfiguration
  Node $Allnodes.NodeName {
    WindowsFeature NFSClientPresent { 
      Name     = 'NFS-Client'
      Ensure   = 'Present'  
    }    
  }
}
$CHT1 = @{
  ConfigurationData = $ConfigData
  OutputPath        = 'C:\DSCConfiguration'
}
NFSConfig @CHT1 
$RIHT = @{
  Path     = "C:\DSCConfiguration\$Guid.mof"
  Newname  = 'C:\DSCConfiguration\NFSConfig.MOF'
}
Rename-Item  @RIHT

# 14. Create and compile the SMB client partial configuration which ensures SMB is Absent
$Guid = '5d79ee6e-0420-4c98-9cc3-9f696901a816'
$ConfigData = @{
   AllNodes = @(
      @{ NodeName = '*' ; PsDscAllowPlainTextPassword = $true},
      @{ NodeName = $Guid }
   )
}
Configuration  SMBConfig {
  Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
  Node $AllNodes.NodeName {
  WindowsFeature SMB1 {
    Name   = 'FS-SMB1'
    Ensure = 'Absent'
  }
}
}
$SMBHT = @{
  ConfigurationData = $ConfigData 
  OutputPath        = 'C:\DSCConfiguration\'  
}
SMBConfig @SMBHT |  Out-Null
$RIHT =  @{
  Path    = "C:\DSCConfiguration\$Guid.mof" 
  NewName = 'C:\DSCConfiguration\SMBConfig.Mof'
}
Rename-Item  @RIHT

# 15. Create Checksums for these two partial configurations
New-DscChecksum -Path C:\DSCConfiguration

# 16. Observe configuration documents and checksum
Get-ChildItem -Path C:\DSCConfiguration

# 17. Check status
Get-WindowsFeature -ComputerName SRV2 -Name 'FS-SMB1',
                                            'NFS-Client' 
# 18. Test DSC configuration
Test-DscConfiguration -ComputerName SRV2  -Verbose