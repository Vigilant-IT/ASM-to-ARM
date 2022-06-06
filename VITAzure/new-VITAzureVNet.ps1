function new-VITAzureVNet
{
  param
  (
    [Parameter(Mandatory)]
    $SourceUserProfile,
    [Parameter(Mandatory)]
    $SourceSubid,
    [Parameter(Mandatory)]
    $vnetname,
    [Parameter(Mandatory)]
    $SourceResGrp,
    [Parameter(Mandatory)]
    $region,
    [Parameter(Mandatory)]
    $TargetResGrp,
    [parameter(Mandatory)]
    $TargetUserProfile,
    [parameter(Mandatory)]
    $TargetSubID
  )
  $vnet = Get-VITAzureASMVMInventory -UserProfile $SourceUserProfile -Subscriptionid $SourceSubid -ResID $vnetname.id -ResGroup $SourceResGrp
  $null = Select-AzureRmProfile -Profile $TargetUserProfile -Verbose 
  $null = Get-AzureRmSubscription -Subscriptionid $TargetSubID -TenantId $targetuserprofile.Context.Tenant.TenantId -WarningAction SilentlyContinue -Verbose  | Set-AzureRmContext -Verbose 
  if($vnet.properties.dhcpOptions.dnsServers)
  {
    $dns = $vnet.properties.dhcpOptions.dnsServers
  }
  else
  {
    $dns = @('8.8.8.8','8.8.4.4')
  }
  $subconfig = @()
  foreach ($subnet in $vnet.properties.subnets)
  {
    $subconfig += New-AzureRmVirtualNetworkSubnetConfig -name $subnet.name -AddressPrefix $subnet.Addressprefix -Verbose 
  }
  $newvnet = New-AzureRmVirtualNetwork -ResourceGroupName $TargetResGrp -name $vnet.name -Location $region -AddressPrefix $vnet.properties.addressspace.addressPrefixes -DnsServer $dns -Subnet $subconfig -Force -Verbose 
  foreach ($subnet in $vnet.Properties.subnets)
  {
    $subNSG = Get-AzureNetworkSecurityGroupForSubnet -VirtualNetworkName $VNetName -SubnetName $SubNet.Name -Detailed -erroraction SilentlyContinue
    if($subNSG)
    {
      $SubNetNSG = Get-VITAzureNSG -UserProfile $SourceUserProfile -Subid $SourceSubid -NSG $subNSG
      $null = Select-AzureRmProfile -Profile $TargetUserProfile -Verbose 
  $null = Get-AzureRmSubscription -Subscriptionid $TargetSubID -TenantId $targetuserprofile.Context.Tenant.TenantId -WarningAction SilentlyContinue -Verbose  | Set-AzureRmContext -Verbose 
  $newNSG = New-AzureRmNetworkSecurityGroup -Name ($subNSG.name -replace '\W') -Location $Region -ResourceGroupName $TargetResGrp -SecurityRules $SubNetNSG -Force -Verbose 
      $Subnet = Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $newvnet -name $subnet.name -AddressPrefix $subnet.AddressPrefix -NetworkSecurityGroup $newNSG -Verbose 
      Set-AzureRmVirtualNetwork -VirtualNetwork $Subnet -Verbose 
    }
  }
}