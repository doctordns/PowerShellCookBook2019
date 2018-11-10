    ########################################################
    # PrinterUtils.ps1
    # Version 0.1.0.0
    #
    # Functions for advanced printer management
    #
    # Vadims Podans (c) 2008
    # http://www.sysadmins.lv/
    ########################################################

    # Internal function that converts numeric return code writes ACL 
	# in a text value. 
	function _PrinterUtils_Get-Code ($Write) {
        switch ($Write.ReturnValue) {
            "0" {"Success"}
            "2" {"Access Denied"}
            "8" {"Unknown Error"}
            "9" {"The user does not have adequate privileges to execute the method"}
            "21" {"A parameter specified in the method call is invalid"}
            default {"Unknown error $Write.ReturnValue"}
        }
    }

    # function get the list (List) ACL printer or all Printer 
    function Get-Printer ($Computer = ".", $name) {
        # If the variable $name is empty, it returns a list of all local printers 
        if ($name) {
            $Printers = gwmi Win32_Printer -ComputerName $Computer -Filter "name = '$name'"
        } else {
            $Printers = gwmi Win32_Printer -ComputerName $Computer -Filter "local = '$True'"
        }
        # array declaration lists ACL 
        $PrinterInfo = @()
        # Retrieve the ACL of each element of the array of lists ACL 
        foreach ($Printer in $Printers) {
            if ($printer) {
                # the variable $SD obtain the security descriptor for each printer and each element of the ACE (DACL) 
				# And add $PrinterInfo 
                $SD = $Printer.GetSecurityDescriptor()
                $PrinterInfo += $SD.Descriptor.DACL | %{
                    $_ | Select @{e = {$Printer.SystemName}; n = 'Computer'},
                    @{e = {$Printer.name}; n = 'Name'},
                    AccessMask,
                    AceFlags,
                    AceType,
                    @{e = {$_.trustee.Name}; n = 'User'},
                    @{e = {$_.trustee.Domain}; n = 'Domain'},
                    @{e = {$_.trustee.SIDString}; n = 'SID'}
                }
            } else {
                Write-Warning "Specified printer not found!"
            }
        }
        # Giving information about the ACL on the yield function for subsequent submission to the conveyor 
        $PrinterInfo
    }

    # recording function in the ACL printer.  It takes no arguments, 
	# but only receives data from the conveyor 
    function Set-Printer {
        # get an array of pipelined ACE from an external source 
        $PrinterInfo = @($Input)
        # embroider the resulting array by the name of the printer and continue to serve on the cycle 
		# ACL processing only one printer 
        $PrinterInfo | Select -Unique Computer, Name | % {
            $Computer = $_.Computer
            $name = $_.name
            # create the new objects required classes 
            $SD = ([WMIClass] "Win32_SecurityDescriptor").CreateInstance()
            $ace = ([WMIClass] "Win32_Ace").CreateInstance()
            $Trustee = ([WMIClass] "Win32_Trustee").CreateInstance()
            # now embroider each ACE is already filtered by an ACL from PrinterInfo and 
			# Fill the form SecurityDescriptor 
            $PrinterInfo | ? {$_.Computer -eq $Computer -and $_.name -eq $name} | % {
                $SID = new-object security.principal.securityidentifier($_.SID)
                [byte[]] $SIDArray = ,0 * $SID.BinaryLength
                $SID.GetBinaryForm($SIDArray,0)
                $Trustee.Name = $_.user
                $Trustee.SID = $SIDArray
                $ace.AccessMask = $_.AccessMask
                $ace.AceType = $_.AceType
                $ace.AceFlags = $_.AceFlags
                $ace.trustee = $Trustee
                # Set ACE gradually add to the security descriptor DACL 
                $SD.DACL += @($ace.psobject.baseobject)
                # set the flag SE_DACL_PRESENT, that will say that we are changing 
              # DACL only and nothing more 
                $SD.ControlFlags = 0x0004
            }
            # when full ACL for the current printer is assembled, select the name of the current printer 
            $Printer = gwmi Win32_Printer -ComputerName $Computer -Filter "name = '$name'"
            # Verify that the printer for an ACL entry is found and produced the record. 
          # Otherwise, the ACL entry is skipped 
            if ($Printer) {
                $Write = $Printer.SetSecurityDescriptor($SD)
                Write-Host "Processing current printer: $name"
                _PrinterUtils_Get-Code $Write
            } else {
                Write-Warning "Skipping non-present printer: $name"
            }
        }
    }

    # internal function, which only creates a user object with a set of rules 
	# and returns the object to the calling function for the subsequent transformation 
    function _Create-SDObject ( $user, $AceType, $AccessMask) {
        # convert the text form of rights in the numerical values 
        $masks = @{ManagePrinters = 983052; ManageDocuments = 983088; Print = 131080;
            TakeOwnership = 524288; ReadPermissions = 131072; ChangePermissions = 262144}
        $types = @{Allow = 0; Deny = 1}
        # create the necessary properties for the object.  To support remote management 
		  # Was added to the property of Computer, which will take on the Get-Printer analogous 
		  # Value.  This provides a pass-through broadcast computer name where 
		  # Printer is connected by pipeline to the subsequent record 
        $AddInfo = New-Object System.Management.Automation.PSObject
        $AddInfo | Add-Member NoteProperty Computer ([PSObject]$null)
        $AddInfo | Add-Member NoteProperty Name ([PSObject]$null)
        $AddInfo | Add-Member NoteProperty AccessMask ([uint32]$null)
        $AddInfo | Add-Member NoteProperty AceFlags ([uint32]$null)
        $AddInfo | Add-Member NoteProperty AceType ([uint32]$null)
        $AddInfo | Add-Member NoteProperty User ([PSObject]$null)
        $AddInfo | Add-Member NoteProperty Domain ([PSObject]$null)
        $AddInfo | Add-Member NoteProperty SID ([PSObject]$null)
        # populate the data which were given as arguments to the function call and return 
      # Object to the calling function 
        $AddInfo.Name = $name
        $AddInfo.User = $user
        $AddInfo.SID = (new-object security.principal.ntaccount $user).translate([security.principal.securityidentifier])
        $AddInfo.AccessMask = $masks.$AccessMask
        $AddInfo.AceType = $types.$AceType
        if ($masks.$AccessMask -eq 983088) {$AddInfo.AceFlags = 9}
        $AddInfo
    }

    # function to set permissions on the printer.  When using it, the current ACL 
	# cleared of all records and set only one polzovateley / team with the right ManagePrinters 
    function Set-PrinterPermission ($user) {
        # Data taken from the conveyor 
        $PrinterInfo = @($Input)
        $AddInfo = _Create-SDObject $user Allow ManagePrinters
        # This loop goes through the names of all the names of printers for each of them 
      # Specified in the written arguments of the user with the removal of the current ACE from the ACL printer 
      # This is evident from the fact that no part of the $PrinterInfo not piped to record 
        foreach ($Printer in ($PrinterInfo | select -Unique Computer, Name)) {
            $AddInfo.Computer = $Printer.Computer
            $AddInfo.Name = $Printer.name
            $AddInfo | Set-Printer
        }
    }

    # function to add a user / group to an existing ACL on the printer.  The main difference from the previous version 
	# that for each printer ACE is not installed, and added 
    function Add-PrinterPermission ($user, $AceType, $AccessMask) {
        $PrinterInfo = @($Input)
        $AddInfo = _Create-SDObject $user $AceType $AccessMask
        foreach ($Printer in ($PrinterInfo | select -Unique Computer, Name)) {
            $AddInfo.Name = $Printer.name
            $AddInfo.Computer = $Printer.Computer
            # here is this line, we list all the printers iteratively iterate through each printer 
            $PrinterInfoNew = $PrinterInfo | ?{$_.name -eq $Printer.name}
            # and the tail of the ACL are adding a new ACE 
            $PrinterInfoNew += $AddInfo
            # And serve to record 
            $PrinterInfoNew | Set-Printer
        }
    }

    # function to remove the ACE group / user from the ACL 
    function Remove-PrinterPermission ($user) {
        $Printers = @($Input)
        # just take the list of ACL, which came on the conveyor belt and throwing out all the ACE, 
		# In which the figures given in the arguments of the user / group and writing the ACE back in the ACL 
        $printers | ? {$_.user -ne $user} | Set-Printer
    }

    function New-NetworkPrinter ($Computer, $name) {
        ([wmiclass]'Win32_Printer').AddPrinterConnection("\\$Computer\$name")
    }

    function Remove-NetworkPrinter ($name) {
        if ($name) {
            (gwmi Win32_Printer -Filter "sharename='$name'").delete()
        } else {
            (gwmi Win32_Printer -Filter "local='$false'").delete()
        }
    }

    function Set-DefaultPrinter ($name) {
        if (!$name) {
            Write-Warning "You must to specify printer name. Operation aborted!"
        } else {
            if (gwmi win32_Printer -Filter "name='$name'") {
                $SetDefault = (gwmi win32_Printer -Filter "name='$name'").SetDefaultPrinter()
                switch ($SetDefault.ReturnValue) {
                    "0" {Write-Host "Now your default printer is $name"}
                    default {Write-Warning "Some error occur"}
                }
            } else {
                Write-Warning "Specified printer not exist!"
            }
        }
    }

    function Get-PrinterInfo ($Computer = ".", $name) {
        # here I suggest getting a full set of properties and a simplified derivation of information. 
        if ($name) {
            gwmi Win32_Printer -ComputerName $Computer -Filter "name='$name'" | select *
        } else {
            gwmi Win32_Printer -ComputerName $Computer
        }
    }

    function New-PrinterShare ($Computer = ".", $name, $ShareName) {
        $Printer = gwmi win32_Printer -ComputerName $Computer -Filter "name='$name'"
        if ($Printer) {
            $Printer.shared = $True
            $Printer.ShareName = $ShareName
            $Printer.put()
        } else {
            Write-Warning "Specified printer not exist!"
        }
    }

    function Remove-PrinterShare ($Computer = ".", $name) {
        if ($name) {
            $filter = "name = '$name'"
        } else {
            $filter = "local = '$false'"
        }
        gwmi Win32_Printer -ComputerName $Computer -Filter $filter | % {
            $_.shared = $false
            $_.put()
        }
    }