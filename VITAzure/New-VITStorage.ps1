Function New-VITStorage
{
  param
  (
    [Parameter(Mandatory)]
    $UserProfile,
    [Parameter(Mandatory)]
    [string]$SubID,
    [Parameter(Mandatory)]
    [object]$RG,
    [Parameter(Mandatory)]
    [string]$region,
    [Parameter(Mandatory)]
    [string]$StorageKey,
    [Parameter(Mandatory)]
    [string]$StorageName,
    [Parameter(Mandatory)]
    [ValidateSet('Standard','Provisioned')]
    [string]$IOType,
    [Parameter(Mandatory)]
    [ValidateSet('OS','Data')]
    [string]$DiskType,
    [Parameter(Mandatory)]
    [string]$StorageType
  )
  $null = Select-AzureRmProfile -Profile $UserProfile -Verbose 
  $null = Get-AzureRmSubscription -Subscriptionid $Subid -TenantId $userprofile.Context.Tenant.TenantId -WarningAction SilentlyContinue -Verbose  | Set-AzureRmContext -Verbose 
  Write-Information "Loggedon:$(([datetime]::now).ToLongTimeString())"
  #$rg = get-VITAzureResourceGroup -RgName $RGName -region $region
  Write-Information "GotRG:$(([datetime]::now).ToLongTimeString())"
  $disk = Get-VITAzureStorageName -IOtype $IOType -DiskType $DiskType
  $storname = "$($RG.ResourceGroupName.Replace('-','').ToLower())$($disk.Storname)1"
  if($storname.Length -gt 24)
  {
    $storname = $storname.Substring(0,23)
  }
  Write-Information "StorageSettings:$(([datetime]::now).ToLongTimeString())"
  $usestore = $null
  $store = Get-AzureRmStorageAccount -ResourceGroupName $rg.ResourceGroupName -Name $storname -ErrorAction SilentlyContinue -Verbose 
  Write-Information "GetStorageAccount:$(([datetime]::now).ToLongTimeString())"
  if ($store.count -ge 1)
  {
    foreach($stor in $store)
    {
      if ((Get-AzureStorageContainer -Context $stor.context -Verbose ).count -ne 0)
      { 
        if ((Get-AzureStorageBlob -Container (Get-AzureStorageContainer -Context $stor.context ).name -Context $stor.context  | Where-Object {$_.Name -like '*.vhd'}  ).count -lt 8)
        {
          Write-Information "ExistingStorageContainer:$(([datetime]::now).ToLongTimeString())"
          $usestore = $stor
          break
        }
      }
      else
      {
        if(!(Get-AzureStorageContainer -Context $stor.context -Name 'vhds' -ErrorAction SilentlyContinue -Verbose ))
        {
          Write-Information "newStorageContainer:$(([datetime]::now).ToLongTimeString())"
          New-AzureStorageContainer -Context $stor.context -name 'vhds' -Permission Off -Verbose 
          $usestore = $stor
          break
        }
      }
    }
  }
  Write-Information "StorageContainersorted:$(([datetime]::now).ToLongTimeString())"  
  if (!$usestore)
  {
    #$PotentialStorage.StorageAccountName -match '\d{1,4}';$int = 1+$matches[0]
    $TargetStorageName = ((("$int" + "$identifier" + $rg.ResourceGroupName.ToLower()) -Replace '\W','').ToCharArray() | Select-Object -First 24) -join ''
    $null = New-AzureRmStorageAccount -ResourceGroupName $rg.ResourceGroupName -Name $storname -Location $region -skuname $StorageType -Verbose 
    $usestore = (Get-AzureRmStorageAccount -ResourceGroupName $rg.ResourceGroupName -Name $storname -Verbose ).Context
    New-AzureStorageContainer -Context $usestore -name 'vhds' -Permission Off -Verbose 
  }
  Write-Information "StorageCompleted:$(([datetime]::now).ToLongTimeString())"
  $usestore
}