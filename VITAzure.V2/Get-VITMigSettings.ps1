Import-Module C:\Scripts\Azure\Azure.psd1
Import-Module azurerm
$env = 'ASM' #'ASM' or 'ARM'
class Sub
{
  [string]$SubID
  [string]$SubName
  [string]$username
  [string]$TenantID
  [string]$AccountType
  [string]$environment
  sub([string]$ENV)
  {
    if($env -eq 'ASM')
    {
      $null = add-AzureAccount -ErrorAction Ignore
      $sub = Get-AzureSubscription 
      $sub = $sub | Out-GridView -PassThru
      Select-AzureSubscription -SubscriptionId $sub.SubscriptionId -Current
      $this.SubID = $sub.SubscriptionId
      $this.SubName = $sub.SubscriptionName
      $this.AccountType = 'ASM'
      $this.username = $sub.DefaultAccount
      $this.TenantID = $sub.TenantId
      $this.environment = $sub.Environment
    }    
    elseif($env -eq 'ARM')
    {
      $null = Add-AzurermAccount
      $sub = Get-AzureRmSubscription 
      $sub = $sub | Out-GridView -PassThru
      $context = Set-AzureRmContext -SubscriptionId $sub.SubscriptionId -TenantId $sub.TenantId
      $this.SubID = $Context.Subscription.SubscriptionId
      $this.SubName = $context.Subscription.SubscriptionName
      $this.AccountType = 'ARM'
      $this.username = $context.Account.id
      $this.TenantID = $context.Subscription.TenantId
      $this.environment = $context.Environment.name
    }
  }
}
class VM
{
  [string]$name
  [string]$Size
  [string]$Region
  [string]$ResourceGroup
  [int]$NumberDataDisk
  [int]$NumberNic
  VM($env)
  {
    if($env -eq 'ASM')
    {
      $vm = Get-AzureVM | Out-GridView -PassThru
      $service = Get-AzureService -ServiceName $vm.ServiceName
      $this.name = $vm.Name
      $this.ResourceGroup = $vm.ServiceName
      $this.Size = $vm.InstanceSize
      $this.Region = $service.Location
      $this.NumberDataDisk = $vm.vm.DataVirtualHardDisks.count
    }
    elseif ($env -eq 'ARM')
    {
      $vm = get-azurermvm | Out-GridView -PassThru
      $this.name = $vm.Name
      $this.ResourceGroup = $vm.ResourceGroupName
      $this.Region = $vm.Location
      $this.Size = $vm.hardwareprofile.VmSize
      $this.NumberDataDisk = $vm.StorageProfile.DataDisks.count
      $this.NumberNic = $vm.networkprofile.networkinterfaces.count
    }
  }
}
class Disks
{
  [string]$StoragePath
  [string]$StorageKey
  [string]$VHDName
  [int]$LUN
  [int]$size
  [string]$resourceGroup
  [string]$IO
  [string]$contents
  op_Addition(){}
  Disks($env, [vm]$sVM) #OSDisk
  {
    if($env -eq 'ASM')
    {
      $sourcevm = get-azurevm -Name $svm.Name -ServiceName $svm.ResourceGroup
      $osdisk = $sourcevm.vm.OSVirtualHardDisk
      $this.VHDName = $osdisk.MediaLink.LocalPath -split '/' | Select-Object -Last 1
      $this.size = 0
      $this.LUN = $null
      $this.IO = $osdisk.IOType
      $this.contents = $osdisk.OS
      $this.StoragePath = "$($osdisk.MediaLink.Scheme)://$($osdisk.MediaLink.Authority)"
      $this.resourceGroup = $osdisk.MediaLink.Authority -replace ".blob.core.windows.net"
      $this.StorageKey = (Get-AzureStorageKey -StorageAccountName $this.resourceGroup).Primary
    }
    elseif($env -eq 'ARM')
    {
      $sourcevm = Get-AzureRmVM -name $svm.name -ResourceGroupName $svm.ResourceGroup
      $odisk = $sourcevm.StorageProfile.OsDisk
      $StoreAccount = Get-AzureRmStorageAccount | Where-Object {$_.StorageAccountName -eq (($odisk.vhd.Uri.Split('.') | Select-Object -First 1).split('//') | select -last 1)}
      $this.contents = $odisk.OSType
      $this.VHDName = $odisk.Name
      $this.size = $null
      $this.LUN = $null
      $this.StoragePath = $odisk.Vhd.Uri -replace "/$($odisk.Name)"
      $this.StorageKey = (Get-AzureRmStorageAccountKey -Name $StoreAccount.StorageAccountName -ResourceGroupName $StoreAccount.ResourceGroupName).Value[0]
      $this.resourceGroup = $StoreAccount.ResourceGroupName
      $this.IO = $StoreAccount.sku.Name
    }
  }
  Disks($env, [vm]$sVM, [int]$DiskNum) #DataDisk
  {
    if($env -eq 'ASM')
    {
      $sourcevm = get-azurevm -Name $svm.Name -ServiceName $svm.ResourceGroup
      $datadisk = $sourcevm.vm.DataVirtualHardDisks[$disknum]
      $this.VHDName = $datadisk.medialink.LocalPath -split '/' | Select-Object -Last 1
      $this.size = $datadisk.LogicalDiskSizeInGB
      $this.contents = 'data'
      $this.lun = $datadisk.lun
      $this.IO = $datadisk.IOType
      $this.StoragePath = "$($datadisk.medialink.Scheme)://$($datadisk.medialink.Authority)"
      $this.resourceGroup = $datadisk.medialink.Authority -replace ".blob.core.windows.net"
      $this.StorageKey = (Get-AzureStorageKey -StorageAccountName $this.resourceGroup).Primary
    }
    elseif($env -eq 'ARM')
    {
      $sourcevm = Get-AzureRmVM -name $svm.name -ResourceGroupName $svm.ResourceGroup
      $datadisk = $sourcevm.StorageProfile.DataDisks[$disknum]
      $StoreAccount = Get-AzureRmStorageAccount | Where-Object {$_.StorageAccountName -eq ($datadisk.vhd.Uri -replace ".blob.core.windows.net/vhds/$($datadisk.Name)" -split '//' | select -last 1)}
      $this.VHDName = $datadisk.Name
      $this.LUN = $datadisk.Lun
      $this.size = $datadisk.DiskSizeGB
      $this.contents = 'Data'
      $this.StoragePath = $datadisk.Vhd.Uri -replace "/$($datadisk.Name)"
      $this.StorageKey = (Get-AzureRmStorageAccountKey -Name $StoreAccount.StorageAccountName -ResourceGroupName $StoreAccount.ResourceGroupName).Value[0]
      $this.resourceGroup = $StoreAccount.ResourceGroupName
      $this.IO = $StoreAccount.sku.Name
    }
  }
}
class Network
{
  [string]$vnetname
  [string]$InternalIP
  [string]$ExternalIP
  [string]$VNetID
  [string]$ResourceGroup
  [string]$SubnetScope
  Network($env, [vm]$svm, [int]$nicnum)
  {
    if($env -eq 'ASM')
    {
      $sourcevm = get-azurevm -Name $svm.Name -ServiceName $svm.ResourceGroup
      $vnet = [xml]((Get-AzureVNetConfig).XMLConfiguration)
      $nets = $vnet.NetworkConfiguration.VirtualNetworkConfiguration.VirtualNetworkSites.VirtualNetworkSite | Where-Object {$_.name -eq $sourcevm.VirtualNetworkName}
      $subnet = $nets.Subnets.Subnet | Where-Object {$_.name -eq $sourcevm.vm.ConfigurationSets.subnetnames}
      $this.InternalIP = $sourcevm.IpAddress
      $this.ExternalIP = $sourcevm.PublicIPAddress
      $this.vnetname = $sourcevm.VirtualNetworkName
      $this.SubnetScope = $subnet.AddressPrefix
    }
    elseif($env -eq 'ARM')
    {
      $sourcevm = Get-AzureRmVM -name $svm.name -ResourceGroupName $svm.ResourceGroup
      $vnic = Get-AzureRmResource -ResourceId $sourcevm.NetworkProfile.NetworkInterfaces[$nicnum].Id
      $vnet = Get-AzureRmVirtualNetwork -Name ($vnic.Properties.ipConfigurations.properties.subnet.id.Split('/') | Select-Object -Last 3 | Select-Object -First 1) -ResourceGroupName $vnic.ResourceGroupName
      $subnet = $vnet.Subnets | Where-Object {$_.name -eq ($vnic.Properties.ipConfigurations.properties.subnet.id.Split('/') | Select-Object -last 1)}
      $this.InternalIP = $vnic.Properties.ipConfigurations.properties.privateIPAddress
      $this.ResourceGroup = $vnet.ResourceGroupName
      $this.SubnetScope = $subnet.AddressPrefix
      $this.vnetname = $vnet.Name
      $this.VNetID = $vnet.Id
    }
  }
}

