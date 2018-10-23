# Recipe 6-2 - Get Performance Counters using CIM Cmdlets

#  1. Find Perf related counters in RootzCimV2
Get-CimClass -ClassName Win32*perf* | Measure-Object
Get-CimClass -ClassName Win32*perfFormatted* | Measure-Object
Get-CimClass -ClassName Win32*perfraw* | Measure-Object

# 2. Find key Performance classes
Get-CimClass "win32_PerfFormatted*perfos*" |
    Select-Object -Property CimClassName
Get-CimClass "win32_PerfFormatted*disk*" |
    Select-Object -Property CimClassName

# 3. Get Memory counter samples
Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_Memory

# 4. Get CPU counter samples
Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_Processor |
    Where-Object Name -eq '_Total'
Get-Ciminstance -ClassName Win32_PerfFormattedData_PerfOS_Processor |
    Select-Object -Property Name, PercentProcessortime

# 5. Get Memory counter samples from a remote system
$CHT = @{
    ClassName     = 'Win32_PerfFormattedData_PerfOS_Memory'
    ComputerName  = 'DC1'
}
Get-CimInstance @CHT
