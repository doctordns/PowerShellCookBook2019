# Recipe 2.2 - Configuring IP addressing

# Run on SRV2

# 1 Get existing IP address information for SRV2:
$IPType = 'IPv4'
$Adapter = Get-NetAdapter |
    Where-Object Status -eq 'Up'     |Select -First 1
$Interface = $Adapter |
    Get-NetIPInterface -AddressFamily $IPType
$IfIndex = $Interface.ifIndex
$IfAlias = $Interface.Interfacealias
Get-NetIPAddress -InterfaceIndex $Ifindex -AddressFamily $IPType

# 2. Set the IP address for SRV2
$IPHT = @{
    InterfaceAlias = $IfAlias
    PrefixLength   = 24
    IPAddress      = '10.10.10.51'
    DefaultGateway = '10.10.10.254'
    AddressFamily  = $IPType
}
New-NetIPAddress @IPHT | Out-Null

# 3. Set DNS Server details
$CAHT = @{
    InterfaceIndex  = $IfIndex
    ServerAddresses = '10.10.10.10'
}
Set-DnsClientServerAddress  @CAHT

# 4. Test new configuration
Get-NetIPAddress -InterfaceIndex $IfIndex -AddressFamily IPv4
Test-NetConnection -ComputerName DC1.Reskit.Org
Resolve-DnsName -Name SRV2.Reskit.Org -Server DC1.Reskit.Org |
  Where-Object Type -eq 'A'


# Undo
$IPHT = @{
    InterfaceAlias = $IfAlias
    PrefixLength   = 24
    IPAddress      = '10.10.10.51'
    DefaultGateway = '10.10.10.254'
    AddressFamily  = $IPType
}
New-NetIPAddress @IPHT    