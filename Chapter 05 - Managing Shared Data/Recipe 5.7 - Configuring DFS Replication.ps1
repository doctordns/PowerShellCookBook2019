# Recipe 5.8 - Configuring DFS Replication

# Uses VMs: DC1, DC2, FS2, FS2, SRV1, SRV2
# Run on CL1

# 1. Install DFS-Replication feature on key servers:
$SB = {
  $IHT = @{
    Name                   ='FS-DFS-Replication'
    IncludeManagementTools = $true
  }
  Add-WindowsFeature @IHT
}
$ICHT = @{
  ScriptBlock     = $SB
  ComputerName    = 'DC1', 'DC2', 'FS1', 'FS2', 'SRV1', 'SRV2'
}
Invoke-Command @ICHT |
  Format-Table -Property PSComputername,FeatureResult, Success

# 2. Turn on administrative shares:
$SB2 = {
  $SCHT = @{
    AutoShareServer      = $true 
    AutoShareWorkstation = $true
    Confirm              = $false    
  }
  Set-SmbServerConfiguration @SCHT
  "Restarting LanmanServer on $(hostname)"
  Stop-Service -Name  LanManServer -Force
  Start-Service -Name  LanManServer
}
$CN = @('DC1','DC2','FS1','FS2','SRV1','SRV2')
Invoke-Command -ScriptBlock $SB2 -ComputerName $CN

# 3. View DFS cmdlets:
Get-Module -Name DFSR -ListAvailable
Get-Command -Module DFSR | Measure-Object

# 4. Create replication groups:
$RGHT1 = @{
  GroupName   = 'FSShareRG'
  DomainName  = 'Reskit.org'
  Description = 'Replication Group for FS1, FS2 shares'
}
$RGHT2 = @{
  GroupName    = 'DCShareRG'
  DomainName   = 'Reskit.Org'
  Description  = 'Replication Group for DC1, DC2 shares'
}
New-DfsReplicationGroup @RGHT1 | Out-Null
New-DfsReplicationGroup @RGHT2 | Out-Null

# 5. Get replication groups in Reskit.Org
Get-DfsReplicationGroup -DomainName Reskit.Org |
    Format-Table

# 6. Add replication group members for FSShareRG
$MHT1 = @{
  GroupName    = 'FSShareRG'
  Description  = 'ITData on FS1/2'
  ComputerName = ('FS1','FS2')
  DomainName   = 'Reskit.Org' 
}
Add-DfsrMember @MHT1

# 7. Add DFSN folder to FSShareRG Replication Group, 
#    thus replicating the \ITData share
$RFHT1 = @{
GroupName   = 'FSShareRG'
FolderName  = 'ITData'
Domain      = 'Reskit.Org'
Description = 'ITData on FS1/2'
DfsnPath    = '\\Reskit.Org\ShareData\IT\ITData'
}
New-DfsReplicatedFolder @RFHT1

# 8. Add replication group members for DCShareRG
$MHT2 = @{
GroupName    = 'DCShareRG'
Description  = 'DC Server members'
ComputerName = ('DC1','DC2')
DomainName   = 'Reskit.Org'
}
Add-DfsrMember @MHT2 |
  Out-Null

# 9. Add DFSN folders to DCShareRG Replication Group
$RFHT2 = @{
GroupName   = 'DCShareRG'
FolderName  = 'ITManagement'
Domain      = 'Reskit.Org'
Description = 'IT Management Data'
DfsnPath    = '\\Reskit.Org\ShareData\IT\ITManagement'
}
New-DfsReplicatedFolder @RFHT2 | 
  Out-Null
 
# 10. View replicated folders:
Get-DfsReplicatedFolder |
  Format-Table -Property DomainName, GroupName, 
                         FolderName, Description

