# Recipe7-7 - create Printer Pool
# Run on PSRV printer server

# 1. Add a port for the printer$P = 'SalesPP2' # new port nameAdd-PrinterPort -Name $P -PrinterHostAddress 10.10.10.62# 2. Create the printer pool for SalesPrinter1:$P1='SalesPP'
$P2='SalesPP2'
rundll32.exe printui.dll,PrintUIEntry /Xs /n $p Portname $P1,$P2# 3. View resultant details, showing both ports:$P = 'SalesPrinter1'Get-Printer $P |    Format-Table -Property Name, Type, DriverName, PortName