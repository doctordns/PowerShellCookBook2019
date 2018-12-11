# Recipe 14.3 - Using BPA
#
# Run on SRV1

# 1. Get all BPA Models on SRV1
Get-BpaModel | Format-Table -Property Name, Id

# 2. Invoke BPA model for file services
Invoke-BpaModel -ModelId Microsoft/Windows/FileServices

# 3. Get BPA results for this scan:
$Results = Get-BpaResult -ModelId Microsoft/Windows/FileServices

# 4. Display how many tests/results in the BPA model
$Results.Count

# 5 How many errors were found?
($Results | Where-Object Severity -eq 'Error').Count

# 6. How many warnings were found?
$Warnings = $Results | Where-Object Severity -eq 'Warning'
$Warnings.Count

# 7. Examaine the first 3 warnings:
$Warnings | Select-Object -First 3 |
    Format-List Category, Problem, Impact, Resolution

# 8. Use BPA Remotely - what models exist on DC1
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