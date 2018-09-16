#  Recipe 3-6 - Managing Updates

# 1. Open a PowerShell session, and view the overall status of all Windows updates
#    on WSUS1:
$WSUSServer = Get-WsusServer
$WSUSServer.GetStatus()

# 2. View the computer targets:
$WSUSServer.GetComputerTargets()

# 3. View the installed updates on DC1 using Get-Hotfix and GetSilWindowsUpdate:
Get-HotFix -ComputerName DC1
$CimSession = New-CimSession -ComputerName DC1
Get-SilWindowsUpdate -CimSession $CimSession
$CimSession | Remove-CimSession

# 4. Search the WSUS server for updates with titles containing Windows Server 2016
#    that are classified as security updates, newest to oldest, and store them in a
#    variable. Examine the variable using Get-Member, reviewing the properties and
#    methods of the Microsoft.UpdateServices.Internal.BaseApi.Update
#    object:
$SecurityUpdates = $WSUSServer.SearchUpdates( `
    'Windows Server 2016') |
        Where-Object -Property UpdateClassificationTitle `
             -eq 'Security Updates' |
                  Sort-Object -Property CreationDate -Descending
$SecurityUpdates | Get-Member

# 5. View the matching updates:
$SecurityUpdates |
    Select-Object -Property CreationDate, Title

# 6. Select one of the updates to approve based on the KB article ID:
$SelectedUpdate = $SecurityUpdates |
    Where-Object KnowledgebaseArticles -eq 4019472

# 7. Define the computer target group where you will approve this update:
$DCTargetGroup = $WSUSServer.GetComputerTargetGroups() |
    Where-Object -Property Name -eq 'Domain Controllers'
  
# 8. Approve the update for installation in the target group:
$SelectedUpdate.Approve('Install',$DCTargetGroup)

# 9. Select one of the updates to decline based on the KB article ID:
$DeclinedUpdate = $SecurityUpdates |
Where-Object -Property KnowledgebaseArticles -eq 4020821

# 10. Decline the update:
$DeclinedUpdate.Decline($DCTargetGroup)