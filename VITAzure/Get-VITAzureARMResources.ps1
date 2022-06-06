Function Get-VITAzureARMResources
{
  <#
      .SYNOPSIS
      Gets Azure Resources

      .DESCRIPTION

      .PARAMETER UserProfile
      this is a UserProfile object to be used

      .PARAMETER SubscriptionName
      Name of the Subscription to be used

      .EXAMPLE
      Get-VITAzureARMResources -UserProfile $UserProfile -SubscriptionName $SubscriptionName

      .NOTES
      this is where you put in extra notes.

  #>
  param
  (
    [Parameter(Mandatory)]
    $UserProfile,
    [Parameter(Mandatory)]
    [String]$Subscriptionid
  )
  $null = Select-AzureRmProfile -Profile $UserProfile -verbose 
  $null = Get-AzureRmSubscription -SubscriptionName $Subscriptionid -TenantId $userprofile.Context.Tenant.TenantId -WarningAction SilentlyContinue -Verbose | Set-AzureRmContext -Verbose 
  Get-AzureRmResource -ExpandProperties -verbose 
}