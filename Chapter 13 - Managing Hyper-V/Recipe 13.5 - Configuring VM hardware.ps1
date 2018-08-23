# Recipe 11-5 - Configuring VM Hardware
# Run on HV1

# 1. Turn off the VM1 VM
Get-VM -VMName VM1 -Verbose
Stop-VM -VMName VM1
Get-VM -VMName VM1 -Verbose

# 2. Set the StartupOrder in the VM's BIOS:
Set-VMBios -VmName VM1 -StartupOrder ('IDE',
                                      'CD',
                                      'LegacyNetworkAdapter',
                                      'Floppy')
Get-VMBios VM1

# 3. Set CPU count for VM1

Set-VMProcessor -VMName VM1 -Count 2
Get-VMProcessor -VmName VM1

# 4. Set VM1 memory
$VMHT = [ordered] @{
    VMName               = 'VM1'
    DynamicMemoryEnabled = $true
    MinimumBytes         = 512MB
    StartupBytes         = 1GB
    MaximumBytes         = 2GB
}
Set-VMMemory @VMHT
Get-VMMemory -VMName VM1

# 5. Add a ScsiController to VM1
Get-VMScsiController -VMName VM1
Add-VMScsiController -VMName VM1
Get-VMScsiController -VMName VM1
# 6. Restart the VM
Start-VM -VMName VM1
Wait-VM -VMName VM1 -For IPAddress

# 7. Create a new VHDX file:
$VHDPath = 'H:\Vm\Vhds\VM1-D.VHDX'
New-VHD -Path $VHDPath -SizeBytes 8GB -Dynamic

# 8. Add the VHD to the ScsiController:
$VHDHT = @{
    VMName            = 'VM1'
    ControllerType    = 'SCSI'
    ControllerNumber  =  0
    ControllerLocation = 0
    Path               = $VHDPath
}
Add-VMHardDiskDrive @VHDHT