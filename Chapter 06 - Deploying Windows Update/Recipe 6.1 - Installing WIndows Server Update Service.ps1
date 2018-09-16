# Recipe 6.1 - Installing WIndows Server Update Services
#
# Run as administrator on WSUS1


# 1. Install the Windows Update feature and tools
$IFHT = @{
  Name                   = 'UpdateServices' 
  IncludeManagementTools = $true
}
Install-WindowsFeature @IFHT

# 2. Determine the features installed on WSUS1 server after installation of WSUW
Get-WindowsFeature | Where-Object Installed

# 3. Create a folder for WSUS update content
$WSUSDir = 'C:\WSUS'
If (-Not (Test-Path -Path $WSUSDir -ErrorAction SilentlyContinue))
    {New-Item -Path $WSUSDir -ItemType Directory | Out-Null}

# 4. Perform post-installation configuration using WsusUtil.exe
$CMD ="$env:ProgramFiles\" + "Update Services\Tools\WsusUtil.exe " 
& $CMD Postinstall CONTENT_DIR=$WSUSDir

# 5. View the post installation log file
$LOG = "$env:localappdata\temp\WSUS_Post*.log"
Get-ChildItem -Path $LOG

# 6. View some websites on this machine, noting the WSUS website
Get-Website -Name ws* | Format-Table -AutoSize

# 7. View the cmdlets in the UpdateServices module
Get-Command -Module UpdateServices

# 8. Inspect the TypeName and properties of the object 
#    created with GetWsusServer
$WSUSServer = Get-WsusServer
$WSUSServer.GetType().Fullname
$WSUSServer | Select-Object -Property *

# 9. The object is of type UpdateServer in the
#    Microsoft.UpdateServices.Internal.BaseApi namespace, and 
#    is the main object you use to manage WSUS from PowerShell.
($WSUSServer | Get-Member -MemberType Method).count
$WSUSServer | Get-Member -MemberType Method


# 10. View WSUS Configuration
$WSUSServer.GetConfiguration() |
    Select-Object -Property SyncFromMicrosoftUpdate,LogFilePath

# 11. Get product categories after initial install:
$WSUSProducts = Get-WsusProduct -UpdateServer $WSUSServer
$WSUSProducts.Count
$WSUSProducts

# 12. Display subscription information
$WSUSSubscription = $WSUSServer.GetSubscription()
$WSUSSubscription | Select-Object -Property * | Format-List


# 13. Get the latest categories of products available  from Microsoft Update
#     servers. 
$WSUSSubscription.StartSynchronization()
Do {
     Write-Output $WSUSSubscription.GetSynchronizationProgress()
     Start-Sleep -Seconds 5
   }  
While ($WSUSSubscription.GetSynchronizationStatus() -ne
                                          'NotProcessing')

# 14. Once synchronization is complete, check the results of the synchronization:
$WSUSSubscription.GetLastSynchronizationInfo()

# 15.Review the categories of the products available after synchronzation:
$WSUSProducts = Get-WsusProduct -UpdateServer $WSUSServer
$WSUSProducts.Count
$WSUSProducts