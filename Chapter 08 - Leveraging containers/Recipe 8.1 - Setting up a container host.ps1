# Recipe 8.1 - Setting up a container host

# Run on CH1

# 1. Install nuget provider
Install-PackageProvider -Name nuget -Force 

# 2. Install the Docker provider
$IHT1 = @{
  Name       = ‘DockerMSFTProvider’ 
  Repository = ‘PSGallery’ 
  Force      = $True
}
Install-Module @IHT1

# 3. Install the latest version of the docker package
#    This also enables the continers feature in Windows Server
$IHT2 = @{
  Name         = ‘Docker’ 
  ProviderName = ‘DockerMSFTProvider' 
  Force        = $True
}
Install-Package @IHT2

# 4. Ensure Hyper-V and related tools are added:
Add-WindowsFeature -Name Hyper-V -IncludeManagementTools | 
  Out-Null

# 5. Remove Defender as it interferes with Docker
Remove-WindowsFeature -Name Windows-Defender |
  Out-Null

# 6. Restart the computer to enable docker and containers
Restart-Computer 

# 7. Check Windows Containers and Hyper-V features are installed on CH1:
Get-WindowsFeature -Name Containers, Hyper-v

# 8. Nect check Docker service:
Get-Service -Name Docker   

# 9. Check Docker Version information
docker version             

# 10. Display docker configuration information:
docker info
