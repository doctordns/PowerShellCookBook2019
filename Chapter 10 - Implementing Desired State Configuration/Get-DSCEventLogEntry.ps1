# dsc debugging

# 1. turn on DSC event logging
wevtutil.exe set-log "Microsoft-Windows-Dsc/Analytic" /q:true /e:true
wevtutil.exe set-log "Microsoft-Windows-Dsc/Debug" /q:True /e:true
wevtutil.exe set-log "Microsoft-Windows-Dsc/Operational" /q:True /e:true
# do stuff in dsc...


# 2. Collect the logs:
$DscEvents  = [System.Array](Get-WinEvent "Microsoft-Windows-Dsc/Operational") 
$DscEvents += [System.Array](Get-WinEvent "Microsoft-Windows-Dsc/Analytic" -Oldest)
$DscEvents += [System.Array](Get-WinEvent "Microsoft-Windows-Dsc/Debug" -Oldest)

# Group based on Job ID
$SeparateDscOperations = $DscEvents | Group {$_.Properties[0].Value}


$SeparateDscOperations[0].Group

# Look at errors
$SeparateDscOperations | Where-Object {$_.Group.LevelDisplayName -contains "Error"}

# last 30 minutes
$DateLatest = (Get-Date).AddMinutes(-30)
$SeparateDscOperations | Where-Object {$_.Group.TimeCreated -gt $DateLatest} | 

# finding errors