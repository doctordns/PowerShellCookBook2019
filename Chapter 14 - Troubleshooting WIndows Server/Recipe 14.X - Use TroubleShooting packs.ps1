#  Recipe 14.3 - Use troubleshooting packs
#
# Run on SRV1

#
#  NB: THis recipe was cut from the book, but here it is.
#  Using Get-TroubleshootingPack with -Answerfile does not work propertly.

# 1. Get Trobleshooting packs
$Path = 'C:\Windows\diagnostics\system'
$TSPackfolders = Get-ChildItem -Path $Path -Directory
$TSPacks =
    Foreach ($TSPack in $TSPackfolders) {
              Get-TroubleshootingPack -Path $TSPack.FullName}

# 2. Display the packs
$FTHT = @{
 Property = 'Name',
            'Version',
            'MinimumVersion',
            'Description'
 Wrap     = $true
 AutoSize = $true
}
$TSPacks | Format-Table @FTHT

# 3. Get a troubleshooting pack
$TsPack = $TSPacks | Where-Object id -eq 'NetworkDiagnostics'

# 4. look at the problems this pack looks for
$TSPack.RootCauses

# 5. And look at the solutions to these issues
$TSPack.RootCauses.Resolutions

# 6. Run this troubleshooting pack
#    (answering questions from the command line)
$TsPack | Invoke-TroubleshootingPack

# 7. Use get-TroubleshootingPack to create an answer file:
$TSHT = @{
  Path       = $TSPack.Path
  AnswerFile = 'c:\Answers.xml'
}
Get-TroubleshootingPack @TSHT

# 8. Display the XML:
Get-Content -Path C:\Answers.xml

# 9. Run WU pack using answer file
$AFHT = @{
  AnswerFile = 'C:\Answers.xml'
  Unattend   = $true
}
$TsPack |
  Invoke-TroubleshootingPack @AFHT
