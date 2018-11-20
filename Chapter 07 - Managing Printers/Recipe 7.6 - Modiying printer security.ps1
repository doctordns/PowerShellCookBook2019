# Recipe 4-7 - Modifying printer security
#
# Run on PSRV, after Create-Sales.ps1 has run

# 1. Download the Set-PrinterPermissions script.
$URL = 'https://gallery.technet.microsoft.com/scriptcenter/' +
        'Modify-Printer-Permissions-149ae172/file/116651/1/' +
        'Set-PrinterPermissions.ps1'
$Target = 'C:\Foo\Set-PrinterPermissions.ps1'
Start-BitsTransfer -Source $URL -Destination $Target

# 2. Get help on the script
Get-Help $Target

# 3. Use PrintUI.DLL to bring up the printer properties GUI:
rundll32.exe printui.dll,PrintUIEntry /p /nSalesprinter1

# 4. From the GUI, click on Security to view the initial ACL.

# 5. Remove the Everyone Group ACE from the printers ACL
$SPHT1 = @{
  ServerName        = 'PSRV'
  Remove            = $True
  AccountName       = 'EVERYONE'
  SinglePrinterName = 'SalesPrinter1'
}
C:\foo\Set-PrinterPermissions.ps1 @SPHT1

# 6. Add Sales group to ACL with Print permissions
$SPHT2 = @{
  ServerName        = 'PSRV'
  AccountName       = 'Reskit\Sales'
  AccessMask        = 'Print'
  SinglePrinterName = 'SalesPrinter1'
}
C:\foo\Set-PrinterPermissions.ps1 @SPHT2

# 7. Give SalesAdmins manage documents permission, and log
$SPHT3 = @{
  ServerName        = 'PSRV'
  AccountName       = 'Reskit\SalesAdmins'
  AccessMask        = 'ManageDocuments'
  SinglePrinterName = 'SalesPrinter1'
}
C:\foo\Set-PrinterPermissions.ps1 @SPHT3

# 8. Bring up the Printer Gui
rundll32.exe printui.dll,PrintUIEntry /p /nSalesprinter1

# 9. Click the security tab and view the updated ACL

