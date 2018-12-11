#  Recipe 14.3 - Use troubleshooting packs
#
# Run on SRV1


# 1. Get Trobleshooting packs
$Path = 'C:\Windows\diagnostics\syste'
$TSPackfolders = Get-ChildItem -Path $Path -Directory
$TSPacks =
    Foreach ($TSPack in $TSPackfolders) {
              Get-TroubleshootingPack -Path $TSPack.FullName}

# 2. Display the packs
$FTHT = @{
   Property = 'Name,
               Version,
               MinimumVersion,
               Description'
   Wrap     = $true
   AutoSize  = $true
}
$TSPacks | Format-Table @FTHT

# 3. Get a troubleshooting pack
$TsPack = $TSPacks | Where-Object id -eq 'WindowsUpdateDiagnostic'

# 4. look at the problems this pack looks for
$TSPack.RootCauses

# 5. And look at the solutions to these issues
$TSPack.RootCauses.Resolutions

# 6. Run this troubleshooting pack
#    (answering questions from the command line)
$TsPack | Invoke-TroubleshootingPack

# 7. Use get-TroubleshootingPack to create an answer file:
Get-TroubleshootingPack -Path $TSPack.path `
              -AnswerFile c:\Answers.xml

# 8. Display the XML:
Get-Content -Path C:\Answers.xml

# 9. Run WU pack using answer file
$TsPack |
    Invoke-TroubleshootingPack -AnswerFile C:\Answers.xml -unattend
