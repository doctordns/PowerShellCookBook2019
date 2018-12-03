# Recipe 13-1 - Create Performance Report
# 
#  Uses CSV output from Recipe 13-3
#  Run on SRV1

# 1 - Import the CSV file of counters
$Folder = 'C:\PerfLogs\Admin'
$File = Get-ChildItem -Path $folder\*.csv -Recurse

# 2. Import the performance counters.
$Counters = Import-Csv $File.FullName 
"$($Counters.Count) counters in $($File.FullName)"

# 3. Fix issue with 1st row in the counters
$counters[0] = $counters[1]

# 4. Obtain basic CPU stats
$CN = '\\SRV1\Processor(_Total)\% Processor Time'
$HT = @{
 Name = 'CPU'
 Expression = {[system.double] $_.$cn}
}
$Stats = $counters | 
  Select-Object -Property *,$ht |
Measure-Object -Property CPU `
               -Average -Minimum -Maximum

# 5. Add  95th percent value of CPU 
$CN = '\\srv1\Processor(_Total)\% Processor Time'
$Row = [int]($Counters.Count * .95 )
$Cpu = ($counters.$CN | Sort-Object)
$Cpu95 = [double] $CPU[$Row]
$AMHT = @{
  InputObject = $stats 
  Name        = 'CPU95'
  MemberType  = 'NoteProperty'
  Value       = $cpu95

}
Add-Member @AMHT

# 6. Combine the results into a single report:
$Stats.CPU95   = $Stats.CPU95.ToString('n2')
$Stats.Average = $Stats.Average.ToString('n2')
$Stats.Maximum = $stats.Maximum.ToString('n2')
$Stats.Minimum = $stats.Minimum.ToString('n2')

# 7. Display statistics
$Stats | 
  Format-Table -Property Property,Count, Maximum, CPU95, Minimum