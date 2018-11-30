# Recipe 11.9 - Configuring VM and storage movement

# 1. View the PSDirect VM on HV1 and verify that it is turned off and not saved
Get-VM -Name PSDirect -Computer HV1

# 2. Get the VM configuration location 
(Get-VM -Name PSDirect).ConfigurationLocation 

# 3. Get Hard Drive locations
Get-VMHardDiskDrive -VMName PSDirect | 
  Format-Table -Property VMName, ControllerType, Path

# 4. Move the VM's to the C\PSDirectNew folder:
$MHT = @{
  Name                   = 'PSDirect'
  DestinationStoragePath = 'C:\PSDirectNew'
}
Move-VMStorage @MHT

# 5. View the configuration details after moving the VM's storage:
(Get-VM -Name PSDirect).ConfigurationLocation
Get-VMHardDiskDrive -VMName PSDirect | 
  Format-Table -Property VMName, ControllerType, Path
  
# 6. Get the VM details for VMs from HV2:
Get-VM -ComputerName HV2

# 7. Enable VM migration from both HV1 and HV2:
Enable-VMMigration -ComputerName HV1, HV2

# 8. Configure VM Migration on both hosts:
$SVHT = @{
  UseAnyNetworkForMigration                 = $true
  ComputerName                              = 'HV1', 'HV2'
  VirtualMachineMigrationAuthenticationType =  'Kerberos'
  VirtualMachineMigrationPerformanceOption  = 'Compression'
}
Set-VMHost @SVHT

# 9. Move the VM to HV2
$Start = Get-Date
$VMHT = @{
    Name                   = 'PSDirect'
    ComputerName           = 'HV1'
    DestinationHost        = 'HV2'
    IncludeStorage         =  $true
    DestinationStoragePath = 'C:\PSDirect' # on HV2
}
Move-VM @VMHT
$Finish = Get-Date
($Finish - $Start)

# 10. Display the time taken to migrate
$OS = "Migration took: [{0:n2}] minutes"
($os -f ($($finish-$start).TotalMinutes))

# 11. Check the VMs on HV1
Get-VM -ComputerName HV2

# 12. Check the VMs on HV2
Get-VM -ComputerName HV2

# 13. Look at the details of the moved VM
((Get-VM -Name PSDirect -Computer HV2).ConfigurationLocation)
Get-VMHardDiskDrive -VMName PSDirect -Computer HV2  |
  Format-Table -Property VMName, Path

###  Move it back (not for publication)

# 14.  Move the VM to HV1
$Start = Get-Date
$VMHT2 = @{
    Name                   = 'PSDirect'
    ComputerName           = 'HV2'
    DestinationHost        = 'HV1'
    IncludeStorage         =  $true
    DestinationStoragePath = 'C:\vm\vhds\PSDirect' # on HV1
}
Move-VM @VMHT2
$Finish = Get-Date
($Finish - $Start)

# 10. Display the time taken to migrate
$OS = "Migration took: [{0:n2}] minutes"
($os -f ($($finish-$start).TotalMinutes))
