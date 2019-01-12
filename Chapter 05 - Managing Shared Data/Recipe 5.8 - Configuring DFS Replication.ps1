# Recipe 9.8 - Configuring DFS Replication

# Uses VMs: DC1, DC2, FS2, FS2,SRV1, SRV2

# 1. Install DFS-Replication feature on key servers:
$Sb = {
  Add-WindowsFeature -Name FS-DFS-Replication -IncludeManagementTools
}
Invoke-Command -ScriptBlock $Sb ComputerName DC1, DC2, FS1,FS2, SRV1, SRV2 |
    Format-Table -Property PSComputername,FeatureResult, Success

# 2. Turn on administrative shares:
$Sb = {
  $SCHT = @{
    AutoShareServer      = $true 
    AutoShareWorkstation = $true
    Confirm              = $false    
  }
  Set-SmbServerConfiguration @sSCHT
}
$CN = @('DC1', 'DC2', 'FS2', 'FS2','SRV1', 'SRV2')
Invoke-Command -ScriptBlock $Sb -ComputerName $CN

# 3. View DFS cmdlets:
Get-Module -Name DFSR -ListAvailable
Get-Command -Module DFSR | Measure-Object

# 4. Create and display replication groups:
$RGHT1 = {
  GroupName   = 'FSShareRG'
  DomainName  = 'Reskit.Org'
  Description = 'Replication Group for FS1, FS2 shares'
}
New-DfsReplicationGroup ` @RGHT1 | Out-Null
$RGHT2 = {
  GroupName    = 'DCShareRG'
  DomainName   = 'Reskit.Org'
  Description  = 'Replication Group for DC1, DC2 shares'
}
New-DfsReplicationGroup `@$RGHT2 | Out-Null
# see the RGs
Get-DfsReplicationGroup | Format-Table

# 5. Add replication group members for FSShareRG
$MHT1 = @{
GroupName    = FSShareRG
Description  = 'File Server members'
ComputerName = ('FS1','FS2')
DomainName   = Reskit.Org 
}
Add-DfsrMember @MHT1| Out-Null
$RFHT1 = @{
GroupName   = 'FSShareRG'
FolderName  = 'ITData'
Domain      = 'Reskit.Org'
Description = 'ITData'
DfsnPath    = '\\Reskit.Prg\ShareData\IT\ITData'
}
New-DfsReplicatedFolder @RFHT1| Out-Null
$RFHT2 = @{
GroupName   = 'FSShareRG'
FolderName  = 'Sales'
Domain      = 'Reskit.Org'
Description = 'Sales'
DfsnPath    =  \\Reskit.Org\ShareData\Sales\SalesData       
}
New-DfsReplicatedFolder @RFHT2 -| Out-Null
$RFHT3 = @{
GroupName   = 'FSShareRG'
FolderName  = 'SalesHistorical'
Domain      = 'Reskit.Org'
Description = 'Sales history'
DfsnPath    = '\\Reskit.Org\ShareData\Sales\SalesHistoric'
}
New-DfsReplicatedFolder @RFHT3| Out-Null

# 6. Add replication group members for DCShareRG
$MHT2  @{
GroupName    = DCShareRG
Description  = 'DC Server members'
ComputerName = ('DC1','DC2')
DomainName   = 'Reskit.Org'
}
Add-DfsrMember @MHT2|
Out-Null
$RFHT4 = @{
GroupName   = DCShareRG
FolderName  = 'ITManagement'
Domain      = 'Reskit.Org'
Description = 'IT Management Data'
DfsnPath    = '\\Reskit.Org\sharedata\IT\ITManagement'
}
New-DfsReplicatedFolder @RFHT4

# 7. View replicated folders:
Get-DfsReplicatedFolder |
    Format-Table -Property GroupName, FolderName, DomainName,DfsnPath

# 8. Set membership for FSShareRG replication group:
$DMHT1 = @{
  GroupName     = FSShareRG
  FolderName    = 'ITData'
  ComputerName  = 'FS1'
  ContentPath   = 'C:\IT2'
  PrimaryMember = $true 
  Force         = $true
}
Set-DfsrMembership  @DMHT1 |Out-Null
$DMHT2 = @{
  GroupName     = FSShareRG
  FolderName    = 'ITData'
  ComputerName  = 'FS2'
  ContentPath   = 'C:\IT2'
  PrimaryMember = $true 
  Force         = $true
}
Set-DfsrMembership @DMHT2 | Out-Null

