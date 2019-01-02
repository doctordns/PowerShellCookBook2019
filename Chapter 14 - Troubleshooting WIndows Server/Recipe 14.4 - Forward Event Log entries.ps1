#  Recipe 14.4 - Forward event logs from SRV1 to SRV2
#  Run First part on SRV2 to setup SRV2 as a collector
#  Ensure RSAT AD DS Tools and GPMC featurs are loaded

# 1. Ensure SRV2, SRV1 are in the correct OU (IT)
Get-ADComputer -Identity SRV1 | 
  Move-ADObject -TargetPath 'OU=IT,DC=Reskit,DC=ORG'
Get-ADComputer -Identity SRV2 | 
  Move-ADObject -TargetPath 'OU=IT,DC=Reskit,DC=ORG'

# 2. Create the collector security group
$ECGName = 'Event Collection Group'
$Path = 'OU=IT,DC=Reskit,DC=Org'
New-ADGroup -Name $ECGName -GroupScope Global -Path  $Path

# 3. Add SRV2 to event collectors group
Add-ADGroupMember -Identity $ECGName -Members 'SRV2$'

# 4. View membership of Event Collection Group
Get-ADGroupMember -Identity $ECGName |
  Format-Table Name,DistinguishedName

# 5. Create a new GPO to configure event collection on SRV2
$GpoName = 'Event Collection'
$Gpo  = New-GPO $GpoName

# 6. Link new GPO to IT OU Systems 
$Link = New-GPLink -Name $GPOName -Target "OU=IT,DC=Reskit,DC=Org"

# 7. Set permissions to GPO - Ensure members of the Event Collection
#    Group can apply this policy, and no one else can.
$GPHT1 = @{
  Name            = $GPOName
  TargetName      = 'Event Collection Group'
  TargetType      = 'Group'
  PermissionLevel = 'GpoApply'
}
$P1 = Set-GPPermission @GPHT1 -Confirm:$False
$GPHT2 = @{
  Name            = $GPOName
  TargetName      = 'Authenticated Users'
  TargetType      = 'Group'
  PermissionLevel = 'None'
}
$P2 = Set-GPPermission @GPHT2 -Confirm:$False

# 8. Apply the registry settings to configure the EC GPO:
# first ensure WINRM on target system is listening for WINRM requests
$WinRMKey='HKLM\Software\Policies\Microsoft\Windows\WinRM\Service'
$RVHT1 = @{
  Name      = 'Event Collection'
  Key       = $WinRMKey
  ValueName = 'AllowAutoConfig'
  Type      = 'DWORD' 
  Value     = 1
}
$RV1 = Set-GPRegistryValue  @RVHT1
# Listen on all IPv4 addressess
$RVHT2 = @{
  Name      = 'Event Collection'
  Key       = $WinRMKey
  ValueName = 'IPv4Filter'
  Type      = 'STRING'
  Value     = '*'
}
$RV2 = Set-GPRegistryValue @RVHT2
# And listen on IPv6 addresses too
$RVHT3 = @{
  Name      = 'Event Collection'
  Key       = $WinRMKey
  ValueName = 'IPv6Filter'
  Type      = 'STRING'
  Value     = '*'
}
$RV3 = Set-GPRegistryValue @RVHT3

# 9. Enable and configure Windows Event Collector on the collector system on SRV2.
Stop-Service -Name Wecsvc 
wecutil qc -q
Start-Service -Name Wecsvc 

# 10. Just in case create c:\foo
$NIHT = @{
 Path        = 'C:\Foo'
 ItemType    = 'Directory'
 ErrorAction = 'Silentlycontinue'
}
New-Item  @NIHT

# 11. Create XML file to describe event to be forwarded
$xmlfile = @'
<Subscription xmlns="http://schemas.microsoft.com/2006/03/windows/events/subscription">
<SubscriptionId>FailedLogins</SubscriptionId>
<SubscriptionType>SourceInitiated</SubscriptionType>
<Description>Collects failed logins to SRV1</Description>
<Enabled>true</Enabled>
<Uri>http://schemas.microsoft.com/wbem/wsman/1/windows/EventLog</Uri>
<ConfigurationMode>Custom</ConfigurationMode>
<Delivery Mode="Push">
<Batching>
 <MaxItems>1</MaxItems>
 <MaxLatencyTime>1000</MaxLatencyTime>
