# Recipe 10-6 - Configure IIS Logging and log files

# 1. Import the web administration module to ensure IIS provider is loaded
Import-Module WebAdministration

# 2. Look at where you are currently storing log files:
$IPHT = @{
    Path  = 'IIS:\Sites\Default Web Site' `
    Name logfile).directory
}
$LogfileLocation = (Get-ItemProperty `
                      -Path 'IIS:\Sites\Default Web Site' `
                      -Name logfile).directory
$LogFileFolder = 
    [System.Environment]::ExpandEnvironmentVariables("$LogfileLocation") 
ls $LogFileFolder -Recurse

# 3 Change the folder to C:\IISLogs
Set-ItemProperty -Path 'IIS:\Sites\Default Web Site' -Name logFile.directory -Value 'C:\IISLogs'

# 4. Change the Logging type:
Set-ItemProperty 'IIS:\Sites\Default Web Site' -Name logFile.logFormat 'W3C'

# 5. Change logging frequency:
Set-ItemProperty 'IIS:\Sites\Default Web Site' -Name logFile.period -Value Weekly

# 6. Change logging to use a maximum size:
Set-ItemProperty 'IIS:\Sites\Default Web Site' -Name logFile.period -Value MaxSize
$Size = 1GB
Set-ItemProperty 'IIS:\Sites\Default Web Site' -Name logFile.truncateSize $size

# 7. Disable logging:
Set-ItemProperty 'IIS:\Sites\Default Web Site' -Name logFile.enabled -Value False

# 8. Delete old log files
$LogDirs = Get-ChildItem -Path IIS:\Sites | 
               Get-ItemProperty -Name logFile.directory.value |
                   Select -Unique
$Age = 7  # day
foreach ($LogDir in $LogDirs){
  $dir = [Environment]::ExpandEnvironmentVariables($LogDir)
  $DIR
  Get-ChildItem -Path $Dir -Recurse -ErrorAction SilentlyContinue | 
      Where-Object LastWriteTime -lt (Get-Date).AddDays(-$Age) }
          #Remove-Item 
}

