# Recipe 12.5 - Create an Azure Web App

# 1.  Define Variables
$Locname    = 'uksouth'     # location name
$RgName     = 'packt_rg'    # resource group we are using
$SAName     = 'packt42sa'   # storage account name
$AppSrvName = 'packt42'
$AppName    = 'packt42'

# 2. Login to your Azure Account and ensure RG exists
$CredAZ = Get-Credential
Login-AzAccount -Credential $CredAz
$RGHT1 = @{
      Name        = $RgName
#      ErrorAction = 'Silentlycontinue'
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

#3.  ENSURE the  SA is created.
$SA = Get-AzStorageAccount -Name $SAName -ResourceGroupName $RgName -ErrorAction SilentlyContinue
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

# 4. Create app service plan
$SPHT = @{
     ResourceGroupName   = $RgName
     Name                = $AppSrvName
     Location            = $Locname
     Tier               =  'Free'
}
New-AzAppServicePlan @SPHT |  Out-Null

# 5. View the service plan
Get-AzAppServicePlan -ResourceGroupName $RGname -Name $AppSrvName

# 6. Create the new azure webapp
New-AzWebApp -ResourceGroupName $RgName -Name $AppSrvName `
                -AppServicePlan $AppSrvName -Location $Locname |
                    Out-Null

# 7. View application details
$WebApp = Get-AzWebApp -ResourceGroupName $RgName -Name $AppSrvName
$WebApp

# 8 Now see the web site
$SiteUrl = "https://$($WebApp.DefaultHostName)"
$IE  = New-Object -ComObject InterNetExplorer.Application
$IE.Navigate2($SiteUrl)
$IE.Visible = $true


# 9. Install the psftp module
Install-module PSFTP -Force

# 10.  Get publishing profile XML and extract FTP upload details
$APHT = @{
  ResourceGroupName = $RgName
  Name              = $AppSrvName  
  OutputFile        = 'C:\Foo\pdata.txt'
}
$x = [xml] (Get-AzWebAppPublishingProfile @APHT)
$x.publishData.publishProfile[1]

# 11. Extract crededentials and site details
$UserName = $x.publishData.publishProfile[1].userName
$UserPwd  = $x.publishData.publishProfile[1].userPWD
$Site     = $x.publishData.publishProfile[1].publishUrl

# 12 connect
$PS = ConvertTo-SecureString $UserPWD -AsPlainText -Force
$Cred = New-Object System.Management.automation.PSCredential $UserName,$PS
Set-FTPConnection -Credentials $Cred -Server $Site -Session 'First upload' -UsePassive 
$Session = Get-FTPConnection -Session 'First upload'

# 13. Create a Web Page
'Azure web site' | Out-File -FilePath c:\foo\index.html
$Filename = 'C:\foo\index.html'
Add-FTPItem -Path '/' -LocalPath C:\foo\index.html -Session 'First upload'


# 14. NOW look at the site!
$SiteUrl = "https://$($WebApp.DefaultHostName)"
Start-Process -FilePath $SiteUrl