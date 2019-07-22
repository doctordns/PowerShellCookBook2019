# Recipe 11-12 Creating a Hyper-V Status Report

# 1. Create a basic report object hash table
$ReportHT = [Ordered] @{}

# 2. Get the host details and add them to the Report object
$HostDetails = Get-CimInstance -ClassName Win32_ComputerSystem
$ReportHT.HostName = $HostDetails.Name
$ReportHT.Maker = $HostDetails.Manufacturer
$ReportHT.Model = $HostDetails.Model

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
    Namespace  = 'root/virtualization/v2'
}
$Proc = Get-CimInstance @PHT
$ReportHT.CPUCount = ($Proc |
    Where-Object elementname -Match 'Logical Processor').COUNT

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

# 8. Create the host report object:
$Reportobj = New-Object -TypeName PSObject -Property $ReportHT

# 9. Create report Header
$Report =  "Hyper-V Report for: $(hostname)`n"
$Report += "At: [$(Get-Date)]"


# 10 Add report object to report:
$Report += $Reportobj | Out-String

# 11. Get VM details on the local VM host and create a container array for individual
#     VM related objects:
$VMs = Get-VM -Name *
$VMHT = @()

# 12. Get VM details for each VM into an object added to the hash table container:
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
 $VMReport.VMCPU = $VM.CPUProcessorCount
# Replication Mode/Status
 $VMReport.ReplMode = $VM.ReplicationMode
 $VMReport.ReplState = $Vm.ReplicationState

 # Create object from Hash table, add to array
 $VMR = New-Object -TypeName PSObject -Property $VMReport
 $VMHT += $VMR
}

# 123 Finish creating the report
$Report += $VMHT | Format-Table | Out-String

# 13. Display the report:
$Report
