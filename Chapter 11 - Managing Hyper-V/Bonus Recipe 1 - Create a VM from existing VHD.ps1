# create vm from vhdx

# 1. Create variables
$Locname   = 'uksouth'        # location name
$RgName    = 'packt_rg'       # resource group we are using
$SAName    = 'packt42sa'      # storage account name
$CName     = 'vhd'            # a blob container 
$VHDName   = 'server42.vhd'     # vhd name
$OP        = 'd:\test\windows server 2016.vhdx'
$LP        = 'd:\test\ws2016.vhd' # local path to vhdx

$Cred = Get-Credential thomas_lee@msn.com
$Acct = Login-AzAccount -Credential $cred

# 2. Convert vhdx to vhd
$s = Get-Date
Convert-VHD –Path $OP -DestinationPath $LP
$e = Get-Date
$e - $s

# 3. upload
$URL = "https://$SAName.blob.core.windows.net/$Cname/$vhdName"
$s2 = get-date
Add-AzVhd -ResourceGroupName $RgName -Destination $URL -LocalFilePath $LP
$e2 = get-date
$e2-$s2


# 4. Create a managed image
$IC = New-AzImageConfig -Location $Locname
$IC = Set-AzImageOsDisk -Image $IC -OsType Windows -OsState Generalized -BlobUri $URL
$Image = New-AzImage -ImageName $imageName -ResourceGroupName $RGName  -Image $IC

# 5, Create the networking resources
$singleSubnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.0.0/24
$vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroup -Location $location `
    -AddressPrefix 10.0.0.0/16 -Subnet $singleSubnet
$pip = New-AzPublicIpAddress -Name $ipName -ResourceGroupName $resourceGroup -Location $location `
    -AllocationMethod Dynamic
$rdpRule = New-AzNetworkSecurityRuleConfig -Name $ruleName -Description 'Allow RDP' -Access Allow `
    -Protocol Tcp -Direction Inbound -Priority 110 -SourceAddressPrefix Internet -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange 3389
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location `
    -Name $nsgName -SecurityRules $rdpRule
$nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $resourceGroup -Location $location `
    -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id
$vnet = Get-AzVirtualNetwork -ResourceGroupName $resourceGroup -Name $vnetName

# Start building the VM configuration
$vm = New-AzVMConfig -VMName $vmName -VMSize $vmSize

# Set the VM image as source image for the new VM
$vm = Set-AzVMSourceImage -VM $vm -Id $image.Id

# Finish the VM configuration and add the NIC.
$vm = Set-AzVMOSDisk -VM $vm  -DiskSizeInGB $diskSizeGB -CreateOption FromImage -Caching ReadWrite
$vm = Set-AzVMOperatingSystem -VM $vm -Windows -ComputerName $computerName -Credential $cred `
    -ProvisionVMAgent -EnableAutoUpdate
$vm = Add-AzVMNetworkInterface -VM $vm -Id $nic.Id

# Create the VM
New-AzVM -VM $vm -ResourceGroupName $resourceGroup -Location $location