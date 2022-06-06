#UPDATE THIS SECTION FOR YOUR TESTING
#TODO: AzCopy of the VHD's
#TODO: Create New VM
#TODO: Get VM
#TODO: Get Existing Disk
#TODO: Output to JSON file
#TODO: Read from JSON file

$ErrorActionPreference = "Stop"
$env = 'ARM'
$new = $true
$name = $storename = ''
$location = ''
$addressRange = '10.0.0.0/11'
$skunames = @('Premium_LRS', 'Standard_GRS','Standard_LRS','Standard_RAGRS','Standard_ZRS')
$netname = ''
$netResGrp = ''

#region handle JSON
#param
#(
#  [String]
#  [Parameter(Mandatory)]
#  $JSONFile,
#  [string]
#  [Parameter(Mandatory)]
#  $env
#)
#if($JSONFile -match ".json")
#{
#  $source = (Get-Content -Path $JSONFile -Raw) | ConvertFrom-Json
#}
#else
#{
#  Write-Error -Message 'File does not end in ".JSON"'
#  return
#}
##endregion 
##region Completed Classes
#Import-Module azure
#Import-Module azurerm
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
      $null = Add-AzureAccount
      $sub = Get-AzureSubscription | Out-GridView -PassThru
      $null = Select-AzureSubscription -SubscriptionId $sub.SubscriptionId -Current
      $this.SubID = $sub.SubscriptionId
      $this.SubName = $sub.SubscriptionName
      $this.AccountType = 'ASM'
      $this.username = $sub.DefaultAccount
      $this.TenantID = $sub.TenantId
      $this.environment = $sub.Environment
    }    
    elseif($env -eq 'ARM')
    {
      Write-Progress -Activity 'Get ARM Subscription' -Status 'Please Authenticate to ARM' -Id 1 -PercentComplete 0
      $null = Add-AzurermAccount
      Write-Progress -Activity 'Get ARM Subscription' -Status 'Thank you for the Creds' -id 1 -PercentComplete 25
      $sub = Get-AzureRmSubscription 
      Write-Progress -Activity 'Get ARM Subscription' -Status 'Please Select the Correct Subscription' -id 1 -PercentComplete 50
      $sub = $sub | Out-GridView -PassThru
      $context = Set-AzureRmContext -SubscriptionId $sub.SubscriptionId -TenantId $sub.TenantId
      Write-Progress -Activity 'Get ARM Subscription' -Status 'Thank you for the selection' -id 1 -PercentComplete 75
      $this.SubID = $Context.Subscription.SubscriptionId
      $this.SubName = $context.Subscription.SubscriptionName
      $this.AccountType = 'ARM'
      $this.username = $context.Account.id
      $this.TenantID = $context.Subscription.TenantId
      $this.environment = $context.Environment.name
      Write-Progress -Activity 'Get ARM Subscription' -Status 'Returning Subscription, Thank you, Please Come again' -Id 1 -Completed
    }
  }
}
class ResGrp
{
  [string]$Name
  [string]$ResID
  [string]$Region
  resgrp(){}
  ExistingRG($Name)
  {
    $rg = Get-AzureRmResourceGroup -Name $name -ErrorAction SilentlyContinue
    if($rg -ne $null)
    {
      $this.Name = $rg.ResourceGroupName
      $this.ResID = $rg.ResourceId
      $this.Region = $rg.Location
    }
    else
    {
      Write-Error 'Resource Group Doesnt Exists, Please use the [ResGrp]::new.CreateRG($Name,$location) method.' 
    }
  }
  CreateRG($name, $Loc)
  {
    $rg = Get-AzureRmResourceGroup -Name $name -ErrorAction SilentlyContinue
    if($rg -eq $null)
    {
      $rg = new-AzureRmResourceGroup -name $name -location $loc
      $this.Name = $rg.ResourceGroupName
      $this.ResID = $rg.ResourceId
      $this.Region = $rg.Location
    }
    else
    {
      Write-Error 'Resource Group Already Exists, Please use the [ResGrp]::new.ExistingRG($Name) method.'
    }
  }
}
class StorageAccount
{
  [string]$StorageAccountPath
  [string]$StorageAccountKey
  [string]$ResourceID
  [string]$SKU
  [string]$Storagename
  [string]$region
  Existing($Storagename, [sub]$sub, [ResGrp]$RG)
  {
    if($Storagename -eq '')
    {
      $azurestore = Get-AzureRmStorageAccount | ogv -PassThru
      $this.region = $azurestore.Location
      $this.ResourceID = $azurestore.id
      $this.Storagename = $azurestore.StorageAccountName
      $this.SKU = $azurestore.Sku.Name
      $this.StorageAccountPath = $azurestore.PrimaryEndpoints.Blob
      $this.StorageAccountKey = (Get-AzureRmStorageAccountKey -Name $azurestore.StorageAccountName -ResourceGroupName $azurestore.ResourceGroupName).Value[0]
    }
    else
    {
      $azurestore = Get-AzureRmStorageAccount -name $Storagename -ResourceGroupName $rg.Name
      $this.region = $azurestore.Location
      $this.ResourceID = $azurestore.id
      $this.Storagename = $azurestore.StorageAccountName
      $this.SKU = $azurestore.Sku.Name
      $this.StorageAccountPath = $azurestore.PrimaryEndpoints.Blob
      $this.StorageAccountKey = (Get-AzureRmStorageAccountKey -Name $azurestore.StorageAccountName -ResourceGroupName $azurestore.ResourceGroupName).Value[0]
    }
  }
  create($name, [ResGrp]$RG, $SKU)
  {
    Write-Progress -Activity 'Create new Storage Account' -Status 'Creating Storage Account this can take a while please wait' -Id 1 -PercentComplete 10
    $AzureStore = new-azurermstorageaccount -ResourceGroupName $rg.Name -Name ($name.ToLower()) -SkuName $sku -Location $rg.Region
    Write-Progress -Activity 'Create new Storage Account' -Status 'Storage Account Created, now creating VHDS Container' -Id 1 -PercentComplete 80
    Set-AzureRmCurrentStorageAccount -ResourceGroupName $rg.name -Name $name
    $null = New-AzureStorageContainer -name 'vhds' -Permission Off -Verbose 
    $this.region = $azurestore.Location
    $this.ResourceID = $azurestore.id
    $this.Storagename = $azurestore.StorageAccountName
    $this.SKU = $azurestore.Sku.Name
    $this.StorageAccountPath = $azurestore.PrimaryEndpoints.Blob
    $this.StorageAccountKey = (Get-AzureRmStorageAccountKey -Name $azurestore.StorageAccountName -ResourceGroupName $azurestore.ResourceGroupName).Value[0]
    Write-Progress -Activity 'Create new Storage Account' -Status 'Completed Creating the new Storage Account' -Id 1 -PercentComplete 100
  }
}
Class Network
{
  [String]$VNetName
  [String]$SubnetName
  [String]$ResourceGroup
  [string]$NICID
  Existing($env, $name, [sub]$sub, [ResGrp]$Rg)
  {
    $vnet = get-azurermvirtualnetwork -ResourceGroupName $rg.name -Name $name
    $nic = Get-AzureRmNetworkInterface -ResourceGroupName $rg.name -name "$name-NIC"
    $this.ResourceGroup = $rg.Name
    $this.VNetName = $vnet.Name
    $this.SubnetName = $vnet.Subnets[0].name
    $this.NICID = $nic.Id
  }
  Create($Env, $name, [sub]$sub, [ResGrp]$rg, $subnetName, $AddressRange, $region)
  {
    $newsubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $name -AddressPrefix $addressRange
    $newvnet = New-AzureRmVirtualNetwork -ResourceGroupName $rg.name -name $name -Location $region -AddressPrefix @($addressRange) -DnsServer @('8.8.8.8','8.8.4.4') -Subnet $newsubnet -Force
    $nic = New-AzureRmNetworkInterface -Name "$name-NIC" -ResourceGroupName $rg.Name -Location $region -Subnet $newvnet.Subnets[0]
    $this.ResourceGroup = $rg.Name
    $this.SubnetName = $newsubnet.Name
    $this.VNetName = $newvnet.Name
    $this.NICID = $nic.Id
  }
  NewNIC($env, $nicname, $name,  [ResGrp]$Rg, $region)
  {
    $vnet = get-azurermvirtualnetwork -ResourceGroupName $rg.name -Name $name
    $nic = New-AzureRmNetworkInterface -Name "$nicname-NIC" -ResourceGroupName $rg.Name -Location $region -Subnet $vnet.Subnets[0]
    $this.ResourceGroup = $rg.Name
    $this.SubnetName = $vnet.subnets[0].Name
    $this.VNetName = $vnet.Name
    $this.NICID = $nic.Id
  }
}
#endregion
Class Disks
{
  [string]$azcopySourceuri
  [string]$azcopyTargeturi
  [string]$sourcekey
  [string]$targetKey
  [string]$vhdfilename
  [string]$vhduri
  [string]$size
  [int]$lun
  [string]$type
  Copy([storageaccount]$TARstoracc, [sub]$sub, $SRC, $path)
  {
    
   
  }
}
$scriptblock = {
  param($TARstoracc, $testsub, $SRC, $Path)
  $APEScriptPath = $Path
  $azcopytemp = "$env:USERPROFILE\AppData\Local\Microsoft\Azure\AzCopy"
  $jnpath = ("$azcopytemp\$(($SRC.VHDName).replace('.vhd',''))")
  new-item -path $azcopytemp -Name ($SRC.VHDName.split('.') | Select-Object -first 1) -ItemType Directory
  if (($APEScriptPath -split '\\' | select-object -last 1) -eq 'vitazure') {$apescriptpath = split-path $APEScriptPath}
  $params = "/source:$($SRC.StoragePath)/vhds /dest:$($TARstoracc.StorageAccountPath)vhds /SourceKey:$($SRC.StorageKey) /destkey:$($TARstoracc.StorageAccountKey) /pattern:$($SRC.VHDName) /z:$jnpath /v:$($azcopytemp + "\" + $($SRC.VHDName) + ".log")"
  if ($true) 
  {
    $params = $params + ' /y'
  }
  Start-Process -FilePath "$APEScriptPath\Tools\AzCopy\AzCopy.exe" -ArgumentList @($params) -WorkingDirectory "$APEScriptPath\Tools\AzCopy" -Wait -Verbose 
  #remove-item -path "$azcopytemp\$($SRC.VHDName.split('.') | Select-Object -first 1)\" -Recurse
}
##################################
#LOADTO HERE
##################################
$testsub = [sub]::new($env)
if($new)
{
  $ResGrp = [ResGrp]::new()
  $ResGrp.CreateRG($name, $location)
  $StorageAccount = [StorageAccount]::new()
  $StorageAccount.create($storename, $resgrp, $skunames[2])
  $net = [network]::new()
  $net.Create($env, $netname, $testsub, $resgrp, $netname, $addressRange, $location)
}
else
{
  $resgrp = [ResGrp]::new()
  $resgrp.ExistingRG()
  $StorageAccount = [StorageAccount]::new()
  $StorageAccount.Existing($name, $testsub, $ResGrp)
  $net = [Network]::new()
  $net.Existing($env, $netname, $testsub, $netResGrp)
}


