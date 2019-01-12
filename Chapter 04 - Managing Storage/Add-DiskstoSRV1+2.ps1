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


#  Format the srv2 drives so that recipe 4.3 works
$SB = {

# Initialize the disks
Get-Disk | 
  Where PartitionStyle -eq Raw |
    Initialize-Disk -PartitionStyle GPT 

$NVHT1 = @{
  DiskNumber   =  1 
  FriendlyName = 'Storage' 
  FileSystem   = 'NTFS' 
  DriveLetter  = 'F'
}
New-Volume @NVHT1
#  Create two volumes in Disk 2 - first create G:
New-Partition -DiskNumber 2  -DriveLetter G -Size 4gb
# Create a second partition H:
New-Partition -DiskNumber 2  -DriveLetter H -UseMaximumSize
# Format G: and H:
$NVHT1 = @{
  DriveLetter        = 'G'
  FileSystem         = 'NTFS' 
  NewFileSystemLabel = 'Log'}
Format-Volume @NVHT1
$NVHT2 = @{
  DriveLetter        = 'H'
  FileSystem         = 'NTFS' 
  NewFileSystemLabel = 'GDShow'}
Format-Volume @NVHT2
}
Invoke-Command -ComputerName SRV2 -ScriptBlock $SB -Credential $Credrk


###  For testing - remove the disksfrom the VMs, delete them, and recreate them if necessary!

# Remove disks from the VMs
Get-VMHardDiskDrive -vmname srv1 | where ControllerType -eq scsi | remove-vmharddiskdrive
Get-VMHardDiskDrive -vmname srv2 | where ControllerType -eq scsi | remove-vmharddiskdrive

# remove disks
Remove-Item -Path D:\v6\SRV1\SRV1-F.vhdx
Remove-Item -Path D:\v6\SRV1\SRV1-G.vhdx
Remove-Item -Path D:\v6\SRV2\SRV2-F.vhdx
Remove-Item -Path D:\v6\SRV2\SRV2-G.vhdx
