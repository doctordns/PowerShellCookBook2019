# Recipe 5.5 - Using an ISCSI Target
#
#  Run from FS1


# 1. Adjust the iSCSI service to auto start, then start the service 
Set-Service MSiSCSI -StartupType 'Automatic'
Start-Service MSiSCSI

# 2. Setup portal to SRV1
$PHT = @{
  TargetPortalAddress     = 'SRV1.Reskit.Org'
  TargetPortalPortNumber  = 3260
}
New-IscsiTargetPortal @PHT
                   
# 3. Find and view the SalesTarget on portal
$Target  = Get-IscsiTarget | 
               Where-Object NodeAddress -Match 'SalesTarget'
$Target 

# 4. Connect to the target on SRV1
$CHT = @{
  TargetPortalAddress = 'SRV1.Reskit.Org'
  NodeAddress         = $Target.NodeAddress
}
Connect-IscsiTarget  @CHT
                    

# 5. View ICI disk from FST on SRV1
$ISD =  Get-Disk | 
  Where-Object BusType -eq 'iscsi'
$ISD | 
  Format-Table -AutoSize

# 6. Turn disk online and make R/W
$ISD | 
  Set-Disk -IsOffline  $False
$ISD | 
  Set-Disk -Isreadonly $False

# 7. Format the volume on FS1
$NVHT = @{
  FriendlyName = 'SalesData'
  FileSystem   = 'NTFS'
  DriveLetter  = 'I'
}
$ISD | 
  New-Volume @NVHT

# 8. Use the drive as a local drive:
Set-Location -Path I:
New-Item -Path I:\  -Name SalesData -ItemType Directory |
  Out-Null
'Testing 1-2-3' | 
  Out-File -FilePath I:\SalesData\Test.Txt
Get-ChildItem I:\SalesData







<#  Undo it

Disconnect-IscsiTarget -NodeAddress iqn.1991-05.com.microsoft:srv1-salestarget-target -Confirm:$false

#>