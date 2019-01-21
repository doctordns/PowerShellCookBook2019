#
# Originally from: "http://sbrickey.com/Tech/Blog/Post/Parsing_IIS_Logs_with_PowerShell"
#

# Define the location of log files and a temporary file
$LogFolder = "C:\inetpub\logs\LogFiles\W3SVC1"
$LogFiles = Get-ChildItem $LogFolder\*.log -Recurse
$LogTemp = "C:\inetpub\logs\LogFiles\W3SVC1\AllLogs.tmp"

# Logs will store each line of the log files in an array
$Logs = @()
# Skip the comment lines
$LogFiles | % { Get-Content $_ | 
  Where-Object {$_ -notLike "#[D,F,S,V]*" } | 
    Foreach { $Logs += $_ } }
# Then grab the first header line, and adjust its format for later
$LogColumns = ( $LogFiles | 
               Select-Object -First 1 | 
                 Foreach { Get-Content $_ | 
                   Where-Object {$_ -Like "#[F]*" } } ) -replace "#Fields: ", "" -replace "-","" -replace "\(","" -replace "\)",""

# Temporarily, store the reformatted logs
Set-Content -LiteralPath $LogTemp -Value ( [System.String]::Format("{0}{1}{2}", $LogColumns, [Environment]::NewLine, ( [System.String]::Join( [Environment]::NewLine, $Logs) ) ) )

# Read the reformatted logs as a CSV file
$Logs = Import-Csv -Path $LogTemp -Delimiter " "

# View Client IP addresses
$Logs | 
  Sort-Object -Property cip | 
    Select-Object -Property CIP -Unique


# View clients

$Logs | 
  Sort-Object -property csUserAgent | 
    Select-Object -Property csUserAgent -Unique
$Logs | 
  Sort-Object -Property csUserAgent |
    Group-Object csuseragent | 
      Sort-object -Property Count -Desc | 
        Format-Table -Property Count, Name

