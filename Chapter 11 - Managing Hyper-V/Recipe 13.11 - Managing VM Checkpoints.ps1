# Recipe 11-10 - Managing VM Checkpoints

# 1. Create credentials for VM1
$RKAn = 'Reskit\Administrator'
$PS   = 'Pa$$w0rd'
$RKP  = ConvertTo-SecureString -String $PS -AsPlainText -Force
$T = 'System.Management.Automation.PSCredential'
$RKCred = New-Object -TypeName $T -ArgumentList $RKAn,$RKP

# 2. Look at C: in VM1 before we start
$sb = { Get-ChildItem -Path C:\ }
Invoke-Command -VMName VM1 -ScriptBlock $sb -Credential $RKCred

# 3. Create a snapshot of VM1 on HV1:
Checkpoint-VM -ComputerName HV1 -VMName VM1 -SnapshotName 'Snapshot1'

# 4. Look at the files created to support the checkpoints
$Parent = Split-Path -Parent (Get-VM -Name VM1 |
              Select-Object -ExpandProperty HardDrives).Path
Get-ChildItem -Path $Parent

# 5. Create some content in a file on VM1 and display it
$sb = {
   $FileName1 = 'C:\File_After_Checkpoint_1'
   Get-Date | Out-File -FilePath $FileName1
   Get-Content -Path $FileName1
}
Invoke-Command -VMName VM1 -ScriptBlock $sb -Credential $RKCred

# 6. Take a second checkpoint
Checkpoint-VM -ComputerName HV1 -VMName VM1 SnapshotName 'Snapshot2'

# 7. Get the VM checkpoint details for VM1
Get-VMSnapshot -VMName VM1

# 8. Look at the files supporting the two checkpoints
Get-ChildItem -Path $Parent

# 9. Create and display another file in VM1 (after you have taken Snapshot2)
$sb = {
  $FileName2 = 'C:\File_After_Checkpoint_2'
  Get-Date | Out-File -FilePath $FileName2
  Get-ChildItem -Path C:\ -File
}
Invoke-Command -VMName VM1 -ScriptBlock $sb -Credential $cred

# 10. Restore VM1 back to the checkpoint named Snapshot1

$Snap1 = Get-VMSnapshot -VMName VM1 -Name Snapshot1
Restore-VMSnapshot -VMSnapshot $Snap1 -Confirm:$false
Start-VM -Name VM1
Wait-VM -For IPAddress -Name VM1

# 11. See what files we have now on VM1
$sb = {
  Get-ChildItem -Path C:\
}
Invoke-Command -VMName VM1 -ScriptBlock $sb -Credential $RKCred

# 12. Roll forward to Snapshot2
$Snap2 = Get-VMSnapshot -VMName VM1 -Name Snapshot2
Restore-VMSnapshot -VMSnapshot $Snap2 -Confirm:$false
Start-VM -Name VM1
Wait-VM -For IPAddress -Name VM1

# 13. Observe the files you now have on VM2
$sb = {
    Get-ChildItem -Path C:\
}
Invoke-Command -VMName VM1 -ScriptBlock $sb -Credential $RKCred

# 14. Restore to Snapshot1 again:
$Snap1 = Get-VMSnapshot -VMName VM1 -Name Snapshot1
Restore-VMSnapshot -VMSnapshot $Snap1 -Confirm:$false
Start-VM -Name VM1
Wait-VM -For IPAddress -Name VM1

# 15. Check snapshots and VM data files again:
Get-VMSnapshot -VMName VM1
Get-ChildItem -Path $Parent

# 16. Remove all the snapshots from HV1:
Get-VMSnapshot -VMName VM1 |
Remove-VMSnapshot

# 17. Check VM data files again:
Get-ChildItem -Path $Parent