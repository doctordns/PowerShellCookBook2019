# Recipe 4-4 Change Printer Driver

# 1. Add the print driver for the new printing device:
Add-PrinterDriver -Name "HP LaserJet 9000 PS Class Driver"

# 2. Get the Sales group printer object and store it in $Printer:
$Printer = Get-Printer -Name "SGCP1"

# 3. Update the driver using the Set-Printercmdlet:
Set-Printer -Name $Printer.Name `
            -DriverName "HP LaserJet 9000 PS Class Driver"

# 4. Observe the results:
Get-Printer SGCP1