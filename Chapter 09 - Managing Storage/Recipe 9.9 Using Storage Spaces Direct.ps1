# Recipe 9.1 - Using Storage Spaces Direct (STSD)
# 
# Uses CL1,SSRV1, SSRV2, HV1
# Runs on CL1 and SSRV1

# Setup S2D cluster on SSRV1, SSRV2, SSRV3

# 1. Create credential for Reskit
$Username   = "Reskit\administrator"
$Password   = 'Pa$$w0rd'
$PasswordSS = ConvertTo-SecureString  -String $Password -AsPlainText -Force
$CredRK     = New-Object -Typename System.Management.Automation.PSCredential -Argumentlist $Username,$PasswordSS

# 2. Create sessions on each of the storge servers
$s1 = New-PSSession -Name S1 -ComputerName SSRV1 -Credential $credrk                                                                          
$s2 = New-PSSession -Name S2 -ComputerName SSRV2 -Credential $credrk                                                                          
$s3 = New-PSSession -Name S3 -ComputerName SSRV3 -Credential $credrk
$S = $S1, $S2, $S3

# 3. Create Feature addition script block
$SB = {
## Ensure C:\Foo exists!
New-Item -Path c:\foo  -ItemType Directory -ErrorAction SilentlyContinue
Write-Verbose 'Adding features'
## set features to add
$Features = @('Hyper-V', 'Failover-Clustering', 'FS-FileServer',
              'RSAT-Clustering-PowerShell','Hyper-V-PowerShell')
## create a hash table
$SBHT = @{
  Name                   = $Features
  IncludeAllSubFeature   = $True
  IncludeManagementTools = $True
}

## Install these features on this machine
Install-WindowsFeature @SBHT
} # End Config Script block

# 4. Run script block on all three systems
$Results = Invoke-Command -Session $S -ScriptBlock $SB # do all three in parallel

# 5. See what is there
Invoke-Command -Session $s -scr {Get-windowsfeature *  | Where-Object Installed}| 
    Sort-Object -Property PSComputerName,DisplayName |
      Format-Table -Property DisplayName -Group PSComputerName

# 6. Remove Windows-Defender
# This avoids issues with clulster validation
Remove-WindowsFeature -Name 'Windows-Defender' -ComputerName SSRV1, SSRV2, SSRV3

# 7. Restart SSRVx - with Hyper-V added, reboot is required
Stop-Computer -ComputerName SSRV1 -Force
Stop-Computer -ComputerName SSRV2 -Force
Stop-Computer -ComputerName SSRV3 -Force


## After reboot - run this from on SSRV1
##
# 8. Take a check point to avoid re-installing. :-)
Checkpoint-VM -VM SSRV1, SSRV2, SSRV3 -SnapshotName 'Post WU, Pre-Cluster test'
Start-vm -VMName SSRV1, SSRV2, SSRV3

# 9. Check the status of Windows update on each server
Get-WindowsUpdate -ComputerName SSRV1, SSRV2, SSRV3 -Verbose -AcceptAll -Install 

### Do not move on till all updates installed on all three nodes

# 10. Test the cluster
Get-Date
$Nodes = @('SSRV1.Reskit.org', 'SSRV2.Reskit.org','SSRV3.Reskit.Org')
$INF = Test-Cluster –Node $Nodes -verbose -debug –Include "Storage Spaces Direct", "Inventory", "Network", "System Configuration"

# 11. view the output report
Invoke-Item $INF

# 12. Take a further checkpoint
$VMs = @('SSRV1','ssrv2', 'ssrv3')
$SN  = 'Post WU, post-Cluster test'
Checkpoint-VM -VMName $VMs -SnapshotName $SN -ComputerName Cooham24

# 13. Build a new fail over cluster
$NCHT = @{}
$NCHT.Name          = 'SSRV'
$NCHT.Node          = $Nodes
$NCHT.NoStorage     = $True
$NCHT.StaticAddress = '10.10.10.110/24'
New-Cluster @NCHT -verbose -Debug


# 9. Enable S2D 
Enable-ClusterStorageSpacesDirect -PoolFriendlyName 'ReskitS2D' -Confirm:$False

# 10. Create Scale Out File Server 
Add-ClusterScaleOutFileServerRole -Name SOFS -Cluster SSRV


# 11. Create two volumes
New-Volume -FriendlyName 'IT' -FileSystem CSVFS_ReFS -StoragePoolFriendlyName 'ReskitS2D' -size 100mb
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
Get-ClusterResource | where name -match 'sofs' | Remove-ClusterResource -Force
Get-ClusterResource | Remove-ClusterResource -force
Get-Cluster | Remove-Cluster -CleanupAD -verbose -Force
invoke-Command -computer -script {
Get-ADComputer -Filter 'samaccountname -like "*sof*"' | 
    Remove-ADComputer -Confirm:$False
}
