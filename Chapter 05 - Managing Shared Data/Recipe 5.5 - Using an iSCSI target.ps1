# Recipe 9.5 - Using an ISCSI Target


# Step 1 - adjust and start the service 
Set-Service msiscsi -StartupType 'Automatic'
Start-Service msiscsi

# Step 2 - get to portal
New-IscsiTargetPortal –TargetPortalAddress Srv1.Reskit.Org `
                      -TargetPortalPortNumber 3260

# Step 3 - Find Target on portal
$Target  = Get-IscsiTarget | 
               Where-Object NodeAddress -Match 'SalesTarget'
$Target 

# Step 4 - Connect to the target
Connect-IscsiTarget -TargetPortalAddress Srv1 `
                    –NodeAddress $Target.NodeAddress

# Step 5 - Set up the disk
$ISD = Get-Disk | Where-Object BusType -eq 'iscsi'
Set-Disk -InputObject $isd -IsOffline  $False
Set-Disk -InputObject $isd -Isreadonly $False
$ISD | New-Volume -FriendlyName SalesData -FileSystem NTFS -DriveLetter S

# Step 6 - use the drive as, well, a drive!
Set-Location -Path S:
New-Item -Path S:\  -Name SalesData -ItemType Directory
'Testing 1-2-3' | Out-File -FilePath s:\SalesData\Test.txt
Get-ChildItem s:\SalesData

# step 7 - Setup Iscsi on FS2
$Fs2Sb = { 
  # Setup Iscsi Client on FS2
  Set-Service -name msiscsi -StartupType 'Automatic'
  Start-Service msiscsi
  # Get targets on SRV1
  $Salestarget = Get-IscsiTargetPortal Srv1.reskit.org |Get-IscsiTarget |
                      WHere-Object NodeAddress -Match 'salestarget'
  $HVTarget    = Get-IscsiTargetPortal Srv1.reskit.org |Get-IscsiTarget |
                      WHere-Object NodeAddress -Match 'hvtarget'
  # Now connect to the targets
  Connect-IscsiTarget –NodeAddress $Salestarget.NodeAddress
  Connect-IscsiTarget –NodeAddress $HVTarget.NodeAddress
}
Invoke-Command -ComputerName FS2 `
               -ScriptBlock $Fs2Sb



<#  Undo it

Disconnect-IscsiTarget -NodeAddress iqn.1991-05.com.microsoft:srv1-salestarget-target -Confirm:$false

#>