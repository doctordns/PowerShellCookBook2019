# Recipe 5.6 - Configuring a DFS Namespace
#
# Run on CL1


# 1. Add DFSN Rsat Tools to CL1
Get-WindowsCapability -Online -Name *FileServices.Tools* |
  Add-WindowsCapability -Online |
    Out-Null

# 2. Install DFS Namespace, DFS Replication, and the related management tools:
$IHT = @{
  Name                   = 'FS-DFS-Namespace'
  IncludeManagementTools = $True
}
Install-WindowsFeature @IHT -ComputerName SRV1
Install-WindowsFeature @IHT -ComputerName SRV2

# 3. View the DFSN module and the DFSN cmdlets:
Get-Module -Name DFSN -ListAvailable

# 4. Create folders and shares for DFS Root:
$SB = {
  New-Item -Path C:\ShareData -ItemType Directory -Force |
    Out-Null
  New-SmbShare -Name ShareData -Path C:\ShareData -FullAccess Everyone
}
Invoke-Command -ComputerName SRV1, SRV2 -ScriptBlock $SB |
  Out-Null

# 5. Create DFS Namespace Root pointing to ShareData:
$NSHT = @{
    Path        = '\\Reskit.Org\ShareData'
    TargetPath  = '\\SRV1\ShareData'
    Type        = 'DomainV2'
    Description = 'Reskit Shared Data DFS Root'
}    
New-DfsnRoot @NSHT

# 6. Add a second target and view results:
$NSHT2 = @{
    Path       = '\\Reskit.Org\ShareData'
    TargetPath = '\\Srv2\ShareData'
}
New-DfsnRootTarget @NSHT2 | Out-Null
Get-DfsnRootTarget -Path \\Reskit.Org\ShareData

# 7. Create IT Data shares and populate:
# FS1 folders/shares
$SB = {
    New-Item -Path C:\IT2 -ItemType Directory | Out-Null
    New-SmbShare -Name 'ITData' -Path C:\IT2 -FullAccess Everyone
    # Add content to files in root
    'Root' | Out-File -FilePath C:\IT2\Root.Txt
}
Invoke-Command -ScriptBlock $SB -Computer FS1 | Out-Null
# FS2 folders/shares
$SB = {
    New-Item -Path C:\IT2 -ItemType Directory | Out-Null
    New-SmbShare -Name 'ITData' -Path C:\IT2 -FullAccess Everyone
    'Root' | Out-File -FilePath c:\IT2\Root.Txt
}
Invoke-Command -ScriptBlock $SB -Computer FS2 | Out-Null
# DC1 folders/shares
$SB = {
    #New-Item -Path C:\ITM -ItemType Directory | Out-Null
    New-SmbShare -Name 'ITM' -Path C:\ITM -FullAccess Everyone
    'Root' | Out-File -Filepath C:\ITM\Root.Txt
}
Invoke-Command -ScriptBlock $SB -Computer DC1 | Out-Null
# DC2 folders/shares
$SB = {
    New-Item C:\ITM -ItemType Directory | Out-Null
    New-SmbShare -Name 'ITM' -Path C:\ITM -FullAccess Everyone
    'Root' | Out-File -FilePath c:\ITM\Root.Txt
}
Invoke-Command -ScriptBlock $SB -Computer DC2

# 8. Create DFS Namespace and set DFS targets
$NSHT1 = @{
  Path                 = '\\Reskit\ShareData\IT\ITData'
  TargetPath           = '\\FS1\ITData'
  EnableTargetFailback = $true
  Description          = 'IT Data'
}
New-DfsnFolder @NSHT1 | Out-Null

$NSHT2 = @{
    Path       = '\\Reskit\ShareData\IT\ITData'
    TargetPath = '\\FS2\ITData'
}
New-DfsnFolderTarget @NSHT2 | Out-Null

$NSHT3 = @{
   Path                 = '\\Reskit\ShareData\IT\ITManagement'
   TargetPath           = '\\DC1\ITM'
   EnableTargetFailback = $true
   Description          = 'IT Management Data'
}
New-DfsnFolder @NSHT3 | Out-Null
   
$NSHT4 = @{
    Path       = '\\Reskit\ShareData\IT\ITManagement' 
    TargetPath = '\\DC2\ITM'
} 
New-DfsnFolderTarget @NSHT4 | Out-Null

# 9. View the hierarchy
Get-ChildItem -Path \\Reskit.Org\ShareData\IT -Recurse

