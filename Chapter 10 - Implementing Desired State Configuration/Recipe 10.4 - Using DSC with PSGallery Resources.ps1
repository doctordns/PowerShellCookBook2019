#   Recipe 13-4 - Using DSC with PS Gallery resources

#  Step 0 - Get Srv2 ready - copy module and update 
#  firewall rule just in case
$CIHT = @{
    Path        = 'C:\Program Files\WindowsPowerShell\Modules\xWebAdministration'
    Destination = '\\srv2\c$\Program Files\WindowsPowerShell\Modules'
    Recurse     = $True
}
Copy-Item @CIHT
$C = {
FHT = @{
DisplayGroup = 'File and Printer Sharing'
Enabled     = 'True'
}
Set-NetFirewallRule @FHT
}
Invoke-Command -ComputerName SRV2 -Script = $C

#  Step 1 - Create Configuration
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
        Log Completed 
        {Message = 'Finished running the RKAPP DSC against SRV2' }         
    }
} # End of onfiguration

# 2. Remove any old MOF files (just in case), then
#    run the configuration block to compile it.
Remove-Item C:\DSC\* -Rec -Force 
Remove-Item '\\SRV2\c$\Windows\System32\configuration\*.mof' `
    -ErrorAction SilentlyContinue
RKAppSRV2 -OutputPath C:\DSC 

# 3. Deploy the configuration to SRV2
Start-DscConfiguration -Path C:\DSC  -Verbose -Wait

# 4. Test Result
$IE = New-Object -ComObject InterNetExplorer.Application
$Uri = 'http://SRV2/ReskitApp/' 
$IE.Navigate2($Uri)
$IE.Visible = $TRUE