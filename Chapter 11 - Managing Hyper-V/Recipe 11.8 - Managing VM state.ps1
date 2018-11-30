# Recipe 11.8 - Managing VM state

# 1. Get the VM's state to check if it is off
Stop-VM -Name PSDirect -WarningAction SilentlyContinue
Get-VM -Name PSDirect

# 2. Start the VM, get its status, then wait until the VM has an
#    IP address assigned and the networking stack is working, then
#     examine the VM's state:
Start-VM -VMName PSDirect
Wait-VM -VMName PSDirect -For IPAddress
Get-Vm -VMName PSDirect

# 3. Suspend and view the PSDirect VM:
Suspend-VM -VMName PSDirect
Get-VM -VMName PSDirect

# 4. Resumve the VM
Resume-VM -VMName PSDirect
Get-VM -VMName PSDirect

# 5. Save the VM and check status:
Save-VM -VMName PSDirect
Get-VM -VMName PSDirect

# 6. Resume the saved VM and view the status:
Start-VM -VMName PSDirect
Get-Vm -VMName PSDirect

# 7. Restart a VM:
Restart-VM -VMName PSDirect -Force
Get-VM     -VMName PSDirect

# 8. Wait for VM to get an IP address:
Wait-VM    -VMName PSDirect -For IPaddress
Get-VM     -VMName PSDirect

# 8. Perform a hard power off on the VM:
Stop-VM -VMName PSDirect -TurnOff
Get-VM  -VMname PSDirect