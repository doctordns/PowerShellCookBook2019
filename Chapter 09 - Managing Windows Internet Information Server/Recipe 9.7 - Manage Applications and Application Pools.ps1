# Reipe 10-8 - Mamage Applications and Applications Pools

#  1. Import the web admin module
Import-Module WebAdministration

# 2. Create new application poor
New-WebAppPool -Name WWW2Pool

# 3. Create new application in the pool
$WAHT = @{
    Name            = 'WWW2'
    Site            = 'www2'
    ApplicationPool = 'WWW2Pool'
    PhysicalPath    = 'C:\inetpub\www2'
}
New-WebApplication @WAHT

# 4. View the application pools
Get-IISAppPool

# 5. Set Application Pool Restart time
IPHT = @{
    Path = 'IIS:\AppPools\WWW2Pool'
    Name = Recycling.periodicRestart.schedule
}
Clear-ItemProperty  -Name Recycling.periodicRestart.schedule
$RestartAt = @('07:55', '19:55')
$IPHT = @{
    Path   = 'IIS:\AppPools\WWW2Pool'
    Name   = 'Recycling.periodicRestart.schedule'
    Value  = $RestartAt
}
New-ItemProperty @IPHT

# 6. Set Application Pool Maximum Private memory
Clear-ItemProperty IIS:\AppPools\WWW2Pool -Name Recycling.periodicRestart.privatememory
[int32] $PrivMemMax = 1GB
Set-ItemProperty -Path "IIS:\AppPools\WWW2Pool" -Name Recycling.periodicRestart.privateMemory -Value $PrivMemMax
Get-ItemProperty -Path "IIS:\AppPools\WWW2Pool" -Name Recycling.periodicRestart.privateMemory

# 7. Set max requests before a recycle
Clear-ItemProperty IIS:\AppPools\WWW2Pool -Name Recycling.periodicRestart.requests
[int32] $MaxRequests = 100000
Set-ItemProperty -Path "IIS:\AppPools\www2POOL" -Name Recycling.periodicRestart.requests -Value $MaxRequests
Get-ItemProperty -Path "IIS:\AppPools\www2POOL" -Name Recycling.periodicRestart.requests
