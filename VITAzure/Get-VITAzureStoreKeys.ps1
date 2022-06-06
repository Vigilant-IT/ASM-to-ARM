function Get-VITAzureStoreKeys
{
  param
  (
    [Parameter(Mandatory)]
    $UserProfile,
    [Parameter(Mandatory)]
    [string]$SubId,
    [Parameter(Mandatory)]
    [string]$StoreName,
    [Parameter(Mandatory)]
    [string]$resGrpName,
    [switch]$ARM
  )
  if($ARM)
  {
    $null = Select-AzureRmProfile -Profile $UserProfile -Verbose 
    $null = Get-AzureRmSubscription -SubscriptionId $SubId -TenantId $userprofile.Context.Tenant.TenantId -WarningAction SilentlyContinue -Verbose  | Set-AzureRmContext -Verbose 
    Get-AzureRmStorageAccountKey -Name $StoreName -ResourceGroupName $resGrpName -Verbose
  }
  else
  {
  $null = Select-AzureProfile -Profile $(New-AzureProfile)
        $null = Add-AzureAccount
    (Get-AzureStorageKey -StorageAccountName $StoreName -Verbose).Primary
  }
}