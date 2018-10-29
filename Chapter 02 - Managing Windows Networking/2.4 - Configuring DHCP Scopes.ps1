# Recipe 2.4 - Configuring DHCP Scopes

# Run on DC1

# 1. Create a Scope
$SHT = @{
  Name         = 'Reskit'
  StartRange   = '10.10.10.150'
  EndRange     = '10.10.10.199'
  SubnetMask   = '255.255.255.0'
  ComputerName = 'DC1.Reskit.Org'
}
Add-DhcpServerV4Scope @SHT

# 2. Get Scopes from the server
Get-DhcpServerv4Scope -ComputerName DC1.Reskit.Org

# 3. Set Option Values
$OHT = @{
  ComputerName = 'DC1.Reskit.Org'
  DnsDomain = 'Reskit.Org'
  DnsServer = '10.10.10.10'
}
Set-DhcpServerV4OptionValue @OHT 

# 4. Get options set
Get-DhcpServerv4OptionValue -ComputerName DC1.Reskit.Org