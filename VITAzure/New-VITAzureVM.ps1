function New-VITAzureVM
{
  param
  (
    [Parameter(Mandatory)]
    $UserProfile,
    [Parameter(Mandatory)]
    [string]$SubscriptionId,
    [Parameter(Mandatory)]
    [string]$VMName,
    [Parameter(Mandatory)]
    [string]$ResGroupName,
    [string]$availset = '',
    [Parameter(Mandatory)]
    [string]$Region,
    [Parameter(Mandatory)]
    [string]$vmsize
  )
  $null = Select-AzureRmProfile -Profile $UserProfile -Verbose 
  $null = Get-AzureRmSubscription -SubscriptionId $SubscriptionId -TenantId $userprofile.Context.Tenant.TenantId -WarningAction SilentlyContinue -Verbose  | Set-AzureRmContext -Verbose 
  if($availset = '')
  {
    $AvailabilitySet = New-AzureRmAvailabilitySet -ResourceGroupName $ResGroupName -Name $availset -Location $Region -Verbose 
    New-AzureRmVMConfig -VMName $VMName -VMSize $vmsize -AvailabilitySetId $AvailabilitySet.Id -Verbose 
  }
  else
  {
    New-AzureRmVMConfig -VMName $VMName -VMSize $vmsize -Verbose 
  }   
}