# Recipe 8.10 - Creating and managing AD users, groups, and computers

# 1.Create a hash table for general user attributes:
$Password = 'Pa$$w0rd'
$PSS = ConvertTo-SecureString -String $Password -AsPlainText -Force
$NewUserHT = @{}
$NewUserHT.AccountPassword =     = $PSS
$NewUserHT.Enabled               = $true
$NewUserHT.PasswordNeverExpires  = $true
$NewUserHT.ChangePasswordAtLogon = $false

# 2. Create two new users adding to basic hash table
$NewUserHT.SamAccountName    = 'ThomasL'
$NewUserHT.UserPrincipalName = 'thomasL@reskit.org'
$NewUserHT.Name              = 'ThomasL'
$NewUserHT.DisplayName       = 'Thomas Lee (IT)'
New-ADUser @NewUserHT

$NewUserHT.SamAccountName    = 'RLT'
$NewUserHT.UserPrincipalName = 'rlt@reskit.org'
$NewUserHT.Name              = 'Rebecca Tanner'
$NewUserHT.DisplayName       = 'Rebecca Tanner (IT)'
New-ADUser @NewUserHT

# 3. Create an OU and move users into it:
$OUHT = @{
    Name        = 'IT'
    DisplayName = 'Reskit IT Team'
    Path        = 'DC=Reskit,DC=Org'
}
New-ADOrganizationalUnit @OUHT
$MHT1 = @{
    Identity   = 'CN=ThomasL,CN=Users,DC=Reskit,DC=ORG'
    TargetPath = 'OU=IT,DC=Reskit,DC=Org'
}
Move-ADObject @MHT1
$MHT2 = @{
    Identity = 'CN=Rebecca Tanner,CN=Users,DC=Reskit,DC=ORG'
    TargetPath = 'OU=IT,DC=Reskit,DC=Org'
}
Move-ADObject @MHT2

# 4. Create a third user in the IT OU:

$NewUserHT.SamAccountName    = 'JerryG'
$NewUserHT.UserPrincipalName = 'jerryg@reskit.org'
$NewUserHT.Description       = 'Virtualization Team'
$NewUserHT.Name              = 'JerryGarcia'
$NewUserHT.DisplayName       =  'Jerry Garcia (IT)'
$NewUserHT.Path              =  'OU=IT,DC=Reskit,DC=Org'
New-ADUser @NewUserHT

# 5. Add and then remove users two ways:
$NewUserHT.SamAccountName    = 'TBR'
$NewUserHT.UserPrincipalName = 'tbr@reskit.org'
$NewUserHT.Name              = 'TBR'
$NewUserHT.DisplayName       = 'User to be removed'
$NewUserHT.Path              = 'OU=IT,DC=Reskit,DC=Org'
New-ADUser @NewUserHT

$NewUserHT.SamAccountName     = 'TBR2'
$NewUserHT.UserPrincipalName  = 'tbr2@reskit.org'
$NewUserHT.Name               = 'TBR2'
New-ADUser @NewUserHT `

# Remove get | remove
Get-ADUser -Identity 'CN=TBR,OU=IT,DC=Reskit,DC=Org' |
    Remove-ADUser -Confirm:$false
# Remove directly
Remove-ADUser -Identity 'CN=TBR2,OU=IT,DC=Reskit,DC=Org' -Confirm:$false

# 6. Update and display a user:
Set-ADUser -Identity ThomasL `
    -OfficePhone '44168555420' `
    -Office 'Cookham HQ' `
    -EmailAddress 'ThomasL@Reskit.Org' `
    -GivenName 'Thomas' `
    -Surname 'Lee' `
    -HomePage 'Https://tfl09.blogspot.com'
Get-ADUser -Identity ThomasL `
    -Properties Office, OfficePhone, EmailAddress

    # 7. Create and populate a group:
New-ADGroup -Name 'IT Team' `
    -Path 'OU=IT,DC=Reskit,DC=org' `
    -Description 'All members of the IT Team' `
    -GroupScope DomainLocal
$ItUsers = Get-ADUser -Filter * `
    -SearchBase 'OU=IT,DC=Reskit,DC=Org'
Add-ADGroupMember -Identity 'CN=IT Team,OU=IT,DC=Reskit,DC=org' `
    -Members $ItUsers

# 8. Add a computer to the AD:
New-ADComputer -Name 'Wolf' `
    -DNSHostName 'wolf.reskit.org' `
    -Description 'One for Jerry'`
    -Path 'OU=IT,DC=Reskit,DC=Org' `
    -OperatingSystemVersion 'Window Server 2016 Data Center'