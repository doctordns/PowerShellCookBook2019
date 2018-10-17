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
 

# 3  Search the WSUS server for updates with titles containing Windows Server 2016.
#    Then pull out the security updates amd sort by creation date:

$ST = 'Windows Server 2016'
$SU = 'Security Updates'
$SecurityUpdates = $WSUSServer.SearchUpdates($ST) |
  Where-Object UpdateClassificationTitle -eq $SU |
    Sort-Object -Property CreationDate -Descending


# 4. View the matching updates (first 10).
$SecurityUpdates | 
  Sort-Object -Property Title |
    Select-Object -First 10 |
      Format-Table -Property Title, Description
      

# 5. Select one of the updates to approve based on the KB article ID:
$SelectedUpdate = $SecurityUpdates |
    Where-Object KnowledgebaseArticles -eq 3194798

# 6. Define the computer target group where you will approve this update:
$DCTargetGroup = $WSUSServer.GetComputerTargetGroups() |
    Where-Object -Property Name -eq 'Domain Controllers'
  
# 7. Approve the update for installation in the target group:
$SelectedUpdate.Approve('Install',$DCTargetGroup)

# 8. Select one of the updates to decline based on a KB article ID:
$DeclinedUpdate = $SecurityUpdates |
  Where-Object -Property KnowledgebaseArticles -eq 4020821

# 9. Decline the update:
$DeclinedUpdate.Decline($DCTargetGroup)