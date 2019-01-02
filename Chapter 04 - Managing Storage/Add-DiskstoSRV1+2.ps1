# Add-DiskstoSrv1+2
#
#
# Add two disks to SRV1/2 for Storage Chapter

# Create volumes for Srv1, 2
New-VHD -Path D:\v6\SRV1\SRV1-F.vhdx -SizeBytes 10gb -Dynamic
New-VHD -Path D:\v6\SRV1\SRV1-G.vhdx -SizeBytes 10gb -Dynamic
New-VHD -Path D:\v6\SRV2\SRV2-F.vhdx -SizeBytes 10gb -Dynamic
New-VHD -Path D:\v6\SRV2\SRV2-G.vhdx -SizeBytes 10gb -Dynamic

# Add disks
Add-VMHardDiskDrive -VMName SRV1 -Path D:\v6\srv1\SRV1-F.vhdx    -ControllerType SCSI -ControllerNumber 0
Add-VMHardDiskDrive -VMName SRV1 -Path D:\v6\srv1\SRV1-G.vhdx    -ControllerType SCSI -ControllerNumber 0
Add-VMHardDiskDrive -VMName SRV2 -Path D:\v6\srv2\SRV2-F.vhdx    -ControllerType SCSI -ControllerNumber 0
Add-VMHardDiskDrive -VMName SRV2 -Path D:\v6\srv2\SRV2-G.vhdx    -ControllerType SCSI -ControllerNumber 0

# what have we here then?
Get-VMHardDiskDrive -vmname srv1 
Get-VMHardDiskDrive -vmname srv2 


###  For testing - remove the disksfrom the VMs, delete them, and recreate them if necessary!

# Remove disks from the VMs
Get-VMHardDiskDrive -vmname srv1 | where ControllerType -eq scsi | remove-vmharddiskdrive
Get-VMHardDiskDrive -vmname srv2 | where ControllerType -eq scsi | remove-vmharddiskdrive

# remove disks
Remove-Item -Path D:\v6\SRV1\SRV1-F.vhdx
Remove-Item -Path D:\v6\SRV1\SRV1-G.vhdx
Remove-Item -Path D:\v6\SRV2\SRV2-F.vhdx
Remove-Item -Path D:\v6\SRV2\SRV2-G.vhdx
