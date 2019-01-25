# Revipe 10-2 - Configure IIS for SSL/TLS

# 1 - Import the WebAdministration module
Import-Module -Name WebAdministration

# 2 - Create a self signed certificate
$CHT = @{
  CertStoreLocation = 'CERT:\LocalMachine\MY'
  DnsName           = 'SRV1.Reskit.Org'
}
$SSLCert = New-SelfSignedCertificate @CHT

# 3. Copy the certificate to the root store on SRV1:
$C = 'System.Security.Cryptography.X509Certificates.X509Store'
$AL = ‘Root’, ‘LocalMachine’
$Store = New-Object -TypeName $C -ArgumentList $AL
$Store.Open(‘ReadWrite’)
$Store.Add($SSLcert)
$Store.Close()

# 4. Create a new SSL binding on the Default Web Site
$NBHT = @{
  Name     = 'Default Web Site' 
  Protocol = 'https'
  Port     = 443
}
New-WebBinding @NBHT

# 5 ASssign the cert created earlier to this new binding
$SSLCert | New-Item -Path IIS:\SslBindings\0.0.0.0!443

# 6. View the site using https!
$IE  = New-Object -ComObject InterNetExplorer.Application
$URL = 'https://srv1.reskit.org'
$IE.Navigate2($URL)
$IE.Visible = $true




<#  cLEAN UP for testing
ls Cert:\LocalMachine\MY   | WHERE SUBJECT -MATCH 'SRV1.RESKIT.ORG' | ri
ls Cert:\LocalMachine\ROOT | WHERE SUBJECT -MATCH 'SRV1.RESKIT.ORG' | ri
ls IIS:\SslBindings | where port -eq 443 | ri
remove-webbinding -Protocol https
#>