# Recipe 4-6 - Reporting on printer security

# 1. Create a hash table containing printer permissions:
$Permissions = @{
ReadPermissions = [uint32] 131072
Print = [uint32] 131080
PrintAndRead = [uint32] 196680
ManagePrinter = [uint32] 983052
ManageDocuments = [uint32] 983088
ManageChild = [uint32] 268435456
GenericExecute = [uint32] 536870912
ManageThisPrinter = [uint32] 983116
}

# 2. Get a list of all printers and select the Sales Group color printer:
$Printer = Get-CimInstance -Class Win32_Printer `
                           -Filter "Name = 'SGCP1'"

# 3. Get the SecurityDescriptor and DACL for each printer:
$SD = Invoke-CimMethod -InputObject $Printer `
                       -MethodName GetSecurityDescriptor
$DACL = $SD.Descriptor.DACL

# 4. For each Ace in the DACL, look to see what permissions you have set, and report
#    accordingly:

ForEach ($Ace in $DACL) {

# 5. Look at each permission that can be set and check to see if the Ace is set for that
#     permission:
Foreach ($Flag in ($Permissions.GetEnumerator() ) ) {
# Is this flag set in the access mask?
If ($Flag.value -eq $Ace.AccessMask) {

# 6. If this permission is set, then get the AceType:
$AceType = switch ($Ace.AceType)
{
0 {'Allowed'; Break}
1 {'Denied'; Break}
2 {'Audit'}
}

# 7. Get the permission type, nicely formatted:
$PermType = $flag.name  `
           -Csplit '(?=[A-Z])' -ne '' -join ' '

# 8. Finally, display the results (and end the loops and If statement):
'Account: {0}{1} - {2}: {3}' -f $ace.Trustee.Domain,
$Ace.Trustee.Name,
$PermType, $AceType

} # End of If $flag,Value

} # End Foreach $Flag loop

} # End Each $Ace