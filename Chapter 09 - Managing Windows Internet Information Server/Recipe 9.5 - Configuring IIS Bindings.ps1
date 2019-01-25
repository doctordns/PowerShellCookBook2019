# Recipe 9.5 - Configure IIS bindings
#
# Run on SRV1 after running 9.1

# 1. Import the web administration module
Import-Module -Name WebAdministration

# 2. Create and populate a new page
$SitePath = 'C:\inetpub\WWW2'
New-Item $SitePath -ItemType Directory | Out-Null
$page = @'
<!DOCTYPE html>
<html>
<head><title>Main Page for WWW2.Reskit.Org</title></head>
<body><p><center>
<b>HOME PAGE FOR WWW2.RESKIT.ORG</b></p>
This is the root page for this site
</body>
</html>
'@
$PAGE | OUT-FILE $sitepath\INDEX.HTML | Out-Null

# 3.Create a new web site that uses Host headers
$WSHT = @{
  PhysicalPath = $SitePath 
  Name         = 'WWW2'
  HostHeader   = 'WWW2.reskit.org'
}
New-Website @WSHT  
            

# 4. Create DNS record on DC1
Invoke-Command -Computer DC1.Reskit.Org -ScriptBlock {
  $DNSHT = @{
    ZoneName  = 'Reskit.Org'
    Name      = 'www2'
    IpAddress = '10.10.10.50'
  }    
  Add-DnsServerResourceRecordA @DNSHT
}

# 5. And show the site
$IE  = New-Object -ComObject InterNetExplorer.Application
$URL = 'http://www2.reskit.org'
$IE.Navigate2($URL)
$IE.Visible = $true