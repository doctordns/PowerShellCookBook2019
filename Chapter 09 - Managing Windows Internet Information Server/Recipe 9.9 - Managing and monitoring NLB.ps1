# Recipe 9.9 - Managing and monitoring network load balancing
#
# Uses NLB1, 2 - run on NLB1
# end of recipe uses DC1


# 1. Install web-server (and .NET 3.5) feature NLB1, NLB2:
$IHT1 = @{
   Name                   = 'Web-Server'
   IncludeManagementTools = $True
   IncludeAllSubFeature   = $True
   Source                 = 'D:\sources\sxs'
}
Install-WindowsFeature @IHT1 -ComputerName NLB1
Install-WindowsFeature @IHT1 -ComputerName NLB2


# 2. And add NLB to NLB1, NLB2
$IHT2 = @{
   Name                   = 'NLB'
   IncludeManagementTools = $True
   IncludeAllSubFeature   = $True
}
Install-WindowsFeature @IHT -ComputerName NLB1 | Out-Null
Install-WindowsFeature @IHT -ComputerName NLB2 | Out-Null
 

# 3. Confirm NLB and Web-Server feats are loaded on both systems:
$SB = {
  Get-WindowsFeature Web-Server, NLB
}
Invoke-Command -ScriptBlock $SB -ComputerName NLB1, NLB2 |
  Format-table -Property DisplayName,PSComputername,Installstate

# 4. Create the NLB cluster, initially on NLB1:
$NLBHT1 = @{
  InterFaceName    = 'Ethernet'
  ClusterName      = 'ReskitNLB'
  ClusterPrimaryIP = '10.10.10.55'
  SubnetMask       = '255.255.255.0'
  OperationMode    = 'Multicast'
}
New-NlbCluster @NLBHT1

# 5. Add NLB2 to the ReskitNLB cluster:
$NLBHT2 = @{
  NewNodeName      = 'NLB2.Reskit.Org'
  NewNodeInterface = 'Ethernet'
  InterfaceName    = 'Ethernet'
}
Add-NlbClusterNode @NLBHT2

# 6. Create a network firewall rule:
$SB = {
  $NFTHT =@{
    DisplayGroup  = 'File and Printer Sharing'
    Enabled       = 'True'
  }
  Set-NetFirewallRule @NFTHT
}
Invoke-Command -ScriptBlock $SB -ComputerName NLB1
Invoke-Command -ScriptBlock $SB -ComputerName NLB2


# 7. Create a default document—differently on each machine:
'NLB Cluster: Hosted on NLB1' |
    Out-File -FilePath C:\inetpub\wwwroot\index.html
'NLB Cluster: Greetings from NLB2' |
    Out-File -FilePath \\nlb2\c$\inetpub\wwwroot\index.html

# 8. check VIP
Get-NlbClusterVip 

# 9. Add a DNS A record for the cluster:
$SB = {
  $NAHT = @{
    Name        = 'ReskitNLB'
    IPv4Address = '10.10.10.55' 
    ZoneName    = 'Reskit.Org'
  }
  Add-DnsServerResourceRecordA @NAHT
}
Invoke-Command -ComputerName DC1 -ScriptBlock $SB

#    DO REMAINDER OF THIS RECIPE FROM DC1

# 10. view the cluster node details From DC1
Get-NlbClusterNode -HostName NLB1.Reskit.Org

# 11. View the NLB site from DC1
Start-Process 'HTTP://ReskitNLB.Reskit.Org'

# 12. Stop one node (the one that responded in step 10):
Stop-NlbClusterNode -HostName NLB1 
Clear-DnsClientCache

# 13. view the cluster node details from NLB1
Get-NlbClusterNode -HostName NLB1

# 14. Then view the site again (from DC1):
Start-Process 'HTTP://ReskitNLB.Reskit.Org'
