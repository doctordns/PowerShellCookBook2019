#  Recipe 14.4 - Search Event Logs for specific events.
#  Run on SRV1


# 1. Get core event logs
Get-EventLog -LogName *

# 2. Get remote classic event logs from DC1
Get-EventLog -LogName * -ComputerName DC1

# 3. Clear application log on DC1:
Clear-EventLog -LogName Application -ComputerName DC1

# 4. Look At the types of events on SRV1
Get-EventLog -LogName application |
    Group-Object -property EntryType |
        Format-Table -Property Name, Count

# 5 Examine which area created the events in the application log:
Get-EventLog -LogName System |
    Group-Object -Property Source |
        Sort-Object -Property Count -Descending |
            Select-Object -First 10 |
                Format-Table -Property Name, Count

# 6. Examine ALL local event logs
$LocEventLogs = Get-WinEvent -ListLog *
$LocEventLogs.count
$LocEventLogs |
    Sort-Object -Property RecordCount -Descending |
        Select-Object -First 10

# 7. Examine ALL event logs on DC1
$RemEventLogs = Get-WinEvent -ListLog * -ComputerName DC1
$RemEventLogs.count
$RemEventLogs |
    Sort-Object -Property RecordCount -Descending |
        Select-Object -First 10

# 8. Look at New logs - Windows Update - what updates have been found
$LN = 'Microsoft-Windows-WindowsUpdateClient/Operational'
$Updates = Get-WinEvent -LogName $LN |
  Where-Object ID  -EQ 41
$Out = Foreach ($Update in $Updates) {
  $HT = @{}
  $HT.Time = $Update.TimeCreated
  $HT.Update = ($Update.Properties | Select-Object -First 1).Value
  New-Object -TypeName PSObject -Property $HT 
}
$Out |
  Sort-Object -Property TimeCreated |
     Format-Table -Wrap