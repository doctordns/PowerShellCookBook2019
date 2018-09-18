#  Recipe 6.4 - Creating computer taget groups
#
# Run this on WSUS1

# 1. Create a WSUS computer target group for the Domain Controllers
$WSUSServer = Get-WsusServer  -Name WSUS1 -port 8530
$WSUSServer.CreateComputerTargetGroup('Domain Controllers')

# 2. Examine existing target groups and viewing the new one
$WSUSServer.GetComputerTargetGroups() |
    Format-Table -Property Name

# 3. Find the DCs
Get-WsusComputer -NameIncludes DC
    
# 4. Add DC1 and DC2 to the Domain Controllers Target Group
Get-WsusComputer -NameIncludes DC |
    Add-WsusComputer -TargetGroupName 'Domain Controllers'

# 5. Get the DC group
$DCGroup = $WSUSServer.GetComputerTargetGroups() |
               Where-Object Name -eq 'Domain Controllers'

# 6. Find thecomputers in the group:
Get-WsusComputer |
    Where-Object ComputerTargetGroupIDs -Contains $DCGroup.id |
      Sort-Object -Property FullDomainName | 
          Format-Table -Property FullDomainName, ClientVersion,
                                 LastSyncTime
