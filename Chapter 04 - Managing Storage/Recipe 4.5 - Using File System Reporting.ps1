# Recipe 4.5 - Using Storage Reporting
#
# Run on SRV1 after you run Recipe 4.4 to install FSRM

# 1. Create a new Storage report for large files on C:\ on SRV1
$NRHT = @{
  Name             = 'Large Files on SRV1'
  NameSpace        = 'C:\'
  ReportType       = 'LargeFiles'
  LargeFileMinimum = 10MB 
  Interactive      = $true 
  }
New-FsrmStorageReport @NRHT

# 2. Get reports
Get-FsrmStorageReport *

# 3. After Storage Report is run, view in filestore
$Path = 'C:\StorageReports\Interactive'
Get-ChildItem -Path $Path

# 4. View the report
$Rep = Get-ChildItem -Path $Path\*.html
Invoke-item -Path $Rep

# 5. Extract key information from the XML
$XF   = Get-ChildItem -Path $Path\*.xml 
$XML  = [XML] (Get-Content -Path $XF)
$Files = $XML.StorageReport.ReportData.Item
$Files | Where-Object Path -NotMatch '^Windows|^Program|^Users'|
  Format-Table -Property name, path,
  @{ name ='Sizemb'
     expression = {(([int]$_.size)/1mb).tostring('N2')}},
     DaysSinceLastAccessed -AutoSize

# 6. Create a monthly task in task scheduler
$Date = Get-Date '04:00'
$NTHT = @{
  Time    = $Date
  Monthly = 1
}
$Task = New-FsrmScheduledTask @NTHT
$NRHT = @{
  Name             = 'Monthly Files by files group report'
  Namespace        = 'C:\'
  Schedule         = $Task 
  ReportType       = 'FilesbyFileGroup'
  FileGroupINclude = 'text files'
  LargeFileMinimum = 25MB
}
New-FsrmStorageReport @NRHT | Out-Null

# 7. Get details of the task
Get-ScheduledTask | 
  Where-Object taskname -Match 'Monthly' |
    Format-Table -AutoSize

# 8. Run the task now
Get-ScheduledTask -TaskName '*Monthly*' | 
  Start-ScheduledTask
Get-ScheduledTask -TaskName '*Monthly*'

# 9. view the report
$Path = 'C:\StorageReports\Scheduled'
$Rep = Get-ChildItem -Path $path\*.html
Invoke-item -Path $Rep




#  cleanup
Unregister-ScheduledTask -TaskName "StorageReport-Monthly report on Big Files" -Confirm:$False
Get-FsrmStorageReport | Remove-FsrmStorageReport