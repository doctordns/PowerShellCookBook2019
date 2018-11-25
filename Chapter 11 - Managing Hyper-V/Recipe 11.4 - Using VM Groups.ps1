# Recipe 11.4 - Using VM Groups
#
# Run on HV2


# 0. Create VMs on HV2
# Use the script: Create-HV2VMs.ps1

# 1. Setup Hyper-V VM groups and display group
$VHGHT1 = @{
  Name      = 'SQLAccVMG'
  GroupType = 'VMCollectionType'
}
$VMGroupACC = New-VMGroup @VHGHT1
$VHGHT2 = @{
  Name      = 'SQLMfgVMG'
  GroupType = 'VMCollectionType'
}
$VMGroupMFG = New-VMGroup @VHGHT2

# 2. Create arrays of group member VM Names
$ACCVMs = 'SQLAcct1', 'SQLAcct2','SQLAcct3'
$MFGVms = 'SQLMfg1', 'SQLMfg2'

# 3. Add members to the Accounting SQL VMgroup
Foreach ($Server in $ACCVMs) {
    $VM = Get-VM -Name $Server
    Add-VMGroupMember -Name SQLAccVMG -VM $VM
}

# 4. Add memvers to the Manufacturing SQL VM Group
Foreach ($Server in $MfgVMs) {
    $VM = Get-VM -Name $Server
    Add-VMGroupMember -Name  SQLMfgVMG -VM $VM
}

# 5 Create a management collection VMGroup
$VMGHT = @{
  Name      = 'VMMGSQL'
  GroupType = 'ManagementCollectionType'
}
$VMMGSQL = New-VMGroup  @VMGHT

# 6. Add the two VMCollectionType groups to the VMManagement group
Add-VMGroupMember -Name VMMGSQL -VMGroupMember $VMGroupACC,
                                               $VMGroupMFG

# 7. Set FormatEnumerationLimit to a higher value, then view the VMGroups
$FormatEnumerationLimit = 99
Get-VMGroup | 
  Format-Table -Property Name, GroupType, VMGroupMembers,
                         VMMembers 

# 8. Stop all the SQL VMs
Foreach ($VM in ((Get-VMGroup VMMGSQL).VMGroupMembers.vmmembers)) {
  Stop-VM -Name $vm.name -WarningAction SilentlyContinue
}

# 9. Set CPU count in ALL SQL VMs to 4
Foreach ($VM in ((Get-VMGroup VMMGSQL).VMGroupMembers.VMMembers)) {
  Set-VMProcessor -VMName $VM.name -Count 4
}

# 10. Set Accounting SQL VMs to have 6 processors
Foreach ($VM in ((Get-VMGroup SQLAccVMG).VMMembers)) {
  Set-VMProcessor -VMName $VM.name -Count 6
}

# 11. Check Processor counts for all VMs sorted by CPU Count:
$VMS = (Get-VMGroup -Name VMMGSQL).VMGroupMembers.VMMembers
Get-VMProcessor -VMName $VMS.name | 
  Sort-Object -Property Count -Descending |
    Format-Table -Property VMName, Count

# 12. Remove VMs from VM Groups
$VMs = (Get-VMGroup -Name SQLAccVMG).VMMEMBERS
Foreach ($VM in $VMS)  {
  $X = Get-VM -vmname $VM.name
  Remove-VMGroupMember -Name SQLAccVMG -VM $x
  }
$VMs = (Get-VMGroup -Name SQLMFGVMG).VMMEMBERS
Foreach ($VM in $VMS)  {
  $X = Get-VM -vmname $VM.name
  Remove-VMGroupMember -Name SQLmfgvMG -VM $x
}

# 13. Remove VMGrouwps from VMManagementGroups
$VMGS = (Get-VMGroup -Name VMMGSQL).VMMembers
Foreach ($VMG in $VMGS)  {
  $X = Get-VMGroup -vmname $VMG.name
  Remove-VMGroupMember -Name VMMGSQL -VMGroupName $x
}
# 14. Remove all the VMGroups
Remove-VMGroup SQLACCVMG -force
Remove-VMGroup SQLMFGVMG -force
Remove-VMGroup VMMGSQL -Force