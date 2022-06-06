function get-VITAzureStorageEndPoint
{
  param(
    [Parameter(Mandatory)]
    $UserProfile,
    [Parameter(Mandatory)]
    [string]$SubId,
    [Parameter(Mandatory)]
    [string]$RGName,
    [Parameter(Mandatory)]
    [string]$StorName
  )
  $null = Select-AzureRmProfile -Profile $UserProfile -Verbose 
  $null = Get-AzureRmSubscription -SubscriptionId $SubId -TenantId $userprofile.Context.Tenant.TenantId -WarningAction SilentlyContinue -Verbose  | Set-AzureRmContext -Verbose 
  $store = Get-AzureRmStorageAccount -ResourceGroupName $RGName -Name $StorName -Verbose 
  (Get-AzureStorageContainer -Context $store.Context -Verbose ).CloudBlobContainer.Uri
}