# Recipe 14.3 - Using BPA
#
# Run on SRV1

# 1. Get all BPA Models on SRV1
Get-BpaModel | 
  Format-Table -Property Name, Id, LastScanTime -Wrap

# 2. Invoke BPA model for Web Server feature
Invoke-BpaModel -ModelId Microsoft/Windows/WebServer

# 3. Get the results of the BPA run
$Results = Get-BpaResult -ModelId Microsoft/Windows/webServer

# 4. Display how many tests/results in the BPA model
$Results.Count

# 5 How many errors and warnings were found?
$Errors = $Results | Where-Object Severity -eq 'Error'
$Warnings = $Results | Where-Object Severity -eq 'Warning'
"Errors found   : {0}" -f $Errors.Count
"Warnings found : {0}" -f $Warnings.Count

# 6. Look at other BPA Results:
$Results  | Format-Table -Property Title, Compliance -Wrap

# 7. Use BPA Remotely - what models exist on DC1
Invoke-Command -ComputerName DC1 -ScriptBlock {Get-BpaModel} |
  Format-Table -Property Name, Id

# 9. Run BPA Analyzer on DC1
$SB = {Invoke-BpaModel -ModelId `
                    Microsoft/Windows/DirectoryServices}
Invoke-Command -ComputerName DC1 -ScriptBlock $sb

# 10. Get the results
$SB = {Get-BpaResult -ModelId Microsoft/WIndows/DirectoryServices}
$RRESULTS = Invoke-Command -ComputerName DC1 -ScriptBlock $sb

# 11 How many checks/results?
$RResults.count
$RResults | Group-Object SEVERITY |
                 Format-Table -Property Name, Count

# 12. Look at one error:
$RResults | Where-Object Severity -EQ 'Error' |
    Format-List -Property Category,Problem,Impact,Resolution