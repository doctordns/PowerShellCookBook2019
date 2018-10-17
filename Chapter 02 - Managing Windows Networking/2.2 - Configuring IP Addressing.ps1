# Recipe 2.2 - Configuring IP addressing

# Run on SRV1

# 1 Get existing IP address information
$IPType = 'IPv4'
$Adapter = Get-NetAdapter |
    Where-Object Status -eq 'Up'
ds = $Adapter |
    Get-NetIPInterface -AddressFamily $IPType
$IfIndex = $Interface.ifIndex
$IfAlias = $Interface.Interfacealias
Get-NetIPAddress -InterfaceIndex $Ifindex -AddressFamily $IPType

# 2. Set the IP address for DC2
$IPHT = @{
    InterfaceAlias = $IfAlias
    PrefixLength   = 24
    IPAddress      = '10.10.10.53'
    DefaultGateway = '10.10.10.254'
    AddressFamily  = $IPType
}
New-NetIPAddress @IPHT

# 3. Set DNS Server details
$CAHT = @{
    InterfaceIndex  = 3
    ServerAddresses = '10.10.10.10'
}

Set-DnsClientServerAddress  @CAHT

# 4. Test new configuration
Get-NetIPAddress -InterfaceIndex $IfIndex
Test-NetConnection -ComputerName DC1
Resolve-DnsName -Name SRV1.Reskit.Org -Server DC1.Reskit.Org |
  Where-Object Type -eq 'A'




# Undo
$IPHT = @{
    InterfaceAlias = $IfAlias
    PrefixLength   = 24
    IPAddress      = '10.10.10.50'
    DefaultGateway = '10.10.10.254'
    AddressFamily  = $IPType
}
New-NetIPAddress @IPHT    