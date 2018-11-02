# Recipe 2.6 - Configuring DHCP Load Balancing and Failover

# Run on DC2

# 1. Install the DHCP Server feature on DC2:
$FHT = @{
  Name         = 'DHCP','RSAT-DHCP' 
  ComputerName =  'DC2.Reskit.Org'}
Install-WindowsFeature @FHT

# 2. Let DHCP know it's all configured:
$IPHT = @{
  Path   = 'HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\12'
  Name   = 'ConfigurationState'
  Value  = 2
}
Set-ItemProperty @IPHT

# 3. Authorize the DHCP server in AD and view the results
Add-DhcpServerInDC -DnsName DC2.Reskit.Org

# 4. View the DHCP Servers authorised in the domain
Get-DhcpServerInDC

# 5. Configure failover and load balancing:
$FHT= @{
  ComputerName       = 'DC1.Reskit.Org'
  PartnerServer      = 'DC2.Reskit.Org'
  Name               = 'DC1-DC2'
  ScopeID            = '10.10.10.0'
  LoadBalancePercent = 60
  SharedSecret       = 'j3RryIsG0d!'
  Force              = $true
}
Add-DhcpServerv4Failover @FHT
-

# 5. Get acrive leases in the scope (from both servers!)
'DC1', 'DC2' |
    ForEach-Object {Get-DhcpServerv4Scope -ComputerName $_}


# 6. Now get serve statistics from both servers
'DC1', 'DC2' |
ForEach-Object {
    Get-DhcpServerv4ScopeStatistics -ComputerName $_} 
