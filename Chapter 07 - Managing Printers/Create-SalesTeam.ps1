# Create-SaleTeam

# Creates the OU, groups, users and group memberships used in Reskit.Org

# Create Sales OU
$OUPath = 'DC=Reskit,DC=Org'
New-ADOrganizationalUnit -Name Sales -Path $OUPath

# Setup for creating users for sales
$OUPath = 'OU=Sales,DC=Reskit,DC=Org'
$Password   = 'Pa$$w0rd'
$PasswordSS = ConvertTo-SecureString  -String $Password -AsPlainText -Force
$NewUserHT  = @{
  AccountPassword       = $PasswordSS;
  Enabled               = $true;
  PasswordNeverExpires  = $true;
  ChangePasswordAtLogon = $false
  Path                  = $OUPath
}
$Password   = 'Pa$$w0rd'
$PasswordSS = ConvertTo-SecureString  -String $Password -AsPlainText -Force

#     Create Sales users Nigel, Samantha, Pippa, Jeremy

New-ADUser @NewUserHT -SamAccountName Nigel  -UserPrincipalName 'Nigel@reskit.org' `
                      -Name "Nigel" -DisplayName 'Nigel Hawthorne-Smyth'

New-ADUser @NewUserHT -SamAccountName Samantha  -UserPrincipalName 'Samantha@reskit.org' `
                      -Name "Samantha" -DisplayName 'Saamantha Rhees-Jenkins'

New-ADUser @NewUserHT -SamAccountName Pippa  -UserPrincipalName 'Pippa@reskit.org' `
                      -Name "Pippa" -DisplayName 'Pippa van Spergel'

New-ADUser @NewUserHT -SamAccountName Jeremy  -UserPrincipalName 'Jeremy@reskit.org' `
                      -Name "Jeremy" -DisplayName 'Jeremy Cadwalender'

# Create Sales Groups
$OUPath = 'OU=Sales,DC=Reskit,DC=Org'
New-ADGroup -Name Sales -Path $OUPath -GroupScope Global 
New-ADGroup -Name SalesAdmins -Path $OUPath -GroupScope Global 
New-ADGroup -Name SalesPrinterUsers -Path $OUPath -GroupScope Global 


# Add users to the groups
Add-ADGroupMember -Identity Sales -Members Nigel, Samantha, Pippa, Jeremy
Add-ADGroupMember -Identity SalesAdmins -Members Nigel, Samantha
Add-AdgroupMember -Identity SalesPrinterUsers -Members Sales, ThomasL

