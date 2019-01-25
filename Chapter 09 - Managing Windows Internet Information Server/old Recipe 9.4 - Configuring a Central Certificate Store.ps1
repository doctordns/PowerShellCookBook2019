# Recipe 10-4 - Configuring a Central Cert Store
#
#  Run on SRV1

#  1. Remove existing certificates
Get-ChildItem Cert:\localmachine\My | 
  Where-Object Subject -Match 'SRV1.Reskit.Org' |
    Remove-Item -ErrorAction SilentlyContinue
Get-ChildItem Cert:\localmachine\root |
  Where-Object Subject -match 'SRV1.Reskit.Org' |
    Remove-Item -ErrorAction SilentlyContinue

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
  # Create folder
  If (-NOT (Test-Path c:\SSLCerts)) {
       New-Item  -Path c:\SSLCerts -ItemType Directory |
         Out-Null
  }
  # Create Share
  $SHT = @{
    Name        = 'SSLCertShare'
    Path        = 'C:\SSLCerts'
    FullAccess  = 'Everyone'
    Description = 'SSL Certificate Share' 
  }                     
  New-SmbShare @SHT
  # create a file on that share
  'SSL Cert Share' | Out-File -FilePath c:\SSLCerts\Readme.Txt  
}
Invoke-Command -ScriptBlock $SB -ComputerName DC1 |
  Out-Null

# 4. Check file on share on DC1
Get-ChildItem -Path \\DC1\SSLCertShare\

# 5. Create a new SSL Certs and add to root on SRV1
$CHT = @{
  CertStoreLocation = 'CERT:\LocalMachine\MY'
  DnsName           = 'SRV1.Reskit.Org'
}
$SSLCert = New-SelfSignedCertificate @CHT
$C       = 'System.Security.Cryptography.X509Certificates.X509Store'
$Store   = New-Object -TypeName $C -ArgumentList 'Root',
                                               'LocalMachine'
$Store.Open(‘ReadWrite’)
$Store.Add($SSLcert)
$Store.Close()

# 6. Export cert to pfx file to C: then move it to DC1
$Certpw   = 'SSLCerts101!'
$Certpwss = 
  ConvertTo-SecureString -String $Certpw -Force -AsPlainText
$CertHT = @{
  Cert      = $SSLCert
  FilePath  = 'C:\SRV1.Reskit.Net.pfx'
  Password  = $certpwss
}
Export-PfxCertificate @CertHT | Out-Null
$MHT = @{
  Path        = 'C:\Srv1.Reskit.Net.pfx' 
  Destination = '\\DC1\SSLCertShare\Srv1.Reskit.Net.pfx'
  Force       = $true
}
Move-Item @MHT

# 7. Install the CCS feature on SRV1
Install-WindowsFeature Web-CertProvider

# 8. Create a new user for the certifcate sharing:
$User       = 'Reskit\SSLCertShare'
$Password   = 'Pa$$w0rd'
$PSS = ConvertTo-SecureString  -String $Password -AsPlainText -Force
$NewUserHT = @{
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

# 9 Configure the SSL Cert share in the registry
$IPHT = @{
  Path  = 'HKLM:\SOFTWARE\Microsoft\IIS\CentralCertProvider\'
  Name  = 'Enabled'
  Value = 1
}
Set-ItemProperty @IPHT
$IPHT.Name              = 'CertStoreLocation'
$IPHT.Value             = '\\DC1\SSLCertShare'
Set-ItemProperty @IPHT

# 10. Enable the Web central cert provider
$WCHT = @{
  CertStoreLocation  = '\\DC1\SSLCertShare'
  UserName           = $User
  Password           = $Password
  PrivateKeyPassword = $Certpw
}
Enable-WebCentralCertProvider @WCHT

# 11. Configure CCS
$CPHT = @{
  UserName           = 'Reskit\SSLCertShare'
  Password           = $Password
  PrivateKeyPassword = $Certpw
}
Set-WebCentralCertProvider @CPHT

# 12. Set web binding
$WBHT = @{
  Name        = 'Default Web Site'
  IPAddress   = '*' 
  Protocol    = 'https'
  HostHeader  = 'srv1.reskit.org'
  SslFlags    = 3
  Port        = 443
}
New-WebBinding  @WBHT
$SSLCert | New-Item -Path "IIS:\SslBindings\0.0.0.0!443"

# try this - but it fails too...
$RCertHT = @{
  Path      = 'IIS:\SslBindings\0.0.0.0!443'
#  Cert      = $SSLCert
# FilePath  = '\\dc1\SSLCertShare\SRV1.Reskit.Net.pfx'
#  Password  = $certpwss
}
New-Item @RCertHT


# ok...

$WBHT2 = @{
  Name        = 'Default Web Site' 
  Protocol    = 'https'
  hostheader  =  'srv1.RESKIT.ORG'
  SslFlags    = 3
}
New-WebBinding  @WBHT2
$CertHT | New-Item -Path IIS:\SslBindings\0.0.0.0!443


New-Item -Path "IIS:\SslBindings\!443!$srv1.reskit.org" -Value $certht.cert -SSLFlags 1
# no good...



# 12. And remove the cert from SRV1
Get-ChildItem Cert:\LocalMachine\MY   |
  Where-Object SUBJECT -MATCH 'SRV1.RESKIT.ORG' |
     Remove-Item -Force


#  14. Now view the web site with SSL
$IE  = New-Object -ComObject InterNetExplorer.Application
$URL = 'https://srv1.reskit.org/'
$IE.Navigate2($URL)
$IE.Visible = $true





# Clean up for testing

$sb = {
Get-SmbShare 'SSLCertShare' | Remove-SmbShare -force
Remove-Item  -Path c:\SSLCerts -Incl *.* -Recurse
}
Invoke-Command -ScriptBlock $sb -ComputerName DC1

