# Recipe 4.2 - Managing NTFS Permissions
# 
# Run on SRV1

# 1. Download NTFSSecurity module from PSGallery
Install-Module NTFSSecurity -Force

# 2. Get commands in the module
Get-Command -Module NTFSSecurity 

# 3. Create a new folder, and a file in the folder
New-Item -Path C:\Secure1 -ItemType Directory |
    Out-Null
"Secure" | Out-File -FilePath C:\Secure1\Secure.Txt
Get-ChildItem -Path c:\Secure1

# 4. View ACL of the folder:
Get-NTFSAccess -Path C:\Secure1 |
  Format-Table -AutoSize

# 5. View ACL of file
Get-NTFSAccess C:\Secure1\Secure.Txt |
  Format-Table -AutoSize


# 6. Create Sales group if it does not exist
try {
  Get-ADGroup -Identity 'Sales' -ErrorAction Stop
}
catch {
  New-ADGroup -Name Sales -GroupScope Global |
    Out-Null
}

# 7. Display
Get-ADGroup -Identity Sales


# 8. Add explicit full control for DomainAdmins
$AHT1 = @{
  Path         = 'C:\Secure1'
  Account      = 'Reskit\Domain Admins' 
  AccessRights = 'FullControl'
}
Add-NTFSAccess @AHT1

# 9. Remove builtin\users access from secure.txt file
$AHT2 = @{
  Path         = 'C:\Secure1\Secure.Txt'
  Account      = 'Builtin\Users' 
  AccessRights = 'FullControl'
}

Remove-NTFSAccess @AHT2

# 10. Remove inherited rights for the folder:
$IRHT1 = @{
  Path                       = 'C:\Secure1'
  RemoveInheritedAccessRules = $True
}
Disable-NTFSAccessInheritance @IRHT1

# 11. Add Sales group access to the folder
$AHT3 = @{
  Path         = 'C:\Secure1\'
  Account      = 'Reskit\Sales' 
  AccessRights = 'FullControl'
}
Add-NTFSAccess @AHT3

# 12. get results on path
Get-NTFSAccess -Path C:\Secure1 |
  Format-Table -AutoSize

# 13. and on the file
Get-NTFSAccess -Path C:\Secure1\Secure.Txt |
  Format-Table -AutoSize


