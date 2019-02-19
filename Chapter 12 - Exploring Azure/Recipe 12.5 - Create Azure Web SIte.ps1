# Recipe 12.5 - Create an Azure Web App

# 1.  Define Variables
$Locname    = 'uksouth'     # location name
$RgName     = 'packt_rg'    # resource group we are using
$SAName     = 'packt42sa'   # storage account name
$AppSrvName = 'packt42'
$AppName    = 'packt42website'

# 2. Login to your Azure Account and ensure RG exists
$CredAZ = Get-Credential
Login-AzAccount -Credential $CredAz

# 3. Ensure Resource Group is created
$RGHT1 = @{
  Name        = $RgName
  ErrorAction = 'Silentlycontinue'
}
$RG = Get-AzResourceGroup @RGHT1
if (-not $RG) {
  $RGTag  = [Ordered] @{Publisher='Packt'}
  $RGTag +=           @{Author='Thomas Lee'}
  $RGHT2 = @{
    Name     = $RgName
    Location = $Locname
    Tag      = $RGTag
  }
  $RG = New-AzResourceGroup @RGHT2
  Write-Host "RG $RgName created"
}

# 4.  Ensure the  Stoage Account is created.
$SAHT = @{
  Name              = $SAName
  ResourceGroupName = $RgName 
  ErrorAction       = 'SilentlyContinue'
}
$SA = Get-AzStorageAccount @SAHT
if (-not $SA) {
  $SATag  = [Ordered] @{Publisher='Packt'}
  $SATag +=           @{Author='Thomas Lee'}
  $SAHT = @{
    Name              = $SAName
    ResourceGroupName = $RgName
    Location          = $Locname
    Tag               = $SATag
    SkuName           = 'Standard_LRS'
  }
  $SA = New-AStorageAccount @SAHT
  "SA $SAName created"
}

# 5. Create app service plan
$SPHT = @{
     ResourceGroupName   = $RgName
     Name                = $AppSrvName
     Location            = $Locname
     Tier               =  'Free'
}
New-AzAppServicePlan @SPHT |  Out-Null

# 6. View the service plan
$PHT = @{
  ResourceGroupName = $RGname 
  Name              = $AppSrvName
}
Get-AzAppServicePlan @PHT

# 7. Create the new azure webapp
$WAHT = @{
  ResourceGroupName = $RgName 
  Name              = $AppName
  AppServicePlan    = $AppSrvName
  Location          = $Locname
}
New-AzWebApp @WAHT |  Out-Null

# 8. View application details
$WebApp = Get-AzWebApp -ResourceGroupName $RgName -Name $AppName
$WebApp | 
  Format-Table -Property Name, State, Hostnames, Location

# 9 Now see the web site
$SiteUrl = "https://$($WebApp.DefaultHostName)"
$IE  = New-Object -ComObject InterNetExplorer.Application
$IE.Navigate2($SiteUrl)
$IE.Visible = $true

# 10. Install the PSFTP module
Install-module PSFTP -Force | Out-Null
Import-Module PSFTP

# 11.  Get publishing profile XML and extract FTP upload details
$APHT = @{
  ResourceGroupName = $RgName
  Name              = $AppName  
  OutputFile        = 'C:\Foo\pdata.txt'
}
$x = [xml] (Get-AzWebAppPublishingProfile @APHT)
$x.publishData.publishProfile[1]

# 12. Extract crededentials and site details
$UserName = $x.publishData.publishProfile[1].userName
$UserPwd  = $x.publishData.publishProfile[1].userPWD
$Site     = $x.publishData.publishProfile[1].publishUrl

# 13. Connect to the FTP site
$FTPSN  = 'FTPtoAzure'
$PS     = ConvertTo-SecureString $UserPWD -AsPlainText -Force
$T      = 'System.Management.automation.PSCredentiaL'
$Cred   = New-Object -TypeName $T -ArgumentList $UserName,$PS
$FTPHT  = @{
  Credentials = $Cred 
  Server      = $Site 
  Session     = $FTPSN
  UsePassive  = $true
}
Set-FTPConnection @FTPHT
$Session = Get-FTPConnection -Session $FTPSN

# 15. Create a Web Page and upload it
'My First Azure Web Site' | Out-File -FilePath C:\Foo\Index.Html
$Filename = 'C:\foo\index.html'
$IHT = @{
  Path       = '/'
  LocalPath  = 'C:\foo\index.html'
  Session    = $FTPSN
}
Add-FTPItem @IHT


# 16. NoW look at the site using default browser (Chrome):
$SiteUrl = "https://$($WebApp.DefaultHostName)"
Start-Process -FilePath $SiteUrl