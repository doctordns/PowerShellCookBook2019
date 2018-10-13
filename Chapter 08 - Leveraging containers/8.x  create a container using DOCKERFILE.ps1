# Recipe 8.X- Creating a Image using a DOCKERFILE
# 
# run on CH2
# 1. Create folder and move there
New-Item -Path c:\foo\iiscontainer -ErrorAction SilentlyContinue -ItemType Directory
Set-Location -Path c:\foo\iiscontainer

# 2. Create docker file 
$DF = @"
FROM mcr.microsoft.com/windowsservercore-insider:10.0.17733.1000
LABEL Description="IIS" Vendor="Microsoft" Version="Server2019"
RUN powershell -Command Add-WindowsFeature Web-Server
RUN powershell -Command GIP
CMD [ "ping", "localhost", "-t" ]
"@
$DF | Out-File -FilePath c:\foo\iiscontainer\DOCKERFILE -Encoding ascii

# 3. Build the image
docker build -t iis .

# 4. Run the image
docker run --name iisdemo -p 80:80 iis

# 4. Run 