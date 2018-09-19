# Recipe 1.1 - Installing RSAT Tools
#
# Uses: DC1, SRV1, CL1

# Run From CL1


#  0 - Setup CL1 for first time
#      Run this the first time you use CL1     

#   Set execution Policy
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
#   Create Local Foo folder
New-Item c:\foo -ItemType Directory -Force
#   Create basic profile and populate
New-Item $profile -Force
'# Profile file created by recipe' | OUT-File $profile
“# Profile for $(hostname)"        | OUT-File $profile -Append
''                                 | OUT-File $profile -Append
'#  Set location'                  | OUT-File $profile -Append
'Set-Location -Path C:\Foo'        | OUT-File $profile -Append
''                                 | OUT-File $profile -Append
'# Set an alias'                   | Out-File $Profile -Append
'Set-Alias gh get-help'            | Out-File $Profile -Append
‘###  End of profile’              | Out-File $Profile -Append
# Now view profile in Notepad
Notepad $Profile
# And update Help
Update-Help -Force
### 

# 1. Get all available PowerShell commands
$CommandsBeforeRSAT = Get-Command -Module *
$CountBeforeRSAT    = $CommandsBeforeRSAT.Count
"On Host: [$(hostname)]"
"Commands available before RSAT installed: [$CountBeforeRSAT]"

# 2. Examine the types of commands returned by Get-Command
$CommandsBeforeRSAT |
  Get-Member |
    Select-Object -ExpandProperty TypeName -Unique


# 3. Get the collection of PowerShell modules and a count of 
#    modules before adding the RSAT tools
$ModulesBefore = Get-Module -ListAvailable 
$CountOfModulesBeforeRSAT = $ModulesBeforeRSAT.count
"$CountOfModulesBefore modules installed prior to adding RSAT"

# 4. Get Windows Client Version and Hardware platform
$Key      = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$CliVer   = (Get-ItemProperty -Path $Key).ReleaseId
$Platform = $ENV:PROCESSOR_ARCHITECTURE
"Windows Client Version : $CliVer"
"Hardware Platform      : $Platform"

# 5. Create URL for download file
#    NB: only works with 1709 and 1803.
$LP1 = 'https://download.microsoft.com/download/1/D/8/'+
       '1D8B5022-5477-4B9A-8104-6A71FF9D98AB/'
$Lp180364 = 'WindowsTH-RSAT_WS_1803-x64.msu'
$Lp170964 = 'WindowsTH-RSAT_WS_1709-x64.msu'
$Lp180332 = 'WindowsTH-RSAT_WS_1803-x86.msu'
$Lp170932 = 'WindowsTH-RSAT_WS_1709-x86.msu'
If     ($CliVer -eq 1803 -and $Platform -eq 'AMD64') {
  $DLPath = $Lp1 + $lp180364}
ELSEIf ($CliVer -eq 1709 -and $Platform -eq 'AMD64') {
  $DLPath = $Lp1 + $lp170964}
ElseIf ($CliVer -eq 1803 -and $Platform -eq 'X86')   {
  $DLPath = $Lp1 + $lp180332}
ElseIf ($CliVer -eq 1709 -and $platform -eq 'x86')   {
  $DLPath = $Lp1 + $lp170932}
Else {"Version $cliver - unknown"; return}

# 6. Display the download details
"RSAT MSU file to be downloaded:"
$DLPath

# 7. Use BITS to download the file
$DLFile = 'C:\foo\Rsat.msu'
Start-BitsTransfer -Source $DLPath -Destination $DLFile

# 8. Check Authenticode signature
$Authenticatefile = Get-AuthenticodeSignature $DLFile
If ($Authenticatefile.status -NE "Valid")
  {'File downloaded fails Authenticode check'}
Else
  {'Downloaded file passes Authenticode check'}

# 9. Install the RSAT tools
$WusaArguments = $DLFile + " /quiet"
'Installing RSAT for Windows 10 - Please Wait...'
$Path = 'C:\Windows\System32\wusa.exe' 
Start-Process -FilePath $Path -ArgumentList $WusaArguments -Wait

