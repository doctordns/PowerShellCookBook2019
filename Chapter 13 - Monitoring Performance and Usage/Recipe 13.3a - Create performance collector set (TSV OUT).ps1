# 11.3 - Create and add a data collector set
# This variant creates a TSV Output file
#
# Run on SRV1

# 1. Create and populate a new collector 
$Name = 'SRV1 Collector Set - tsv'
$SRV1CS = New-Object -COM Pla.DataCollectorSet
$SRV1CS.DisplayName                = $Name
$SRV1CS.Duration                   = 12*3600  # 12 hours - 19:00
$SRV1CS.SubdirectoryFormat         = 1 
$SRV1CS.SubdirectoryFormatPattern  = 'yyyy\-MM'
$JPHT = @{
Path      = "$Env:SystemDrive"
ChildPath = "\PerfLogs\Admin\$Name"
}
$SRV1CS.RootPath =  Join-Path @JPHT
$SRV1Collector = $SRV1CS.DataCollectors.CreateDataCollector(0) 
$SRV1Collector.FileName              = "$Name_"
$SRV1Collector.FileNameFormat        = 1 
$SRV1Collector.FileNameFormatPattern = "\-MM\-dd"
$SRV1Collector.SampleInterval        = 15
$SRV1Collector.LogFileFormat         = 1  # Tab separated
$SRV1Collector.LogAppend             = $True

# 2. Define counters of interest
$Counters = @(
    '\Memory\Pages/sec',
    '\Memory\Available MBytes', 
    '\Processor(_Total)\% Processor Time', 
    '\PhysicalDisk(_Total)\% Disk Time',
    '\PhysicalDisk(_Total)\Disk Transfers/sec' ,
    '\PhysicalDisk(_Total)\Avg. Disk Sec/Read',
    '\PhysicalDisk(_Total)\Avg. Disk Sec/Write',
    '\PhysicalDisk(_Total)\Avg. Disk Queue Length'    
)

# 3. Add the counters to the collector
$SRV1Collector.PerformanceCounters = $Counters

# 4. Create a schedule - start tomorrow morning at 07:00
$StartDate = Get-Date -Day $((Get-Date).Day+1) -Hour 7 -Minute 0 -Second 0
$Schedule = $SRV1CS.Schedules.CreateSchedule()
$Schedule.Days = 127
$Schedule.StartDate = $StartDate
$Schedule.StartTime = $StartDate

# 5. Create, add and start the collector set
try
{
    $SRV1CS.Schedules.Add($Schedule)
    $SRV1CS.DataCollectors.Add($SRV1Collector) 
    $SRV1CS.Commit("$Name" , $null , 0x0003) | Out-Null
    $SRV1CS.Start($false);
}
catch [Exception] 
{ 
    Write-Host "Exception Caught: " $_.Exception -ForegroundColor Red 
    return 
} 


pause

# 6. Remove the counter
$DCStRemote = New-Object -COM Pla.DataCollectorSet  
$Name = 'SRV1 Collector Set - tsv'
$DCstRemote.Query($Name,'LocalHost')
$DCstRemote.Stop($true)
$DCstRemote.Delete()

# 7 and start the counter too
$DCStRemote = New-Object -COM Pla.DataCollectorSet  
$Name = 'SRV1 Collector Set'
$DCstRemote.Query($Name,'LocalHost')
$DCstRemote.Start($true)