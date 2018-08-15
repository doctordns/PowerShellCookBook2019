# Recipe 1.6 - Establishing a script signing envionment
# Performed on CL1

# 0. Creeate the C:\Foo folder
#    If it exists, just ignore any error
New-item -Name Foo -path C:\ -ItemType Directory -ErrorAction SilentlyContinue

# 1. Create a script-signing certificate
$CHT = @{
  DnsName           = 'CodeSign.Reskit.Org'
  Type              = 'CodeSigning' 
  CertStoreLocation = 'Cert:\CurrentUser\My'
}
$cert = New-SelfSignedCertificate @CHT

# 2. Display Cert and show cert in store
$Cert
Get-ChildItem Cert:\CurrentUser\my -CodeSigningCert | 
  Where-Object {$_.Subjectname.Name -eq "CN=$($CHT.DnsName)"}

# 32. View the certificate in the loca$Rl user certificate store
$SHT = @{
    TypeName     = 'System.Security.Cryptography.X509Certificates.X509Store'
    ArgumentList = @($DestStoreName, $DestStoreScope)
}
$DestStore = New-Object  @SHT
$StoreF = [System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite

$DestStore.Add($cert)


$SourceStore.Close()
$DestStore.Close()
   

# 3. Ensure certificate is trusted
$DestStoreScope = 'LocalMachine'
$DestStoreName = 'TrustedPublisher'

$DestStore = New-Object  -TypeName System.Security.Cryptography.X509Certificates.X509Store  -ArgumentList $DestStoreName, $DestStoreScope
$DestStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
$DestStore.Add($cert)
$DestStore.Close()

L





# 3. Create a simple script
$Script = @"
 # Sample Script
 Write-Output -Inputobject "Hello World!"
 Hostname
"@
$Script | Out-File -FilePath-    
