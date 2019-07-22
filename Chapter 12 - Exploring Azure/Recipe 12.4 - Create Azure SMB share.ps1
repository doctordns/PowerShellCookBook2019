# Recipe 12-4 -  Create an Azure SMB Share

# Run from CL1

# 1.  Define Variables
$Locname   = 'uksouth'      # location name
$RgName    = 'packt_rg'     # resource group we are using
$SAName    = 'packt42sa'    # storage account name
$ShareName = 'packtshare'   # must be lower case!

# 2. Login to your Azure Account and ensure the RG and SA is created.
$CredAZ = Get-Credential
$Account = Login-AzAccount -Credential $CredAZ

# 3. Get Storage account, accountkey and context:
$SA = Get-AzStorageAccount -ResourceGroupName $Rgname 
$SAKHT = @{
    Name              = $SAName
    ResourceGroupName = $RgName
}
$Sak = Get-AzStorageAccountKey @SAKHT
$Key = ($Sak | Select-Object -First 1).Value
$SCHT = @{
    StorageAccountName = $SAName
    StorageAccountKey  = $Key
}
$SACon = New-AzStorageContext @SCHT

# 4. Add credentials to local store:
$T = "$SAName.file.core.windows.net"
cmdkey /add:$T /user:"AZURE\$SAName" /pass:$Key

# 5. Create a share:
New-AzStorageShare -Name $ShareName -Context $SACon

# 6. Test that Share is reachable
$TNCHT = @{
  ComputerName = "$SAName.file.core.windows.net"
  Port         = 445
}
Test-NetConnection @TNCHT

# 7. Mount the share as Z:
$Mount = 'Z:'
$Rshare = "\\$SaName.file.core.windows.net\$ShareName"
$SMHT = @{
    LocalPath  = $Mount 
    RemotePath = $Rshare 
    UserName   = $SAName 
    Password   = $Key
}
New-SmbMapping @SMHT

# 8. View the share in Azure:
Get-AzStorageShare -Context $SACon  |
    Format-List -Property *

# 9. View local SMB mappings:
Get-SmbMapping

# 10. Now use the new share - create a file in the share:
New-Item -Path Z:\Foo -ItemType Directory | Out-Null
'Azure and PowerShell Rock!!!' |
   Out-File -FilePath Z:\Foo\recipe.txt

# 11. Retrievie details about the share contents:
Get-ChildItem -Path z:\ -Recurse |
    Format-Table -Property FullName, Mode, Length

# 12. Get the content from the file:
Get-Content -Path Z:\Foo\recipe.txt