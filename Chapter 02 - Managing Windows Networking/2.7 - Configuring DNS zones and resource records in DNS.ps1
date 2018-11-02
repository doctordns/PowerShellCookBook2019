# Recipe 8.5 - Configuring zones and resource records in DNS

# Run on DC1, CL1
# uses DC2

# 0. Getting ready
$PSS = ConvertTo-SecureString -String 'Pa$$w0rd' -AsPlainText -Force
$NewUserHT = @{
    AccountPassword       = $PSS
    Enabled               = $true
    PasswordNeverExpires  = $true
    ChangePasswordAtLogon = $false
    SamAccountName        = 'DNSADMIN'
    UserPrincipalName     = 'DNSADMIN@reskit.org'
    Name                  = 'DNSADMIN'
    DisplayName           = 'Reslkit DNS Admin'
}
New-ADUser @NewUserHT

# Add to Enterprise and Domain Admin groups
$GRPN = 'CN=Enterprise Admins,CN=Users,DC=reskit,DC=org',
         'CN=Domain Admins,CN=Users,DC=reskit,DC=org'
$PMHT = @{
    Identity = 'CN=DNSADMIN,CN=Users,DC=reskit,DC=org'
    MemberOf = $GRPN
}
Add-ADPrincipalGroupMembership @PMHT
# Ensure the user has been added
Get-ADUser -LDAPFilter '(Name=DNSADMIN)'

# Main script starts here

# 1. Add DNS to DC2
Add-WindowsFeature -Name DNS -ComputerName Dc2.Reskit.Org

# 2. Check DC1 replicates Reskit.Org to DC2 after installing DNS
$DnsSrv = 'DC2.Reskit.Org'
Resolve-DnsName -Name DC1.Reskit.Org -Type A -Server $DnsSrv

# 3. Add new DNS Server to DHCP scope
$OHT = @{
  ComputerName = 'DC1.Reskit.Org'
  DnsDomain    = 'Reskit.Org'
  DnsServer    = '10.10.10.10','10.10.10.11'
}
Set-DhcpServerV4OptionValue @OHT 


# 4. Check options on DC1
Get-DhcpServerv4OptionValue | Format-Table -AutoSize


# 5. Check IP Configuration now on CL1
#    Run on CL1
Get-DhcpServerv4OptionValue | Format-Table -AutoSize

# 6. Create a new primary forward DNS zone
$ZHT = @{
  Name              = 'Cookham.Reskit.Org'
  ReplicationScope  = 'Forest'
  DynamicUpdate     = 'Secure'
  ResponsiblePerson = 'DNSADMIN.reskit.org'
}
Add-DnsServerPrimaryZone @ZHT

# 7. Create a new primary reverse lookup domain (for IPv4), 
#    and view both new DNS zones
$PSHT = @{
  Name              = '10.in-addr.arpa'
  ReplicationScope  = 'Forest'
  DynamicUpdate     = 'Secure'
  ResponsiblePerson = 'DNSADMIN.Reskit.Org.'
}
Add-DnsServerPrimaryZone @PSHT


# 8. Check both zones served from DC1
Get-DNSServerZone -Name 'Cookham.Reskit.Org', '10.in-addr.arpa'

# 9. Add an A resource record to Cookham.Reskit.Org and get results:
$RRHT1 = @{
  ZoneName      =  'Cookham.Reskit.Org'
  A              =  $true
  Name           = 'Home'
  AllowUpdateAny =  $true
  IPv4Address    = '10.42.42.42'
  TimeToLive     = (30 * (24 * 60 * 60))  # 30 days in seconds
}
Add-DnsServerResourceRecord @RRHT1

# 10. Check results of RRs in Cookham.Reskit.Org zone
$Zname = 'Cookham.reskit.Org'
Get-DnsServerResourceRecord -ZoneName $Zname -Name 'home'

# 11. Check Reverse lookup zone
$RRH = @{
  ZoneName     = '10.in-addr.arpa'
  RRType       = 'Ptr'
  ComputerName = 'DC2'
}
Get-DnsServerResourceRecord @RRH


# 12. Add A resource records to the reskit.org zone:
$RRHT2 = @{
  ZoneName       = 'reskit.org'
  A              =  $true
  Name           = 'mail'
  CreatePtr      =  $true
  AllowUpdateAny = $true
  IPv4Address    = '10.10.10.42'
  TimeToLive     = '21:00:00'
}
Add-DnsServerResourceRecord  @RRHT2
$MXHT = @{
  Preference     = 10 
  Name           = '.'
  TimeToLive     = '1:00:00'
  MailExchange   = 'mail.reskit.org'
  ZoneName       = 'reskit.org'
}
Add-DnsServerResourceRecordMX @MXHT

$GHT = @{
  ZoneName = 'reskit.org'
  Name     = '@'
  RRType   = 'Mx'
}
Get-DnsServerResourceRecord  @GHT


# 13. Test the DNS service on DC1
Test-DnsServer -IPAddress 10.10.10.10 -Context DnsServer
Test-DnsServer -IPAddress 10.10.10.10 -Context RootHints
Test-DnsServer -IPAddress 10.10.10.10 -ZoneName 'Reskit.Org' 