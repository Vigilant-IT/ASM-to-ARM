Function Get-VITAzureRGs
{
<#
    .SYNOPSIS
    Gets a list of all Azure Resource Groups

    .DESCRIPTION

    .PARAMETER UserProfile
    this is a UserProfile object to be used

    .PARAMETER SubscriptionName
    Name of the Subscription to be used

    .EXAMPLE
    Get-VITAzureRGs -UserProfile $UserProfile -SubscriptionName $SubscriptionName

    .NOTES
    this is where you put in extra notes.

#>
  param
  (
    [Parameter(Mandatory)]
    $UserProfile,
    [Parameter(Mandatory)]
    [string]$SubscriptionID,
    [Parameter(Mandatory=$false)]
    [string]$ResGroupName
  )
  $null = Select-AzureRmProfile -Profile $UserProfile -Verbose 
  $null = Get-AzureRmSubscription -SubscriptionId $SubscriptionId -TenantId $userprofile.Context.Tenant.TenantId -WarningAction SilentlyContinue -Verbose  | Set-AzureRmContext -Verbose 
  if ($ResGroupName.Length -eq 0)
  {
    Get-AzureRmResourceGroup -Verbose 
  }
  else
  {
    Get-AzureRmResourceGroup -Name $ResGroupName -Verbose 
  } 
}