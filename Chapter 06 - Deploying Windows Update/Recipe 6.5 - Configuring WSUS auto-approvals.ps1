# 1. Create the auto-approval rule:
$WSUSServer = Get-WsusServer
$ApprovalRule = 
    $WSUSServer.CreateInstallApprovalRule('Critical Updates')

# 2. Define a deadline for the rule:
$type = 'Microsoft.UpdateServices.Administration.' + `
        'AutomaticUpdateApprovalDeadline'
$RuleDeadLine = New-Object -Typename $type
$RuleDeadLine.DayOffset = 3
$RuleDeadLine.MinutesAfterMidnight = 180
$ApprovalRule.Deadline = $RuleDeadLine

# 3. Add update classifications to the rule:
$UpdateClassification = $ApprovalRule.GetUpdateClassifications()
$UpdateClassification.Add(($WSUSServer.GetUpdateClassifications() |
    Where-Object -Property Title -eq 'Critical Updates'))
$UpdateClassification.Add(($WSUSServer.GetUpdateClassifications() |
    Where-Object -Property Title -eq 'Definition Updates'))
$ApprovalRule.SetUpdateClassifications($UpdateClassification)

# 4. Assign the rule to a computer target group:
$TargetGroups = New-Object `
    Microsoft.UpdateServices.Administration.ComputerTargetGroupCollection
$TargetGroups.Add(($WSUSServer.GetComputerTargetGroups() |
    Where-Object -Property Name -eq "Domain Controllers"))
$ApprovalRule.SetComputerTargetGroups($TargetGroups)

# 5. Enable and save the rule:
$ApprovalRule.Enabled = $true
$ApprovalRule.Save()