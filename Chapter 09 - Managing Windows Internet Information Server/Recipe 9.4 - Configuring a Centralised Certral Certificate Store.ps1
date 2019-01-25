# Recipe 10-4 - Central Cert Store

#  1. Remove existing certificates
Get-ChildItem Cert:\localmachine\My | 
  Where-Object Subject -Match 'SRV1.Reskit.Org' |
    Remove-Item -ErrorAction SilentlyContinue
Get-ChildItem Cert:\localmachine\root |
  Where-Object Subject -match 'SRV1.Reskit.Org' |
    Remove-Item

#  2. Remove SSL web bindings if any exist
Import-Module -Name WebAdministration
Get-WebBinding |
  Where-Object protocol -EQ 'https' |
    Remove-WebBinding
Get-ChildItem IIS:\SslBindings |
  Where-Object Port -eq 443 |
     Remove-Item

# 3. Create shared folder and share it on DC1
$SB = {
  If ( -NOT (Test-Path c:\SSLCerts)) {
     New-Item  -Path c:\SSLCerts -ItemType Directory |
                   Out-Null}
  $SHAREHT= @{
    Name        = 'SSLCertShare'
    Path        = 'C:\SSLCerts'
    FullAccess  = 'Everyone'
    Description = 'SSL Certificate Share'
  }
  New-SmbShare @SHAREHT
  'SSL Cert Share' | Out-File C:\SSLCerts\Readme.Txt
}
Invoke-Command -ScriptBlock $SB -ComputerName DC1 |
  Out-Null

#  4. Check Share
New-SmbMapping -LocalPath X: -RemotePath \\dc1\SSLCertShare |
    Out-Null
Get-ChildItem -Path X:

# 5. Add new SSL Certs and add to root on SRV1
$SSLHT = @{
  CertStoreLocation = 'CERT:\LocalMachine\MY'
  DnsName           = 'SRV1.Reskit.Org'
}
$SSLCert = New-SelfSignedCertificate @SSLHT
$C = 'System.Security.Cryptography.X509Certificates.X509Store'
$NOHT = @{
  TypeName     = $C
  ArgumentList = 'Root','LocalMachine'
}
$Store = New-Object @NOHT
$Store.Open(‘ReadWrite’)
$Store.Add($SSLcert)
$Store.Close()

# 6. Export cert to pfx file
$Certpw   = 'SSLCerts101!'
$Certpwss = ConvertTo-SecureString -String $Certpw -Force -AsPlainText
$CertHT = @{
    Cert      = $SSLCert
    FilePath  = 'C:\Srv1.Reskit.Org.pfx'
    Password  = $Certpwss
}
Export-PfxCertificate @CertHT 


# 7. Move cert to DC1 SSLCertShare
$MHT = @{
    Path        = 'C:\SRV1.Reskit.Org.pfx' 
    Destination = '\\DC1\SSLCertShare\Srv1.Reskit.Org.Pfx'
    Force       = $True
}
Move-Item @MHT

# 8. Install the CCS feature on SRV1
Install-WindowsFeature Web-CertProvider 

# 9. Create a new user for the certifcate sharing:
$User       = 'Reskit\SSLCertShare'
$Password   = 'Pa$$w0rd'
$SSHT2 = @{
  String      = $Password 
  AsPlainText = $true
  Force       = $True
}
$PSS = ConvertTo-SecureString  @SSHT2
$NewUserHT  = @{
  AccountPassword       = $PSS
  Enabled               = $true
  PasswordNeverExpires  = $true
  ChangePasswordAtLogon = $false
  SamAccountName        = 'SSLCertShare'
  UserPrincipalName     = 'SSLCertShare@reskit.org'
  Name                  = 'SSLCertShare' 
  DisplayName           = 'SSL Cert Share User'
}
New-ADUser @NewUserHT 

# 10 Configure the SSL Cert share in the registry
$IPHT = @{
    Path   = 'HKLM:\SOFTWARE\Microsoft\IIS\CentralCertProvider\'
    Name   = 'Enabled'
    Value  = 1
    }
Set-ItemProperty @IPHT
$IPHT.Name              = 'CertStoreLocation'
$IPHT.Value               = '\\DC1\SSLCertShare'
Set-ItemProperty @IPHT

# 11. Enable SSL Cert Service
$WCHT = @{
    CertStoreLocation  = '\\DC1\SSLCertShare'
    UserName           = $User
    Password           = $Password
    PrivateKeyPassword = $Certpw
}
Enable-WebCentralCertProvider @WCHT
$CPHT = @{
    UserName           = 'Reskit\SSLCertShare'
    Password           = $Password
    PrivateKeyPassword = $Certpw
}
Set-WebCentralCertProvider @CPHT

# 12. Setup SSL for default site
New-WebBinding -Name 'Default Web Site' -Protocol https -Port 443
$SslCert | New-Item -Path IIS:\SslBindings\0.0.0.0!443


# 13. And remove the cert from SRV1
Get-ChildItem Cert:\LocalMachine\My   |
  Where-Object Subject -Match 'SRV1.RESKIT.ORG' |
    Remove-Item -Force

# 14. Now view the web site with SSL
$IE  = New-Object -ComObject InterNetExplorer.Application
$URL = 'HTTPS://SRV1.Reskit.Org/'
$IE.Navigate2($URL)
$IE.Visible = $true



DIR Cert:\CurrentUser\MY\s* -REC | FT NAME

  



# Clean up for testing

$sb = {
Get-SmbShare 'SSLCertShare' | Remove-SmbShare -force
RI  -Path c:\SSLCerts -Incl *.* -Recurse
}
Invoke-Command -ScriptBlock $sb -ComputerName DC1

