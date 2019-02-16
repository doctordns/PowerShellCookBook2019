# Recipe 8.X- Creating a Image using a Dockerfile
# 
# run on CH1

# 1. Create folder and Set-location to here
$NIHT = @{
Path         = 'C:\Foo\IISContainer'
ItemType     = 'Directory'
ErrorAction  = 'SilentlyContinue'
}
New-Item @NIHT
Set-Location -Path $NIHT.Path
  
# 2. Create DOCKERFILE
$DF = @"
FROM mcr.microsoft.com/windows/servercore:1809
LABEL Description="IISDemo" Vendor="Microsoft" Version="Server2019"
RUN powershell -Command Add-WindowsFeature Web-Server
RUN powershell -Command GIP
"@
$DF | Out-File -FilePath .\DOCKERFILE -Encoding ascii

# 3. Build the image
docker build -t iis .

# 4. Run the image
docker run --name iisdemo -p 80:80 iis

# 5. Navigate to it
Start-Process "http://ch1/"