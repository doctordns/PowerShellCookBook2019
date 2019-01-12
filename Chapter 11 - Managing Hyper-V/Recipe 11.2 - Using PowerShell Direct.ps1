# Recipe 11-2 - Using PS Direct with Hyper-V
#
# Run on HV1 after Tiger/PSDirect has been created on HV1

# 1. Create a credential object for ReskitAdministrator:
$RKAn = 'Reskit\Administrator'
$PS   = 'Pa$$w0rd'
$RKP  = ConvertTo-SecureString -String $PS -AsPlainText -Force
$T = 'System.Management.Automation.PSCredential'
$RKCred = New-Object -TypeName $T -ArgumentList $RKAn,$RKP

# 2. Display the details of the psdirect VM:
Get-VM -Name psdirect

# 3. Invoke a command on the VM, specifying VM name:
$SBHT = @{
    VMName      = 'psdirect'
    Credential  = $RKCred
    ScriptBlock = {hostname}
}
Invoke-Command @SBHT

# 4. Invoke a command based on VMID:
$VMID = (Get-VM -VMName psdirect).VMId.Guid
Invoke-Command -VMid $VMID -Credential $RKCred  -ScriptBlock {hostname}

# 5. Enter a PS remoting session with the psdirect VM:
Enter-PSSession -VMName psdirect -Credential $RKCred
Get-CimInstance -Class Win32_ComputerSystem
Exit-PSSession