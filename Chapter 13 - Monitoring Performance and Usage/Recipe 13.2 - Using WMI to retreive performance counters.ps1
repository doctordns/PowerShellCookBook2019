# Recipe 12.2 - Get Performance Counters using CIM Cmdlets
#
#  Run on SRV1

#  1. Find Perf related counters in Root\CIMV2 namespace:
Get-CimClass -ClassName Win32*perf* | Measure-Object |
  Select-Object -Property Count
Get-CimClass -ClassName Win32*perfFormatted* | Measure-Object |
  Select-Object -Property Count
Get-CimClass -ClassName Win32*perfraw* | Measure-Object |
  Select-Object -Property Count

# 2. Find key Performance classes for the OS
Get-CimClass "Win32_PerfFormatted*PerfOs*" |
  Select-Object -Property CimClassName

# 3. Find key performance classes for the disk
Get-CimClass "win32_PerfFormatted*Disk*" |
  Select-Object -Property CimClassName

# 4. Get Memory counter samples
$Class = 'Win32_PerfFormattedData_PerfOS_Memory'
Get-CimInstance -ClassName $Class |
  Select-Object -Property PagesPerSec, AvailableMBytes

# 5. Get CPU counter samples
$Class2 = 'Win32_PerfFormattedData_PerfOS_Processor'
Get-CimInstance -ClassName $Class2 |
    Where-Object Name -eq '_Total' |
      Select-Object -Property Name, PercentProcessortime

# 6. Get Memory counter samples from a remote system
$CHT = @{
    ClassName     = 'Win32_PerfFormattedData_PerfOS_Memory'
    ComputerName  = 'DC1'
}
Get-CimInstance @CHT |
  Select-Object -Property PSComputerName, PagesPerSec,
                          AvailableMBytes
