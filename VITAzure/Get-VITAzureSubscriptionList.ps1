Function Get-VITAzureSubscriptionList
{
  <#
      .SYNOPSIS
      Gets list of Subscriptions from Azure Account

      .DESCRIPTION

      .PARAMETER UserProfile
      this is a UserProfile object to be used

      .PARAMETER SubscriptionName
      Name of the Subscription to be used

      .EXAMPLE
      Get-VITAzureSubscriptionList -UserProfile $UserProfile

      .EXAMPLE
      Get-VITAzureSubscriptionList -UserProfile $UserProfile -SubName 'SubscriptionName'

      .NOTES
      this is where you put in extra notes.

  #>
  param
  (
    [Parameter(Mandatory)]
    $UserProfile,
    [string]$Subscriptionid = ''
  )
  $null = Select-AzureRmProfile -Profile $UserProfile -WarningAction Ignore -Verbose 
  if ($Subscriptionid -eq '') 
  {
    Get-AzureRmSubscription -WarningAction Ignore -Verbose 
  }
  else 
  {
    Get-AzureRmSubscription -Subscriptionid $Subscriptionid -TenantId $userprofile.Context.Tenant.TenantId -WarningAction Ignore -Verbose 
  }
}