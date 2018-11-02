#  Recipe 4-1 Installing and sharing printers
#  
#  Run on Psrv.Reskit.Org

# 1. Install the Print-Server feature on PSRV, along with the print management
#    tools:
Install-WindowsFeature -Name Print-Server,
                             RSAT-Print-Services

# 2. Add a PrinterPort for a new printer:
Add-PrinterPort -Name Sales_Color `
                -PrinterHostAddress 10.10.10.61

# 3. Add a PrinterDriver for this printer server:
Add-PrinterDriver -Name 'NEC Color MultiWriter Class Driver' `
                  -PrinterEnvironment 'Windows x64'

# 4. Add the printer:
Add-Printer -Name SGCP1 `
            -DriverName 'NEC Color MultiWriter Class Driver' `
            -Portname 'Sales_Color'

# 5. Share the printer:
Set-Printer -Name SGCP1 -Shared $True

# 6. Review what you have done:
Get-PrinterPort -Name Sales_Color |
    Format-Table -Property Name, Description,
                           PrinterHostAddress, PortNumber `
                 -Autosize
Get-PrinterDriver -Name NEC* |
    Format-Table -Property Name, Manufacturer,
                           DriverVersion, PrinterEnvironment
Get-Printer -ComputerName PSRV -Name SGCP1 |
    Format-Table -Property Name, ComputerName,
                           Type, PortName, Location, Shared