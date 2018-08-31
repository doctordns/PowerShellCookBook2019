# Containers - recipe 1 - Setup For containers

# 1. Install nuget provider
Install-PackageProvider -Name nuget -Force

# 2. Install the Docker provider
Install-Module -name DockerMSFTProvider -Repository PSGallery -Force

# 3. Get latest version of the docker package
Install-Package -Name docker -ProviderName DockerMsftProvider -Force

# 4. Ensure Hyper-V and related tools are added:
Add-WindowsFeature Hyper-V -IncludeManagementTools | Out-Null

# 5. Restart the computer to enable docker and containers
Restart-Computer 

# 5. Ensure the docker daemon is running
Start-Service Docker

# 6. Get Base Container Images
docker pull microsoft/nanoserver
docker pull microsoft/windowsservercore

docker run microsoft/dotnet-samples:dotnetapp-nanoserver


