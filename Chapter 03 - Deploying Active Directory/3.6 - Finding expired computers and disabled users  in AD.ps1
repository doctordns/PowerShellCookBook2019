# Recipe 3.5 - Finding expired computers and disabled users in AD

# 1.Build the report header
$RKReport = ''
$RkReport += "*** Reskit.Org AD Daily AD report`n"
$RKReport += "*** Generated [$(Get-Date)]`n"
$RKReport += "***********************************`n`n"

# 2. Report on computer accounts that have not logged in the past month
$RkReport += "*** Machines not logged on in past month`n"
$AMonthAgo = (Get-Date).AddMonths(-1)
$ADCHT2 = @{
  Properties = 'lastLogonDate'
  Filter     = 'lastLogonDate -lt $AMonthAgo'
}
$RkReport += Get-ADComputer @ADCHT2 |
    Sort-Object -Property lastLogonDate |
        Format-Table -Property Name, LastLogonDate |
            Out-String

# 3. Get users who have not logged on in the past month
$RKReport += "*** Users not logged on in past month`n"
$RkReport += Get-AdUser @ADCHT2 |
    Sort-Object -Property lastLogonDate |
        Format-Table -Property Name, LastLogonDate |
            Out-String

# 4. Find any user accounts that are disabled

$ADCHT3 = @{
  Properties = 'Enabled'
}
$RKReport += "*** Disabled Users`n"
$RkReport += Get-ADUser @Adcht3 -Filter {Enabled -ne $true}|
                 Sort-Object -Property lastLogonDate |
                     Format-Table -Property Name, LastLogonDate |
                        Out-String

# 5. Display the Report
$RKReport