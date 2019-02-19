#  Recipe 12.6 - Create an Azure VM
#
# Run on CL1

# 1. Define key variables
$Locname = 'uksouth'          # location name
$RgName = 'packt_rg'         # resource group name
$SAName = 'packt42sa'        # Storage account name
$NSGName = 'packt_nsg'        # NSG name
$FullNet = '10.10.0.0/16'     # Overall networkrange
$CLNet = '10.10.2.0/24'     # Our cloud subnet
$GWNet = '192.168.200.0/26' # Gateway subnet
$DNS = '8.8.8.8'          # DNS Server to use
$IPName = 'Packt_IP1'        # Private IP Address name
$VMName = "Packt100"         # the name of the VM
$CompName = "Packt100"         # the name of the VM's host

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

# CREATING THE VNET

# 5. Create subnet network config objects
$SubnetName = 'CloudSubnet1'
$SNHT = @{
    Name          = $SubnetName
    AddressPrefix = $CLNet
}
$CloudSubnet = New-AzVirtualNetworkSubnetConfig @SNHT
$GWSubnetName = 'GatewaySubnet'
$GWHT = @{
    Name          = $GWSubnetName
    AddressPrefix = $GWNet
}
$GWSubnet = New-AzVirtualNetworkSubnetConfig @GWHT

# 6. Create the virtual network, and tag it - this can take a while
$VnetName = "PacktVnet"
$VNHT = @{
    Name              = $VnetName
    ResourceGroupName = $RgName
    Location          = $Locname
    AddressPrefix     = $FullNet, '192.168.0.0/16'
    Subnet            = $CloudSubnet, $GWSubnet
    DnsServer         = $DNS
    Tag               = @{Owner = 'PACKT'; Type = 'VNET'}
}
$PackVnet = New-AzVirtualNetwork @VNHT

# 7. Create a public IP address and NIC for our VM to use
$PublicIp = New-AzPublicIpAddress -Name $IPName `
    -ResourceGroupName $RgName `
    -Location $Locname -AllocationMethod Dynamic `
    -Tag @{Owner = 'PACKT'; Type = 'IP'}
$PublicIp | 
    Format-Table -Property Name, IPAddress, ResourceGroup, Location, State

# 6. Create the NIC
$NicName = "VMNic1"
$NICHT = @{
    Name              = $NicName
    ResourceGroupName = $RgName
    Location          = $Locname
    SubnetId          = $Packvnet.Subnets[0].Id
    PublicIpAddressId = $UblicIp.Id
    Tag               = @{Owner = 'PACKT'; Type = 'NIC'}
}
$Nic = New-AzNetworkInterface @NICHT
$Nic

# 7. Create NSG rule
$NGSHT = @{
    Name                     = 'RDP-In'
    Protocol                 = 'Tcp'
    Direction                = 'Inbound'
    Priority                 = '1000 '
    SourceAddressPrefix      = '*'
    SourcePortRange          = '*'
    DestinationAddressPrefix = '*'
    DestinationPortRange     = 3389
    Access                   = 'Allow'
}
$NSGRule1 = New-AzNetworkSecurityRuleConfig @NGSHT

# 8. Create an NSG
$NSGHT = @{
  ResourceGroupName = $RgName
  Location          = $Locname
  Name              = $NSGName
  SecurityRules     = $NSGRule1
}
$PacktNSG = New-AzNetworkSecurityGroup @NGSHT
    
# 9. Configure subnet
Set-AzureRmVirtualNetworkSubnetConfig `
    -Name $SubnetName `
    -VirtualNetwork $PackVnet `
    -NetworkSecurityGroup $PacktNSG `
    -AddressPrefix $CLNet | Out-Null

# 10 Set the Azure virtual netowrk based on prior configuration steps:
Set-AzureRmVirtualNetwork -VirtualNetwork $PackVnet | Out-Null

# 11. create VM Configuration object
$VM = New-AzureRmVMConfig -VMName $VMName -VMSize 'Standard_A1'
Write-Host -Object $VM

# 12. Create credential for VM Admin
$VMUser = 'tfl'
$VMPass = ConvertTo-SecureString 'J3rryisG0d!!'-AsPlainText -Force
$T = 'System.Management.automation.PSCredential'
$VMCred = New-Object -tyhp   $T -ArgumentList $VMUser, $VMPass

# 13. Set OS information for the VM
$VMHT = @{
    VM               = $VM
    Windows          = $true
    ComputerName     = $CompName
    Credential       = $VMCred
    ProvisionVMAgent = $true
    EnableAutoUpdate = $true
}
$VM = Set-AzureRmVMOperatingSystem @VMHT
Write-Host -Object $VM

# 14. Determine which image to use and get the offer
$Publisher = 'MicrosoftWindowsServer'
$OfferName = 'WindowsServer'
$OHT = @{
    Location      = $Locname
    PublisherName = $Publisher
}
$Offer = Get-AzureRmVMImageoffer @OHT |
    Where-Object Offer -eq $Offername

# 15. Then get the SKU/Image
$SkuName = '2016-Datacenter'
$SKUHT = @{
    Location  = $Locname
    Publisher = $Publisher
    Offer     = $Offer.Offer
}
$SKU = Get-AzureRmVMImageSku @SKUHT |
    Where-Object Skus -eq $SkuName
$SIHT = @{
    VM            = $VM
    PublisherName = $Publisher
    Offer         = $Offer.offer
    Skus          = $SKU.Skus
    Version       = 'latest'
}
$VM = Set-AzureRmVMSourceImage @SIHT
Write-Host -Object $VM

# 16. Add the nic to the vm config object
$VM = Add-AzureRmVMNetworkInterface -VM $VM -Id $Nic.Id

# 17. Identify the page blob to hold the VMDisk
$StorageAcc = Get-AzureRmStorageAccount -ResourceGroupName $RgName -Name $SAName
$BlobPath = "vhds/Packt100.vhd"
$OsDiskUri = $storageAcc.PrimaryEndpoints.Blob.ToString() + $BlobPath
$DiskName = 'PacktOsDisk'
$VMDHT = @{
    VM           = $VM
    Name         = $DiskName
    VhdUri       = $OsDiskUri
    CreateOption = 'FromImage'
}
$VM = Set-AzureRmVMOSDisk @VMDHT
Write-Host -Object $VM

# 18. And finally Create the VM
# NB: This can take some time to provision
$S = Get-Date
$NVMHT = @{
    ResourceGroupName = $RgName
    Location          = $Locname
    VM                = $VM
    Tag               = "@{Owner = 'Packt'}"
}
$VM = New-AzureRmVM @NVMHT
$E = Get-Date
$OS = "VM creation too [{0}] seconds" -f $(($E - $S).TotalSeconds)
Write-Host -Object $OS

# 19. Now get the Public IP address...
$IPHT = @{
    Name              = $IPName
    ResourceGroupName = $RgName
}
$VMPublicIP = Get-AzureRmPublicIpAddress @IPHT

# 20. Open a RDP session on our new VM:
$IpAddress = $VMPublicIP.IpAddress
mstsc / v:$IpAddress / w:1024 / h:768

# 21. Once the RDP client opens, logon using
#  Userid:   pact100\tfl
#  Password: J3rryisG0d!!


#  If you want to use WSMAN by IP...

# 20. Set trusted path to allow connections by IP to our new host
Set-Item WSMan:\localhost\Client\TrustedHosts  "$($IpAddress.IpAddress)" -Force