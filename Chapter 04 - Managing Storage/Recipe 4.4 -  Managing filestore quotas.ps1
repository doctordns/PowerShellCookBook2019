# 4.4 - Managing filestore quotas
# 
# Run on SRV1, with SRV2, DC1 online


# 1.Install FS Resource Manager feature
$IHT = @{
  Name                   = 'FS-Resource-Manager' 
  IncludeManagementTools = $True
}
Install-WindowsFeature @IHT

# 2. Set SMTP settings in FSRM
$MHT = @{
  SmtpServer        = 'SRV1.Reskit.Org'   # Previously setup 
  FromEmailAddress  = 'FSRM@Reskit.Org'
  AdminEmailAddress = 'Doctordns@Gmail.Com'
}
Set-FsrmSetting @MHT

# 3. Send a test email to check the setup
$MHT = @{
ToEmailAddress = 'DoctorDNS@gmail.com'
Confirm        = $false
}
Send-FsrmTestEmail @MHT

# 4. Create a new FSRM quota template for a 10MB limit
$QHT1 = @{
Name        = 'TenMB Limit'
Description = 'Quota of 10 MB'
Size        = 10MB
}
New-FsrmQuotaTemplate @QHT1

# 5. Create another quota template for 5mb
$QHT2 = @{
Name        = 'Soft 5MB Limit'
Description = 'Soft Quota of 5mb'
Size        = 5mb
SoftLimit   = $True
}
New-FsrmQuotaTemplate @QHT2

# 6. View available FSRM quota templates
Get-FsrmQuotaTemplate |
  Format-Table -Property Name, Description, Size, SoftLimit
  
# 7. Create two new folders on which to place quotas
If (-Not (Test-Path C:\Quota)) {
  New-Item -Path C:\Quota -ItemType Directory  |
    Out-Null
}
If (-Not (Test-Path C:\QuotaS)) {
  New-Item -Path C:\QuotaS -ItemType Directory  |
    Out-Null
}

# 8. Create a FSRM action for threshold exceeded
$Body = @'
User [Source Io Owner] has exceeded the [Quota Threshold]% quota threshold for 
the quota on [Quota Path] on server [Server].  The quota limit is [Quota Limit MB] MB, 
and [Quota Used MB] MB currently is in use ([Quota Used Percent]% of limit).
'@
$NAHT = @{
Type      = 'Email'
MailTo    = 'Doctordns@gmail.Com'
Subject   = 'FSRM Over limit [Source Io Owner]'
Body      = $Body
}
$Action1 = New-FsrmAction @NAHT

# 9. Create a FSRM action for soft threshold exceeded 
$Thresh = New-FsrmQuotaThreshold -Percentage 85 -Action $Action1

# 10. Create a soft 10 MB quota on C:\Quotas folder with threashold
$NQHT1 = @{
  Path      = 'C:\QuotaS'
  Template  = 'Soft 5MB Limit'
  Threshold = $Thresh
}
New-FsrmQuota @NQHT1

# 11. Now test 85% SOFT quota limit on C:\QuotaS
Get-ChildItem c:\quotas -Recurse | Remove-Item -Force
$S = '42'
1..24 | foreach {$s = $s + $s}
$S | Out-File -FilePath C:\QuotaS\Demos.txt
Get-ChildItem -Path C:\QuotaS\Demos.txt

# 12. View mail received
#  View via Outlook

# 13. Create a second Threshold Action to log to the applicationlog
$Action2 = New-FsrmAction -Type Event -EventType Error
$Action2.Body = $Body

# 14. Create two quota thresholds for a new quota
$Thresh2 = New-FsrmQuotaThreshold -Percentage 65 
$Thresh3 = New-FsrmQuotaThreshold -Percentage 85 
$Thresh2.Action = $Action2
$Thresh3.Action = $Action2  # same action details 


# 15. Create a hard quota, with two thresholds and,
#     related threshold actions, based on a template
$NQHT = @{
Path        = 'C:\Quota'
Template    = 'TenMB Limit'
Threshold   =  ($Thresh2, $Thresh3)
Description = 'Hard Threshold with2 actions'
}
New-FsrmQuota @NQHT 

# 16. Remove existing files if any
Get-ChildItem C:\Quota -Recurse | Remove-Item -Force


# 17. Test hard limit on C:\Quota
$URK = "ThomasL@reskit.org"
$PRK = ConvertTo-SecureString 'Pa$$w0rd' -AsPlainText -Force
$CredRK = New-Object system.management.automation.PSCredential $URK,$PRK
$SB = {
  $S = '42'
  1..27 | foreach {$s = $s + $s}
  $S | Out-File -FilePath C:\Quota\Demos.Txt -Encoding ascii
  $Len = (Get-ChildItem -Path C:\Quota\Demos.Txt).Length}
$ICMHT = @{
  ComputerName = 'SRV1'
  Credential   = $CredRK
  ScriptBlock  = $SB}
Invoke-Command -ComputerName SRV1 -Credential $CredRK -ScriptBlock $SB

# 18. View event logs
Get-EventLog -LogName Application -Source SRMSVC  | 
  Format-Table -AutoSize -Wrap
