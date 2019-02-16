# Recipe 8.4- Creating a Image using a Dockerfile
# 
# run on CH1

# 1. Create folder and Set-location to the folder on CH1
$SitePath = 'C:\RKWebContainer'
$NIHT = @{
  Path         = $SitePath
  ItemType     = 'Directory'
 ErrorAction  = 'SilentlyContinue'
}
New-Item @NIHT | Out-Null
Set-Location -Path $NIHT.Path

# 2. Create a script to run in the container to create a new site in the Containe
$SB = {
# 2.1 create folder in the container
$SitePath = 'C:\RKWebContainer'
$NIHT = @{
  Path         = $SitePath
  ItemType     = 'Directory'
 ErrorAction  = 'SilentlyContinue'
}
New-Item @NIHT | Out-Null
Set-Location -Path $NIHT.Path
# 2.1 Create a page for the site
$PAGE = @'
<!DOCTYPE html>
<html> 
<head><title>Main Page for RKWeb.Reskit.Org</title></head>
<body><p><center><b>
HOME PAGE FOR RKWEBr.RESKIT.ORG</b></p>
Containers and PowerShell Rock!
</center/</body></html>
'@
$PAGE | OUT-FILE $SitePath\Index.html | Out-Null
#2.2 Create a new web site in the container that uses Host headers
$WSHT = @{
  PhysicalPath = $SitePath 
  Name         = 'RKWeb'
  HostHeader   = 'RKWeb.Reskit.Org'
}
New-Website @WSHT  
} # End of script block
# 2.5 Save script block to file
$SB | Out-File $SitePath\Config.ps1

# 3. Create a new A record for our soon to be containerized site:
Invoke-Command -Computer DC1.Reskit.Org -ScriptBlock {
  $DNSHT = @{
    ZoneName  = 'Reskit.Org'
    Name      = 'RKWeb'
    IpAddress = '10.10.10.221'
  }    
  Add-DnsServerResourceRecordA @DNSHT
}

# 4. Create Dockerfile
$DF = @"
FROM mcr.microsoft.com/windows/servercore:1809
LABEL Description="RKWEB Container" Vendor="PS Partnership" Version="1.0.0.42"
RUN powershell -Command Add-WindowsFeature Web-Server
RUN powershell -Command GIP
WORKDIR C:\\RKWebContainer
COPY Config.ps1 \Config.ps1
RUN powershell -command ".\Config.ps1"
"@
# to add in maybe
# Run powershell -Command c:/config.ps1
$DF | Out-File -FilePath .\Dockerfile -Encoding ascii

# 5. Build the image:
docker build -t rkwebc .

# 6. Run the image:
docker run -d --name rkwebc -p 80:80 rkwebc

# 7. Now navigate to the container:
Invoke-WebRequest -UseBasicParsing HTTP://RKweb.Reskit.Org
Start-Process "http://RKWeb.Reskit.Org"

# 8. test net connection
Test-NetConnection -ComputerName localhost -Port 80

# 7. clean up forcibly
docker container rm rkwebc -f
