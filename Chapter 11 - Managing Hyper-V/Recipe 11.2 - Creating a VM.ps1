# Recipe 11.2 - Creating a VM

# 1. Set up the VM name and paths for this recipe:
$VMname      = 'PSDirect'
$VMLocation  = 'C:\Vm\VMs'
$VHDlocation = 'C:\Vm\Vhds'
$VhdPath     = "$VHDlocation\PSDirect.Vhdx"
$ISOPath     = 'C:\builds\en_windows_server_2019_x64_dvd_4cb967d8.iso'

# 2.    Create a new VM:
New-VM -Name $VMname -Path $VMLocation -MemoryStartupBytes 1GB

# 3. Create a virtual disk file for the VM:
New-VHD -Path $VhdPath -SizeBytes 128GB -Dynamic | Out-Null

# 4. Add the virtual hard drive to the VM:
Add-VMHardDiskDrive -VMName $VMname -Path $VhdPath

# 5. Set ISO image in the VM's DVD drive:
$IHT = @{
  VMName           = $VMName
  ControllerNumber = 1
  Path             = $ISOPath
}
Set-VMDvdDrive @IHT

# 6. Start the VM:
Start-VM -VMname $VMname 

# 7. View the results:
Get-VM -Name $VMname
