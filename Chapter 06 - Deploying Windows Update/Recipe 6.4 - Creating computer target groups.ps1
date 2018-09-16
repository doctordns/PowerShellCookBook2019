#  Recipe 3-4 - Creating computer taget groups

# 1. Create a WSUS computer target group for the Domain Controllers:
$WSUSServer = Get-WsusServer
$WSUSServer.CreateComputerTargetGroup('Domain Controllers')

# 2. Add a computer to the new computer target group:
Get-WsusComputer -NameIncludes DC1 |
    Add-WsusComputer -TargetGroupName 'Domain Controllers'

# 3. List the clients in the computer target group:
$DCGroup = $WSUSServer.GetComputerTargetGroups() |
    Where-Object Name -eq 'Domain Controllers'
Get-WsusComputer |
    Where-Object ComputerTargetGroupIDs -Contains $DCGroup.id
