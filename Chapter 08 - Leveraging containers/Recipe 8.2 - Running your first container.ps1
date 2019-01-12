# Recipe 8.1 - Setting up a container host

# Run on CH1

# 1. Install nuget provider
Install-PackageProvider -Name nuget -Force

# 2. Install the Docker provider
Install-Module -name DockerMSFTProvider -Repository PSGallery -Force

# 3. Get latest version of the docker package
#    This also enabled the conteiners feature in Windows Server
Install-Package -Name docker -ProviderName DockerMsftProvider -Force

# 4. Ensure Hyper-V and related tools are added:
Add-WindowsFeature -RName Hyper-V -IncludeManagementTools | 
  Out-Null

# 5. Remove Defender as it interferes with Docker
Remove-WindowsFeature -Name Windows-Defender |
  Out-Null

# 6. Restart the computer to enable docker and containers
Restart-Computer 

# 7. After reboot - check Docker installation
Get-Service -Name Docker   # check docker service
docker version             # check docker version

# 8. Check Windows container feature
Get-WindowsFeature -Name Containers

# 9. Finally test docker works
docker run --isolation=hyperv hello-world





###  stuff for later!

docker run --isolation=hyperv  microsoft/dotnet-samples:dotnetapp-nanoserver


