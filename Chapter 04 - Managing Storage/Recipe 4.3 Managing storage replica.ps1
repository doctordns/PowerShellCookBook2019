# 4.3 - Manage Storage replica
# 
# Run on SRV1, with SRV2, DC1 online


# 1. Create Content on F:
1..100 | ForEach {
  $NF = "F:\CoolFolder$_"
  New-Item -Path $NF -ItemType Directory | Out-Null
  1..100 | ForEach {
    $NF2 = "$NF\CoolFile$_"
    "Cool File" | Out-File -PSPath $NF2
  }
}

# 2. Show what is on F: locally
Get-ChildItem -Path F:\ -Recurse | Measure-Object

# 3. And examine the same drives remotely on SRV2
$SB = {
  Get-ChildItem -Path F:\ -Recurse |
    Measure-Object
}
Invoke-Command -ComputerName SRV2 -ScriptBlock $SB

# 4. Add storage replica feature to SRV1
Add-WindowsFeature -Name Storage-Replica

# 5. Restart SRV1 to finish the installation process
Restart-Computer

# 6. Add SR Feature to SRV2
$SB= {
  Add-WindowsFeature -Name Storage-Replica | Out-Null
}
Invoke-Command -ComputerName SRV2 -ScriptBlock $SB

# 7. And restart SRV2 Waiting for the restart
$RSHT = @{
  ComputerName = 'SRV2'
  Force        = $true
}
Restart-Computer @RSHT -Wait -For PowerShell

# 8. Create an SR Replica
$SRHT =  @{
  SourceComputerName       = 'SRV1'
  SourceRGName             = 'SRV1RG'
  SourceVolumeName         = 'F:'
  SourceLogVolumeName      = 'G:'
  DestinationComputerName  = 'SRV2'
  DestinationRGName        = 'SRV2RG'
  DestinationVolumeName    = 'F:'
  DestinationLogVolumeName = 'G:'
  LogSizeInBytes           = 2gb
}
New-SRPartnership @SRHT -Verbose 

# 9. View it
Get-SRPartnership

# 10. And examine the same drives remotely on SRV2
$SB = {
  Get-Volume |
    Sort-Object -Property DriveLetter |
      Format-Table   
}
Invoke-Command -ComputerName SRV2 -ScriptBlock $SB


# 11. Reverse the replication
$SRHT2 = @{ 
  NewSourceComputerName   = 'SRV2'
  SourceRGName            = 'SRV2RG' 
  DestinationComputerName = 'SRV1'
  DestinationRGName       = 'SRV1RG'
  Confirm                 = $false
}
Set-SRPartnership @SRHT2


# 12 View RG
Get-SRPartnership

# 13. Examine the same drives remotely on SRV2
$SB = {
  Get-ChildItem -Path F:\ -Recurse |
    Measure-Object
}
Invoke-Command -ComputerName SRV2 -ScriptBlock $SB

