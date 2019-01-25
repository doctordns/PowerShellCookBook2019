# Recipe 10-6 - Configure IIS Logging and log files

# 1. Import the web administration module to ensure IIS provider is loaded
Import-Module WebAdministration

# 2. Look at where you are currently storing log files:
$IPHT1 = @{
  Path  = 'IIS:\Sites\Default Web Site'
  Name  =  'logfile.directory'
}
$LogfileLocation = (Get-ItemProperty @IPHT1).value
$LF = [System.Environment]::ExpandEnvironmentVariables("$LF") 
Get-ChildItem $LogFileFolder -Recurse

# 3. Change the folder to C:\IISLogs
New-Item -Path C:\IISLogs -ItemType Directory
$IPHT2 = @{
  Path  = 'IIS:\Sites\Default Web Site'
  Name  =  'logfile.directory'
}
Set-ItemProperty @IPHT2 -Value 'C:\IISLogs'

# 4. Change the Logging type:
$IPHT3 = @{
  Path = 'IIS:\Sites\Default Web Site'
  Name = 'logFile.logFormat'
}
Set-ItemProperty @IPHT3 -Value 'W3C'

# 5. Change logging frequency:
$IPHT3 = @{
  Path = 'IIS:\Sites\Default Web Site'
  Name = 'logFile.period'
}
Set-ItemProperty @IPHT3 -Value Weekly

# 6. Change logging to use a maximum size:
$IPHT4 = @{
  Path = 'IIS:\Sites\Default Web Site'
  Name = 'logFile.period'
}
Set-ItemProperty @IPHT4 -Value 'MaxSize'
$Size = 1GB
$IPHT5 = @{
  Path = 'IIS:\Sites\Default Web Site'
  Name = 'logFile.truncateSize'
}
Set-ItemProperty @IPHT5 -Value $size

# 7. Disable logging:
$IPHT5 = @{
  Path = 'IIS:\Sites\Default Web Site'
  Name = 'logFile.enabled'
}
Set-ItemProperty @IPHT5 -Value $false

# 8. Delete old log files
$LogDirs = Get-ChildItem -Path IIS:\Sites | 
             Get-ItemProperty -Name logFile.directory.value |
               Select -Unique
$Age = 30 # h0ow long to keep log files for
$DaysOld = (Get-Date).AddDays(-$Age) 
foreach ($LogDir in $LogDirs){
  $Dir = [Environment]::ExpandEnvironmentVariables($LogDir)
  $DIR
  Get-ChildItem -Path $Dir -Recurse -ErrorAction SilentlyContinue | 
    Where-Object LastWriteTime -lt $DaysOld
      Remove-Item 
}

