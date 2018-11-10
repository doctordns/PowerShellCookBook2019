<#
    .Synopsis
    Purpose:  Modifies Printer Permissions.

    .DESCRIPTION 
    This script was created to modify the DACL of printer objects.  It can be
    used to add specific permissions or remove permissions from printers on 
    the localhost or a specified server.
    
    See -full help for example usage.  If no parameters are set, aside from the
    mandatory AccountName, it will set the "Print" permission on all printers
    of the host it is ran on.      
    
    As an alternative to this script, something like SubInACL.exe can be used 
    to alter printer permissions.
        
	.PARAMETER ServerName
    Specify the SamAccountName of a server on which to modify printer permissions.

    .PARAMETER AccountName
    Mandatory. Specify the sAMAccountName, or userPrincipalName, of a User or Group
    on which to modify or create permissions.

    .PARAMETER SinglePrinterName
    Specify an individual printer to modify permissions on. If no printer is
    specified, all printers on the target server will be updated.

    .PARAMETER AccessMask
    The permission Access Mask to be applied. Only relevant printer bit masks represented.
    "ManagePrinters","ManageDocuments","Print","TakeOwnership","ReadPermissions",
     or "ChangePermissions". The default value for this is Print.

    .PARAMETER Deny
    AccessMask AccessType will be set to "Deny".  Default is to "Allow"

    .PARAMETER Remove
    Removes all Access Control Entries associated with the specified Account Name.

    .PARAMETER AceFlag
    A bit flag that indicates permission propagation:
    0x0001 - OBJECT_INHERIT_ACE
    0x0002 - CONTAINER_INHERIT_ACE
    0x0004 - NO_PROPAGATE_INHERIT_ACE
    0x0008 - INHERIT_ONLY_ACE
    0x0010 - INHERITED_ACE
    	
    .PARAMETER IntAccessMask
    uint32 representation of an access mask.  If used, it overrides the AccessMask
    parameter.

    .PARAMETER NoLog
    Specify not to create a log file.

    .PARAMETER LogFile
    The path and file name of the desired log file. "C:\Logfile.txt"

    .Example 
    .\Set-PrinterPermissions -AccountName "ServerAdmins" -AccessMask ManageDocuments
    Grants a "ServerAdmins" group the ManageDocuments permission on all printers of
    the executing host.  Creates a log in the executing directory.
    
    .Example
    .\Set-PrinterPermissions -AccountName "bob" -Remove -NoLog
    Removes all Access Control Entries associated with "bob" on all printers
    of the executing host. Specifies not to create a log.

    .Example
    .\Set-PrinterPermissions -ServerName "PrtSrv1" -AccountName "alice@upn.loc" -AccessMask Print -SinglePrinterName "Printer1"
    Gives alice@upn.loc the Print permission on "Printer1" located on the 
    server "PrtSrv1". Creates a log in the executing directory. 

    .Example    
    .\Set-PrinterPermissions -ServerName "PrtSrv2" -AccountName "bob" -AccessMask ChangePermissions -Deny -LogFile "C:\ScriptLogs\aLogFile.txt"
    Denies bob the ChangePermissions permission on all printers on the
    "PrtSrv2" server.  Writes the log to the "aLogFile.txt" file in the
    "C:\ScriptLogs" directory.

    .Example 
    .\Set-PrinterPermissions -ServerName "PrtSrv1" -AccountName "ServerAdmins" -IntAccessMask 268435456
    Grants a "ServerAdmins" group all permissions sans "ManageDocuments" on
    "PrintSrv1" using the integer Access Mask. Creates a log in the
    executing directory.

    .NOTES
    Author:   Dan Ubel

    Comments: This script uses WMI.  At somepoint it will be updated to use the
              System.Security.AccessControl Namespace and/or Get-CimInstance. 

    Warning:  This code is made available as is, without warranty of any kind.
              The risk of use or results from the use of this code remains with
              the user.    
#>

