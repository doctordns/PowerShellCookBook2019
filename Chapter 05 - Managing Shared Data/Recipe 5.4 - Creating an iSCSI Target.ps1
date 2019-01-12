# Recipe 9.4 - Creating an iSCSI Target
# Assumes you have the Iscsi Target feature installed, 
# and the E: drive on SRV1 created.
#  NB Typo in book talks about I:
# Run from SRV1 as Administrator@reskit.org

# 1. Install the iSCSI target feature
Install-WindowsFeature FS-iSCSITarget-Server

# 2. Explore iSCSI target server settings:
Get-IscsiTargetServerSetting

# 3. Create an iSCSI disk (that is a LUN):
$LunPath = 'E:\SalesData.Vhdx'
$LunName = 'SalesTarget'
$VDHT = @{
   Path        = $LunPath
   Description = 'LUN For Sales'
   SizeBytes   = 1.1GB
 }
New-IscsiVirtualDisk @VDHT

# 4. Create the iSCSI target:
$THT = @{
    TargetName   = $LunName
    InitiatorIds = 'DNSNAME:FS1.Reskit.Org'
}
New-IscsiServerTarget @THT

# 5. Create iSCSI disk target mapping:
Add-IscsiVirtualDiskTargetMapping -TargetName $LunName -Path $LunPath