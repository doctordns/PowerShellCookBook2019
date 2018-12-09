# Recipe 13.5
# Create a performance monitoring Graph

# 1. Load the Forms assembly
Add-Type -AssemblyName System.Windows.Forms.DataVisualization

# 2. Import the CSV data from earlier, and fix row 0
$CSVFile     = Get-ChildItem -path C:\PerfLogs\Admin\*.csv -rec
$Counters    = Import-Csv $CSVFile
$Counters[0] = $Counters[1] # fix row 0 issues

# 3. Create a chart object
$CPUChart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart

# 4. Defne the chart dimensions
$CPUChart.Width  = 1000
$CPUChart.Height = 600
$CPUChart.Titles.Add("SRV1 CPU Utilisation") | Out-Null

# 5 Create and define the chart area
$ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
$ChartArea.Name        = "SRV1 CPU Usage"
$ChartArea.AxisY.Title = "% CPU Usage"
$CPUChart.ChartAreas.Add($ChartArea)

# 6. Identify the date/time column.
$Name = ($counters[0] | Get-Member | 
          Where-Object MemberType -EQ "NoteProperty")[0].Name

# 7. Add the data points to the chart.
$CPUChart.Series.Add("CPUPerc")  | Out-Null
$CPUChart.Series["CPUPerc"].ChartType = "Line"
$CPUCounter = '\\SRV1\Processor(_Total)\% Processor Time'
$counters | ForEach-Object{
   $CPUChart.Series["CPUPerc"].Points.AddXY($_.$name,$_.$CPUCounter) |
        Out-Null
}

# 8. Ensure folder exists, then save the chart image as a png file in the folder:
$NIHT = @{
  Path        = 'C:\Perflogs\Reports'
  ItemType    = 'Directory'
  ErrorAction = 'SilentlyContinue' 
}
New-Item @NIHT
$CPUChart.SaveImage("C:\PerfLogs\Reports\Srv1CPU.Png", 'PNG')

# 9. view the chart image
MSPaint C:\PerfLogs\Reports\SRV1cpu.Png
