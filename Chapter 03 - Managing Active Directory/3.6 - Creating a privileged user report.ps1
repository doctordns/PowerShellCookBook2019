# Recipe 10-14 - Creating a Privileged user report

# 1.Create an array for privileged users:
$PUsers = @()

# 2. Query the Enterprise Admins/Domain Admins/Scheme Admins groups for
#    members and add to the $Pusers array
# Enterprise Admins
$Members = Get-ADGroupMember -Identity 'Enterprise Admins' -Recursive |
    Sort-Object -Property Name
$PUsers += foreach ($Member in $Members) {
    Get-ADUser -Identity $Member.SID -Properties * |
        Select-Object-Property Name,
               @{Name='Group';expression={'Enterprise Admins'}},
               whenCreated,LastlogonDate
}
# Domain Admins
$Members = Get-ADGroupMember -Identity 'Domain Admins' -Recursive|
    Sort-Object -Property Name
$PUsers += Foreach ($Member in $Members)
    {Get-ADUser -Identity $member.SID -Properties * |
        Select-Object -Property Name,
                @{Name='Group';expression={'Domain Admins'}},
                WhenCreated, Lastlogondate,SamAccountName
}
# Schema Admins
$Members = Get-ADGroupMember -Identity 'Schema Admins' -Recursive |
    Sort-Object Name
$PUsers += Foreach ($Member in $Members) {
    Get-ADUser -Identity $member.SID -Properties * |
        Select-Object -Property Name,
            @{Name='Group';expression={'Schema Admins'}}, `
            WhenCreated, Lastlogondate,SamAccountName
}

# 3. Create the basic membership report:
$Report = ""
$Report += "*** Reskit.Org AD Privileged
User Report`n"
$Report += "*** Generated [$(Get-Date)]`n"
$Report += "***********************************"
$Report += $PUsers| Format-Table -Property Name,
            WhenCreated,Lastlogondate -GroupBy Group |
           Out-String
$Report += "`n"

# 4. Find out what has changed since last time this report ran
$ExportFile = "c:\Foop\users.clixml"
$OldFile = Try {Test-Path $ExportFile} Catch {}
if ($OldFile) {
    # if the file exists, report against changes

# Import the results from the last time the
# script was executed
$OldUsers = Import-Clixml-Path -Path $ExportFile
# Identify and report on the changes
$Changes = "*** Changes to Privileges
User Membership`n"
$Diff = Compare-Object
-ReferenceObject $OldUsers `
-DifferenceObject $PUsers
    If ($diff) {
$Changes += $diff |
Select-Object -Property @{Name='Name' ;expression={$_.InputObject.Name}},
                        @{Name='Group';expression={$_.InputObject.Group}},
                        @{Name='Side' ;expression=
           {If ($_.SideIndicator -eq '<=') `
                {'REMOVED'} Else
                 {'ADDED'}}} | Out-String
}
Else
{
  $LCT = (Get-Childitem -Path $ExportFile).LastWriteTime
  $Changes += "No Changes since previous Report [$LCT]"
}
}
Else # Old file does not exist
{
  $Changes += "EXPORT FILE NOT FOUND - FIRST TIME EXECUTION?"
}
$Report += $Changes

# 5. Display the report
$Report
# 6. Save results from this execution 
Export-Clixml -InputObject $PUsers -Path $ExportFile