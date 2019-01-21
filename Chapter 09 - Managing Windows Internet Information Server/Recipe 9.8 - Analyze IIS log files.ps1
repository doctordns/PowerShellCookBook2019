# Recipe 9.8 - Analyze IIS Log Files
# 
# Run from SRV1 after previous recipes have created log entries for SRV1

# 1. Define the location of log files and a temporary file
$LogFolder = 'C:\inetpub\logs\LogFiles\W3SVC1'
$LogFiles = Get-ChildItem $LogFolder\*.log -Recurse
$LogTemp = "C:\inetpub\logs\LogFiles\W3SVC1\AllLogs.tmp"

# 2. $Logs holds each line of each log file
$Logs = @()                 # Create empty array
# Remove the comment lines
$LogFiles | 
  ForEach { Get-Content $_ | 
    Where-Object {$_ -notLike "#[D,F,S,V]*" } | 
      Foreach { $Logs += $_ }  # add log entry to $Logs array
}

# 3. Build a better header
$LogColumns = ( $LogFiles | 
               Select-Object -First 1 | 
                 Foreach { Get-Content $_ | 
                   Where-Object {$_ -Like "#[F]*" } } )
$LogColumns = $LogColumns -replace "#Fields: ", ""
$LogColumns = $LogColumns -replace "-","" 
$LogColumns = $LogColumns -replace "\(","" 
$LogColumns = $LogColumns -replace "\)",""

# 4. Save the updated log files
$NL = [Environment]::NewLine
$P  = [System.String]::Join( [Environment]::NewLine, $Logs)
$S = "{0}{1}{2}" -f  $LogColumns, $NL,$P
Set-Content -Path $LogTemp -Value  $S

# 5. Read the reformatted logs as a CSV file
$Logs = Import-Csv -Path $LogTemp -Delimiter " "

# 6. View Client IP addresses
$Logs | 
  Sort-Object -Property cip | 
    Select-Object -Property CIP -Unique

# 7. View User Agents used to communicate with SRV1
$Logs | 
  Sort-Object -property csUserAgent | 
    Select-Object -Property csUserAgent -Unique

# 8. View frequency of each user agent
$Logs | 
  Sort-Object -Property csUserAgent |
    Group-Object csuseragent | 
      Sort-object -Property Count -Desc | 
        Format-Table -Property Count, Name

# 9. Who is using what:
$Logs | 
  Select-Object -Property CIP, CSUserAgent -Unique |
    Sort-Object -Property CIP 



