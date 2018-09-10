# Recipe 1.6 - Establishing a script signing envionment
# Performed on CL1

# 1. Create a script-signing certificate
$CHT = @{
  Subject           = 'Reskit Code Signing'
  Type              = 'CodeSigning' 
  CertStoreLocation = 'Cert:\CurrentUser\My'
}
$Cert = New-SelfSignedCertificate @CHT

# 2. Display newly created certificate
Get-ChildItem -Path Cert:\CurrentUser\my -CodeSigningCert | 
  Where-Object {$_.Subjectname.Name -match $CHT.Subject}

# 3. Create a simple script
$Script = @"
 # Sample Script
 'Hello World!'
 Hostname
"@
$Script | Out-File -FilePath c:\foo\signed.ps1
Get-ChildItem -Path C:\foo\signed.ps1

# 4. Sign the script
$SHT = @{
  Certificate = $cert
  FilePath    = 'C:\foo\signed.ps1'
}
Set-AuthenticodeSignature @SHT

# 5. Look at script after signing
Get-ChildItem -Path C:\foo\signed.ps1

# 6. Test the signature
Get-AuthenticodeSignature -FilePath C:\foo\signed.ps1 |
  Format-List

# 7. Ensure certificate is trusted
# Note ugly construct in opening the store!
$DestStoreName  = 'Root'
$DestStoreScope = 'CurrentUser'
$Type   = 'System.Security.Cryptography.X509Certificates.X509Store'
$MHT = @{
  TypeName = $Type  
  ArgumentList  = ($DestStoreName, $DestStoreScope)
}
$DestStore = New-Object  @MHT
$DestStore.Open(
  [System.Security.Cryptography.X509Certificates.OpenFlags]::
    ReadWrite)
$DestStore.Add($cert)
$DestStore.Close()

# 8. Resign With a trusted cert 
Set-AuthenticodeSignature @SHT  | Out-Null

# 9. Check the cert
Get-AuthenticodeSignature -FilePath C:\foo\signed.ps1 | 
  Format-List






# UnDo 

Gci cert:\ -recurse | where subject -match 'Reskit Code Signing' | RI -Force
ri C:\foo\signed.ps1


