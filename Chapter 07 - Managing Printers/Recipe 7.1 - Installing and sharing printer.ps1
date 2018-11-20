#  Recipe 7-1 Installing and sharing printers
#  
#  Run on Psrv.Reskit.Org

# 1. Install the Print-Server feature on PSRV, along with the print management
#    tools:
Install-WindowsFeature -Name Print-Server, RSAT-Print-Services


# 2. Create a folder for the Xerox printer drivers:
$NIHT = @{
  Path        = 'C:\Foo\Xerox'
  ItemType    = 'Directory'
  Force       = $true
  ErrorAction = "Silentlycontinue"
}
New-Item @NIHT | Out-Null

#3. Download printer drivers for Xerox printers:
$URL='http://download.support.xerox.com/pub/drivers/6510/'+
     'drivers/win10x64/ar/6510_5.617.7.0_PCL6_x64.zip'
$Target='C:\Foo\Xerox\Xdrivers.zip'
Start-BitsTransfer -Source $URL -Destination $Target

# 4. Expand the zip file
$Drivers = 'C:\Foo\Xerox\Drivers'
Expand-Archive -Path $Target -DestinationPath $Drivers

# 5. Install the drivers
$M1 = 'Xerox Phaser 6510 PCL6'
$P =  'C:\Foo\Xerox\Drivers\6510_5.617.7.0_PCL6_x64_Driver.inf\'+
      'x3NSURX.inf'
rundll32.exe printui.dll,PrintUIEntry /ia /m "$M1"  /f "$P"
$M2 = 'Xerox WorkCentre 6515 PCL6'
rundll32.exe printui.dll,PrintUIEntry /ia /m "$M2"  /f "$P"


# 6. Add a PrinterPort for a new printer:
$PPHT = @{
  Name               = 'SalesPP' 
  PrinterHostAddress = '10.10.10.61'
}
Add-PrinterPort @PPHT  


# 7. Add the printer
$PRHT = @{
  Name = 'SalesPrinter1'
  DriverName = $m1 
  PortName   = 'SalesPP'
}
Add-Printer @PRHT

# 8. Share the printer:
Set-Printer -Name SalesPrinter1 -Shared $True

# 9. Review what you have done:
Get-PrinterPort -Name SalesPP |
    Format-Table -Autosize -Property Name, Description,
                           PrinterHostAddress, PortNumber
Get-PrinterDriver -Name xerox* |
    Format-Table -Property Name, Manufacturer,
                           DriverVersion, PrinterEnvironment
Get-Printer -ComputerName PSRV -Name SalesPrinter1 |
    Format-Table -Property Name, ComputerName,
                           Type, PortName, Location, Shared




# undo things

Remove-printer SalesPrinter1
net stop spooler;net start spooler
Remove-PrinterPort 'SalesPP' 

