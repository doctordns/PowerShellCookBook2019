# Recipe 3-2 0 Configuring the Windows Update client

# 1. Define and view the WSUS server URL using the properties returned from GetWsusServer:
$WSUSServer = Get-WsusServer
$WSUSServerURL = "http{2}://{0}:{1}" -f `
                  $WSUSServer.Name,
                  $WSUSServer.PortNumber,
                  ('','s')[$WSUSServer.UseSecureConnection]
$WSUSServerURL

# 2. Create a Group Policy Object (GPO) and link it to your domain:
$PolicyName = 'WSUS Client'
New-GPO -Name $PolicyName
New-GPLink -Name $PolicyName -Target 'DC=RESKIT,DC=Org'

# 3. Add registry key settings to the group policy to assign the WSUS server:
$key = 'HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU'
Set-GPRegistryValue -Name $PolicyName `
                    -Key $key `
                    -ValueName 'UseWUServer'`
                    -Type DWORD -Value 1
$key = 'HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU'
Set-GPRegistryValue -Name $PolicyName `
                    -Key $key `
                    -ValueName 'AUOptions' `
                    -Type DWORD `
                    -Value 2
$key = 'HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate'
Set-GPRegistryValue -Name $PolicyName `
                    -Key $key `
                    -ValueName 'WUServer' `
                    -Type String `
                    -Value $WSUSServerURL
$key = 'HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate'
Set-GPRegistryValue -Name $PolicyName `
                    -Key $key `
                    -ValueName 'WUStatusServer' `
                    -Type String -Value $WSUSServerURL

# 4. Each PC on the domain then begins using the WSUS server once the group policy
#    is updated. To make this happen immediately, on each PC, run the following
#    commands:
Gpupdate /force
Wuauclt /detectnow