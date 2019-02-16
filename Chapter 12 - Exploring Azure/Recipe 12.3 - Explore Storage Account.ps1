# Recipe 12-3 Explore Azure Storage Account

# Run from CL1

# 1. Define key variables
$Locname    = 'uksouth'         # location name
$RgName     = 'packt_rg'        # resource group we are using
$SAName     = 'packt42sa'       # storage account name
$CName      = 'packtcontainer'  # a blob container name
$CName2     = 'packtcontainer2' # a second blob container name

# 2. Login to your Azure Account and ensure the RG and SA is created.
$CredAz = Get-Credential
$Account = Login-AzAccount -Credential $CredAz

# 3. Ensure the RG and SA is created. 
$RGHT = @{
    Name  = $RgName
    ErrorAction =  'SilentlyContinue'
}
$RG = Get-AzResourceGroup  @RGHT
if (-not $RG) {
  $RGTag  = [Ordered] @{Publisher='Packt'}
  $RGTag +=           @{Author='Thomas Lee'}
  $RGHT2 = @{
    Name     = $RgName
    Location = $Locname
    Tag      = $RGTag
}
  $RG = New-AzResourceGroup @RGHT2
  "RG $RgName created"
}
$SAHT = @{
    Name              = $SAName
    ResourceGroupName = $RgName
    ErrorAction       = 'SilentlyContinue'
}
$SA = Get-AzStorageAccount @SAHT
if (-not $SA) {
    $SATag = [Ordered] @{Publisher = 'Packt'}
    $SATag += @{Author = 'Thomas Lee'}
    $SAHT = @{
        Name              = $SAName
        ResourceGroupName = $RgName
        Location          = $Locname
        Tag               = $SATag
        SkuName           = 'Standard_LRS'
    }
    $SA = New-AzStorageAccount  @SAHT
    "SA $SAName created"
}

# 4. Get and display the storage account key
$SAKHT = @{
    Name              = $SAName
    ResourceGroupName = $RgName
}
$Sak = Get-AzStorageAccountKey  @SAKHT
$Sak

# 5. Extract the first key's 'password'
$Key = ($Sak | Select-Object -First 1).Value

# 6. Get the Storage Account context which encapsulates credentials
#   for the storage account)
$SCHT = @{
    StorageAccountName = $SAName
    StorageAccountKey = $Key
}
$SACon = New-AzStorageContext @SCHT
$SACon

# 7. Create 2 blob containers
$CHT = @{
  Context    = $SACon
  Permission = ‘Blob’
}
New-AzStorageContainer -Name $CName @CHT
New-AzStorageContainer -Name $CName2 @CHT

# 8. View blob containers
Get-AzStorageContainer -Context $SACon |
    Select-Object -ExpandProperty CloudBlobContainer


# 9. Create a blob
'This is a small Azure blob!!' | Out-File .\azurefile.txt
$BHT = @{
    Context = $SACon
    File = '.\azurefile.txt'
    Container = $CName
}
$Blob = Set-AzStorageBlobContent  @BHT
$Blob

# 10. Construct and display the blob name
$BlobUrl = "$($Blob.Context.BlobEndPoint)$CName/$($Blob.name)"
$BlobUrl

# 11. view the URL via IE
$IE = New-Object -ComObject InterNetExplorer.Application
$IE.Navigate2($BlobUrl)
$IE.Visible = $true