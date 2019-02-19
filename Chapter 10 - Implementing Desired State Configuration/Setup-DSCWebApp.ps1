# Setup-DSCWebApp.ps1
#

# Setup for DSC Recipe
# Create folder/share on DC1
$SB = {
    New-Item C:\ReskitApp -ItemType Directory
    New-SMBShare -Name ReskitApp -Path C:\ReskitApp
}
Invoke-Command -ComputerName DC1 -ScriptBlock $SB |
    Out-Null
# Create Index.Htm on DC1
$HP = '\\DC1.Reskit.Org\C$\ReskitApp\Index.htm'
$P2 = '\\DC1.Reskit.Org\C$\ReskitApp\Page2.htm'

$Index = @"
<!DOCTYPE html>
<html><head><title>
Main Page - ReskitApp Application</title></head>
<body><p><center><b>
HOME PAGE FOR RESKITAPP APPLICATION</b></p>
This is the root page of the RESKITAPP application
<br><hr>
Pushed via DSC</p><br><hr>
<a href="http://SRV2/ReskitApp/Page2.htm">
Click to View Page 2</a>
</center>
<br><hr></body></html>
"@
$Index | 
    Out-File -FilePath $HP -Force
# Create Page2.htm on DC1
$Page2 = @"
<!DOCTYPE html>
<html>
<head><title>ReskitApp Application - Page 2</title></head>
<body><p><center>
<b>Page 2 For the ReskitApp Web Application</b></p>
<a href="http://SRV2/ReskitApp/Index.htm">
Click to Go Home</a>
<hr></body></html>
"@ 
$Page2 | 
    Out-File -FilePath $P2 -Force
    