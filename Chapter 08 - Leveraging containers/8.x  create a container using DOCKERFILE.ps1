# Recipe 8.X- Creating a Image using a DOCKERFILE
# 
# run on CH1

# 1. Create folder and Set-location to here
$NIHT = @{
Path         = 'C\Foo\IISContainer'
ItemType     = 'Directory'
ErrorAction  = 'SilentlyContinue'
}
New-Item @NIHT
Set-Location -Path $NIHT.Path
  
# 2. Create DOCKERFILE
$DF = @"
FROM mcr.microsoft.com/windows/servercore
LABEL Description="IIS" Vendor="Microsoft" Version="Server2019"
RUN powershell -Command Add-WindowsFeature Web-Server
RUN powershell -Command GIP
CMD [ "ping", "localhost", "-t" ]
"@
$DF | Out-File -FilePath c:\foo\iiscontainer\DOCKERFILE -Encoding ascii

# 3. Build the image
Set-Location -Path C:\foo\iiscontainer
docker build -t iis .

# 4. Run the image
docker run --name iisdemo -p 80:80 iis

# 5. Navigate to it
Start-Process "http://ch1/"