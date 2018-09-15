# Recipe 3.3 - Adding Users to Active Directory using a CSV File

# 0. Create CSV
$CSVDATA = @'
Firstname, Initials, Lastname, UserPrincipalName, Alias, Description, Password
S,K,Masterly, SKM, Sylvester, Data Team, Christmas42
C,B, Smith, CBS, Claire, Receptionist, Christmas42
Billy, Bob, JoeBob, BBJB, BillyBob, A Bob, Christmas42
Malcolm, Dudley, Duelittle, Malcolm, Malcolm, Mr Danger, Christmas42
'@
$CSVDATA | Out-File -FilePath C:\Foo\Users.Csv

# 1. Import a CSV file containing the details of the users you 
#    want to add to AD:
$Users = Import-CSV -Path C:\Foo\Users.Csv | 
  Sort-Object  -Property Alias
$users | Sort-Object -Property Alias |Format-Table

# 2. Add the users using the CSV
ForEach ($User in $Users) {
#    Create a hash table of properties to set on created user
$Prop = @{}
#    Fill in values
$Prop.GivenName         = $User.Firstname
$Prop.Initials          = $User.Initials
$Prop.Surname           = $User.Lastname
$Prop.UserPrincipalName =
  $User.UserPrincipalName+"@reskit.org"
$Prop.Displayname       = $User.firstname.trim() + " " +
  $user.lastname.trim()
$Prop.Description       = $User.Description
$Prop.Name              = $User.Alias
$PW = ConvertTo-SecureString -AsPlainText $user.password -Force
$Prop.AccountPassword   = $PW
#    To be safe!
$Prop.ChangePasswordAtLogon = $true
#    Now create the user
New-ADUser @Prop -Path 'OU=IT,DC=Reskit,DC=ORG' -Enabled:$true
#   Finally, display user created
"Created $($Prop.Displayname)"
}



### Remove the users created in the recipe

$users = Import-Csv C:\foo\users.csv
foreach ($User in $Users)
{
  Get-ADUser -Identity $user.alias | remove-aduser
}
