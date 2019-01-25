# Recipe 9.7 - Manage Applications and Applications Pools
#
# Run on SRV1 after running 9.5, and 9.1

#  1. Import the web administration module
Import-Module -Name WebAdministration

# 2. Create new application poor
New-WebAppPool -Name WWW2Pool

# 3. Create new application in the pool
$WAHT = @{
    Name            = 'WWW2'
    Site            = 'WWW2'
    ApplicationPool = 'WWW2Pool'
    PhysicalPath    = 'C:\inetpub\WWW2'
}
New-WebApplication @WAHT 

# 4. View the application pools
Get-IISAppPool

# 5. Set Application Pool Restart time
$IPHT1 = @{
    Path = 'IIS:\AppPools\WWW2Pool'
    Name = 'Recycling.periodicRestart.schedule'
}
Clear-ItemProperty  @IPHT1
$RestartAt = @('07:55', '19:55')
New-ItemProperty @IPHT1 -Value $RestartAt

# 6. Set Application Pool Maximum Private memory
$IPHT2 = @{
  Path = 'IIS:\AppPools\WWW2Pool'
  Name = 'Recycling.periodicRestart.privatememory'
}
Clear-ItemProperty @IPHT2
[int32] $PrivMemMax = 150mb
Set-ItemProperty -Path 'IIS:\AppPools\WWW2Pool' `
                 -Name Recycling.periodicRestart.privateMemory `
                 -Value $PrivMemMax

# 7. Set max requests before a recycle and view
$IPHT3 = @{
  Path = 'IIS:\AppPools\WWW2Pool'
  Name = 'Recycling.periodicRestart.requests'
}
Clear-ItemProperty @IPHT3
[int32] $MaxRequests = 104242
Set-ItemProperty @IPHT3 -Value $MaxRequests
Get-ItemProperty @IPHT3

# 8. Recyle the app pool
$Pool = Get-IISAppPool -Name WWW2Pool
$Pool.Recycle()
