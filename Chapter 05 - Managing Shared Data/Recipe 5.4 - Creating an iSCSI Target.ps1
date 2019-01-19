# Recipe 5.4 - Creating an iSCSI Target
# Run from SRV1 as Administrator@reskit.org

# 1. Install the iSCSI target feature on SRV1
Install-WindowsFeature FS-iSCSITarget-Server

# 2. Explore iSCSI target server settings:
Get-IscsiTargetServerSetting

# 3. Create a folder on SRV1 to hold the iscis virtual disk
$NIHT = @{
  Path        = 'C:\iSCSI' 
  ItemType    = 'Directory'
  ErrorAction = 'SilentlyContinue'
}
New-Item @NIHT | Out-Null


# 4. Create an iSCSI disk (that is a LUN):
$LP = 'C:\iSCSI\SalesData.Vhdx'
$LN = 'SalesTarget'
$VDHT = @{
   Path        = $LP
   Description = 'LUN For Sales'
   SizeBytes   = 500MB
 }
New-IscsiVirtualDisk @VDHT

# 5. Set the iSCSI target, specifiying who can initiate
#    an iSCSI connection. 
$THT = @{
  TargetName   = $LN
  InitiatorIds = 'DNSNAME:FS1.Reskit.Org'
}
New-IscsiServerTarget @THT

# 6. Create iSCSI disk target mapping:
Add-IscsiVirtualDiskTargetMapping -TargetName $LN -Path $LP



# Undo:
Get-IscsiServerTarget | Remove-IscsiServerTarget
Get-IscsiVirtualDisk | Remove-IscsiVirtualDisk
Remove-item $LP
