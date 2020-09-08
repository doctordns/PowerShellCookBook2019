# Recipe 1.6 - Implementing JEA
# Run on DC1


# Setup envionment with OU, User, Group and group membership

# 0.1 Create an IT OU
$DomainRoot = 'DC=Reskit,DC=Org'
New-ADOrganizationalUnit -Name IT -Path $DomainRoot

# 0.2 Create a user - JerryG in the OU
$OURoot = "OU=IT,$DomainRoot"
$PW     = 'Pa$$w0rd'
$PWSS = 
  ConvertTo-SecureString  -String $PW -AsPlainText -Force
$NUHT  = @{Name                  = 'Jerry Garcia'
           SamAccountName        = 'JerryG'
           AccountPassword       = $PWSS
           Enabled               = $true
           PasswordNeverExpires  = $true
           ChangePasswordAtLogon = $false
           Path                  = $OURoot
}
New-ADUser @NUHT

# 0.3 Create ReskitDNSAdmins security universal group in the OU
$NGHT  = @{
  Name        = 'RKDnsAdmins '
  Path        = $OURoot 
  GroupScope  = 'Universal'
  Description = 'RKnsAdmins group for JEA'
}

New-ADGroup -Name RKDnsAdmins -Path $OURoot -GroupScope Universal

# 0.4 Add Jerryg to the ReskitAdmin's group
Add-ADGroupMember -Identity 'RKDNSADMINS' -Members 'JerryG'

# 0.5 Create transcripts folder
New-Item -Path C:\Foo\JEATranscripts -ItemType Directory

####  Start of main script

# 1. Build RC module folder
$PF = $env:Programfiles
$CP = 'WindowsPowerShell\Modules\RKDnsAdmins'
$ModPath = Join-Path -Path $PF -ChildPath $CP
New-Item -Path $ModPath -ItemType Directory | Out-Null

# 2. Create Role Capabilities file
$RCHT = @{
  Path            = 'C:\foo\RKDnsAdmins.psrc' 
  Author          = 'Reskit Administration'
  CompanyName     = 'Reskit.Org' 
  Description     = 'Defines RKDnsAdmins role capabilities'
  AliasDefinition = @{name='gh';value='Get-Help'}
  ModulesToImport = 'Microsoft.PowerShell.Core','DnsServer'
  VisibleCmdlets  = ("Restart-Service",
                     @{ Name = "Restart-Computer"; 
                        Parameters = @{Name = "ComputerName"}
                        ValidateSet = 'DC1, DC2'},
                      'DNSSERVER\*')
  VisibleExternalCommands = ('C:\Windows\System32\whoami.exe')
  VisibleFunctions = 'Get-HW'
  FunctionDefinitions = @{
    Name = 'Get-HW'
    Scriptblock = {'Hello JEA World'}}
}
New-PSRoleCapabilityFile @RCHT

# 3. Create the module manifest in the module folder
$P = Join-Path -Path $ModPath -ChildPath 'RKDnsAdmins.psd1'
New-ModuleManifest -Path $P -RootModule 'RKDNSAdmins.psm1'

# 4. create the role capabilies folder and copy the psrc
#    file into the module
$RCF = Join-Path -Path $ModPath -ChildPath 'RoleCapabilities'
New-Item -ItemType Directory $RCF
Copy-Item -Path $RCHT.Path -Destination $RCF -Force

# 5. Create a JEA Session Configuration file
$P = 'C:\foo\RKDnsAdmins.pssc'
$RDHT = @{
'Reskit\RKDnsAdmins' = @{RoleCapabilities = 'RKDnsAdmins'}
}
$PSCHT= @{
  Author              = 'DoctorDNS@Gmail.Com'
  Description         = 'Session Definition for RKDnsAdmins'
  SessionType         = 'RestrictedRemoteServer'   # ie JEA!
  Path                = $P                 # the output file
  RunAsVirtualAccount = $true
  TranscriptDirectory = 'C:\foo\jeatranscripts'
  RoleDefinitions     = $RDHT     # RKDnsAdmins role mapping
}
New-PSSessionConfigurationFile @PSCHT 

# 6. Test the session configuration file
Test-PSSessionConfigurationFile -Path C:\foo\RKDnsAdmins.pssc 

# 7. Register the JEA Session definition
$SCHT = @{
Path  = 'C:\foo\RKDnsAdmins.pssc'
Name  = 'RKDnsAdmins' 
Force =  $true 
}
Register-PSSessionConfiguration @SCHT

# 8. Check what the user can do:
Get-PSSessionCapability -ConfigurationName rkdnsadmins -Username 'reskit\jerryg' 

# 9. Create credentials for user JerryG
$U = 'Reskit\JerryG'
$P = ConvertTo-SecureString 'Pa$$w0rd' -AsPlainText -Force 
$Cred = New-Object System.Management.Automation.PSCredential $u,$p

# 10. Define two scriptbolocks and an invocation hash table
$SB1   = {Get-HW}
$SB2   = {Get-Command -Name  '*-DNSSERVER*'}
$ICMHT = @{
ComputerName      = 'LocalHost'
Credential        = $Cred 
ConfigurationName = 'RKDnsAdmins' 
} 

# 11. Invoke a JEA defined function in a JEA session and do it as JerryG
Invoke-Command -ScriptBlock $SB1 @ICMHT

# 12. Get DNSServer commands available to JerryG
$C = Invoke-command -ScriptBlock $SB2 @ICMHT 
"$($C.Count) DNS commands available"

# 13. Examine the contents of the Transcripts folder:
Get-ChildItem -Path $PSCHT.TranscriptDirectory

# 14. Examine a transcript
Get-ChildItem -Path $PSCHT.TranscriptDirectory | 
  Select -First 1  |
     Get-Content


Enter-PSSession -ComputerName LocalHost -ConfigurationName RKDnsAdmins -Credential $cred 




#  Extra things!

#  Enter a JEA session and see what you can do
Invoke-command -ComputerName Localhost -Credential $Cred -ConfigurationName rkdnsadmins -ScriptBlock $SB1


