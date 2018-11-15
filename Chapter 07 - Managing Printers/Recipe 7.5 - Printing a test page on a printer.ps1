# Recipe 7-5 - Printing a test page on a printer

# 1. Get the printer objects from WMI:
$Printers = Get-CimInstance -ClassName Win32_Printer

# 2. Display the number of printers defined on PSRV:
'{0} Printers defined on this system' -f $Printers.Count

# 3. Get the Sales Group printer WMI object:
$Printer = $Printers |
  Where-Object Name -eq 'SalesPrinter1'

# 4. Display the printer's details:
$Printer | Format-Table -AutoSize

# 5. Print a test page:
Invoke-CimMethod -InputObject $Printer -MethodName PrintTestPage