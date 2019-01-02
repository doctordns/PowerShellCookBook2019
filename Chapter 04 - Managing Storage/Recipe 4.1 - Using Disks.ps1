# Recipe 4.1 - Manaing physical Disks and Volumes
#
# Run on SRV1
# SRV1 has 2 extra disks that are 'bare' and just added to the VM


# 1. Get physical disks on this system:
Get-Disk |
  Format-Table -AutoSize

# 2. Initialize the disks
Get-Disk | 
  Where PartitionStyle -eq Raw |
    Initialize-Disk -PartitionStyle GPT 

# 3. Re-display disks
Get-Disk |
  Format-Table -AutoSize

# 4. Create a F: volume in disk 1
$NVHT1 = @{
  DiskNumber   =  1 
  FriendlyName = 'Storage(F)' 
  FileSystem   = 'NTFS' 
  DriveLetter  = 'F'
}
New-Volume @NVHT1

# 5. Create two volumes in Disk 2 - first create G:
New-Partition -DiskNumber 2  -DriveLetter G -Size 4gb

# 6. Create a second partition H:
New-Partition -DiskNumber 2  -DriveLetter H -UseMaximumSize

# 7. Format G: and H:
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

# 8. Get partitions on this system
Get-Partition  | 
  Sort-Object -Property DriveLetter |
    Format-Table -Property DriveLetter, Size, Type

# 9. Get Volumes on SRV1
Get-Volume | 
  Sort-Object -Property DriveLetter
