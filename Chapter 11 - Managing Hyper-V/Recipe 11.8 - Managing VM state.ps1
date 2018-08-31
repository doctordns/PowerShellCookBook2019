# Recipe 11-7 - Managing VM state

# 1. Get the VM's state to check if it is off
Get-VM -Name VM1

# 2. Start the VM, get its status, then wait until the VM has an
#    IP address assigned and the networking stack is working, then
#     examine the VM's state:
Start-VM -VMName VM1
Get-Vm -VMName VM1
Wait-VM -VMName VM1 -For IPAddress
Get-VM -VMName VM1

# 3. Suspend and resume a VM:
Suspend-VM -VMName VM1
Get-VM -VMName VM1
Resume-VM -VMName VM1
Get-VM -VMName VM1

# 4. Save the VM and check status:
Save-VM -VMName VM1
Get-VM -VMName VM1

# 5. Resume the saved VM and view the status:
Start-VM -VMName VM1
Get-Vm -VMName VM1
# 6. Restart a VM:
Get-VM -VMname VM1
Restart-VM -VMName VM1 -Force
Get-VM -VMName VM1
Wait-Vm -VMName VM1 -For IPaddress
Get-VM -VMName VM1

# 7. Hard power Off:
Stop-VM -VMName VM1 -TurnOff
Get-VM -VMname VM1