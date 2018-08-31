# Recipe 3.1 - Installing Active Directory with DNS

# This recipe uses DC1 and DC2
# The recipe starts on DC1, then uses DC2.
# DC1 is initially a stand-alone work group server you convert
# into a DC with DNS.
# Then you convert DC2 (a domain joined server) to a DC and setup DNS there too.


###  Part 1 - run on DC1

# 1. Install the AD Domain Services feature and management tools
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

# 2.	Install DC1 as forest root server (DC1.Reskit.Org)d
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
  DomainMode                    = 'Win2016'
  ForestMode                    = 'Win2016'
  Force                         = $true
  NoRebootOnCompletion          = $true
}
Install-ADDSForest @ADHT

# 3. Restart Computer
Restart-Computer -Force

### Part 2 - run on DC2
#   Assumes DC1 is a DC, DC2 is a domain joined server

# 4. Check DC1 can be resolved, and can be reached over 445 and 389 from DC2
Resolve-DnsName -Name DC1.Reskit.Org -Server DC1.Reskit.Org -Type A
Test-NetConnection -ComputerName DC1.Reskit.Org -Port 445
Test-NetConnection -ComputerName DC1.Reskit.Org -Port 389

# 5. Add the AD DS features on DC2
$Features = 'AD-Domain-Services, DNS,RSAT-DHCP, Web-Mgmt-Tools'
Install-WindowsFeature -Feature @Features

# 6. Promote DC2 to be a DC in the Reskit.Org domain:
$PSS = ConvertTo-SecureString -String 'Pa$$w0rd' -AsPlainText -Force
$IHT =@{
  DomainName                    = 'Reskit.org'
  SafeModeAdministratorPassword = $PSS
  SiteName                      = 'Default-First-Site-Name'
  NoRebootOnCompletion          = $true
  Force                         = $true
}
Install-ADDSDomainController @IHT

# 7. After reboot, logon to DC1
Get-ADRootDSE -Server DC1
