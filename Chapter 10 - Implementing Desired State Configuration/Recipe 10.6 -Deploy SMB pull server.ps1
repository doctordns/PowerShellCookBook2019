#  Recipe 13-6 - Implemeinting an SMB pull servrer
#  

# 0 Check that the xSMBShare module is installed
Install-Module -Name xSmbShare -Force

# 1. Create Local Configuration block
Configuration PullSrv1
{
 Import-DscResource -ModuleName PSDesiredStateConfiguration
 Import-DscResource -ModuleName xSmbShare
 File ConfigFolder
      { DestinationPath = 'C:\DSCConfiguration'
        Type        = 'Directory'
        Ensure      = 'Present' }
File ResourceFolder 
      { DestinationPath = 'C:\DscResource'
        Type        = 'Directory'
        Ensure      = 'Present' }
xSmbShare DscConfiguration 
      { Name        = 'DSCConfiguration'
        Path        = 'C:\DscConfiguration\'
        DependsOn   = '[File]ConfigFolder'
        Description = 'DSC Configuration Share'
        Ensure      = 'Present' }
xSmbShare DscResource 
     {  Name        = 'DSCResource'
        Path        = 'C:\DscResource'
        DependsOn   = '[File]ResourceFolder'
        Description = 'DSC Resource Share'
        Ensure      = 'Present' }
}

# 2. Remove existing MOF Files then create MOF file
New-Item -Path C:\DSC -ItemType Directory `
         -ErrorAction SilentlyContinue | Out-Null
Get-ChildItem -Path C:\DSC | Remove-Item -Force | Out-Null
Remove-Item 'C:\Windows\System32\configuration\*.mof' `
            -ErrorAction SilentlyContinue
PullSrv1 -OutputPath C:\DSC

# 3. Configure Local host
Start-DscConfiguration -Path C:\DSC -Wait -Verbose

# 4. Get shares
Get-SMBShare -Name DSC*

# 5. Create new configuration for SRV2
Configuration  TelnetSRV2
{
Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
Node SRV2
{
    WindowsFeature TelnetSRV2
    { Name     = 'Telnet-Client'
      Ensure   = 'Present'  }
}
}

# 6. Create a MOF file for the Configuration
TelnetSRV2 -OutputPath C:\DSCConfiguration

# 7. Rename the MOF File with the GUID name
$Guid = '5d79ee6e-0420-4c98-9cc3-9f696901a816'
Rename-Item  -Path    'C:\DSCConfiguration\SRV2.mof' `
             -NewName "C:\DSCConfiguration\$Guid.MOF"

# 8. Create MOF Checkshum
New-DscChecksum -Path C:\DSCConfiguration

# 9. View MOF and checksum files
Get-ChildItem C:\DSCConfiguration

# 10. Check presence of Telnet client on SRV2
Get-WindowsFeature -Name Telnet-Clinet -ComputerName SRV2
