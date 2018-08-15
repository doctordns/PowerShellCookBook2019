# Recipe 1.1 - Installing RSAT Tools
#
# Uses: DC1, SRV1, CL1
# Run From CL1

# 1. Get all available PowerShell commands prior to installing RSAT tools
$CommandsBeforeRSAT        = Get-Command 
$CountOfCommandsBeforeRSAT = $CommandsBeforeRSAT.count
"Commands available on [$(hostname)] before RSAT installed: [$CountOfCommandsBeforeRSAT]"

# 2. Examine the types of objects returned by Get-Command:
$CommandsBeforeRSAT | Get-Member |
    Select-Object -ExpandProperty TypeName -Unique

# 3. View commands in Out-GridView:
$CommandsBeforeRSAT |
  Select-Object -Property Name, Source, CommandType |
    Sort-Object -Property Source, Name |
      Out-GridView

# 4. Store the collection of PowerShell modules and a count into variables as well:
$ModulesBeforeRSAT = Get-Module -ListAvailable 
$CountOfModulesBeforeRSAT = $ModulesBeforeRSAT.count
"$CountOfModulesBeforeRSAT modules are installed prior to adding RSAT"

# 5. View modules in Out-GridView:
$ModulesBeforeRSAT |
   Select-Object -Property Name,Description -Unique |
     Sort-Object -Property Name|
       Out-GridView

# 6. Review the RSAT Windows Features available and their installation status:
Get-WindowsFeature -Name RSAT*

# 7. Perform information gathering on DC1, SRV1
$SB = {
    "On Host: [$(hostname)]:"
    $CommandsBefore = Get-Command 
    $CountBefore = $CommandsBefore.count
    "  Commands available before RSAT installed: [$CountBefore]"
    $ModulesBeforeRSAT = Get-Module -ListAvailable 
    $CountOfModulesBeforeRSAT = $ModulesBeforeRSAT.count
    "  $CountOfModulesBeforeRSAT modules are installed prior to adding RSAT"
}
Invoke-Command -ComputerName DC1 -ScriptBlock $SB
"On DC1:"
"On SRV1"

#8. Get Windows Client Version and platform
$CliVer = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ReleaseId
$Platfm = $ENV:PROCESSOR_ARCHITECTURE

# 9. Create URL for download file
$LP1 = 'https://download.microsoft.com/download/1/D/8/1D8B5022-5477-4B9A-8104-6A71FF9D98AB/'
$Lp180364 = 'WindowsTH-RSAT_WS_1803-x64.msu'
$Lp170964 = 'WindowsTH-RSAT_WS_1709-x64.msu'
$Lp180332 = 'WindowsTH-RSAT_WS_1803-x86.msu'
$Lp170932 = 'WindowsTH-RSAT_WS_1709-x86.msu'
If     ($CliVer -eq 1803 -and $Platfm -eq 'AMD64') {$DLPath = $Lp1 + $lp180364}
ELSEIf ($CliVer -eq 1709 -and $Platfm -eq 'AMD64') {$DLPath = $Lp1 + $lp170964}
ElseIf ($CliVer -eq 1803 -and $Platfm -eq 'X86')   {$DLPath = $Lp1 + $lp180332}
ElseIf ($CliVer -eq 1709 -and $platfm -eq 'x86')   {$DLPath = $Lp1 + $lp170932}
Else {Write-Output "Version $cliver - unknown"; return}
Write-Host "Downloading RSAT MSU file [$DLPath]" 

# 10. Download the file
$DLFile = 'C:\foo\Rsat.msu'
Start-BitsTransfer -Source $DLPath -Destination $DLFile

# 11. Check authenticode signature
$Authenticatefile = Get-AuthenticodeSignature $DLFile
If ($Authenticatefile.status -NE "Valid")
{ Write-Output 'File downloaded fails authenitcode check'}

# 12. Run the RSAT tools
$WusaArguments = $DLFile + " /quiet"
Write-host "Installing RSAT for Windows 10 - please wait" -foregroundcolor yellow
Start-Process -FilePath "C:\Windows\System32\wusa.exe" -ArgumentList $WusaArguments -Wait

# 13. Examine RSAT Tools on CL1
Add-WindowsCapability -Online -Name RSAT* | Sort-Object -Property FeatureName
    Format-Table 

# 14. Add them all
$Features = Get-WindowsCapability -online -Name RSAT* 
Write-Output "$($Features.count) RSAT Features"
$Features = Add-WindowsCapability -OnLine

# 15. Now that RSAT features are installed, see what commands are available on the client:
$CommandsAfterRSAT        = Get-Command 
$CountOfCommandsAfterRSAT = $CommandsBeforeRSAT.count
Write-Output "$CountofCommandsAfterRsat commands"

# 16. View commands in Out-GridView:
$CommandsAfterRSAT |
   Select-Object -Property Name, Source, CommandType |
     Sort-Object -Property Source, Name |
       Out-GridView
  
# 17. Now check how many modules are available:
$ModulesAfterRSAT        = Get-Module -ListAvailable 
$CountOfModulesAfterRsat = $ModulesAfterRSAT.count
Write-OUtout "$CountOfModulesAfterRsat modules"

# 18. View modules in Out-GridView:
$ModulesAfterRSAT | Select-Object -Property Name -Unique |
   Sort-Object -Property Name |
     Out-GridView

# 19. Install RSAT with sub features and management tools on DC1 and SRV1
$SB = {
  Get-WindowsFeature -Name *RSAT* |
    Install-WindowsFeature
}
$Computers = @('DC1', 'SRV1')
Invoke-Command -Scriptblock $SB -ComputerName $Computers                -Credential $CredRK