$DMHT2 = @{
    GroupName     = 'FSShareRG'
    FolderName    = 'Sales'
    ComputerName  = 'FS1'
    ContentPath   = 'C:\Sales'
    PrimaryMember = $true
    Force         = $true
}
Set-DfsrMembership @DMHT2 | Out-Null

$DMHT3 = @{
    GroupName     = 'FSShareRG'
    FolderName    = 'Sales'
    ComputerName  = 'FS2'
    ContentPath   = 'C:\Sales'
    Force         = $true
}
Set-DfsrMembership @DMHT3 | Out-Null

$DMHT4 = @{
    GroupName     = 'FSShareRG'
    FolderName    = 'SalesHistorical'
    ComputerName  = 'FS1'
    ContentPath   = 'C:\OldSales'
    PrimaryMember = $true
    Force         = $true
}
Set-DfsrMembership @DMHT4 | Out-Null

$DMHT5 = @{
    GroupName    = 'FSShareRG'
    FolderName   = 'SalesHistorical'
    ComputerName = 'FS2'
    ContentPath  = 'C:\OldSales'
    Force        = $true
}
Set-DfsrMembership @DMHT5 | Out-Null

# 9. Set membership for DCShareRG replication group:
$DMHT6 = @{
    GroupName     = 'DCShareRG'
    FolderName    = 'ITManagement'
    ComputerName  = 'DC1'
    ContentPath   = 'C:\ITM'
    PrimaryMember = $true
    Force         = $true
}
Set-DfsrMembership @DMHT6 |Out-Null

$DMHT7 = @{
    GroupName     = 'DCShareRG'
    FolderName    = 'ITManagement'
    ComputerName  = 'DC2'
    ContentPath   = 'C:\ITM'
    Force         = $true
}
Set-DfsrMembership @DMHT7 | Out-Null

# 10. View DFSR membership of the two replication groups:
Get-DfsrMembership -GroupName FSShareRG -ComputerName FS1, FS2 |
    Format-Table -Property GroupName, ComputerName,
                           ComputerDomainName, ContentPath, Enabled
Get-DfsrMembership -GroupName DCShareRG -ComputerName DC1, DC2 |
    Format-Table -Property GroupName, ComputerName,
                           ComputerDomainName, ContentPath, Enabled

####

# 11. Add replication connections for both replication groups:
$RCHT1 = @{
  GroupName               = 'FSShareRG'
  SourceComputerName      = 'FS1'
  DestinationComputerName = 'FS2'
  Description             = 'FS1-FS2 connection'
  DomainName              = 'Reskit.Org'
}
Add-DfsrConnection @RCHT1| Out-Null

$RCHT2 = @{
    GroupName                   = 'DCShareRG'
    SourceComputerName          = 'DC1'
        DestinationComputerName = 'DC2'
        Description             = 'DC1-DC2 connection'
        DomainName              = 'Reskit.Org'
}
Add-DfsrConnection @RCHT2 | Out-Null
Get-DfsrMember |
    Format-Table -Property Groupname, DomainName, DNSName, Description

# 12. Update the DFSR configuration:
Update-DfsrConfigurationFromAD -ComputerName DC1, DC2, FS1, FS2

# 13. Run a DfsrPropogationTest on FSShareRG:
$PTHT = @{
    GroupName             = 'FSShareRG'
    FolderName            = 'ITData'
    ReferenceComputerName = 'FS1'
    DomainName            = 'Reskit.Org'
}
Start-DfsrPropagationTest @PTHT

# 14. Create and review the output of DfsrPropagationReport:
Write-DfsrPropagationReport @PTHT -Path C:\Foo\
$i = Get-Item -Path C:\Foo\Propagation*.Html |
    Sort-Object -Property LastWriteTime -Descending|
        Select-Object -First 1
Invoke-Item $i

# 15. Create and review the output of DfsrHealthReport
$HTHT = @{
    GroupName             = ' FSShareRG'
    ReferenceComputerName = 'FS1'
    DomainName            = 'Reskit.Org'
    Path                  = 'C:\Foo'
}
Write-DfsrHealthReport @HTHT
$i = Get-Item -Path C:\Foo\Health*.Html |
    Sort-Object -property LastWriteTime |
        Select-Object -Last 1
Invoke-Item $i