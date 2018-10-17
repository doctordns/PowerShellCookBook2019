# 8.8 - Configuring DHCP Load Balancing and Failover

# Run on DC2

# Install the DHCP feature on DC2:
$FHT = @{
  Name         = 'DHCP', 'RSAT-DHCP' 
  ComputerName =  'DC2.Reskit.Org'
}
Install-WindowsFeature @FHT

# 2. Let DHCP know it's all configured:
$SB = {
  $IPHT = @{
    Pat   = 'HKLM\:SOFTWARE\Microsoft\ServerManager\Roles\12'
    Name  = 'ConfigurationState'
    Value = 2
  }
  Set-ItemProperty @IPHT
}
Invoke-Command ComputerName DC2 -ScriptBlock $SB

# 3. Authorize the DHCP server in AD and view the results
Add-DhcpServerInDC -DnsName DC2.Reskit.Org
Get-DhcpServerInDC

# 4. Configure failover and load balancing:
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

# 5. Observe the result:
'DC1', 'DC2' |
    ForEach-Object {Get-DhcpServerv4Scope -ComputerName $_}
'DC1', 'DC2' |
ForEach-Object {Get-DhcpServerv4ScopeStatistics
-ComputerName $_}
