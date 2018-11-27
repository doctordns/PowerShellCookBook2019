# Recipe 11.7 - Implementing nested Hyper-V
#
# Run on PSDirect

#  1. Stop VM1 VM:
Stop-VM -VMName PSDirect

# 2. Change and view the VM's processor to support virtualization:
$VMHT = @{
  VMName                         = ‘PSDirect’ 
  ExposeVirtualizationExtensions = $true
}
Set-VMProcessor @VMHT
Get-VMProcessor -VMName PSDirect |
    Format-Table -Property Name, Count,
                           ExposeVirtualizationExtensions

# 3. Start the VM1 VM:
Start-VM -VMName PSDirect
Wait-VM  -VMName PSDirect -For Heartbeat
Get-VM   -VMName PSDirect

# 4. Create credentials 
$User = 'Wolf\Administrator'
$PHT = @{
  String      = 'Pa$$w0rd'
  AsPlainText = $true
  Force       = $true
}
$PSS  = ConvertTo-SecureString @PHT
$Type = 'System.Management.Automation.PSCredential'
$CredRK = New-Object -TypeName $Type -ArgumentList $User,$PSS

# 5. Create a script block for remote execution
$SB = {
  Install-WindowsFeature -Name Hyper-V -IncludeManagementTools
}

# 6. Install Hyper-V inside the PSDirect VM
$Session = New-PSSession -VMName PSDirect -Credential $CredRK
$IHT = @{
  Session     = $Session
  ScriptBlock = $SB 
}
Invoke-Command @IHT

# 7. Restart the VM to finish adding Hyper-V:
Stop-VM  -VMName PSDirect
Start-VM -VMName PSDirect
Wait-VM  -VMName PSDirect -For IPAddress
Get-VM   -VMName PSDirect

# 8. Create a nested VM:
$SB2 = {
        $VMname = 'NestedVM'
        New-VM -Name $VMname -MemoryStartupBytes 1GB
}
$IHT2 = @{
  VMName = 'PSDirect'
  ScriptBlock = $SB2
}
Invoke-Command @IHT2 -Credential $CredRK