Function Set-PrinterPermission {

param(
        [parameter(Position=0,HelpMessage='Server sAMAccountName on which to modify permissions.')]`
    [string]$ServerName=".",
        [parameter(Position=1,Mandatory=$true,HelpMessage='User or Group SamAccountName, or userPrincipalName, for permissions.')]`
    [string]$AccountName="",
	    [parameter(Position=2,HelpMessage='Individual Win32_Printer Name of a printer to modify permissions on.')]`
    [string]$SinglePrinterName="",
        [parameter(Position=3,HelpMessage='Printer Access Mask. Default is Print')]`
        [ValidateSet("ManagePrinters","ManageDocuments","Print","TakeOwnership","ReadPermissions","ChangePermissions")]`
    [string]$AccessMask="Print",
        [parameter(Position=4,HelpMessage='Default Access Type is Allow. Use the -Deny to set access type to Deny.')]`
    [switch]$Deny,
        [parameter(Position=5,HelpMessage='Remove all access control entries for AccountName.')]`
    [switch]$Remove,
        [parameter(Position=6,HelpMessage='Win32 ACE Flag.')]`
        [ValidateRange(1,31)]
    [int]$AceFlag=-1,
        [parameter(Position=7,HelpMessage='uint32 Access Mask.')]`
    [uint32]$IntAccessMask=0,
        [parameter(Position=8,HelpMessage='Do not output a log file')]`
    [switch]$NoLog,
        [parameter(Position=9,HelpMessage='Path and filename of a log file.')]`
    [string]$LogFile=""

    )

#included for clairty
Set-Variable AccessMasks -Option ReadOnly -Force -Value @{
    "ManagePrinters"    = 983052;
    "ManageDocuments"   = 983088;
    "Print"             = 131080;
    "TakeOwnership"     = 524288;
    "ReadPermissions"   = 131072;
    "ChangePermissions" = 262144}
    
Set-Variable AccessTypes -Option ReadOnly -Force -Value @{
    "Allow" = 0;
    "Deny" = 1}
    
Set-Variable AceFlags -Option ReadOnly -Force -Value @{ 
    "OBJECT_INHERIT_ACE"       = 0x0001;
    "CONTAINER_INHERIT_ACE"    = 0x0002;
    "NO_PROPAGATE_INHERIT_ACE" = 0x0004;
    "INHERIT_ONLY_ACE"         = 0x0008;
    "INHERITED_ACE"            = 0x0010}

Set-Variable SDControlFlags -Option ReadOnly -Force -Value @{
    "SE_DACL_AUTO_INHERIT_REQ" = 0x0100;
    "SE_DACL_AUTO_INHERITED"   = 0x0400;
    "SE_DACL_DEFAULTED"        = 0x0008;
    "SE_DACL_PRESENT"          = 0x0004;
    "SE_DACL_PROTECTED"        = 0x1000;
    "SE_GROUP_DEFAULTED"       = 0x0002;
    "SE_OWNER_DEFAULTED"       = 0x0001;
    "SE_RM_CONTROL_VALID"      = 0x4000;
    "SE_SACL_AUTO_INHERIT_REQ" = 0x0200;
    "SE_SACL_AUTO_INHERITED"   = 0x0800;
    "SE_SACL_DEFAULTED"        = 0x0008;
    "SE_SACL_PRESENT"          = 0x0010;
    "SE_SACL_PROTECTED"        = 0x2000;
    "SE_SELF_RELATIVE"         = 0x8000}

Set-Variable SecDescriptorReturnCodes -Option ReadOnly -Force -Value @{
    "Success"           = 0;
    "Access Denied"     = 2;
    "Unknown Error"     = 8;
    "The user does not have adequate privileges to execute the method"= 9;
    "A parameter specified in the method call is invalid"= 21}



function Get-Win32_Printers(){
    param(
        [string]$ServerSamAccount,
        [string]$PrinterName='')

Write-Verbose 'In Get-Win32Printers'

    [System.Management.ManagementBaseObject[]]$win32Printers = @()
    
    $win32Printers

    try{
        if($PrinterName -ne ''){
            $win32Printers += Get-WmiObject Win32_Printer -ComputerName $ServerSamAccount -Filter "Name='$PrinterName'"
        }
        else{
            $win32Printers += Get-WmiObject Win32_Printer -ComputerName $ServerSamAccount -Filter "Local='$True'"
        }
    }
    catch{Write-ScriptMessage -Msg("`nERROR: Get-Win32Printers()`nType: " + `
        $_.Exception.GetType().FullName+"`nMessage: "+$_.Exception.Message) -LogDisabled $NoLog -File $LogFile}

    return $win32Printers
}



