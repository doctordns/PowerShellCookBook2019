# Recipe 5.3 - Acessing SMB shares
#
# run from CL1
# Uses the foo share on FS1 created earlier

# 1. Examine the SMB client's configuration
Get-SmbClientConfiguration

# 2. You require SMB signing from the client. You must run this
#    command from an elevated console on the client computer
$CHT = @{Confirm=$false}
Set-SmbClientConfiguration -RequireSecuritySignature $True @CHT

# 3. Examine SMB client's network interface
Get-SmbClientNetworkInterface |
    Format-Table

#     4. Examine the shares provided by FS1
net view \\FS1

# 5. Create a drive mapping, mapping the r: to the share on server FS1
New-SmbMapping -LocalPath r: -RemotePath \\FS1.Reskit.Org\foo

# 6. View the shared folder mapping
Get-SmbMapping

# 7. View the shared folder contents
Get-ChildItem -Path r:

# 8. Run a program from the shared file
# assumes this application is already on that share
R:\MarsInstaller.exe

# 9. View existing connections 
# Note: you need to run this in an elevated console)
Get-SmbConnection

# 10. What files are open on FS1? If any files are open you view them
#     by doing this on FS1:
Get-SmbOpenFile