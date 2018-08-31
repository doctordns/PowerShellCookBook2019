# Recipe 8.13 - Finding expired computers in AD

# 1.Build the report header:
$RKReport = ''
$RkReport += "*** Reskit.Org AD Unused Computer Report`n"
$RKReport += "*** Generated [$(Get-Date)]`n"
$RKReport += "***********************************`n`n"

# 2. Report on computer accounts that have not logged in the
#    past 14 days:
$RkReport += "*** Machines not logged on in past 14 days`n"
$FortnightAgo = (Get-Date).AddDays(-14)
$ADCHT1 = @{
  Properties = 'lastLogonDate'
  Filter     = 'lastLogonDate -lt $FortnightAgo'
}
$RKReport += Get-ADComputer @ADCHT1  |
    Sort-Object -Property lastLogonDate |
        Format-Table -PropertyName lastLogonDate |
            Out-String

# 3. Report on computer accounts that have not logged in the past month:
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

# 4. Display the report:
$RKReport