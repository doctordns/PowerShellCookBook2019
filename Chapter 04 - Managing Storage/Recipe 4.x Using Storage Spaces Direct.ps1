# Recipe 4.5 - Using Storage Spaces Direct (STSD)
# 
# Uses CL1,SSRV1, SSRV2, HV1
# Runs on SSRV1 

# Setup SSDirect cluster on SSRV1, SSRV2, SSRV3

# 1. Create credential for Reskit
$Username   = "Reskit\ThomasL"
$Password   = 'Pa$$w0rd'
$CHT = @{
String      = $Password
AsPlainText = $True
Force       = $True
}
$PasswordSS = ConvertTo-SecureString  @CHT
$NOHT = @{
  Typename     = 'System.Management.Automation.PSCredential'
  Argumentlist =  ($Username,$PasswordSS)
}
$CredRK = New-Object @NOHT

# 2. Create sessions on each of the storge servers
$S = New-PSSession -ComputerName SSRV1, SSRV2, SSRV3 -Credential $CredRK

# 3. Create Feature addition script block
$SB = {
  ## Ensure C:\Foo exists!
  New-Item -Path C:\Foo  -ItemType Directory -ErrorAction SilentlyContinue
  ## Add features
  Write-Verbose "Adding features to $(hostname)"
  ## Set features to add
  $Features = @('Hyper-V', 'Failover-Clustering', 'FS-FileServer',
                'RSAT-Clustering-PowerShell','Hyper-V-PowerShell',
                'RSAT-Clustering-Mgmt')
  ## Create a hash table for installation parameters
  $SBHT = @{
    Name                   = $Features
    IncludeAllSubFeature   = $True
    IncludeManagementTools = $True
  }
  ## Install these features on this machine
  Install-WindowsFeature @SBHT
  ## remove defender
  Write-Verbose 'Removing Windows Defender'
  Remove-WindowsFeature -Name 'Windows-Defender'
  ## Install modules
  Write-Verbose 'Adding PSWindowsUpdate, NTFSSecurity modules'
  Install-Module PSWindowsUpdate -Force
  Install-Module NTFSSecurity    -Force
} # End Config Script block

# 4. Run script block on all three systems
Invoke-Command -Session $S -ScriptBlock $SB  -Verbose |
    Out-Null 

# 5. With updates installed, reboot to complete installation of patches
Restart-Computer -ComputerName SSRV3, SSRV2  -Force
Restart-Computer -ComputerName SSRV1 -Force 

###  After the reboot...

# 6. Check the status of Windows update on each server
$GUHT = @{
 ComputerName = 'SSRV3', 'SSRV2', 'SSRV1'
 AcceptAll    = $True
 Download     = $True
 Install      = $True
}
Get-WindowsUpdate @GUHT

# 7. If step 5 yeilded reboots are needed...
Restart-Computer -ComputerName SSRV3, SSRV2  -Force -AsJob
Restart-Computer -ComputerName SSRV1 -Force 


##
## After reboot - run on SSRV1
##

### Do not move on till all updates installed on all three nodes

# 8. Test the cluster
$Start = Get-Date
$Nodes = @('SSRV1.Reskit.Org', 
           'SSRV2.Reskit.Org',
           'SSRV3.Reskit.Org')
$Roles = @('Storage Spaces Direct', 
           'Inventory', 
           'Network', 
           'System Configuration')
$INF = Test-Cluster -Node $Nodes -Include $Roles 
$Finish = Get-Date
$Elapsed = $Finish - $Start
"Test took: [$($Elapsed.TotalSeconds)] seconds]"

# 9. view the output report
Invoke-Item -Path $INF

# 10. Build a new fail-over cluster
$NCHT = @{
  Name          = 'SSRV'
  Node          = $Nodes
  NoStorage     = $True
  StaticAddress = '10.10.10.110/24'
}
New-Cluster @NCHT -Verbose

# 11 Test the cluster name
Test-NetConnection -ComputerName SSRV.Reskit.Org

# 12. Enable Storage Spaces Direct
$EHT = @{
 PoolFriendlyName = 'ReskitS2D'
 Confirm          = $False
}

Get-Cluster -Domain reskit.org |
  Enable-ClusterStorageSpacesDirect -PoolFriendlyName 'ReskitS2D'





# 10. Create Scale Out File Server 
Add-ClusterScaleOutFileServerRole -Name SOFS -Cluster SSRV


