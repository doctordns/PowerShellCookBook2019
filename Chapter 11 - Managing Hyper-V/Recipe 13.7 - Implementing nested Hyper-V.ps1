# Recipe 11-6 - Implementing nested Hyper-V

#  1. Stop VM1 VM:
Stop-VM -VMName VM1
Get-VM -VMname VM1

# 2. Change the VM's processor to support virtualization:
Set-VMProcessor -VMName VM1 ExposeVirtualizationExtensions $true
Get-VMProcessor -VMName VM1 |
    Format-Table -Property Name, Count,ExposeVirtualizationExtensions

# 3. Start the VM1 VM:
Start-VM -VMName VM1
Wait-VM -VMName VM1 -For Heartbeat
Get-VM -VMName VM1

# 4. Add Hyper-V into VM1:
$user = 'VM1\Administrator'
$pass = ConvertTo-SecureString -String 'Pa$$w0rd' `
                               -AsPlainText -Force
$cred = New-Object `
           -TypeName System.Management.Automation.PSCredential `
           -ArgumentList $user,$Pass
Invoke-Command -VMName VM1 `
               -ScriptBlock {Install-WindowsFeature `
                             -Name Hyper-V `
                             -IncludeManagementTools} `
               -Credential $cred

# 5. Restart the VM to finish adding Hyper-V:
Stop-VM -VMName VM1
Start-VM -VMName VM1
Wait-VM -VMName VM1 -For IPAddress
Get-VM -VMName VM1

# 6. Create a nested VM:
$sb = {
        $VMname = 'Nested11'
        New-VM -Name $VMname -MemoryStartupBytes 1GB}
Invoke-Command -VMName VM1 -ScriptBlock $sb
