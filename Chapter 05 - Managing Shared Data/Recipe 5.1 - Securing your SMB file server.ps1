# Recipe 5.1 - Securing your SMB file erver
# Run on FS1

# 1. - Add File Server features to FS1
$Featuers = 'FileAndStorage-Services','File-Services',
            'FS-FileServer','RSAT-File-Services'
Add-WindowsFeature -Name $Featuers


# 2. ` Retreive SMB Server settings
Get-SmbServerConfiguration

# 3. - Turn off SMB1 
$CHT = @{
  EnableSMB1Protocol = $false 
  Confirm            = $false
}
Set-SmbServerConfiguration @CHT

# 4.Turn on SMB signing and encryption
$SHT1 = @{
    RequireSecuritySignature = $true
    EnableSecuritySignature  = $true
    EncryptData              = $true
    Confirm                  = $false
}
Set-SmbServerConfiguration @SHT1

# Step 5 - Turn off default server and workstations shares 
$SHT2 = @{
    AutoShareServer       = $false
    AutoShareWorkstation  = $false
    Confirm               = $false
}
Set-SmbServerConfiguration @SHT2

# Step 6 - turn off server announcements
$SHT3 = @{
    ServerHidden   = $true
    AnnounceServer = $false
    Confirm        = $false
}
Set-SmbServerConfiguration @SHT3

# Step 7 - restart the service with the new configuration
Restart-Service lanmanserver


<# undo and set back to defults

Get-SMBShare foo* | remove-SMBShare -Confirm:$False

Set-SmbServerConfiguration -EnableSMB1Protocol $true `
                           -RequireSecuritySignature $false `
                           -EnableSecuritySignature $false `
                           -EncryptData $False `
                           -AutoShareServer $true `
                           -AutoShareWorkstation $false `
                           -ServerHidden $False `
                           -AnnounceServer $True
Restart-Service lanmanserver
#>
