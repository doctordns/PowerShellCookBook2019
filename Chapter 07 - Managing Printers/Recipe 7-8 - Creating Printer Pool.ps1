# Recipe 4-10 Create Printer Pool
# Run on PSRV printer server

# 1. Add a port for the printerAdd-PrinterPort -Name 'Sales_Colour2' `     -PrinterHostAddress 10.10.10.62

# 2. Create printer pool
rundll32 printui.dll,PrintUIEntry /Xs /n "sgcp1" Portname "sales_Colour,Sales_Colour2"

# 3. Get Printer details
Get-Printer 'SGCP1' |
    Format-Table Name, Type, DriverName, PortName