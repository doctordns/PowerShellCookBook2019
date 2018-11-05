#  Recipe 7.3 - Changing the spool directory.

# 1. Load the System.Printing namespace and classes:
Add-Type -AssemblyName System.Printing

# 2. Define the required permissions—that is, the ability to administrate the server:
$Permissions =
   [System.Printing.PrintSystemDesiredAccess]::
          AdministrateServer

# 3. Create a PrintServer object with the required permissions:
$NOHT = @{
  TypeName     = 'System.Printing.PrintServer'
  ArgumentList = $Permissions
}
$PS = New-Object @NOHT


# 4. Create a new spool path:
$NIHT = @{
Path        = 'C:\SpoolPath'
ItemType    = 'Directory'
Force       = $true
ErrorAction = 'SilentlyContinue'
}
New-Item @NIHT | Out-Null 

# 5 Update the default spool folder path:
$Newpath = 'C:\SpoolPath'
$PS.DefaultSpoolDirectory = $Newpath

# 6. Commit the change:
$Ps.Commit()

# 7. Restart the Spooler to accept the new folder:
Restart-Service -Name Spooler

# 7. Once the Spooler has restarted, view the results:
New-Object -TypeName System.Printing.PrintServer |
    Format-Table -Property Name,
                  DefaultSpoolDirectory

#  Another way to set the Spooler directory is by directly editing the registry as follows:
# 1. First stop the Spooler service:
Stop-Service -Name Spooler

# 2. Set the spool directory registry setting:
$RPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\' +
         'Print\Printers'

$Spooldir = 'C:\SpoolViaRegistry' # Folder should exist
Set-ItemProperty -Path $RPath `
                 -Name DefaultSpoolDirectory `
                 -Value 'C:\SpoolViaRegistry'

# 3. Restart the Spooler:
Start-Service -Name Spooler

# 4. View the results:
New-Object -TypeName System.Printing.PrintServer |
    Format-Table -Property Name, DefaultSpoolDirectory