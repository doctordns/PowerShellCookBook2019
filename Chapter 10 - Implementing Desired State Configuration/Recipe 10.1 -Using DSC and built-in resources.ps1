#  Recipe 10.1 - Using DSC and built-in resources
#
#  Run on SRV1

# 0. Create initial documents for Reskit application
#     Also share the application on DC1
# create folders/share
$SB = {
  New-Item C:\ReskitApp -ItemType Directory
  New-SMBShare -Name ReskitApp -Path C:\ReskitApp
}
Invoke-Command -ComputerName DC1 -ScriptBlock $SB |
    Out-Null
# create index.htm
$HP    = '\\dc1.reskit.org\c$\reskitapp\Index.htm'
$Index = @"
<!DOCTYPE html>
<html><head><title>
Main Page - ReskitApp Application</title></head>
<body><p><center><b>
HOME PAGE FOR RESKITAPP APPLICATION</b></p>
This is the root page of the RESKITAPP application
<br><hr>
Pushed via DSC</p><br><hr>
<a href="http://srv2/reskitapp/Page2.htm">
Click to View Page 2</a>
</center>
<br><hr></body></html>
"@
$Index | 
   Out-File -FilePath $HP -Force
# create page2.htm
$P2 = '\\DC1.Reskit.Org\C$\Reskitapp\Page2.htm'
$Page2 = @"
<!DOCTYPE html>
<html>
<head><title>ReskitApp Application - Page 2</title></head>
<body><p><center>
<b>Page 2 For the ReskitApp Web Application</b></p>
<a href="http://srv2/reskitapp/index.htm">
Click to Go Home</a>
<hr></body></html>
"@
$Page2 | 
  Out-File -FilePath $P2 -Force

####  Recipe begins here
    
# 1. Discover DSC resources on SRV1
Get-DscResource |
  Format-Table -Property Name, ModuleName, Version

# 2. Look at File Resource
Get-DscResource -Name File | 
  Format-List -Property *

# 3 Get DSC Resource Syntax
Get-DscResource -Name File -Syntax

# 4. Create/compile a configuration block
Configuration PrepareSRV2 {
  Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
  Node SRV2
  {
    File  BaseFiles
    {
       DestinationPath = 'C:\ReskitApp\'
       SourcePath      = '\\DC1\ReskitApp\'
       MatchSource     = $true
       Ensure          = 'Present'
       Recurse         = $True
    }
  }
 }

# 5. View configuration function
Get-Item -Path Function:\PrepareSRV2

# 6. Create output folder for DSC 
$Conf = {
  $EASC = @{ErrorAction = 'SilentlyContinue'}
  New-Item -Path C:\ReskitApp -ItemType Directory @EASC
}
Invoke-command -ComputerName SRV2 -ScriptBlock $Conf |
  Out-Null

# 7.  Run function to produce MOF file
PrepareSRV2 -OutputPath C:\DSC

# 8. View MOF File
Get-Content -Path C:\DSC\SRV2.mof

# 9. Make it so Mr Riker
Start-DscConfiguration -Path C:\DSC -Wait -Verbose

# 10. Observe results
Get-ChildItem -Path '\\SRV2\C$\ReskitApp'

# 11. Induce configuration drift:
Remove-Item -Path \\SRV2\C$\ReskitApp\Index.htm

# 12. Fix configuration drift
Start-DscConfiguration -Path C:\DSC\ -Wait -Verbose

# 13. What happens if NO config drift?
Start-DscConfiguration -Path C:\DSC\ -Wait -Verbose