$RG = [ResGrp]::new()
$RG.ExistingRG($rgname)
$net = [network]::new()
$net.newnic($env,$name, $netname,  $RG, $location)

$alldisks = @()
$alldisks += $source.OSdisk
foreach ($disk in $source.DataDisk)
{$alldisks += $disk}
$jobs = @()
foreach($d in $alldisks)
{
  $tmpjob = start-job -ScriptBlock $scriptblock -argumentlist $StorageAccount, $testsub, $d, "C:\data" -name $d.VHDName
  $jobs += $tmpjob
}
While ($jobs.state -contains "Running"){
  $jobRunning = $jobs | Where-Object { $_.State -eq "Running" }
  $jobCompleted = $jobs | Where-Object { $_.State -eq "Completed" }
  write-Debug "$($jobCompleted.Count) jobs completed. $($jobRunning.count) jobs remaining."
  Start-Sleep -Seconds 2
}

$vm = New-AzureRmVMConfig -VMName $source.vm.name -VMSize $source.vm.Size
foreach ($d in $alldisks)
{
  if ($d.contents -eq 'Windows')
  {
    $vm = Set-AzureRmVMOSDisk -VM $vm -Name $d.VHDName -VhdUri "$($StorageAccount.StorageAccountPath)vhds/$($d.VHDName)" -CreateOption Attach -Windows
  }
  elseif($d.contents -eq 'Linux')
  {
    $vm = Set-AzureRmVMOSDisk -VM $vm -Name $d.VHDName -VhdUri "$($StorageAccount.StorageAccountPath)vhds/$($d.VHDName)" -CreateOption Attach -Linux
  }
  elseif($d.contents -eq 'data')
  {
    $vm = Add-AzureRmVMDataDisk -VM $vm -Name $d.VHDName -VhdUri "$($StorageAccount.StorageAccountPath)vhds/$($d.VHDName)" -Lun $d.LUN -DiskSizeInGB $d.size -CreateOption Attach
  }
}
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $net.NICID
new-azurermvm -ResourceGroupName $ResGrp.Name -Location $location -VM $vm -DisableBginfoExtension