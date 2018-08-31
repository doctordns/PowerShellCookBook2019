# Recipe 11-11 -Monitoring Huyper-V utilization and performance

# 1. Discover how many counter sets exist (on HV1)
$TotalCounters = Get-Counter -ListSet * |
    Measure-Object
Write-Output ("Total Counter sets : [{0}]" -f $TotalCounters.Count)

# 2. Discover how many counter sets exist for Hyper-V
$Counters = Get-Counter -ListSet *
Write-Output ("Hyper-V Related Counter Sets : [{0}]" -F $Counters.Count)

# 3. View counter set details for Hyper-V:
Get-Counter -ListSet * |
    Where-Object CounterSetName -match 'hyper'|
        Sort-Object -Property CounterSetName |
            Format-Table -Property CounterSetName, Description

# 4. Determine how many individual counters exist in the Root Virtual
#    Processor counter set:
$HVPCounters = Get-Counter -ListSet * |
    Where-Object CounterSetName -Match 'Root virtual Processor' |
        Select-Object -ExpandProperty Paths |
            Measure-Object
Write-Output ("Hyper-V RVP Counters : [{0}]" -f $HVPCounters.count)

# 5. Define some key counters in the Hypervisor Root Virtual Processor
#    counter set:
$HVCounters = @("\\HV1\Hyper-V Hypervisor Root Virtual "+
"Processor(*)\% Guest Run Time")
$HVCounters += @("\\HV1\Hyper-V Hypervisor Root Virtual "+
"Processor(*)\% Hypervisor Run Time")
$HVCounters += @("\\HV1\Hyper-V Hypervisor Root Virtual "+
"Processor(*)\% Remote Run Time")
$HVCounters += @("\\HV1\Hyper-V Hypervisor Root Virtual " +
    "Processor(*)\% Total Run Time")

# 6. Get counter samples for the counters defined:
$Samples = (Get-Counter -Counter $HVCounters).counterSamples |
    Where-Object Path -Like '*(_total)*'

#     7. Display the counter data returned:
Write-Output ("{0,-22} : {1:N3}" -f 'Counter', 'Value')
Write-Output ("{0,-22} : {1:N3}" -f '-------', '-----')
Foreach ($sample in $samples) {
    $countername = Split-Path -path $sample.path -leaf
    $counterdata = $sample.CookedValue
    Write-Output "{0,-22} : {1:N3}" -f $countername, $counterdata
}