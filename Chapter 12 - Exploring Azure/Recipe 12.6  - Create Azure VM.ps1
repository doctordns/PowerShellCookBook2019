#  Recipe 12.6 - Create an Azure VM
#
# Run on CL1

# 1. Define key variables
$Locname = 'uksouth'          # location name
$RgName  = 'packt_rg'         # resource group name
$SAName  = 'packt42sa'        # Storage account name
$VNName  = 'packtvnet'        # Virtual Network Name
$CloudSN = 'packtcloudsn'     # Cloud subnet name
$NSGName = 'packt_nsg'        # NSG name
$Ports   = @(80, 3389)        # ports to open in VBM
$IPName  = 'Packt_IP1'        # Private IP Address name
$User    = 'AzureAdmin'       # User Name
$UserPS  = 'JerryRocks42!'    # User Password
$VMName  = 'Packt42VM'        # VM Name

#  2. Login to azure account
$CredAZ = Get-Credential
Login-AzAccount -Credential $CredAZ 

# 3. Ensure the resource group is created:
$RG = Get-AzResourceGroup -Name $RgName -ErrorAction SilentlyContinue
if (-not $rg) {
    $RGTag = @{Publisher = 'Packt'}
    $RGTag += @{Author = 'Thomas Lee'}
    $RGHT1 = @{
        Name     = $RgName
        Location = $Locname
        Tag      = $RGTag
    }
    $RG = New-AzResourceGroup @RGHT1
    Write-Host  "RG $RgName created"
}

# 4. Ensure the Storage Account is created
$SA = Get-AzStorageAccount -Name $SAName -ResourceGroupName $RgName -ErrorAction SilentlyContinue
if (-not $SA) {
    $SATag = [Ordered] @{Publisher = 'Packt'}
    $SATag += @{Author = 'Thomas Lee'}
    $SAHT - @{
        Name              = $SAName
        ResourceGroupName = $RgName
        Location          = $Locname
        Tag               = $SATag
        $SkuName          = 'Standard_LRS'
    }
    $SA = New-AzStorageAccount @SAHT
    Write-Host "SA $SAName created"
}


# 5.  Create VM credentials
$T = 'System.Management.Automation.PSCredential'
$P = ConvertTo-SecureString -String $UserPS -AsPlainText -Force
$VMCred = New-Object -TypeName $T -ArgumentList $User, $P

# 6. Create a simple VM using defaults
$VMHT = @{
    ResourceGroupName   = $RgName
    Location            = $Locname
    Name                = $VMName
    VirtualNetworkName  = $VNName
    SubnetName          = $CloudSN
    SecurityGroupName   = $NSGName
    PublicIpAddressName = $IPName
    OpenPorts           = $Ports
    Credential          = $VMCred
}
New-AzVm @VMHT 



# 7. Get the VM's External IP address
$VMIP = Get-AzPublicIpAddress -ResourceGroupName $RGname  
$VMIP = $VMIP.IpAddress
"VM Public IP Address: [$VMIP]"

# 8. Connect to the VM
mstsc /v:"$VMIP"
