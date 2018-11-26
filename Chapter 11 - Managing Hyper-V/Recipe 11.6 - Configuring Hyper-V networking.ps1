# Recipe 11.6 - Configuring Hyper-V Networking
#
# Run on HV1

# 1. Get NIC details and any IP Address from the PSDirect VM
Get-VMNetworkAdapter -VMName PSDirect

# 2. Create a credential then get VM networking details
$RKAn = 'localhost\Administrator'
$PS = 'Pa$$w0rd'
$RKP = ConvertTo-SecureString -String $PS -AsPlainText -Force
$T = 'System.Management.Automation.PSCredential'
$RKCred = New-Object -TypeName $T -ArgumentList $RKAn, $RKP
$VMHT = @{
    VMName      = 'PSDirect'
    ScriptBlock = {Get-NetIPConfiguration }
    Credential  = $RKCred
}
Invoke-Command @VMHT | Format-List

# 3. Create a virtual switch on HV1
$VSHT = @{
    Name           = 'External'
    NetAdapterName = 'Ethernet'
    Notes          = 'Created on HV1'
}
New-VMSwitch @VSHT

# 4. Connect VM1 to the switch
Connect-VMNetworkAdapter -VMName PSDirect -SwitchName External

# 5. See VM networking information:
Get-VMNetworkAdapter -VMName PSDirect

# 6. With VM1 now in the network, observe the IP address in the VM
$NCHT = @{
    VMName      = 'PSDirect'
    ScriptBlock = {Get-NetIPConfiguration}
    Credential  = $RKCred
}
Invoke-Command @NCHT

# 7. View the hostname on VM1
#    Reuse the hash table from step 6
$NCHT.ScriptBlock = {hostname}
Invoke-Command @NCHT

# 8. Change the name of the host in VM1
#    Reuse the hash table from steps 6,7
$NCHT.ScriptBlock = {Rename-Computer -NewName Wolf -Force}
Invoke-Command @NCHT

# 9. Reboot and wait for the restarted VM1
Restart-VM -VMName PSDirect -Wait -For IPAddress -Force

# 10. Get hostname of the VM1 VM
$NCHT.ScriptBlock = {hostname}
Invoke-Command @NCHT