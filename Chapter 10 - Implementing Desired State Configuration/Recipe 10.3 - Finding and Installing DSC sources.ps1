# Recipe 13-3 - Finding and installing DSC Resources

# 1. Find available repositories
Get-PSRepository

#  2. See what DSC resources you can find
Find-DscResource -Repository 'PSGallery' |
  Measure-Object
  
# 3. See what IIS resources might exist
Find-DscResource | 
  Where-Object ModuleName -match 'web|iis' | 
    Select-Object -Property ModuleName,Version -Unique |
      Sort-Object -Property ModuleName

# 4. Examine the xWebAdministration module
Find-DscResource -ModuleName 'xWebAdministration'

# 5. Install the xWebAdministration module (on SRV1)
Install-Module -Name 'xWebAdministration' -Force

# 6. See local module details:
Get-Module -Name xWebAdministration -ListAvailable

# 7. See what is in the module
Get-DscResource -Module xWebAdministration

# 8 what is IN the module
$Mod = Get-Module -Name xWebAdministration -ListAvailable
$P   = $Mod.Path
$FP  = Split-Path -Parent $P
Get-ChildItem -Path $FP, $FP\DSCResources 