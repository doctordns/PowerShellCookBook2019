# Recipe 11-8 - Configuring VM replication

# 1. Configure HV1 and HV2 to be trusted for delegation in AD on DC1
$Sb1 = {
    Set-ADComputer -Identity HV1 -TrustedForDelegation $True
}
Invoke-Command -ComputerName DC1 -ScriptBlock $Sb1
$Sb2 = {
Set-ADComputer -Identity HV2 -TrustedForDelegation $True}
Invoke-Command -ComputerName DC1 -ScriptBlock $Sb2
# Reboot the HV1 and HV2:
Restart-Computer -ComputerName HV` -Force
Restart-Computer -ComputerName HC2 -Force

# 2. Once both systems are restarted, logon back to HV1,
#    set up HV2 as a replication server
$VMRHT = @{
   ReplicationEnabled              = $true
   AllowedAuthenticationType       = 'Kerberos'
   KerberosAuthenticationPort      = 42000
   DefaultStorageLocation          = 'C:\Replicas'
   ReplicationAllowedFromAnyServer = $true
    ComputerName                    = 'HV2'
}
Set-VMReplicationServer @VMRHT

# 3. Enable VM1 on HV1 to be a replica source
$VMRHT = @{
  VMName            = 'VM1'
  Computer          = 'HV1'
  ReplicaServerName = 'HV2'
  ReplicaServerPort = 42000
 AuthenticationType = 'Kerberos'
 CompressionEnabled = $true
 RecoveryHistory    = 5
}
Enable-VMReplication  @VMRHT

# 4. View the replication status of HV2
Get-VMReplicationServer -ComputerName HV2

# 5. Check VM1 on HV2:
Get-VM -ComputerName HV2

# 6. Start the initial replication
Start-VMInitialReplication -VMName VM1 -ComputerName HV2

# 7. Examine the initial replication state on HV1 just after
#    you start the initial replication
Measure-VMReplication -ComputerName HV1

# 8. Wait for replication to finish, then examine the
     replication status on HV1
Measure-VMReplication -ComputerName HV1

# 9. Test VM1 failover to HV2
$sb = {
  $VM1Test = Start-VMFailover -AsTest -VMName VM1 Confirm:$false
  Start-VM $VM1test
}
Invoke-Command -ComputerName HV2 -ScriptBlock $sb

# 10. View the status of VMs on HV2:
Get-VM -ComputerName HV2

# 11. Stop the failover test
$sb = {
  Stop-VMFailover -VMName VM1 }
  Invoke-Command -ComputerName HV2 -ScriptBlock $sb

#   12. View the status of VMs on HV1 and HV2 after failover stopped
Get-VM -ComputerName HV1
Get-VM -ComputerName HV2

# 13. Stop VM1 on HV1 prior to performing a planned failover
Stop-VM VM1 -ComputerName HV1

# 14. Start VM failover from HV1
Start-VMFailover -VMName VM1 -ComputerName HV2 -Confirm:$false

#15. Complete the failover
Complete-VMFailover -VMName VM1 -ComputerName HV2 Confirm:$false

# 16. Start the replicated VM on HV2
Start-VM -VMname VM1 -ComputerName HV2

# 17. See VMs on HV1 and HV2 after the planned failover
Get-VM -ComputerName HV1
Get-VM -ComputerName HV2