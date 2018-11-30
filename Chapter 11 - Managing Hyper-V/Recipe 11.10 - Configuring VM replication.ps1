# Recipe 11.10 - Configuring VM replication

# 1. Configure HV1 and HV2 to be trusted for delegation in AD on DC1
$Sb1 = {
    Set-ADComputer -Identity HV1 -TrustedForDelegation $True
}
Invoke-Command -ComputerName DC1 -ScriptBlock $Sb1
$Sb2 = {
Set-ADComputer -Identity HV2 -TrustedForDelegation $True}
Invoke-Command -ComputerName DC1 -ScriptBlock $Sb2


# 2. Reboot the HV1 and HV2:
Restart-Computer -ComputerName HV1 -Force
Restart-Computer -ComputerName HV2 -Force

# 3. Once both systems are restarted, logon back to HV2,
#    set up both servers as a replication server
$VMRHT = @{
   ReplicationEnabled              = $true
   AllowedAuthenticationType       = 'Kerberos'
   KerberosAuthenticationPort      = 42000
   DefaultStorageLocation          = 'C:\Replicas'
   ReplicationAllowedFromAnyServer = $true
   ComputerName                    = 'HV1', 'HV2'
}
Set-VMReplicationServer @VMRHT

# 4. Enable PSDirect on HV2 to be a replica source
$VMRHT = @{
  VMName            = 'PSDirect'
  Computer          = 'HV2'
  ReplicaServerName = 'HV1'
  ReplicaServerPort = 42000
 AuthenticationType = 'Kerberos'
 CompressionEnabled = $true
 RecoveryHistory    = 5
}
Enable-VMReplication  @VMRHT

# 5. View the replication status of HV2
Get-VMReplicationServer -ComputerName HV2

# 6. Check PSDIrect on HV2:
Get-VM -ComputerName HV2 -VMName PSDirect

# 7. Start the initial replication
Start-VMInitialReplication -VMName PSDirect -ComputerName HV2

# 8. Examine the initial replication state on HV1 just after
#    you start the initial replication
Measure-VMReplication -ComputerName HV2

# 9. Wait for replication to finish, then examine the
#    replication status on HV1
Measure-VMReplication -ComputerName HV2

# 10. Test PSDirect failover to HV1
$SB = {
  $VM = Start-VMFailover -AsTest -VMName PSDirect -Confirm:$false
  Start-VM $VM
}
Invoke-Command -ComputerName HV1 -ScriptBlock $SB

# 11. View the status of VMs on HV2:
Get-VM -ComputerName HV1

# 12. Stop the failover test
$SB = {
  Stop-VMFailover -VMName PSDirect
}
Invoke-Command -ComputerName HV1 -ScriptBlock $SB

# 13. View the status of VMs on HV1 and HV2 after failover stopped
Get-VM -ComputerName HV1

Get-VM -ComputerName HV2

# 14. Stop VM1 on HV2 prior to performing a planned failover
Stop-VM PSDirect -ComputerName HV2

# 15. Start VM failover from H1
Start-VMFailover -VMName PSDirect -ComputerName HV1 -Confirm:$false

#16. Complete the failover
$CHT = @{
  VMName       = 'PSDIrect'
  ComputerName = 'HV1'
  Confirm      = $false
}
Complete-VMFailover @CHT

# 17. Start the replicated VM on HV1
Start-VM -VMname PSDirect -ComputerName HV1

# 18. See VMs on HV1 and HV2 after the planned failover
Get-VM -ComputerName HV1
Get-VM -ComputerName HV2

