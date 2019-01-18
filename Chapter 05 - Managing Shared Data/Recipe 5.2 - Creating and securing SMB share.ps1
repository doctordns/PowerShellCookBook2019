# Recipe 5.2 - Creating and securing SMB shares
#
# Run from FS1

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
$CHT = @{Confirm=$False}
Set-SmbShare -Name Foo -Description 'Foo share for IT' @CHT

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

# 8. Add system full access
$AHT3 = @{
    Name          = 'foo'
    AccessRight   = 'Full'
    AccountName   = 'NT Authority\SYSTEM'
    Confirm       = $False 
}
Grant-SmbShareAccess  @AHT3 | Out-Null

# 9. Set Creator/Owner to Full Access
$AHT4 = @{
    Name         = 'foo'
    AccessRight  = 'Full'
    AccountName  = 'CREATOR OWNER'
    Confirm      = $False 
}
Grant-SmbShareAccess @AHT4  | Out-Null

# 10. Grant Saves Team read access, SalesAdmins has Full access
$AHT5 = @{
    Name        = 'Foo'
    AccessRight = 'Read'
    AccountName = 'Sales'
    Confirm     = $false 
}
Grant-SmbShareAccess @AHT5 | Out-Null
$AHT6 = @{
    Name        = 'Foo'
    AccessRight = 'Full'
    AccountName = 'SalesAdmins'
    Confirm     = $false     
}
Grant-SmbShareAccess  @AHT6 | Out-Null

# 11. Review share access
Get-SmbShareAccess -Name Foo | 
  Sort-Object AccessRight

# 12. Set file ACL to be same as share acl
Set-SmbPathAcl -ShareName 'Foo'


# 13. Create a file in c:\foo
'foo' | Out-File -FilePath C:\Foo\Foo.Txt


# 14. Set file ACL to be same as share acl
Set-SmbPathAcl -ShareName 'Foo'

# 15. View folder ACL using Get-NTFSAccess
Get-NTFSAccess -Path C:\Foo | 
  Format-Table -AutoSize

# 16. View file ACL
Get-NTFSAccess -Path C:\Foo\Foo.Txt |
  Format-Table -AutoSize
  



# reset for testing

<# reset the shares 
Get-smbshare foo | remove-smbshare -Confirm:$false

#>
