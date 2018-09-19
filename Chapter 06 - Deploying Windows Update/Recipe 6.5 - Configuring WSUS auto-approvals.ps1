# Recipe 6.5 - Configuring WSUS Auto Approvals
#
#  Run on WSUS!

# 1. Create the auto-approval rule:
$WSUSServer = Get-WsusServer
$ApprovalRule = 
    $WSUSServer.CreateInstallApprovalRule('Critical Updates')

# 2. Define a deadline for the rule:
$Type = 'Microsoft.UpdateServices.Administration.' + 
        'AutomaticUpdateApprovalDeadline'
$RuleDeadLine = New-Object -Typename $Type
$RuleDeadLine.DayOffset = 3
$RuleDeadLine.MinutesAfterMidnight = 180
$ApprovalRule.Deadline = $RuleDeadLine

# 3. Add update classifications to the rule:
$UC = $ApprovalRule.GetUpdateClassifications()
$C= $WSUSServer.GetUpdateClassifications() |
       Where-Object -Property Title -eq 'Critical Updates'
$UC.Add($C)
$D = $WSUSServer.GetUpdateClassifications() |
       Where-Object -Property Title -eq 'Definition Updates'
$UC.Add($D)
$ApprovalRule.SetUpdateClassifications($UpdateClassification)


# 4. Assign the rule to a computer target group:
$Type = 'Microsoft.UpdateServices.Administration.'+
        'ComputerTargetGroupCollection'
$TargetGroups = New-Object $Type
$TargetGroups.Add(($WSUSServer.GetComputerTargetGroups() |
  Where-Object -Property Name -eq "Domain Controllers"))
$ApprovalRule.SetComputerTargetGroups($TargetGroups)

# 5. Enable and save the rule:
$ApprovalRule.Enabled = $true
$ApprovalRule.Save()

# 6. Get a list of approval rules
$WSUSServer.GetInstallApprovalRules()  | 
  Format-Table -Property Name, Enabled, Action
