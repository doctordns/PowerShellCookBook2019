# Recipe 2.1 - New ways to do old things
#
# Run on SRV1

# 1. Ipconfig vs new cmdlets

# Two variations on the old way
ipconfig.exe
ipconfig.exe /all

# The new Way
Get-NetIPConfiguration

# Related cmdlets - but not for the book...
Get-NetIPInterface
Get-NetAdapter

# 2. Pinging a computer

# The old way
Ping DC1.Reskit.Org -4

# The New way
Test-NetConnection DC1.Reskit.Org

# And some new things Ping does not do!
Test-NetConnection DC1.Reskit.Org -CommonTCPPort SMB
$ILHT = @{InformationLevel = 'Detailed'}
Test-NetConnection DC1.Reskit.Org -port 389 @ILHT

# 3. Using Sharing folder from DC1

# The old way to use a shared folder
net use X:  \\DC1.Reskit.Org\c$

# The new way using  an SMB  cmdlet
New-SMBMapping -LocalPath 'Y:' -RemotePath \\DC1.Reskit.Org\c$

# See what is shared the old way:
net use

# And the new way
Get-SMBMapping

# 4. - Sharing a folder from SRV1

# Now share the old way
net share Windows=C:\windows
# and the new way
New-SmbShare -Path C:\Windows -Name Windows2
# And see what has been shared the old way
net share
# and the new way
Get-SmbShare

# 5. Getting DNS Cache
# The Old way to see the DNS Client Cache
ipconfig /displaydns
# Vs
Get-DnsClientCache

# 6. Clear the dnsclient client cache the old way
Ipconfig /flushdns
# Vs the new way
Clear-DnsClientCache

# 7. DNS Lookups
Nslookup DC1.Reskit.Org
Resolve-DnsName -Name DC1.Reskit.Org  -Type ALL
#


<# undo
Get-SmbMapping x: | Remove-SmbMapping -force
Get-SmbMapping y: | Remove-SmbMapping -confirm:$false
Get-SMBSHARE Windows* | Remove-SMBShare
#>
