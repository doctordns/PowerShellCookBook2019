# Recipe 8.11 - Adding Users to Active Directoryt using a CSV File

# 0 Create CSV
$CSV = = @"
FN, Initials, Lastname, UserPrincipalName, Alias, Description, PW
S, K, masterley, skm, Sylvester, 'Data Team', christmas
C, A, Smyth, rmlt, Charlie, 'Team Administrator,christmas
"@
$CSV | Out-File -FilePath .\C:\Foo\Users.csv

# 1.  Import a CSV file containing the details of the users you 
#     want to add to AD:
$Users = Import-CSV -Path C:\Foo\Users.Csv

# 2. Add the users using the CSV
$SS = ConvertTo-SecureString -AsPlainText $user.PW -Force

ForEach ($User in $Users) {
    $Prop = @{}
    $Prop.GivenName             = $User.FN
    $Prop.Initials              = $User.Initials
    $Prop.Surname               = $User.Lastname
    $Prop.UserPrincipalName     = $User.UserPrincipalName +
                                  "@reskit.org"
    $Prop.Displayname           = $User.FN.trim() + " " +
                                  $User.lastname.trim()
    $Prop.Description           = $User.Description
    $Prop.Name                  = $User.Alias
    $SS = ConvertTo-SecureString -AsPlainText $user.PW -Force
    $Prop.AccountPassword        = $SS
    $Prop.ChangePasswordAtLogon = $true
    $Prop.Enabledd              = $true
    # Now create the user
    New-ADUser @Prop -Path 'OU=IT,DC=Reskit,DC=ORG' -Enabled:$true
    # Finally, display user created
    Write-OUtput "Created $($Prop.Displayname)"
}