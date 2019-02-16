# Recipe 12-7 - Create and use Azure VPN

# 1.  Define Variables
$Locname = 'uksouth'     # location name
$RgName  = 'packt_rg'    # resource group name
$GWSubnetName = 'GatewaySubnet'
$GWName    = 'pactvpngw'
$GWIPName = 'gwip'
$NetworkName = 'PacktVnet'
$GWIPName = 'gwip'
$VPNClientAddressPool = "172.16.201.0/24"

# 2. If necessary
Login-AzureRmAccount

# 3. Create a self signed root ca cert and a user cert
$P2SRootCertFileName = 'C:\PacktCARootCert.cer'
$P2SRootCertName     = 'PacktRootCert'
$Mc = 'C:\Program Files\Microsoft SDKs\Windows\v7.1\Bin\x64\makecert.exe'
& $Mc -sky exchange -r -n "CN=PACKTCA" -pe -a sha1 -len 2048 -ss Root $P2SRootCertFileName
& $Mc -n "CN=VPNUserCert" -pe -sky exchange -m 12 -ss My -in "PACKTCA" -is root -a sha1
$Cert        = New-Object -Typename System.Security.Cryptography.X509Certificates.X509Certificate2 `
                         -ArgumentList $P2sRootCertName
$CertBase64  = [system.convert]::ToBase64String($Cert.RawData)
$P2SRootCert = New-AzureRmVpnClientRootCertificate -Name $P2SRootCertName -PublicCertData $CertBase64

# 4. Create the RMGateway objects
$Vnet   = Get-AzureRmVirtualNetwork -Name $NetworkName -ResourceGroupName $RgName
$Subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $GWSubnetName -VirtualNetwork $Vnet
$PIPHT = @{
    Name              = $GWIPName
    ResourceGroupName = $RgName
    Location          = $Locname
    AllocationMethod  = 'Dynamic'
    Tag = "@{Owner = 'PACKT'; Type = 'IP'}"
}
$Pip2 = New-AzureRmPublicIpAddress -@$PIPHT
$IPCHT = @{
    Name            = $GWIPName
    Subnet          = $subnet
    PublicIpAddress = $Pip2
}
$IpConf = New-AzureRmVirtualNetworkGatewayIpConfig  @IPCHT

# 5. Create the Gateway
$Start = Get-Date
New-AzureRmVirtualNetworkGateway -Name $GWName -ResourceGroupName $RgName `
    -Location $Locname -IpConfigurations $ipconf `
    -GatewayType Vpn -VpnType RouteBased `
    -EnableBgp $false -GatewaySku Standard `
    -VpnClientAddressPool $VPNClientAddressPool `
    -VpnClientRootCertificates $p2srootcert `
    -Tag @{Owner = 'PACKT'; Type = 'Gateway'}
$Finish = Get-Date
"Creating the gateway took $(($Finish-$Start).totalminutes) minutes"


# 6. Get the VPN client package URL
$URHT = @{
    ResourceGroupName         = $RGName
    VirtualNetworkGatewayName = $GWName
    ProcessorArchitecture     = 'Amd64'
    $Url                       = $Urls.Split('"')[1]
}
$Urls = Get-AzureRmVpnClientPackage @URHT

# 7. Get the VPN Package
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($URL, 'C:\PacktVPNClient.EXE')
Get-ChildItem -path C:\PacktVPNClient.EXE

# 8. Install VPN Package
C:\PacktVPNClient.EXE