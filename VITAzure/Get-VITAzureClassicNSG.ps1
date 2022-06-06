Function Get-VITAzureClassicNSG
{
  <#
      .SYNOPSIS
      Gets a list of all Classic based NSGs on Azure against a specific Azure subscription

      .DESCRIPTION

      .PARAMETER UserProfile
      this is a UserProfile object to be used

      .PARAMETER SubscriptionName
      Name of the Subscription to be used

      .EXAMPLE
      Get-VITAzureClassicNSG -UserProfile $UserProfile -SubscriptionName $SubscriptionName

      .NOTES
      this is where you put in extra notes.

  #>
  param
  (
    [Parameter(Mandatory)]
    $UserProfile,
    [Parameter(Mandatory)]
    [String]$SubscriptionName
  )
  $null = Select-AzureRmProfile -Profile $UserProfile -Verbose 
  $null = Get-AzureRmSubscription -SubscriptionName $SubscriptionName -TenantId $userprofile.Context.Tenant.TenantId -WarningAction SilentlyContinue -Verbose | Set-AzureRmContext -Verbose 
  Get-AzureNetworkSecurityGroup -Detailed -verbose 
}