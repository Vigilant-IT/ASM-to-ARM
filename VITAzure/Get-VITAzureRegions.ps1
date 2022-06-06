Function Get-VITAzureRegions
{
<#
    .SYNOPSIS
    Gets a list of Azure Regions against a specified Azure account

    .DESCRIPTION

    .PARAMETER UserProfile
    this is a UserProfile object to be used

    .PARAMETER SubscriptionName
    Name of the Subscription to be used

    .EXAMPLE
    Get-VITAzureRegions -UserProfile $UserProfile -SubscriptionName $SubscriptionName

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
  $null = Select-AzureRmProfile -Profile $UserProfile -Verbose 
  $null = Get-AzureRmSubscription -Subscriptionid $Subscriptionid -TenantId $userprofile.Context.Tenant.TenantId -WarningAction SilentlyContinue -Verbose | Set-AzureRmContext -Verbose 
  Get-AzureRmLocation -Verbose 
}