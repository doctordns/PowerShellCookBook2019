# Recipe 3-2 - Configuring WUS update synchronization

# 1. Locate the products you want to download to your WSUS server using GetWsusProduct to search the product titles:
Get-WsusProduct -TitleIncludes 'Server 2016'
Get-WsusProduct -TitleIncludes 'Windows 10'

# 2. Build a list of software product titles you wish to include:
$ChosenProducts = @('Windows Server 2016',
                    'Microsoft SQL Server 2016',
                    'Windows 10' )

# 3. Assign the desired products to include in Windows Update:
Get-WsusProduct |
    Where-Object {$PSItem.Product.Title -in $ChosenProducts} |
        Set-WsusProduct

# 4. Updates are classified into distinct categories; a view which classifications of
#    updates are available:
Get-WsusClassification

# 5. Build a list of desired update classifications to make available on your WSUS
#    server and view the list:
$ChosenClassifications = @('Critical Updates',
                           'Definition Updates',
                           'Security Updates',
                           'Service Packs',
                           'Update Rollups',
                           'Updates')
$ChosenClassifications

# 6. Set our list of desired update classifications in WSUS:
Get-WsusClassification |
    Where-Object {$PSItem.Classification.Title -in 
                           $ChosenClassifications} |
            Set-WsusClassification

# 7. Create a variable for the Subscription object, start synchronizing Windows
#    Updates, and watch the progress in a loop:
$WSUSServer = Get-WsusServer
$WSUSSubscription = $WSUSServer.GetSubscription()
# Start synchronizing available updates
$WSUSSubscription.StartSynchronization()
$IntervalSeconds = 5
# Wait for synchronizing to start
Do {
  Write-Output $WSUSSubscription.GetSynchronizationProgress()
  Start-Sleep -Seconds $IntervalSeconds
}
While ($WSUSSubscription.GetSynchronizationStatus() -eq `
                      'NotProcessing')
#wait for all phases of process to end
Do {
  Write-Output $WSUSSubscription.GetSynchronizationProgress()
  Start-Sleep -Seconds $IntervalSeconds
}
Until ($WSUSSubscription.GetSynchronizationStatus() -eq `
                     'NotProcessing')

# 8. Synchronization takes a few moments to start with, and then takes a long time to
#    complete, depending on the number of products chosen. Wait for the process to
#    start in a do-while loop, then wait for the process to complete in a do-until
#    loop:
$WSUSSubscription.StartSynchronization()
$IntervalSeconds = 1
#Wait for synchronizing to start
Do {
Write-Output $WSUSSubscription.GetSynchronizationProgress()
Start-Sleep -Seconds $IntervalSeconds
}
While ($WSUSSubscription.GetSynchronizationStatus() -eq ` 'NotProcessing')
# Wait for all phases of process to end
Do {
Write-Output $WSUSSubscription.GetSynchronizationProgress()
Start-Sleep -Seconds $IntervalSeconds
}
Until ($WSUSSubscription.GetSynchronizationStatus() -eq `
         'NotProcessing')

# 9. When the final loop is complete, check the results of the synchronization:
$WSUSSubscription.GetLastSynchronizationInfo()

# 10. Configure automatic synchronization to run once per day:
$WSUSSubscription = $WSUSServer.GetSubscription()
$WSUSSubscription.SynchronizeAutomatically = $true
$WSUSSubscription.NumberOfSynchronizationsPerDay = 1
$WSUSSubscription.Save()