Function Get-VITAzureASMInventory
{
  <#
      .SYNOPSIS
      Gets Inventory for Azure Classic (ASM) VMs & vNets and displays them as resources

      .DESCRIPTION

      .PARAMETER UserProfile
      this is a UserProfile object to be used

      .PARAMETER SubscriptionName
      Name of the Subscription to be used

      .EXAMPLE
      Get-VITAzureASMInventory -UserProfile $UserProfile -SubscriptionName $SubscriptionName

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
  $null = Get-AzureRmSubscription -Subscriptionid $Subscriptionid -TenantId $userprofile.Context.Tenant.TenantId -WarningAction SilentlyContinue -Verbose  | Set-AzureRmContext -Verbose 
  Get-AzureRmResource -ExpandProperties -verbose 
}