# Recipe 9.1 - Using Storage Spaces Direct (STSD)
# 
# Uses CL1,SSRV1, SSRV2, HV1
# Run on CL1


# Setup STSD cluster on SSRV1, SSRV2, SSRV3

# 1. Create Feature list and installation hash table
$Features = @('Hyper-V', 'Failover-Clustering', 'FS-FileServer',
              'RSAT-Clustering-PowerShell','Hyper-V-PowerShell')
$SBHT = @{
  Name                   = $Features
  IncludeAllSubFeature   = $True
  IncludeManagementTools = $True
}


Install-WindowsFeature @SBHT -ComputerName SSRV1
Install-WindowsFeature @SBHT -ComputerName SSRV2
Install-WindowsFeature @SBHT -ComputerName SSRV3

# x. See the images loaded 
Get-ChildItem -Path C:\ProgramData\Microsoft\Windows\Images

# Create a shared VHD on SSRV cluster


# Create a VMSSD1 on HV1 that uses this shared volume


# Install OS on VMSSD1


# Add Hyper-V to SSRV cluster


# Add hyperconverged VM
