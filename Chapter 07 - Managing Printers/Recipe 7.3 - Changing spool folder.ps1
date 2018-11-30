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

# 8. Once the Spooler has restarted, view the results:
New-Object -TypeName System.Printing.PrintServer |
    Format-Table -Property Name,
                  DefaultSpoolDirectory



#  Another way to set the Spooler directory is by directly editing the registry as follows:


# 9. First stop the Spooler service:
Stop-Service -Name Spooler

# 10. Create a new spool directory:
$SPL = 'C:\SpoolViaRegistry'
$NIHT2 = @{
  Path        = $SPL
  Itemtype    = 'Directory'
  ErrorAction = 'SilentlyContinue'
}
New-Item  @NIHT2 | Out-Null

# 11. Create the spooler folder and configure in the registry
$RPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\' +
         'Print\Printers'
$Spooldir = 'C:\SpoolViaRegistry' # Folder should exist
$IP = @{
  Path    = $RPath
  Name    = 'DefaultSpoolDirectory'
  Value   = $SPL
}
Set-ItemProperty @IP

# 12. Restart the Spooler:
Start-Service -Name Spooler

# 13. View the results:
New-Object -TypeName System.Printing.PrintServer |
    Format-Table -Property Name, DefaultSpoolDirectory