# Recipe 11.5 - Configuring VM Hardware
#
# Run on HV1, using PSDirect VM

# 1. Turn off the VM1 VM
Stop-VM -VMName PSDirect
Get-VM -VMName PSDirect 

# 2. Set the StartupOrder in the VM's BIOS:
$Order = 'IDE','CD','LegacyNetworkAdapter','Floppy'
Set-VMBios -VmName PSDirect -StartupOrder $Order
Get-VMBios PSDirect

# 3. Set CPU count for PSDirect
Set-VMProcessor -VMName PSDirect -Count 2
Get-VMProcessor -VmName PSDirect |
  Format-Table VMName, Count

# 4. Set PSDirect memory
$VMHT = [ordered] @{
    VMName               = 'PSDirect'
    DynamicMemoryEnabled = $true
    MinimumBytes         = 512MB
    StartupBytes         = 1GB
    MaximumBytes         = 2GB
}
Set-VMMemory @VMHT
Get-VMMemory -VMName PSDirect

# 5. Add a ScsiController to PSDirect
Add-VMScsiController -VMName PSDirect
Get-VMScsiController -VMName PSDirect

# 6. Restart the VM
Start-VM -VMName PSDirect
Wait-VM -VMName PSDirect -For IPAddress

# 7. Create a new VHDX file:
$VHDPath = 'C:\Vm\Vhds\PSDirect-D.VHDX'
New-VHD -Path $VHDPath -SizeBytes 8GB -Dynamic

# 8. Add the VHD to the ScsiController:
$VHDHT = @{
    VMName            = 'PSDirect'
    ControllerType    = 'SCSI'
    ControllerNumber  =  0
    ControllerLocation = 0
    Path               = $VHDPath
}
Add-VMHardDiskDrive @VHDHT

# 9. Get Volumes from PSDirect
Get-VMScsiController -VMName PSDirect |
  Select-Object -ExpandProperty Drives





PS C:\foo> 