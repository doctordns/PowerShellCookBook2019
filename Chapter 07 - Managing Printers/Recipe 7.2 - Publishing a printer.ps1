# Recipe 7-2 Publishing a printer
#
# Run on Psrv
# Uses Printer added in 7.1

# 1. Get the printer to publish and store the returned object in $Printer:
$Printer = Get-Printer -Name SalesPrinter1

# 2. Observe the publication status:
$Printer | Format-Table -Property Name, Published

# 3. Publish and share the printer to AD:
$Printer | Set-Printer -Location '10th floor 10E4'
$Printer | Set-Printer -Shared $true -Published $true

# 4. View the updated publication status:
Get-Printer -Name SalesPrinter1 |
    Format-Table -Property Name, Location, Drivername,Published
