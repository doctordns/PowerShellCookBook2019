# Recipe 11-10 - Managing VM Checkpoints

# 1. Create credentials for PSDirect
$RKAn = 'Wolf\Administrator'
$PS   = 'Pa$$w0rd'
$RKP  = ConvertTo-SecureString -String $PS -AsPlainText -Force
$T = 'System.Management.Automation.PSCredential'
$RKCred = New-Object -TypeName $T -ArgumentList $RKAn,$RKP

# 2. Look at C: in PSDirect before we start
$SB = { Get-ChildItem -Path C:\ }
$ICHT = @{
  VMName      = 'PSDirect'
  ScriptBlock = $SB
  Credential  = $RKCred
}
Invoke-Command @ICHT

# 3. Create a snapshot of PSDirect1 on HV1:
$CPHT = @{
  VMName       = 'PSDirect'
  ComputerName = 'HV1'
  SnapshotName = 'Snapshot1'
}
Checkpoint-VM @CPHT

# 4. Look at the files created to support the checkpoints
$Parent = Split-Path -Parent (Get-VM -Name PSdirect |
            Select-Object -ExpandProperty HardDrives).Path |
              Select -First 1
Get-ChildItem -Path $Parent

# 5. Create some content in a file on PSDIrect and display it
$SB = {
   $FileName1 = 'C:\File_After_Checkpoint_1'
   Get-Date | Out-File -FilePath $FileName1
   Get-Content -Path $FileName1
}
$ICHT = @{
  VMName      = 'PSDirect'
  ScriptBlock = $SB
  Credential  = $RKCred
}
Invoke-Command @ICHT

# 6. Take a second checkpoint
$SNHT = @{
  VMName        = 'PSDirect'
  ComputerName  = 'HV1'  
  SnapshotName  = 'Snapshot2'
}
Checkpoint-VM @SNHT

# 7. Get the VM checkpoint details for PSDirect
Get-VMSnapshot -VMName PSDirect

# 8. Look at the files supporting the two checkpoints
Get-ChildItem -Path $Parent

# 9. Create and display another file in PSdirect (ie after you have taken Snapshot2)
$SB = {
  $FileName2 = 'C:\File_After_Checkpoint_2'
  Get-Date | Out-File -FilePath $FileName2
  Get-ChildItem -Path C:\ -File
}
$ICHT = @{
  VMName    = 'PSDirect'
  ScriptBlock = $SB 
  Credential  = $RKCred

}
Invoke-Command @ICHT

# 10. Restore VM1 back to the checkpoint named Snapshot1
$Snap1 = Get-VMSnapshot -VMName PSDirect -Name Snapshot1
Restore-VMSnapshot -VMSnapshot $Snap1 -Confirm:$false
Start-VM -Name PSDirect
Wait-VM -For IPAddress -Name PSDirect

# 11. See what files we have now on PSDirect
$SB = {
  Get-ChildItem -Path C:\
}
$ICHT = @{
  VMName    = 'PSDirect'
  ScriptBlock = $SB 
  Credential  = $RKCred
}
Invoke-Command @ICHT

# 12. Roll forward to Snapshot2
$Snap2 = Get-VMSnapshot -VMName PSdirect -Name Snapshot2
Restore-VMSnapshot -VMSnapshot $Snap2 -Confirm:$false
Start-VM -Name PSDirect
Wait-VM -For IPAddress -Name PSDirect

# 13. Observe the files you now have on VM2
$SB = {
    Get-ChildItem -Path C:\
}
$ICHT = @{
  VMName      = 'PSDirect'
  ScriptBlock = $SB 
  Credential  = $RKCred
}
Invoke-Command @ICHT

# 14. Restore to Snapshot1 again:
$Snap1 = Get-VMSnapshot -VMName PSDirect -Name Snapshot1
Restore-VMSnapshot -VMSnapshot $Snap1 -Confirm:$false
Start-VM -Name PSDirect
Wait-VM -For IPAddress -Name PSDirect

# 15. Check snapshots and VM data files again:
Get-VMSnapshot -VMName PSDirect
Get-ChildItem -Path $Parent

# 16. Remove all the snapshots from HV1:
Get-VMSnapshot -VMName PSDirect |
  Remove-VMSnapshot

# 17. Check VM data files again:
Get-ChildItem -Path $Parent