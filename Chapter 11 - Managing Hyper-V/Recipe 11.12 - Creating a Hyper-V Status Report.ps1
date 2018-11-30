# Recipe 11.2 Creating a Hyper-V Status Report

# 1. Create a basic report object hash table
$ReportHT = [Ordered] @{}

# 2. Get the host details and add them to the Report object
$HostDetails = Get-CimInstance -ClassName Win32_ComputerSystem
$ReportHT.HostName = $HostDetails.Name
$ReportHT.Maker    = $HostDetails.Manufacturer
$ReportHT.Model    = $HostDetails.Model

# 3. Add the PowerShell version information
$ReportHT.PSVersion = $PSVersionTable.PSVersion.tostring()
# Add OS information:
$OS = Get-CimInstance -Class Win32_OperatingSystem
$ReportHT.OSEdition    = $OS.Caption
$ReportHT.OSArch       = $OS.OSArchitecture
$ReportHT.OSLang       = $OS.OSLanguage
$ReportHT.LastBootTime = $os.LastBootUpTime
$Now = Get-Date
$UTD = [float] ("{0:n3}" -f (($Now -$OS.LastBootUpTime).Totaldays))
$ReportHT.UpTimeDays = $UTD

# 4. Add a count of processors in the host
$PHT = @{
  ClassName  = 'MSvm_Processor'
  Namespace = 'root/virtualization/v2'
}
$Proc = Get-CimInstance @PHT
  $ReportHT.CPUCount = ($Proc |
  Where-Object elementname -match 'Logical Processor').COUNT

# 5. Add the current host CPU usage
$Cname = '\\.\processor(_total)\% processor time'
$CPU = Get-Counter -Counter $Cname
$ReportHT.HostCPUUsage = $CPU.CounterSamples.CookedValue

# 6. Add the total host physical memory:
$Memory = Get-Ciminstance -Class Win32_ComputerSystem
$HostMemory = [float] ( "{0:n2}" -f ($Memory.TotalPhysicalMemory/1GB))
$ReportHT.HostMemoryGB = $HostMemory

# 7. Add the memory allocated to VMs:
$Sum = 0
Get-VM | Foreach-Object {$sum += $_.MemoryAssigned + $Total}
$Sum = [float] ( "{0:N2}" -f ($Sum/1gb) )
$ReportHT.AllocatedMemoryGB = $Sum

# 8. Create and view the host report object:
$Reportobj  = New-Object -TypeName PSObject -Property $ReportHT
$ReportBase = $Reportobj | Out-String

# 9. Create some New VMs:
New-VM -VMName SQL1 | Out-Null
New-VM -VMName SQL2 | Out-Null
New-VM -VMName OM1  | Out-Null
                    
# 10. Get VM details on the local VM host and create a container array for individual
#     VM related objects:
$VMs = Get-VM -Name * 
$VMHT = @()           

# 11. Get VM details for each VM into an object added to the hash table container:
Foreach ($VM in $VMs) {
# Create VM Report hash table
  $VMReport = [ordered] @{}
# Add VM's Name
  $VMReport.VMName = $VM.VMName
# Add Status
  $VMReport.Status = $VM.Status
# Add Uptime
  $VMReport.Uptime = $VM.Uptime
# Add VM CPU
  $VMReport.VMCPU = $VM.CPUUsage
# Replication Mode/Status
  $VMReport.ReplMode = $VM.ReplicationMode
  $VMReport.ReplState = $Vm.ReplicationState
 # Create object from Hash table, add to array
 $VMR = New-Object -TypeName PSObject -Property $VMReport
 $VMHT += $VMR
}

# 12. Display the array of objects as a table:
$VMDetails = $VMHT |
 Sort-Object -Property Uptime -Descending |
   Format-Table |
     Out-String

# 13. Now create the report
$ReportBody  = "Hyper-V Status Report`n"
$ReportBody += "---------------------`n`n"
$ReportBody += "Created on:"
$ReportBody += (Get-Date | Out-String) 
$ReportBody += "Hyper-V Server Details:"
$ReportBody += $ReportBase
$ReportBody += 'VM Details on this host:'
$ReportBody += $VMDetails


# 14. Display the Report
$ReportBody





# remove fake VMs
# get-vm -vmname SQL1, SQL1, OM1? | Remove-VM



