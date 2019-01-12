# Recipe 9.2 - Creating and securing SMB shares
# Assumumes two accounts exist: 'IT Team', and 'IT Management' 
# Also assumes C:\foo folder exists
# These accounts create earlier!
# Run from fs1

# 0 Just in case
$EAHT = @{Erroraction='SilentlyContinue'}
New-Item -Path c:\Foo -ItemType Directory @EAHT

# 1. Discover existing shares and access rights
Get-SmbShare -Name * | 
  Get-SmbShareAccess |
    Format-Table -GroupBy Name

# 2. Share a folder 
New-SmbShare -Name Foo -Path C:\Foo

# 3. Update the share to have a description
Set-SmbShare -Name Foo -Description 'Foo share for IT' -Confirm:$False

# 4. Set folder enumeration mode
$CHT = @{Confirm = $false}
Set-SMBShare -Name Foo -FolderEnumerationMode AccessBased @CHT

# 5. Set encryption on for Foo share
Set-SmbShare –Name Foo -EncryptData $true @CHT

# 6. Remove all access to foo share
$AHT1 = @{
  Name        =  'foo'
  AccountName = 'Everyone'
  Confirm     =  $false
}
Revoke-SmbShareAccess @AHT1 | Out-Null

# 7. Add reskit\administrators R/O
$AHT2 = @{
    Name         = 'foo'
    AccessRight  = 'Read'
    AccountName  = 'Reskit\ADMINISTRATOR'
    ConFirm      =  $false 
} 
Grant-SmbShareAccess @AHT2 | Out-Null

# add system full access
$AHT3 = {
    Name          = 'foo'
    AccessRight   = 'Full'
    AccountName   = 'NT Authority\SYSTEM'
    Confirm       = $False 
}
Grant-SmbShareAccess  @AHT3 | Out-Null

# Set Creator/Owner to Full access
$AHT4 = {
    Name         = 'foo'
    AccessRight  = 'Full `'
    AccountName  = 'CREATOR OWNER'
    Confirm      = $false 
}
Grant-SmbShareAccess @AHT4  | Out-Null

# Grant IT Team read access
$AHT5 = {
    Name        = 'foo'
    AccessRight = 'Read'
    AccountName = 'IT Team'
    Confirm     = $false 
}
Grant-SmbShareAccess @AHT5 | Out-Null
#                      
$AHT6 = {
    Name        = 'foo'
    AccessRight = 'Full'
    AccountName = 'IT Management'
    Confirm     = $false     
}
Grant-SmbShareAccess  @AHT6 | Out-Null

# Step 7 - Review share access
Get-SmbShareAccess -Name foo



<# reset the shares 
Get-smbshare foo | remove-smbshare -Confirm:$false

#>
