# Recipe 12-1 Getting started with Azure
#
# Run on CL

#  1. Find core Azure Modules
Find-Module -Name Az

# 2. Install AZ modules
Install-Module -Name Az -Force

# 3. Discover Azure modules and how many cmdlets each contain
$HT = @{ Label ='Cmdlets'
         Expression = {(Get-Command -module $_.name).count}}
Get-Module Az* -ListAvailable | 
    Sort {(Get-command -Module $_.Name).Count} -Descending |
       Format-Table -Property Name,Version,Author,$HT -AutoSize

# 4. Find Azure AD cmdlets
Find-Module AzureAD |
    Format-Table -Property Name,Version,Author -AutoSize -Wrap

# 5. Download the AzureAD Module
Install-Module -Name AzureAD -Force

# 6. Discover Azure AD Module
$FTHT = @{
    Property = 'Name', 'Version', 'Author', 'Description'
    AutoSize = $true
    Wrap     = $true
}
Get-Module -Name AzureAD -ListAvailable |
  Format-Table @FTHT

# 7. Login To Azure 
$Subscription = Login-AzAccount

# 8. Get Azure Subscription details
$SubID = $Subscription.Context.Subscription.SubscriptionId
Get-AzSubscription -SubscriptionId $SubId |
  Format-List -Property *

# 9. Get Azure Locations
Get-AzLocation | Sort-Object Location |
    Format-Table Location, Displayname

# 10 Get Azure Environments
Get-AzEnvironment |
    Format-Table -Property name, ManagementPortalURL
