# Recipe 13-1 - Using Get-Counter to get performance counters
#
#  Run on SRV1
#  Uses DC1, SRV2, PSRV

# 1. Discover performaance counter sets on the local machine
$CounterSets = Get-Counter -ListSet *
"There are {0} counter sets on [{1}]" -f $CounterSets.count, (hostname)

# 2. Discover Performacne counter sets on remote systems
$Machines = 'DC1', 'SRV2', 'PSRV'
Foreach ($Machine in $Machines)
{
  $RCounters =   Get-Counter -ListSet * -ComputerName $Machine
  "There are {0} counters on [{1}]" -f $RCounters.count, ($Machine)
}

# 3 Explore key performance counter sets
Get-Counter -ListSet Processor, Memory, Network*,*Disk* |
    Select-Object -Property countersetname, Description |
        Format-Table -Wrap

# 4. Get and display counters in a counter set
$CountersMem = (Get-Counter -ListSet Memory).Counter
"Memory counter set has [{0}] counters" -f $countersMem.Count
$CountersProc = (Get-Counter -ListSet Processor).Counter
"Processor counter set has [{0}] counters" -f $CountersProc.Count

# 5. Get a sample from each counter in the memory counter set
$Counters = (Get-Counter -ListSet Memory).counter
$FS = "{0,-19}  {1,-50}                      {2,10}"
$FS -f 'At', 'Counter', 'Value'
foreach ($Counter in $Counters)
{
  $C = Get-Counter -Counter $Counter
  $T = $C.Timestamp                        # Time
  $N = $C.CounterSamples.Path.Trim()       # Couner Name
  $V = $C.CounterSamples.CookedValue       # Value
  "{0,-15}  {1,-59}   {2,20}" -f $t, $n, $v
  }

# 6 Explore SampleSet types for key perf counters
Get-Counter -ListSet Processor, Memory, Network*, *Disk* |
      Select-Object -Property CounterSetName, CounterSetType

# 7. Explore two performance counter sample sets
$Counter1 = '\Memory\Page Faults/sec'
$PFS      = Get-Counter -Counter $Counter1
$PFS
$Counter2 = '\Processor(*)\% Processor Time'
$CPU      =  Get-Counter -Counter $Counter2
$CPU

# 8. Look inside a countersampleset
$PFS  | Get-Member -MemberType *Property |
    Format-Table -Wrap

# 9. What is inside a counter sample
$Counter1 = '\Memory\Page Faults/sec'
$PFS      = Get-Counter -Counter $Counter1
$PFS
$Counter2 = '\Processor(*)\% Processor Time'
$CPU      =  Get-Counter -Counter $Counter2
$CPU

# 10. Look inside a countersampleset
$CPU.CounterSamples | Get-Member -MemberType *Property |
     Format-Table -Wrap
$CPU.Countersamples | Format-List -Property  *