function New-Win32PrinterACE(){
    param(
        [string]$AceUser,
        [int]$AceMask,
        [int]$AceAccessType,
        [int]$AceFlag)

    $newWin32PrinterAce = ([WMIClass] "Win32_Ace").CreateInstance()
    
    try{
        $newWin32PrinterAce.Trustee = New-Win32_Trustee $AceUser
        $newWin32PrinterAce.AccessMask = $AceMask
        $newWin32PrinterAce.AceType = $AceAccessType
        $newWin32PrinterAce.AceFlags = $AceFlag
                
    }
    catch{Write-ScriptMessage -Msg ("`nERROR: New-Win32PrinterACE()`nType: " + `
        $_.Exception.GetType().FullName+"`nMessage: "+$_.Exception.Message) -LogDisabled $NoLog -File $LogFile}

    return $newWin32PrinterAce
}



function New-Win32_Trustee(){
    param(
        [string]$TrusteeUser)

    $newWin32Trustee = ([WMIClass] "Win32_Trustee").CreateInstance() 

    try{
        $trusteeUserSid = (New-Object Security.Principal.NTAccount $TrusteeUser).Translate([Security.Principal.SecurityIdentifier])
        $trusteeByteSid = ([System.Text.Encoding]::UTF8).GetBytes($trusteeUserSid.Value)
        $trusteeUserSid.GetBinaryForm($trusteeByteSid, 0)
        
        $newWin32Trustee.Name = $TrusteeUser
        $newWin32Trustee.SID = $trusteeByteSid
    }
    catch{Write-ScriptMessage -Msg ("`nERROR: New-Win32_Trustee()`nType: " + `
        $_.Exception.GetType().FullName+"`nMessage: "+$_.Exception.Message) -LogDisabled $NoLog -File $LogFile}

    return $newWin32Trustee
}



function Get-Win32_PrinterDACL(){
    param(
        [System.Management.ManagementBaseObject]$Win32Printer)
       
    try{
        [System.Management.ManagementBaseObject[]]$win32PrinterDACL = $Win32Printer.GetSecurityDescriptor().Descriptor.DACL            
    }
    catch{Write-ScriptMessage -Msg ("`nERROR: Get-Win32_PrinterDACL()`nType: " + `
        $_.Exception.GetType().FullName+"`nMessage: "+$_.Exception.Message) -LogDisabled $NoLog -File $LogFile}
    
    return  $win32PrinterDACL
}



function New-Win32SecurityDescriptor(){
    param(
        [System.Management.ManagementBaseObject[]]$Win32PrinterDACL,
        [int]$ControlFlags)

    $newSecDescriptor = ([WMIClass] "Win32_SecurityDescriptor").CreateInstance()

    try{        
        $newSecDescriptor.DACL = $Win32PrinterDACL
        $newSecDescriptor.ControlFlags = $ControlFlags 
    }
    catch{Write-ScriptMessage -Msg ("`nERROR: New-Win32_SecurityDescriptor()`nType: " + `
        $_.Exception.GetType().FullName+"`nMessage: "+$_.Exception.Message) -LogDisabled $NoLog -File $LogFile}

    return $newSecDescriptor
}



function Set-Win32_SecurityDescriptor(){
    param(
        [System.Management.ManagementObject]$Win32Printer,
        [System.Management.ManagementObject]$Win32SecurityDescriptor)

    $setResult = 0
    try{       
        $setResult = $Win32Printer.SetSecurityDescriptor($Win32SecurityDescriptor)       
    }
    catch{Write-ScriptMessage -Msg ("`nERROR: Set-Win32_SecurityDescriptor()`nType: " + `
        $_.Exception.GetType().FullName+"`nMessage: "+$_.Exception.Message) -LogDisabled $NoLog -File $LogFile}
    
    return $setResult
}



function Set-LogFile(){
    param(
        [string]$OpLog)
         
    try{                
        if($OpLog -eq ""){
            $newLog = "Set-PrinterPermissions."+(Get-Date -Format MMdd-hhmm) +".txt"
            $OpLog = New-Item $newLog -Type file -Force
        }        
    }
    catch{Write-ScriptMessage -Msg ("`nERROR: Set-LogFile()`nType: " + `
        $_.Exception.GetType().FullName+"`nMessage: "+$_.Exception.Message) -LogDisabled $NoLog -File $LogFile}

    return $OpLog
}



function Write-ScriptMessage(){
    param(
        [bool]$LogDisabled,
        [parameter(Mandatory=$false)][string]$Msg,
        [parameter(Mandatory=$false)][string]$File)
        
    if(!$LogDisabled){
        Add-Content $File $Msg
    }
}



function Set-PrinterPermissions(){
    
    if(!$NoLog){
        [string]$LogFile = Set-LogFile $LogFile
    }
        
    Write-ScriptMessage -Msg ("`nStarted: " + (Get-Date)) -LogDisabled $NoLog -File $LogFile

    $accessType = $AccessTypes.Allow

    if($Deny){
        $accessType = $AccessTypes.Deny  
    }

    [uint32]$aMask = $AccessMasks.Get_Item("$AccessMask")
    
    if($IntAccessMask -ne 0){
        $aMask = $IntAccessMask
    }

    if($aMask -eq $AccessMasks.ManageDocuments -and $AceFlag -eq -1){
        #To "ManageDocuments", according to a bit of testing, you need OBJECT_INHERIT_ACE and INHERIT_ONLY_ACE
        $AceFlag = 0x0009
    }
    elseif($AceFlag -eq -1){
        $AceFlag = 0x0004
    }


    try{        
        (New-Object Security.Principal.NTAccount $AccountName).Translate([Security.Principal.SecurityIdentifier]) | Out-Null
          
        if($ServerName -eq "." -or (Test-Connection $ServerName -Count 1 -Quiet)){        
                        
            [System.Management.ManagementBaseObject[]]$mPrinters = @()

            #Retrieve the requested printers to update
            if($SinglePrinterName -eq ""){
                $mPrinters += Get-Win32_Printers -ServerSamAccount $ServerName 
            }
            else{
                $mPrinters += Get-Win32_Printers -ServerSamAccount $ServerName -PrinterName $SinglePrinterName
            }

            if(!$Remove){
                #Create the requested ACE
                $newAce = New-Win32PrinterACE -AceUser $AccountName -AceMask $aMask -AceType $accessType -AceFlag $AceFlag
                
                Write-ScriptMessage -Msg ("`r`n"+$mPrinters.Count + " Printer(s) to be updated." + `
                "`r`nAccount: $AccountName`r`nMask: $aMask "+ ($AccessMasks.GetEnumerator()|Where-Object {$_.Value -eq $aMask}|`
                select -ExpandProperty Name) +"`r`nType: $accessType`r`nFlag: $AceFlag`r`n") -LogDisabled $NoLog -File $LogFile            
            }
            else{
                Write-ScriptMessage -Msg ("`r`n"+$mPrinters.Count + " Printer(s) to be updated." + `
                "`r`nRemoving all Access Control Entries for: $AccountName`r`n") -LogDisabled $NoLog -File $LogFile            
            }

            foreach($mPrinter in $mPrinters){                
                #Get the DACL for the printer
                $printerDACL = Get-Win32_PrinterDACL -Win32Printer $mPrinter
                
                #Update the DACL
                if($Remove){
                    $printerDACL = $printerDACL | Where-Object {$_.Trustee.Name -ne $AccountName} 
                }
                else{                                                 
                    $printerDACL += $newAce
                }

                #Create an updated Security Descriptor
                $secDescriptor = New-Win32SecurityDescriptor -Win32PrinterDACL $printerDACL -ControlFlags $SDControlFlags.SE_DACL_PRESENT

                #Set new Security Descriptor on the printer
                $sdResult = Set-Win32_SecurityDescriptor -Win32Printer $mPrinter  -Win32SecurityDescriptor $secDescriptor
                                                
                #Write results
                if($SecDescriptorReturnCodes.ContainsValue([int]$sdResult.ReturnValue[0])){
                    $resultMsg = $SecDescriptorReturnCodes.GetEnumerator() | Where-Object {$_.Value -eq $sdResult.ReturnValue[0]} | select -ExpandProperty Name
                    Write-ScriptMessage -Msg ("`n"+$mPrinter.Name+"," +$resultMsg) -LogDisabled $NoLog -File $LogFile
                }
                else{
                    Write-ScriptMessage -Msg ("`n"+$mPrinter.Name + `
                        ": Unrecognized Return Code from Set-Win32_SecurityDescriptor --- " + $sdResult.ReturnValue[0]) -LogDisabled $NoLog -File $LogFile
                }                                              
            }
        }
        else{
            Write-ScriptMessage -Msg ("`nError: Server Offline. Unable to ping Server: " + $ServerName) -LogDisabled $NoLog -File $LogFile           
        }
    }
    catch{Write-ScriptMessage -Msg ("`nERROR: Set-PrinterPermissions()`nType: " + `
        $_.Exception.GetType().FullName+"`nMessage: "+$_.Exception.Message) -LogDisabled $NoLog -File $LogFile}
        
    Write-ScriptMessage -Msg ("`r`nFinished: " + (Get-Date)) -LogDisabled $NoLog -File $LogFile
}


#Start
Set-PrinterPermissions
}