# 10. Now that RSAT features are installed, see what commands are available on the client:
$CommandsAfterRSAT        = Get-Command -Module *
$COHT1 = @{
  ReferenceObject  = $CommandsBeforeRSAT
  DifferenceObject = $CommandsAfterRSAT
}
# NB: This is quite slow
$DiffC = Compare-Object @COHT1
"$($DiffC.count) Commands added with RSAT"

# 11. Check how many modules are now available:
$ModulesAfterRSAT        = Get-Module -ListAvailable 
$CountOfModulesAfterRsat = $ModulesAfterRSAT.count
$COHT2 = @{
  ReferenceObject  = $ModulesBeforeRSAT
  DifferenceObject = $ModulesAfterRSAT
}
$DiffM = Compare-Object @COHT2
"$($DiffM.count) Modules added with RSAT to CL1"
"$CountOfModulesAfterRsat modules now available on CL1"

# 12. Display modules added to CL1
"$($DiffM.count) modules added With RSAT tools to CL1"
$DiffM | Format-Table InputObject -HideTableHeaders


###  NOW Add RSAT to Server


# 13. Get Before Counts
$FSB1 = {Get-WindowsFeature}
$FSRV1B = Invoke-Command -ComputerName SRV1 -ScriptBlock $FSB1
$FSRV2B = Invoke-Command -ComputerName SRV2 -ScriptBlock $FSB1
$FDC1B  = Invoke-Command -ComputerName DC1  -ScriptBlock $FSB1
$IFSrv1B = $FSRV1B | Where-object installed
$IFSrv2B = $SRV2B  | Where-Object installed
$IFDC1B  = $FDC1B  | Where-Object installed 
$RFSrv1B = $FeaturesSRV1B |
              Where-Object Installed | 
                Where-Object Name -Match 'RSAT'
$RFSSrv2B = $FeaturesSRV2B | 
              Where-Object Installed | 
                Where-Object Name -Match 'RSAT'
$RFSDC1B = $FeaturesDC1B | 
             Where-Object Installed |
               Where-Object Name -Match 'RSAT'

# 14. Display before counts
"Before Installation of RSAT tools on DC1, SRV1"
"$($IFDC1B.count) features installed on DC1"
"$($RFSDC1B.count) RSAT features installed on DC1"
"$($IFSrv1B.count) features installed on SRV1"
"$($RFSrv1B.count) RSAT features installed on SRV1"
"$($IFSrv2B.count) features installed on SRV2"
"$($RFSSRV2B.count) RSAT features installed on SRV2"

# 15.  Add the RSAT tools to Servers SRV1. SRV2, and DC1
#      SRV2 is base Windows Server 2019 loaded
#      SRV1 is base windows Server 2019 loaded withb a few tools
#      DC1 is a server that is also a DC and a DNS Server.
$InstallSB = {
  Get-WindowsFeature -Name *RSAT* | Install-WindowsFeature
}
$I = Invoke-Command -ComputerName SRV1 -ScriptBlock $InstallSB
$I
If ($I.RestartNeeded -eq 'Yes') {
  "Restarting SRV1"
  Restart-Computer -ComputerName SRV1 -Force -Wait -For PowerShell
}


# 16. Get Details of RSAT tools on SRV1 vs SRV2
$FSB2 = {Get-WindowsFeature}
$FSRV1A = Invoke-Command -ComputerName SRV1 -ScriptBlock $FSB2
$FSRV2A = Invoke-Command -ComputerName SRV2 -ScriptBlock $FSB2
$IFSrv1A = $FSRV1A | Where-Object Installed
$IFSrv2A = $FSRV2A | Where-Object Installed
$RSFSrv1A = $FSRV1A | Where-Object Installed | 
              Where-Object Name -Match 'RSAT'
$RFSSrv2A = $FSRV2A | Where-Object Installed |
              Where-Object Name -Match 'RSAT'

# 17. Display after effects
"After Installation of RSAT tools on SRV1"
"$($IFSRV1A.count) features installed on SRV1"
"$($RSFSrv1A.count) RSAT features installed on SRV1"
"$($IFSRV2A.count) features installed on SRV2"
"$($RFSSRV2A.count) RSAT features installed on SRV2"
