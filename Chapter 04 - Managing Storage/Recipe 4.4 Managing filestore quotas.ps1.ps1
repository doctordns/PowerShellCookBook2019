# 4.4 - Managing filestore quotas
# 
# Run on SRV1, with SRV2, DC1 online


# 1.Install FS Resource Manager feature
$IHT = @{
  Name                   = 'FS-Resource-Manager' 
  IncludeManagementTools = $True
}
Install-WindowsFeature @IHT

# 2. Set SMTP settings on FSRM
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

# 4. Create a new FSRM quota template for a 10mb limit
$QHT1 = @{
Name        = 'TenMB Limit'
Description = 'Quota of 10 MB'
Size        = 10mb
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

# 9. Create a Threshold with associated action
$Thresh = New-FsrmQuotaThreshold -Percentage 85 -Action $Action1

# 10. Create a soft 10 MB quota on C:\Quotas folder with threashold
$NQHT = @{
Path      = 'C:\QuotaS'
Template  = 'Soft 5MB Limit'
Threshold = $Thresh
}
New-FsrmQuota @NQHT

# 12. Now test 85% SOFT quota limit on C:\QuotaS
Get-ChildItem c:\quotas -Recurse | Remove-Item -Force
$S = '42'
1..24 | foreach {$s = $s + $s}
$S | Out-File -FilePath C:\QuotaS\Demos.txt
Get-ChildItem -Path C:\QuotaS\Demos.txt

# 13. Test over use of soft quota
Get-ChildItem C:\quotas -Recurse | Remove-Item -Force
$S = '42'
1..26 | foreach {$s = $s + $s}
$S | Out-File -FilePath C:\QuotaS\Demos.txt
Get-ChildItem -Path C:\QuotaS\Demos.txt

# 14. View the email that results
#  View via Outlook

# 15. Create a Threshold Action to log to the error log
$Action2 = New-FsrmAction -Type Event -EventType Error
$Action2.Body = $Body

# 16. Create two quota thresholds 
$Thresh2 = New-FsrmQuotaThreshold -Percentage 65 
$Thresh3 = New-FsrmQuotaThreshold -Percentage 85 
$Thresh2.Action = $Action2
$Thresh3.Action = $Action2


# 17. Create a hard quota, with two thresholds,
#     based on a template
$NQHT = @{
Path      = 'C:\Quota'
Template  = 'TenMB Limit'
Threshold =  $Thresh2,$Thresh3
}
New-FsrmQuota @NQHT

# 18. Test hard quota
Get-ChildItem C:\Quota -Recurse | Remove-Item -Force
$S = '42'
1..27 | foreach {$s = $s + $s}
"`$S is $((($s.length)/1mb).tostring('N0'))MB long"
$S | out-file -FilePath C:\Quota\demos.txt -Encoding ascii
$Len = (Get-ChildItem -Path c:\Quota\demos.txt).Length
"Output file is $(($Len/1MB).ToString('N0'))MB long"