# 11. Set membership for FSShareRG replication group:
$DMHT1 = @{
  GroupName     = 'FSShareRG'
  FolderName    = 'ITData'
  ComputerName  = 'FS1'
  ContentPath   = 'C:\IT2'
  PrimaryMember = $true 
  Force         = $true
}
Set-DfsrMembership  @DMHT1 | Out-Null
$DMHT2 = @{
  GroupName     = 'FSShareRG'
  FolderName    = 'ITData'
  ComputerName  = 'FS2'
  ContentPath   = 'C:\IT2'
  PrimaryMember = $false 
  Force         = $true
}
Set-DfsrMembership @DMHT2 | Out-Null

# 12. Set membership for DCShareRG replication group:
$DMHT3 = @{
    GroupName     = 'DCShareRG'
    FolderName    = 'ITManagement'
    ComputerName  = 'DC1'
    ContentPath   = 'C:\ITM'
    PrimaryMember = $true
    Force         = $true
}
Set-DfsrMembership @DMHT3 | Out-Null
$DMHT4 = @{
    GroupName     = 'DCShareRG'
    FolderName    = 'ITManagement'
    ComputerName  = 'DC2'
    ContentPath   = 'C:\ITM'
    Force         = $true
}
Set-DfsrMembership @DMHT4 | Out-Null

# 13. View DFSR membership of the two replication groups
Get-DfsrMembership -GroupName FSShareRG -ComputerName FS1, FS2 |
    Format-Table -Property GroupName, ComputerName,
                           ComputerDomainName, ContentPath, Enabled
Get-DfsrMembership -GroupName DCShareRG -ComputerName DC1, DC2 |
    Format-Table -Property GroupName, ComputerName,
                           ComputerDomainName, ContentPath, Enabled

# 14. Add replication connections for both replication groups:
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

# 15. Get DFSR Membership and format it nicely:
Get-DfsrMember |
  Format-Table -Property Groupname, DomainName, 
                         DNSName, Description

# 16. Update the DFSR configuration:
Update-DfsrConfigurationFromAD -ComputerName DC1, DC2, FS1, FS2

# 17. Check existing foldersw
$Path  = '\\reskit.org\sharedata\it\ITManagement'
$Path1 = '\\dc1\itm'
$Path2 = '\\dc2\itm'
Get-ChiLditem -Path $Path
Get-ChiLditem -Path $Path1
Get-ChildItem -Path $Path2

# 18. Create files
1..100 | foreach { "foo" | 
  Out-File \\Reskit.Org\ShareData\IT\ITManagement\Stuff$_.txt} 
$P  = (Get-ChildItem -Path $Path  | Measure-Object).count
$P1 = (Get-ChildItem -Path $Path1 | Measure-Object).count
$P2 = (Get-ChildItem -Path $Path2 | Measure-Object).count
"$P objects in DFS root"
"$P1 objects on \\DC1"
"$P2 objects on \\DC2"















##### taken out


# 17. Run a DfsrPropogationTest on FSShareRG
$PTHT = @{
    GroupName             = 'FSShareRG'
    FolderName            = 'ITData'
    ReferenceComputerName = 'FS1'
    DomainName            = 'Reskit.Org'
}
Start-DfsrPropagationTest @PTHT

# 18. Write and view the output of DfsrPropagationReport
Write-DfsrPropagationReport @PTHT -Path 'C:\Foo' -verbose
$Report = Get-Item -Path C:\Foo\Propagation*.Html |
            Sort-Object -Property LastWriteTime -Descending |
              Select-Object -First 1
Invoke-Item $i

# 15. Create and review the output of DfsrHealthReport
$HTHT = @{
    GroupName             = 'FSShareRG'
    ReferenceComputerName = 'FS1'
    DomainName            = 'Reskit.Org'
    Path                  = 'C:\Foo'
}
Write-DfsrHealthReport @HTHT
$i = Get-Item -Path C:\Foo\Health*.Html |
    Sort-Object -property LastWriteTime |
        Select-Object -Last 1
Invoke-Item $i