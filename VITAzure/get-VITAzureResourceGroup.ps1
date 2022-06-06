function get-VITAzureResourceGroup
{
  param
  (
    [Parameter(Mandatory)]
    $UserProfile,
    [Parameter(Mandatory)]
    [string]$SubId,
    [Parameter(Mandatory)]
    [string]$RgName,
    [Parameter(Mandatory)]
    [string]$Region
  )

  $null = Select-AzureRmProfile -Profile $UserProfile
  $null = Get-AzureRmSubscription -SubscriptionId $SubId -TenantId $userprofile.Context.Tenant.TenantId -WarningAction SilentlyContinue | Set-AzureRmContext
  if(!(Get-AzureRmResourceGroup -Name $RgName -Location $region -ErrorAction SilentlyContinue))
  {
    New-AzureRmResourceGroup -Name $RGName -Location $region -Force
  }
  else 
  {
    Get-AzureRmResourceGroup -Name $RgName -Location $region  
  }
}