class Source
{
  [sub]$subscription
  [Disks]$OSdisk
  [object]$DataDisk
  [object]$network
  [vm]$vm
  source($sub, $dis, $ddis, $net, $vm)
  {
    $this.subscription = $sub
    $this.osdisk = $dis
    $this.DataDisk = $ddis
    $this.network = $net
    $this.vm = $vm
  }
}
$testsub = $null
$testvm = $null
$osdisk = $null
$ddisk = $null
$testnet = $null
Write-Output $env
$testsub = [sub]::new($env)
$testvm = [vm]::new($env)
$osDisk = [disks]::new($env, $testvm)
$ddisk = @()
$dnum = 0
if($testvm.NumberDataDisk -ne 0)
{
  while($dnum -ne $testvm.NumberDataDisk)
  {
    $ddisk += [disks]::new($env, $testvm, ($dnum))
    $dnum ++
  }
}
$vnum = 0
$vnets = @()
while($vnum -ne $testvm.NumberNic)
{
  $vnets += [Network]::new($env, $testvm, $vnum)
  $vnum ++
}
$vnets = [Network]::new($env, $testvm, $vnum)
$source = [source]::new($testsub, $osDisk, $dDisk, $vnets, $testvm)
$source | ConvertTo-Json -Depth 100 | Out-File "c:\data\$($testvm.name).json"