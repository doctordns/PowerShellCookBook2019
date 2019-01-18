# Recipe 6.3 -  Configuring the Windows Update client Via GPO
#
# Run on CL1

# 0. Get WIndows Upate module and install it
Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null
Install-Module PSWindowsUpdate -force

# 1. Examine 

# 1. Define the WSUS server URL using the properties returned from GetWsusServer:
$WSUSServer = Get-WsusServer -Name WSUS1.Reskit.Org -Port 8530
$FS =  "http{2}://{0}:{1}"
$N  = $WSUSServer.Name
$P  = 8530 # default port
$WSUSServerURL = $FS -f $n, $p, ('','s')[$WSUSServer.UseSecureConnection]
$WSUSServerURL

# 2. Create a Group Policy Object (GPO) and link it to the domain:
$PolicyName = 'Reskit WSUS Policy'
New-GPO -Name $PolicyName
New-GPLink -Name $PolicyName -Target 'DC=RESKIT,DC=Org'

# 3. Add registry key settings to the group policy to assign the WSUS server:
# Set to use WSUS not WU
$KEY1 = 'HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU'
$RVHT1 = @{
  Name       = $PolicyName 
  Key        = $KEY1
  ValueName  = 'UseWUServer'
  Type       = 'DWORD'
  Value      = 1
} 
Set-GPRegistryValue @RVHT1 | Out-Null
# Set AU options
$KEY2 = 'HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU'
$RVHT2 = @{
  Name      = $PolicyName
  Key       = $KEY2
  ValueName = 'AUOptions'
  Type      = 'DWORD'
  Value     = 2
}
Set-GPRegistryValue  @RVHT2 | Out-Null
# Set WSUS Server URL
$KEY3 = 'HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate'
$RVHT3 = @{
Name      = $PolicyName
Key       = $KEY3
ValueName = 'WUServer'
Type      = 'String'
Value     = $WSUSServerURL
}
Set-GPRegistryValue @RVHT3  | Out-Null                   
# Set WU Status server URL                    
$KEY4 = 'HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate'
$RVHT4 = @{
Name       = $PolicyName
Key        = $KEY4
ValueName  = 'WUStatusServer'
Type       = 'String' 
Value      = $WSUSServerURL
}
Set-GPRegistryValue @RVHT4 | Out-Null      


# 4. Get a report on the GPO
$RHT = @{
Name       = $PolicyName
ReportType = 'Html'
Path       = 'C:\foo\out.html'
}
Get-GPOReport @RHT
Invoke-Item -Path $RHT.Path
