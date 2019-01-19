# Recipe 10-4 - Configuring a Central Cert Store

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
$sb = {
If ( -NOT (Test-Path c:\SSLCerts)) {
    New-Item  -Path c:\SSLCerts -ItemType Directory | Out-Null
}
$SHT = @{
    Name        = 'SSLCertShare'
    Path        = 'C:\SSLCerts'
    FullAccess  = 'Everyone'
    Description = 'SSL Certificate Share' 
}                   
New-SmbShare @SHT
# create a file on that share
'SSL Cert Share' | Out-File c:\SSLCerts\readme.txt
}
Invoke-Command -ScriptBlock $sb -ComputerName DC1

#  4. Add new SSL Certs and add to root on SRV1
$CHT = @{
    CertStoreLocation = 'CERT:\LocalMachine\MY'
    DnsName           = 'SRV1.Reskit.Org'
}
$SSLCert = New-SelfSignedCertificate @CHT
$C = 'System.Security.Cryptography.X509Certificates.X509Store'
$Store = New-Object -TypeName $C -ArgumentList 'Root','LocalMachine'
$Store.Open(‘ReadWrite’)
$Store.Add($SSLcert)
$Store.Close()

# 5. Export cert to pfx file
$Certpw   = 'SSLCerts101!'
$Certpwss = ConvertTo-SecureString -String $Certpw -Force -AsPlainText
$CertHT = @{
    Cert     = $SSLCert
    FilePath  = 'C:\srv1.reskit.net.pfx'
    Password  = $certpwss
}
Export-PfxCertificate @CertHT @CertHT

$MHT = @{
    Path        = 'C:\srv1.reskit.net.pfx' 
    Destination = '\\dc1\SSLCertShare\srv1.reskit.net.pfx'
    Force       = $True
}
Move-Item @MHT

# 6. Install the CCS feature on SRV1
Install-WindowsFeature Web-CertProvider

# 7. Create a new user for the certifcate sharing:
$User       = 'Reskit\SSLCertShare'
$Password   = 'Pa$$w0rd'
$PSS = ConvertTo-SecureString  -String $Password -AsPlainText -Force
$NewUserHT = @{
    AccountPassword       = $PSS
    Enabled               = $true
    PasswordNeverExpires  = $true
    ChangePasswordAtLogon = $false
    SamAccountName        = SSLCertShare
    UserPrincipalName     = 'SSLCertShare@reskit.org'
    Name                  = "SSLCertShare" 
    DisplayName           = 'SSL Cert Share User'
}
New-ADUser @NewUserHT 

# 8 Configure the SSL Cert share in the registry
$IPHT = @{
    Path  = 'HKLM:\SOFTWARE\Microsoft\IIS\CentralCertProvider\'
    Name  = 'Enabled'
    Value = 1
}
Set-ItemProperty @IPHT
$IPHT.Name              = 'CertStoreLocation'
$IP.Valule              = \\DC1\SSLCertShare
Set-ItemProperty @IPHT
$WCHT = @{
    CertStoreLocation  = '\\DC1\SSLCertShare'
    UserName           = $User
    Password           = $Password
    PrivateKeyPassword = $Certpw
}
Enable-WebCentralCertProvider @WCHT
$CPHT = @{
    UserName           = 'Reskit\sslCertShare'
    Password           = $Password
    PrivateKeyPassword = $Certpw
}
Set-WebCentralCertProvider @CPHT

# 9. And remove the cert from SRV1
Get-ChildItem Cert:\LocalMachine\MY   |
    WHERE-Object SUBJECT -MATCH 'SRV1.RESKIT.ORG' |
       Remove-Item -Force

#  10. Setup SSL for default site
New-WebBinding -Name 'Default Web Site' -Protocol https -Port 443
$SslCert | New-Item -Path IIS:\SslBindings\0.0.0.0!443

#  11. Now view the web site with SSL
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

