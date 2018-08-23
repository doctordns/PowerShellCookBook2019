# Recipe 9.1 - Using Storage Spaces Direct (STSD)
# 
# Uses CL1,SSRV1, SSRV2, HV1
# Run on CL1

# Setup STSD cluster on SSRV1, SSRV2, SSRV3

# 1. Create credential for Reskit
$Username   = "Reskit\administrator"
$Password   = 'Pa$$w0rd'
$PasswordSS = ConvertTo-SecureString  -String $Password -AsPlainText -Force
$CredRK     = New-Object -Typename System.Management.Automation.PSCredential -Argumentlist $Username,$PasswordSS

# 2. Create sessions on each of the storge servers
$s1 = New-PSSession -Name S1 -VMname SSRV1 -Credential $credrk                                                                          
$s2 = New-PSSession -Name S2 -VMName SSRV2 -Credential $credrk                                                                          
$s3 = New-PSSession -Name S3 -VMName SSRV3 -Credential $credrk
$S = $S1, $S2, $S3

# 3. Create Feature addition script block
$SB = {
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
}

# 4. Run script block on all three systems
$Results = Invoke-Command -Session $S -ScriptBlock $SB # do all three in parallel

# 5. Restart SSRVx - with Hyper-V added, reboot if required
Restart-VM -VMName SSRV1, SSRV2, SSRV3  -Force -Wait -For IPAddress

# 6 Re-create sessions on each of the storge servers
$s1 = New-PSSession -Name S1 -VMname SSRV1 -Credential $credrk                                                                          
$s2 = New-PSSession -Name S2 -VMName SSRV2 -Credential $credrk                                                                          
$s3 = New-PSSession -Name S3 -VMName SSRV3 -Credential $credrk
$S = $S1, $S2, $S3


# x. See the images loaded 
$sb = 
Get-ChildItem -Path C:\ProgramData\Microsoft\Windows\Images

# Create a shared VHD on SSRV cluster


# Create a VMSSD1 on HV1 that uses this shared volume


# Install OS on VMSSD1


# Add Hyper-V to SSRV cluster


# Add hyperconverged VM
