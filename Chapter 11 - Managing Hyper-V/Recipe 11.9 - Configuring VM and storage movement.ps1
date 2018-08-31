# Recipe 11-8 - Configuring VM and storage movement

# .1 View the VM1 VM on HV1 and verify that it is turned off and not saved
Get-VM -Name VM1 -Computer HV1

# 2. Get the VM configuration location and VHD details:
Write-Output -InputObject (Get-VM -Name vm1).ConfigurationLocation
Get-VMHardDiskDrive -VMName VM1

# 3. Move the VM's storage to the C: drive:
Move-VMStorage -Name VM1 -DestinationStoragePath C:\VM1

# 4. View the configuration details after moving the VM's storage:
Write-Output -InputObject (Get-VM -Name VM1).ConfigurationLocation
Get-VMHardDiskDrive -VMName VM1

# 5. Get the VM details for VMs from HV2:
Get-VM -ComputerName HV2

# 6. Enable VM migration from both HV1 and HV2:
Enable-VMMigration -ComputerName HV1, HV2

# 7. Configure VM Migration on both hosts:
Set-VMHost -UseAnyNetworkForMigration $true -ComputerName HV1, HV2
$VMHT1 = @{
    VirtualMachineMigrationAuthenticationType =  'Kerberos'
    ComputerName                              =  'HV1, HV2'
}
Set-VMHost @VMHT1
VMHT2 = @{
    VirtualMachineMigrationPerformanceOption = 'Compression'
    ComputerName                             = 'HV1, HV2'
}
Set-VMHost @VMHT2

# 8. Move the VM to HV2
$start = Get-Date
$VMHT = @{
    Name            = 'VM1'
    ComputerName    = 'HV1.reskit.org'
    DestinationHost = 'HV2.reskit.org'
    IncludeStorage  =  $true
    DestinationStoragePath = 'C:\VM1'
}
Move-VM @VMHT
$finish = Get-Date

# 9. Display the time taken to migrate
$OS = "Migration took: [{0:n2}] minutes"
Write-Output ($os-f ($($finish-$start).totalminutes))

# 10. Check which VMs on are on HV1 and HV2
Get-VM -ComputerName HV1
Get-VM -ComputerName HV2

# 11. Look at the details of the moved VM
Write-Output ((Get-VM -Name VM1 -Computer HV2).ConfigurationLocation)
Get-VMHardDiskDrive -VMName VM1 -Computer HV2