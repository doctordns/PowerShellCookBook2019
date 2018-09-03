$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$DefaultUsername = "reskit\administrator"
$DefaultPassword = "Pa$$W0rd"
Set-ItemProperty $RegPath "AutoAdminLogon" -Value "1" -type String 
Set-ItemProperty $RegPath "DefaultUsername" -Value "$DefaultUsername" -type String 
Set-ItemProperty $RegPath "DefaultPassword" -Value "$DefaultPassword" -type String