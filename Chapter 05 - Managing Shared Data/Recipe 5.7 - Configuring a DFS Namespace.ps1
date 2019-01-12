# Recipe 9.7 - Configuring a DFS Namespace

# 1. Install DFS Namespace, DFS Replication, and the related management tools:
$IHT = @{
    Name                   = 'FS-DFS-Namespace'
    IncludeManagementTools = $True
}
Install-WindowsFeature @IHT -ComputerName Srv1
Install-WindowsFeature @IHT -ComputerName Srv2

# 2. View the DFSN module and the DFSN cmdlets:
Get-Module -Name DFSN -ListAvailable
Get-Command -Module DFSN | Measure-Object

# 3. Create folders and shares for DFS Root:
$Sb = {
  New-Item -Path E:\ShareData -ItemType Directory-Force | Out-Null
  New-SmbShare -Name ShareData -Path E:\ShareData -FullAccess Everyone
}
Invoke-Command -ComputerName Srv1, Srv2 -ScriptBlock $Sb

# 4. Create DFS Namespace Root pointing to ShareData:
$NSHT = @{
    Path        = '\\Reskit.Org\ShareData'
    TargetPath  = '\\Srv1\ShareData'
    Type        = 'DomainV2'
    Description = 'Reskit Shared Data DFS Root'
}    
New-DfsnRoot @NSHT

# 5. Add a second target and view results:
$NSHT2 = @{
    Path       = '\\Reskit.Org\ShareData'
    TargetPath = '\\Srv2\ShareData'
}
New-DfsnRootTarget @NSHT2 | Out-Null
Get-DfsnRootTarget -Path \\Reskit.Org\ShareData

# 6. Create additional shares and populate:
# FS1 folders/shares
$Sb = {
    New-Item -Path C:\IT2 -ItemType Directory | Out-Null
    New-SmbShare -Name 'ITData' -Path C:\IT2 -FullAccess Everyone
    New-Item -Path C:\Sales -ItemType Directory |  Out-Null
    New-SmbShare -Name 'Sales' -Path C:\Sales -FullAccess Everyone
    New-Item -Path C:\OldSales -ItemType Directory | Out-Null
    New-SmbShare -Name 'SalesHistorical' -Path 'C:\OldSales'
    # Add content to files in root
    'Root' | Out-File -FilePath C:\IT2\root.txt
    'Root' | Out-File -FilePath C:\Sales\root.txt
    'Root' | Out-File -FilePath C:\OldSales\root.txt
}
Invoke-Command -ScriptBlock $Sb -Computer FS1
# FS2 folders/shares
$Sb = {
    New-Item -Path C:\IT2 -ItemType Directory | Out-Null
    New-SmbShare -Name 'ITData' -Path C:\IT2 -FullAccess Everyone
    New-Item -Path C:\Sales -ItemType Directory | Out-Null
    New-SmbShare -Name 'Sales' -Path C:\Sales -FullAccess Everyone
    New-Item -Path C:\OldSales -ItemType Directory | Out-Null
    New-SmbShare -Name 'SalesHistorical' -Path C:\IT2
    'Root' | Out-File -FilePath c:\it2\root.txt
    'Root' | Out-File -FilePath c:\Sales\root.txt
    'Root' | Out-File -FilePath c:\oldsales\root.txt
}
Invoke-Command -ScriptBlock $sb -Computer FS2
# DC1 folders/shares
$SB = {
    New-Item -Path C:\ITM -ItemType Directory | Out-Null
    New-SmbShare -Name 'ITM' -Path C:\ITM `-FullAccess Everyone
    'Root' | Out-File -Filepath c:\itm\root.txt
}
Invoke-Command -ScriptBlock $sb -Computer DC1
# DC2 folders/shares
$Sb = {
    New-Item C:\ITM -ItemType Directory | Out-Null
    New-SmbShare -Name 'ITM' -Path C:\ITM -FullAccess Everyone
    'Root' | Out-File -FilePath c:\itm\root.txt
}
Invoke-Command -ScriptBlock $Sb -Computer DC2

# 7. Create DFS Namespace and set DFS targets
$NSHT1 = @{
  Path                 = '\\Reskit\ShareData\IT\ITData'
  TargetPath           = '\\fs1\ITData'
  EnableTargetFailback = $true
  Description          = 'IT Data'
}
New-DfsnFolder @NSHT1

$NSHT2 = @{
    Path       = '\\Reskit\ShareData\IT\ITData'
    TargetPath = '\\fs2\ITData'
}
New-DfsnFolderTarget @NSHT2

$NSHT3 = @{
   Path                 = '\\Reskit\ShareData\IT\ITManagement'
   TargetPath           = '\\DC1\itm'
   EnableTargetFailback = $true
   Description          = 'IT Management Data'
}
New-DfsnFolder @NSHT3
   
$NSHT4 = @{
    Path       = '\\Reskit\ShareData\IT\ITManagement' 
    TargetPath = '\\DC2\itm'
}
New-DfsnFolderTarget @NSHT4

$NSHT5 = @{
   Path                 = '\\Reskit\ShareData\Sales\SalesData'
   TargetPath           = '\\fs1\sales'
   EnableTargetFailback = $true
   Description          = 'SalesData'  
}
New-DfsnFolder @NSHT5

$NSHT6 = @{
    Path       = '\\Reskit\ShareData\Sales\SalesData'
    TargetPath = '\\fs2\sales'
}
New-DfsnFolderTarget @NSHT6
    
$NSHT7 = @{
    Path                 = '\\Reskit\ShareData\Sales\SalesHistoric'
    TargetPath           = '\\fs1\SalesHistorical'
    EnableTargetFailback = $true
    Description          = 'Sales Group Historical Data'
}
New-DfsnFolder @NSHT7

$NSHT8 = @{
    Path       = '\\Reskit\ShareData\Sales\SalesHistoric'
    TargetPath = '\\fs2\SalesHistorical'
}
New-DfsnFolderTarget @NSHT8