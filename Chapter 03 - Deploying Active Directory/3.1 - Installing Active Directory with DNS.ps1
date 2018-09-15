# Recipe 3.1 - Installing Active Directory with DNS

# This recipe uses DC1 and DC2
# The recipe starts on DC1, then uses DC2.
# DC1 is initially a stand-alone work group server you convert
# into a DC with DNS.
# Then you convert DC2 (a domain joined server) to a DC and setup DNS there too.


###  Part 1 - run on DC1

# 1. Install the AD Domain Services feature and management tools
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

# 2.	Install DC1 as forest root server (DC1.Reskit.Org)
$PSSHT = @{
  String      = 'Pa$$w0rd'
  AsPlainText = $true
  Force       = $true
}
$PSS = ConvertTo-SecureString @PSSHT
$ADHT = @{
  DomainName                    = 'Reskit.Org'
  SafeModeAdministratorPassword = $PSS
  InstallDNS                    = $true
  DomainMode                    = 'WinThreshold'
  ForestMode                    = 'WinThreshold'
  Force                         = $true
  NoRebootOnCompletion          = $true
}
Install-ADDSForest @ADHT

# 3. Restart computer
Restart-Computer -Force

# 4. After reboot, log back into DC1 as Reskit\Administrator, then
Get-ADRootDSE |
  Format-Table -Property dns*, *functionality



### Part 2 - run on DC2
#   Assumes DC1 is now a DC, DC2 is another workgroup server

# 5. Check DC1 can be resolved, and 
#    can be reached over 445 and 389 from DC2
Resolve-DnsName -Name DC1.Reskit.Org -Type A
Test-NetConnection -ComputerName DC1.Reskit.Org -Port 445
Test-NetConnection -ComputerName DC1.Reskit.Org -Port 389

# 6. Add the AD DS features on DC2
$Features = 'AD-Domain-Services', 'DNS','RSAT-DHCP', 'Web-Mgmt-Tools'
Install-WindowsFeature -Name $Features

# 7. Promote DC2 to be a DC in the Reskit.Org domain
$URK = "administrator@reskit.org"
$PSS = ConvertTo-SecureString -String 'Pa$$w0rd' -AsPlainText -Force
$CredRK = New-Object system.management.automation.PSCredential $URK,$PSS
$IHT =@{
  DomainName                    = 'Reskit.org'
  SafeModeAdministratorPassword = $PSS
  SiteName                      = 'Default-First-Site-Name'
  NoRebootOnCompletion          = $true
  Force                         = $true
} 
Install-ADDSDomainController @IHT -Credential $CredRK

# 8 Reboot DC2
Restart-Computer -Force

# 9. After reboot, logon to DC1 and view the forest
Get-AdForest | 
  Format-Table -Property *master*,globaL*,Domains

# 10. View details of the domain
Get-ADDomain | 
  Format-Table -Property DNS*,PDC*,*master,Replica*

