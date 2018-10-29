# Recipe 2.3 - Installing and authorizing a DHCP server
#
# Run on DC1

# 1. Install the DHCP Feature
Install-WindowsFeature -Name DHCP -IncludeManagementTools

# 2. Add the DHCP server's security groups
Add-DHCPServerSecurityGroup -Verbose

# 3. Let DHCP know it's all configured
$RegHT = @{
Path  = 'HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\12'
Name  = 'ConfigurationState'
Value = 2
}
Set-ItemProperty @RegHT
d

# 4. Authorise the DHCP server in AD
Add-DhcpServerInDC -DnsName DC1.Reskit.Org

# 5. Restart DHCP
Restart-Service -Name DHCPServer –Force 
