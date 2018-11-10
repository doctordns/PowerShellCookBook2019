# Recipe 4-7 - Modifying printer security

# 1. Define the user who is to be given access to this printer and get the group's
#    security principal details:
$GroupName = 'Sales Group'
$Group = New-Object -Typename `
                         Security.Principal.NTAccount `
                     -Argumentlist $GroupName

# 2. Next, get the group's SID:
$GroupSid = $Group.Translate(
    [Security.Principal.Securityidentifier]).Value

# 3. Now define the SDDL that gives this user access to the printer:
$SDDL = 'O:BAG:DUD:PAI(A;OICI;FA;;;DA)' +
        "(A;OICI;0x3D8F8;;;$GroupSid)"

# 4. Display the details:
'Group Name : {0}' -f $GroupName
'Group SID  : {0}' -f $GroupSid
'SDDL       : {0}' -f $SDDL

# 5. Get the Sales Group printer object:
$SGPrinter = Get-Printer -Name SGCP1

# 6. Set the Permissions:
$SGPrinter | Set-Printer -Permission $SDDL