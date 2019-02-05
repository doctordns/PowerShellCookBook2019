#   Recipe 10.4 - Using DSC with PS Gallery resources
#  
# Run on SRV1  After 10.3 (Getting resources)

#  Step 1 - Copy xWebAdministration module to SRV2

$CIHT = @{
  Path        = 'C:\Program Files\WindowsPowerShell\' +
                'Modules\xWebAdministration'
  Destination = '\\SRV2\C$\Program Files\WindowsPowerShell\'+
                'Modules'
  Recurse     = $True
}
Copy-Item @CIHT

# 2. Clear any existing Configuration documents on SRV, and local mof files
$RIHT =@{
  Path        = '\\SRV2\c$\Windows\System32\configuration\*.mof'
  ErrorAction = 'SilentlyContinue'
}
Get-Childitem @RIHT |
  Remove-Item @RIHT -Force
Remove-Item C:\DSC\* -Recurse -Force 

# 3. Create Configuration:
Configuration  RKAppSRV2 {
  Import-DscResource -ModuleName xWebAdministration
  Import-DscResource -ModuleName PSDesiredStateConfiguration
  Node SRV2 {
    Windowsfeature IISSrv2 {
      Ensure = 'Present' 
      Name = 'Web-Server' 
    }
    Windowsfeature IISSrvTools {
      Ensure = 'Present' 
      Name = 'Web-Mgmt-Tools'
      DependsOn = '[WindowsFeature]IISSrv2' 
    } 
    File RKAppFiles {
      Ensure = 'Present'
      Checksum = 'ModifiedDate'
      Sourcepath = '\\DC1\ReskitApp\'
      Type = 'Directory'
      Recurse = $true
      DestinationPath = 'C:\ReskitApp\'    
      DependsOn = '[Windowsfeature]IISSrv2'
      MatchSource = $true 
    }
    xWebAppPool ReskitAppPool {
      Name = 'RKAppPool'
      Ensure = 'Present'
      State = 'Started'
      DependsOn = '[File]RKAppFiles' 
    }
    xWebApplication ReskitAppPool {
      Website = 'Default Web Site'
      WebAppPool = 'RKAppPool'
      Name = 'ReskitApp'
      PhysicalPath = 'C:\ReskitApp\'
      Ensure = 'Present'
      DependsOn = '[xWebAppPool]ReskitAppPool' 
    } 
    Log Completed {
      Message = 'Finished Configuring ReskitAp via DSC against SRV2'
    }         
    } # End of SRV2 Configuration
} # End of Configuration

# 4. Run the configuration block to compile it
RKAppSRV2 -OutputPath C:\DSC 

# 5. Deploy the configuration to SRV2
Start-DscConfiguration -Path C:\DSC  -Verbose -Wait

# 6. Test Result
Start-Process 'http://SRV2/ReskitApp/' 
