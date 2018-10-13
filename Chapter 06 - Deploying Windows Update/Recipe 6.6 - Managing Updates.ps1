#  Recipe 6.6 - Managing Updates
#
#  Run on WSUS1 after earlier recipes are completed.

# 1. Open a PowerShell session, and view the overall status of all Windows updates
#    on WSUS1:
$WSUSServer = Get-WsusServer
$WSUSServer.GetStatus()

# 2. View the computer targets:
$WSUSServer.GetComputerTargets() | 
  Sort-Object -Property FullDomainName |
    Format-Table -Property FullDomainName, IPAddress, Last*
 

# 3  Search the WSUS server for updates with titles containing Windows Server 2016
#    that are classified as security updates, newest to oldest, and store them in a
#    variable. Examine the variable using Get-Member, reviewing the properties and
#    methods of the Microsoft.UpdateServices.Internal.BaseApi.Update
#    object:
$SecurityUpdates = $WSUSServer.SearchUpdates( `
    'Windows Server 2016') |
        Where-Object -Property UpdateClassificationTitle `
             -eq 'Security Updates' |
                  Sort-Object -Property CreationDate -Descending
$SecurityUpdates | sort title |ft title, description

# 4. View the matching updates:
$SecurityUpdates |
    Select-Object -Property CreationDate, Title

# 5. Select one of the updates to approve based on the KB article ID:
$SelectedUpdate = $SecurityUpdates |
    Where-Object KnowledgebaseArticles -eq 4019472

# 6. Define the computer target group where you will approve this update:
$DCTargetGroup = $WSUSServer.GetComputerTargetGroups() |
    Where-Object -Property Name -eq 'Domain Controllers'
  
# 7. Approve the update for installation in the target group:
$SelectedUpdate.Approve('Install',$DCTargetGroup)

# 8. Select one of the updates to decline based on the KB article ID:
$DeclinedUpdate = $SecurityUpdates |
Where-Object -Property KnowledgebaseArticles -eq 4020821

# 9. Decline the update:
$DeclinedUpdate.Decline($DCTargetGroup)

