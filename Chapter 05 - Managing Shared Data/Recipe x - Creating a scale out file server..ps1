# Recipe 9.6 - Make file server fault tolerant
# This recipe is run on FS1, but involves FS2
# ISCSI initiator is setup on FS1, FS2

# Step 1 - add clustering features
Install-WindowsFeature –Name Failover-Clustering, `
                       -ComputerName FS1 `
                       –IncludeManagementTools

Install-WindowsFeature –Name Failover-Clustering `
                       -ComputerName FS2 `
                       –IncludeManagementTools


# Step 2 - Test the nodes
$CheckOutput = 'c:\foo\clustercheck.htm'
Test-Cluster  -Node FS1, FS2  -ReportName $CheckOutput


# Step 3 - View Validation test results
Invoke-Item  -Path $CheckOutput


# Step 4 - Create The Cluster
New-Cluster -Name FS `
            -Node 'fs1.reskit.org', 'fs2.reskit.org' `
            -StaticAddress 10.10.10.100

# 5. Add the Cluster Scale Out File Server role:
Add-ClusterScaleOutFileServerRole -Name SalesFS

# 6. Add the Target to the CSV
Get-ClusterResource | 
    Where-Object OwnerGroup -Match 'Available' |
        Add-ClusterSharedVolume -Name VM

# 7 add a normal FailOver share
$SdFolder = 'S:\SalesData'
New-SMBShare -Name SalesData  `
             -Path $SdFolder `
             -Description 'SalesData'

# 8. Add a Continously Avaliable share
$HvFolder = 'C:\ClusterStorage\Volume1\HVData'
New-Item -Path $HvFolder -ItemType Directory |
              Out-Null
New-SMBShare -Name SalesHV -Path $HvFolder `
             -Description 'Sales HV (CA)' `
             -FullAccess 'Reskit\IT Team' `
             -ContinuouslyAvailable:$true 

# 9. View Shares
Get-SmbShare


<#  Remove it
Get-SMBShare -name SalesData | Remove-SMBShare -Confirm:$False
Get-SMBShare -name HVShare | Remove-SMBShare -Confirm:$False

get-clusterresource | Stop-ClusterResource
Stop-Cluster

Get-ClusterSharedVolume | Remove-ClusterSharedVolume
Get-Clusterresource | stop-clusterresource
Get-ClusterGroup -Name salesfs | remove-clusterresource
Get-ClusterResource | remove-clusterresource -Force
Remove-Cluster  -force -cleanupad
#>

# later
Add-ClusterSharedVolume -Name HVCSV
