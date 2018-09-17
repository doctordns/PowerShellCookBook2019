# Recipe 3-2 - Configuring WUS update synchronization

# 1. Locate the versions of WIndows Server supported by Windows Update
Get-WsusProduct | 
  Where-Object -FilterScript {$_.product.title -match 
                              '^Windows Server'}

# 2. And get updat titles for Windows 10
Get-WsusProduct -TitleIncludes 'Windows 10'

# 3. Create and view a list of software product titles to include
$CHP = 
 (Get-WsusProduct |  
   Where-Object -FilterScript {$_.product.title -match 
                               '^Windows Server'}).Product.Title
$CHP += @('Microsoft SQL Server 2016','Windows 10')
$CHP


# 4. Assign the desired products to include in Windows Update:
Get-WsusProduct |
    Where-Object {$PSItem.Product.Title -in $CHP} |
        Set-WsusProduct

# 5. Updates are classified into distinct categories; a view which classifications of
#    updates are available:
Get-WsusClassification

# 6. Build a list of desired update classifications to make available on your WSUS
#    server and view the list:
$CCL = @('Critical Updates',
         'Definition Updates',
         'Security Updates',
         'Service Packs',
         'Update Rollups',
         'Updates')

# 7. Set the list of desired update classifications in WSUS:
Get-WsusClassification | 
    Where-Object {$_.Classification.Title -in 
                           $CCL} |
            Set-WsusClassification

# 8. Get Synchronization details
$WSUSServer = Get-WsusServer
$WSUSSubscription = $WSUSServer.GetSubscription()



# 9. Start synchronizing available updates
$WSUSSubscription.StartSynchronization()

# 10 loop and wait for syncronization to complete
$IntervalSeconds = 5
$NP = 'NotProcessing'
Do {
  $WSUSSubscription.GetSynchronizationProgress()
  Start-Sleep -Seconds $IntervalSeconds
  } While ($WSUSSubscription.GetSynchronizationStatus() -eq $NP) 


# 11. Synchronize the updates which can take a long while to compelete.
$IntervalSeconds = 1
$NP = 'NotProessing'
#   Wait for synchronizing to start
Do {
Write-Output $WSUSSubscription.GetSynchronizationProgress()
Start-Sleep -Seconds $IntervalSeconds
}
While ($WSUSSubscription.GetSynchronizationStatus() -eq $NP)
#    Wait for all phases of process to end
Do {
Write-Output $WSUSSubscription.GetSynchronizationProgress()
Start-Sleep -Seconds $IntervalSeconds
}
Until ($WSUSSubscription.GetSynchronizationStatus() -eq $NP)

# 12. When the final loop is complete, check the results of the
#     synchronization:
$WSUSSubscription.GetLastSynchronizationInfo()

# 13. Configure automatic synchronization to run once per day:
$WSUSSubscription = $WSUSServer.GetSubscription()
$WSUSSubscription.SynchronizeAutomatically = $true
$WSUSSubscription.NumberOfSynchronizationsPerDay = 1
$WSUSSubscription.Save()