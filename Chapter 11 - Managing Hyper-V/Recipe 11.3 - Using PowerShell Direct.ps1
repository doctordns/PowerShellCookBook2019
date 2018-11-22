# Recipe 11.3 - Using PS Direct with Hyper-V

# 1. Create a credential object for ReskitAdministrator:
$RKAn = 'Administrator'
$PS   = 'Pa$$w0rd'
$RKP  = ConvertTo-SecureString -String $PS -AsPlainText -Force
$T = 'System.Management.Automation.PSCredential'
$RKCred = New-Object -TypeName $T -ArgumentList $RKAn,$RKP

# 2. Display the details of the PSDirect VM:
Get-VM -Name PSDirect

# 3. Invoke a command on the VM, specifying VM name:
$SBHT = @{
  VMName      = 'PSDirect'
  Credential  = $RKCred
  ScriptBlock = {hostname}
}
Invoke-Command @SBHT

# 4. Invoke a command based on VMID:
$VMID = (Get-VM -VMName PSDirect).VMId.Guid
$ICMHT = @{
  VMid        = $VMID 
  Credential  = $RKCred  
  ScriptBlock = {hostname}
}
Invoke-Command @ICMHT




$VMID = (Get-VM -VMName PSDirect).VMId.Guid
Invoke-Command -VMid $VMID -Credential $RKCred  -ScriptBlock {hostname}

# 5. Enter a PS remoting session with the psdirect VM:
Enter-PSSession -VMName psdirect -Credential $RKCred
Get-CimInstance -Class Win32_ComputerSystem
Exit-PSSession