</Batching>
<PushSettings>
<Heartbeat Interval="60000"/>
</PushSettings>
</Delivery>
<Expires>2020-01-01T00:00:00.000Z</Expires>
<Query>
<![CDATA[
<QueryList>
<Query Path="Security">
<Select>Event[System/EventID='4625']</Select>
</Query>
</QueryList>]]>
</Query>
<ReadExistingEvents>true</ReadExistingEvents>
<TransportName>http</TransportName>
<ContentFormat>RenderedText</ContentFormat>
<Locale Language="en-US"/>
<LogFile>ForwardedEvents</LogFile>
<AllowedSourceNonDomainComputers>
</AllowedSourceNonDomainComputers>
<AllowedSourceDomainComputers>O:NSG:NSD:(A;;GA;;;DC)(A;;GA;;;NS)
</AllowedSourceDomainComputers>
</Subscription>
'@
$xmlfile | Out-File -FilePath C:\Foo\FailedLogins.XML

# 12. Now register this with the WEC on SRV1
wecutil cs C:\foo\FailedLogins.XML

# 13. enumerate the subscriptions to see ours
wecutil es

# 14. Configure Security for Event Readers Group
Add-LocalGroupMember -Name 'Event Log Readers' -Member 'Network Service'

# 15. Next, create the event source security group:
New-ADGroup -Name 'Event Source' -GroupScope Global
Add-ADGroupMember -Identity "Event Source" -Members 'SRV1$'

# 15. Create the GPO for the event source systems and link it
#     to the IT OU
New-GPO -Name 'Event Source'
New-GPLink -Name 'Event Source' -Target 'OU=IT,DC=Reskit,DC=Org'

# 16. Set GPO permissions
$GPHT3 = @{
  Name            = 'Event Source'
  TargetName      = 'Event Source' # group name
  TargetType      = 'Group'
  PermissionLevel = 'GpoApply'
}
Set-GPPermission @GPHT3
$GPHT4 = @{
  Name            = 'Event Source'
  TargetName      = 'Authenticated Users' #everyone else
  TargetType      = 'Group'
  PermissionLevel = 'None'  
}
Set-GPPermission @GPHT4   # generates a warning

# 17. Apply the settings for the source GPO to point to SRV2:
$EventKey='HKLM\Software\Policies\Microsoft\' +
          'Windows\EventLog\EventForwarding\SubscriptionManager'
$TargetAddress= 'Server=http://SRV2.reskit.org:5985/wsman' +
                '/SubscriptionManager/WEC'
$GPRHT1 = @{
  Name      = 'Event Source'
  Key       = $EventKey
  ValueName = '1'
  Type      = 'STRING'
  Value     = $TargetAddress
}
Set-GPRegistryValue @GPRHT1

# 18. Restart SRV1 to pick up the new policy:
Restart-Computer SRV1 -Force -wait 

# 19. Once SRV1 has rebooted, attempt to login interactively
#     to Srv1 using incorrect credentials

# 20. View status of FailedLogins subscription
wecutil gr failedlogins

# 21. Examine Failed Logins Directly from SRV1
$FilterHT = @{LogName='Security'; id = '4625'}
$Events = Get-WinEvent -ComputerName SRV1  -FilterHashTable $FilterHT
Foreach ($Event in $Events)  {
$User = $Event |
  Select-Object -ExpandProperty Properties |
    Select-Object -Skip 5 -First 1
"Failed UserName: {0,16} at {1,-40}" -f $User.Value,$Event.TimeCreated
}

####  EVERYTHING WORKS TO HERE..
#### IN STEP 22, no events get forwarded.

# 22. Now read the forwarded events:
$BadLogins = Get-WinEvent -LogName ForwardedEvents
"$($BadLogins.Count) Events forwarded"
Foreach ($Badlogin in $Badlogins)
{
  $Obj       = [Ordered] @{}
  $Obj.time  = $BadLogins.TimeCreated
  $Obj.logon = ($BadLogins |
                Select-Object -ExpandProperty Properties).Value|
                 Select-Object -Skip 5 -First 1
  New-Object -TypeName PSobject -Property $Obj
}