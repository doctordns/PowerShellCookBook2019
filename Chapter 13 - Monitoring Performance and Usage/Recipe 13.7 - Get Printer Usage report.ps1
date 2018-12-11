# 1. Run WevtUtil to turn on printer monitoring.
wevtutil.exe sl "Microsoft-Windows-PrintService/Operational" /enabled:true

# 2. Define a function

 Function Get-PrinterUsage {
# 2.1 Get events from the print server event log
$LogName = 'Microsoft-Windows-PrintService/Operational'
$Dps = Get-WinEvent -LogName $LogName |
         Where-Object ID -eq 307 
Foreach ($Dp in $Dps) {
# 2.2 Ceate a hash table3 with an event log  record
   $Document          = [ordered] @{}
# 2.3 Populate the hash table with properties from the 
# Event log entry
   $Document.Id       = $Dp.Properties[0].value
   $Document.Type     = $Dp.Properties[1].value
   $Document.User     = $Dp.Properties[2].value
   $Document.Computer = $Dp.Properties[3].value
   $Document.Printer  = $Dp.Properties[4].value
   $Document.Port     = $Dp.Properties[5].value
   $Document.Bytes    = $Dp.Properties[6].value
   $Document.Pages    = $Dp.Properties[7].value

# 2.4 Create an object for this printer usage entry
 $UEntry = New-Object -TypeName PSObject -Property $Document 

# 2.5 And give it a more relecant tyhpe name
 $UEntry.pstypenames.clear()
 $UEntry.pstypenames.add("Packt.PrintUsage")

# 2.6 Output the entry
 $UEntry
} # End of foreach

} # End of function

# 3.0 Set and use an alias to get printer usage
Get-PrinterUsage | Format-Table