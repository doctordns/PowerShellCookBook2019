# Recipe 4-4 Change Printer Driver

# 1. Add the print driver for the new printing device:
$M2 = 'Xerox WorkCentre 6515 PCL6'
Add-PrinterDriver -Name $M2

# 2. Get the Sales group printer object and store it in $Printer:
$Printern = 'SalesPrinter1'
$Printer = Get-Printer -Name $Printern

# 3. Update the driver using the Set-Printercmdlet:
$Printer | Set-Printer -DriverName $M2

# 4. Observe the result
Get-Printer -Name $Printern | 
  Format-Table -Property Name, DriverName, PortName, 
                Published, Shared