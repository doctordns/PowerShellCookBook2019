# Recipe 8.12 - Reporting on AD Users

# 1. Define the function Get-ReskitUser
#    The function returns objects related to users in reskit.org
Function Get-ReskitUser {
# Get PDC Emulator DC
$PrimaryDC = Get-ADDomainController -Discover -Service PrimaryDC
# Get Users
$ADUsers = Get-ADUser -Filter * -Properties * Server $PrimaryDC

# Iterate through them and create $Userinfo hash table:
Foreach ($ADUser in $ADUsers) {
    # Create a userinfo HT
    $UserInfo = [Ordered] @{}
    $UserInfo.SamAccountname = $ADUser.SamAccountName
    $Userinfo.DisplayName    = $ADUser.DisplayName
    $UserInfo.Office         = $ADUser.Office
    $Userinfo.Enabled        = $ADUser.Enabled
    $userinfo.LastLogonDate  = $ADUser.LastLogonDate
    $UserInfo.ProfilePath    = $ADUser.ProfilePath
    $Userinfo.ScriptPath     = $ADUser.ScriptPath
    $UserInfo.BadPWDCount    = $ADUser.badPwdCount
    New-Object -TypeName PSObject -Property $UserInfo
}
}

# 2. Get the users:
$RKUsers = Get-ReskitUser

# 3. Build the report header:
$RKReport = ''
$RkReport += "*** Reskit.Org AD Report`n"
$RKReport += "*** Generated [$(Get-Date)]`n"
$RKReport += "*******************************`n`n"

# 4. Report on Disabled users:
$RkReport += "*** Disabled Users`n"
$RKReport += $RKUsers |
    Where-Object {$_.Enabled -NE $true} |
        Format-Table -Property SamAccountName, Displayname |
            Out-String

# 5. Report users who have not recently logged on:
$OneWeekAgo = (Get-Date).AddDays(-7)
$RKReport += "*** Users Not logged in since $OneWeekAgo"
$RkReport += $RKUsers |
    Where-Object {$_.Enabled -and $_.LastLogonDate -le $OneWeekAgo} |
        Sort-Object -Property LastlogonDate |
            Format-Table -Property Displayname,lastlogondate |
                Out-String

# 6. Users with high invalid password attempts:
#
$RKReport += "*** High Number of Bad Password Attempts`n"
$RKReport += $RKUsers | Where-Object BadPwdCount -ge 5 |
Format-Table -Property SamAccountName, BadPwdCount |
     Out-Stringsd

# 7. Display the report:
$RKReport