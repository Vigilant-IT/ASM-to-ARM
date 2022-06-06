Function connect-Subscription
{
  param
  (
    [Parameter(Mandatory)]
    $UserProfile,
    [Parameter(Mandatory)]
    [String]$Subscriptionid
  )
  Select-AzureRmProfile -Profile $UserProfile -Verbose 
  Get-AzureRmSubscription -Subscriptionid $Subscriptionid -TenantId $userprofile.Context.Tenant.TenantId -WarningAction SilentlyContinue -Verbose  | Set-AzureRmContext -Verbose 
}