# 11. Initialize disks in the cluster
$Computers = ('SSRV1','SSRV2','SSRV3')
$SB   =  {Get-Disk | 
           Where PartitionStyle -eq Raw |
             Initialize-Disk -PartitionStyle GPT 
          }
$INITHT = @{
  ComputerName = $Computers
  ScriptBlock  = $SB
}

# 12. clean any existing drives
$SB = {
  $EAHT = @{ErrorAction='SilentlyContinue'}
  $CHT  = @{Confirm = $False}
  Update-StorageProviderCache
  Get-StoragePool | Where-Object IsPrimordial -EQ $false | 
    Set-StoragePool -IsReadOnly:$False @EAHT
  Get-StoragePool | Where IsPrimordial -EQ $false |
    Get-VirtualDisk | 
      Remove-VirtualDisk @CHT @EAHT
   Get-StoragePool | 
     Where-Object IsPrimordial -EQ $false | 
       Remove-StoragePool @CHT @EAHT
   Get-PhysicalDisk | 
     Reset-PhysicalDisk @EAHT
   Get-Disk | 
     Where-Object Number -NE $Null | 
       Where-Object IsBoot -NE $True | 
         Where-Object IsSystem -NE $True | 
           Where PartitionStyle -NE RAW | 
             Foreach {
               $_ | Set-Disk -IsOffline $false
               $_ | Set-Disk -IsReadonly $false
               $_ | Clear-Disk -RemoveData -RemoveOEM @CHT
               $_ | Set-Disk -IsReadonly $true
               $_ | Set-Disk -IsOffline $true
             }       
  Get-Disk | 
    Where-Object Number -Ne $Null | 
      Where-Object IsBoot -Ne $True |
        Where-Object IsSystem -Ne $True | 
          Where-Object PartitionStyle -Eq RAW | 
            Group -NoElement -Property FriendlyName
} 

# 14. Run the script boock on all three servers
Invoke-Command -ComputerName $Computers -ScriptBlock $SB |
  Sort-Object  -Property PsComputerName, Count


###  this may give errors but the action has worked. Repeat the step and all is klar.



 Creete a storage Pool 


# 11. Create two volumes in the cluster
Get-StoragePool | 
  New-Volume -FriendlyName 'IT' -FileSystem CSVFS_ReFS -Size 100mb

New-Volume -FriendlyName 'HR' -FileSystem CSVFS_ReFS -StoragePoolFriendlyName 'ReskitS2D' -size 100mb

# 12. Share out those folders
$IT1 = 'C:\ClusterStorage\IT\ITFolder'
New-Item -Path $IT1 -ItemType Directory -ErrorAction SilentlyContinue| Out-Null
New-SmbShare -Name IT  -Path $IT1 -Description 'HA Share for IT' -FullAccess Administrators

$HR1 = 'C:\ClusterStorage\HR\HRFolder'
New-Item -Path $HR1 -ItemType Directory | Out-Null
New-SmbShare -Name HR -Path $HR1 -Description 'HA Share for HR' -ContinuouslyAvailable:$True -FullAccess "Administrators"

$ITL1 = 'C:\foo\'
New-SMBShare -Name ITSSRV1 -Path $ITL1

# 13. View results
Get-SmbShare

# 14. Create a test file in the two folders
'IT files' | Out-File -FilePath C:\ClusterStorage\IT\ITFolder\Files.txt
'HR files' | Out-File -FilePath C:\ClusterStorage\HR\HRFolder\Files.txt




#  utility stuff

# trigger a Windows defender Update

$SB = {
Set-Location "$($Env:Programfiles)\Windows Defender"
.\MpCmdRun.exe -removedefinitions -dynamicsignatures
.\MpCmdRun.exe -SignatureUpdate
}

Invoke-Command -ScriptBlock $SB -ComputerName SSRV1.Reskit.Org
Invoke-Command -ScriptBlock $SB -ComputerName SSRV2.Reskit.Org
Invoke-Command -ScriptBlock $SB -ComputerName SSRV2.Reskit.Org

# update status

Get-WindowsUpdate -ComputerName ssrv1, ssrv2, ssrv3 -verbose

#  CLEAN UP
Disable-ClusterStorageSpacesDirect 
Get-ClusterResource | where-Object Name -Match 'sofs' |
  Remove-ClusterResource -Force
Get-ClusterResource | Remove-ClusterResource -force
Get-Cluster | Remove-Cluster -CleanupAD -verbose -Force
invoke-Command -computer -script {
Get-ADComputer -Filter 'samaccountname -like "*sof*"' | 
    Remove-ADComputer -Confirm:$False
}
