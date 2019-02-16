# Recipe 12.2 - Create Azure Assets
#
#

# 1. Set Key variables:
$Locname    = 'uksouth'     # location name
$RgName     = 'packt_rg'    # resource group we are using
$SAName     = 'packt42sa'   # Storage account name

# 2. Login to your Azure Account
$CredAZ = Get-Credential
$Account = Login-AzAccount -Credential $CredAZ

# 3. Create a resource group and tag it
$RGTag  = [Ordered] @{Publisher='Packt'}
$RGTag +=           @{Author='Thomas Lee'}
$RGHT = @{
    Name     = $RgName
    Location = $Locname
    Tag      = $RGTag
}
$RG = New-AzResourceGroup @RGHT
$RG

# 4 View RG with Tags
Get-AzResourceGroup -Name $RGName |
    Format-List -Property *

# 5. Test to see if an SA name is taken
Get-AzStorageAccountNameAvailability $SAName

# 6. Create a new Storage Account
$SAHT = @{
  Name              = $SAName
  SkuName           = 'Standard_LRS'
  ResourceGroupName = $RgName
  Tag               = $RGTag
  Location          = $Locname

}
New-AzStorageAccount @SAHT

# 7. Get overview of the SA in this Resource group
$SA = Get-AzStorageAccount -ResourceGroupName $RgName
$SA |
  Format-List -Property *


# 8. Get Primary Endpoints for the SA
$SA.PrimaryEndpoints

# 9. Review SKU
$SA.Sku

# 10. View Context property
$SA.Context