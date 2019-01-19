# Recipe 10-8 - Managing and monitoring network load balancing
# 1. Install NLB locally on NLB1, them remotely on NLB2:
$IHT = @{
    Name  = 'MLB'
    IncludeManagementTools = $True
    IncludeAllSubFeature   = $True
}
Install-WindowsFeature @IHT

Install-WindowsFeature @IHT -ComputerName NLB2

# 2. Confirm NLB and Web-Server features are loaded on both systems:
Invoke-Command -ScriptBlock {Get-WindowsFeature Web-Server, NLB} `
               -ComputerName NLB1, NLB2 |
Format-table -Property DisplayName,PSComputername,InstallstateManaging Internet Information Server

# 3. Create the NLB cluster, initially on NLB1:
New-NlbCluster -InterfaceName Ethernet `
    -ClusterName 'ReskitNLB' `
    -ClusterPrimaryIP 10.10.10.55 `
    -SubnetMask 255.255.255.0 `
    -OperationMode Multicast
# 4. Add NLB2 to the ReskitNLB cluster:
Add-NlbClusterNode -NewNodeName NLB2 `
    -NewNodeInterface 'Ethernet' `
    -InterfaceName 'Ethernet'

# 5. Create a network firewall rule:
Invoke-Command -ComputerName NLB2 {
Set-NetFirewallRule -DisplayGroup 'File and
Printer Sharing' `
    -Enabled True
}

# 6. Create a default document—differently on each machine:
'NLB Cluster: Hosted on NLB1' |
    Out-File -FilePath C:\inetpub\wwwroot\index.html
'NLB Cluster: Greetings from NLB2' |
    Out-File -FilePath \\nlb2\c$\inetpub\wwwroot\index.html

    # 7. Add a DNS A record for the cluster:
$sb = {
Add-DnsServerResourceRecordA -Name ReskitNLB `
-IPv4Address 10.10.10.55 `
-zonename Reskit.Org}
Invoke-Command -ComputerName DC1 -ScriptBlock $sb

# 8. View the NLB site (do this on DC1):
Start-Process 'http://ReskitNLB.reskit.org'

# 9. Stop one node (the one that responded in step 8!):
Stop-NlbClusterNode -HostName NLB1Managing Internet Information Server

# 10. Then view the site again:
$IE = New-Object -ComObject InterNetExplorer.Application
$URL = 'http://ReskitNLB.reskit.org'
$IE.Navigate2($URL)
$IE.Visible = $true