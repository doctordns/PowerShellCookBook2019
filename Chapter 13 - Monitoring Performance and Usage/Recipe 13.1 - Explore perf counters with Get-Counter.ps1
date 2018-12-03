# Recipe 13.1 - Using Get-Counter to get performance counters
#
#  Run on SRV1
#  Uses DC1,DC2,HV1,HV2,SRV1,SRV2

# 1. Discover performance counter sets on SRV1:
$CounterSets = Get-Counter -ListSet *
$CS1 = 'There are {0} counter sets on [{1}]'
$CS1 -f $CounterSets.count,(hostname)

# 2. Discover performance counter sets on remote systems
$Machines = 'DC1','DC2','HV1','HV2','SRV1','SRV2'
Foreach ($Machine in $Machines)
{
  $RCounters =   Get-Counter -ListSet * -ComputerName $Machine
  $CS2 = "There are {0} counters on [{1}]"
  $CS2 -f $RCounters.Count, $Machine
}

# 3 List key performance counter sets
Get-Counter -ListSet Processor, Memory, Network*,*Disk |
  Sort-Object -Property CounterSetName |
    Format-Table -Property CounterSetName 

# 4. Get description of the memory counter set
Get-Counter -ListSet Memory |
  Format-Table -Property Name, Description -Wrap

# 5. Get and display counters in the memory counter set
$CountersMem = (Get-Counter -ListSet Memory).Counter
'Memory counter set has [{0}] counters:' -f $countersMem.Count
$CountersMem

# 6. Get and display a sample from each counter in the memory counter set
$Counters = (Get-Counter -ListSet Memory).counter
$FS = '{0,-19}  {1,-60} {2,-10}'
$FS -f 'At', 'Counter', 'Value' # Display header row
foreach ($Counter in $Counters)
{
  $C = Get-Counter -Counter $Counter
  $T = $C.Timestamp                        # Time
  $N = $C.CounterSamples.Path.Trim()       # Counter Name
  $V = $C.CounterSamples.CookedValue       # Value
  '{0,-15}  {1,-59}  {2,-14}' -f $T, $N, $V
  }

# 7. Explore Counter Set types for key perf counters
Get-Counter -ListSet Processor, Memory, Network*, *Disk* |
  Select-Object -Property CounterSetName, CounterSetType

# 8. Explore a local performance counter sample set
$Counter1 = '\Memory\Page Faults/sec'
$PFS      = Get-Counter -Counter $Counter1
$PFS

# 9. Look at remote performance counter sample set on HV1:
$Counter2 = '\\HV1\Memory\Page Faults/sec'
$RPFS     = Get-Counter -Counter $Counter1
$RPFS


# 10. Look inside a counter sample set
$PFS  | Get-Member -MemberType *Property |
  Format-Table -Wrap

# 11. What is inside a local multi-value counter sample
$Counter3 = '\Processor(*)\% Processor Time'
$CPU      =  Get-Counter -Counter $Counter3
$CPU

# 12. Vew a multi-value counter sample on HV2
$Counter4 = '\\hv2\Processor(*)\% Processor Time'
$CPU      =  Get-Counter -Counter $Counter4
$CPU
