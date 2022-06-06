function Get-VITAzureStorageAccount
{
<#
    .SYNOPSIS
    Gets a list of all Storage Accounts in Azure for both ASM & ARM

    .DESCRIPTION

    .PARAMETER UserProfile
    this is a UserProfile object to be used

    .PARAMETER SubscriptionName
    Name of the Subscription to be used

    .PARAMETER resourceGroupName
    Parameter which allows for specification of an Azure Resource Group Name to be used

    .PARAMETER ARM
    Parameter which allows for specification of whether to use ARM or not

    .EXAMPLE
    Get-VITAzureStorageAccount -UserProfile $SourceUserProfile -SubscriptionName $SourceSubscriptionName -ARM

    .NOTES
    this is where you put in extra notes.

#>
  param
  (
    [Parameter(Mandatory)]
    $UserProfile,
    [Parameter(Mandatory)]
    [string]$SubscriptionName,
    [switch]$ARM
  )
  $null = Select-AzureRmProfile -Profile $UserProfile -Verbose 
  $null = Get-AzureRmSubscription -SubscriptionName $SubscriptionName -TenantId $userprofile.Context.Tenant.TenantId -WarningAction SilentlyContinue -Verbose  | Set-AzureRmContext -Verbose 
  if($ARM)
  {
    Get-AzureRmStorageAccount -Verbose 
  }
  else
  {
    Get-AzureStorageAccount -Verbose 
  }   
}