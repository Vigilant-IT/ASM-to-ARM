Function Get-VITAzureARMVM
{
  <#
      .SYNOPSIS
      Gets Azure RM VMs

      .DESCRIPTION

      .PARAMETER UserProfile
      this is a UserProfile object to be used

      .PARAMETER SubscriptionName
      Name of the Subscription to be used

      .EXAMPLE
      Get-VITAzureARMVM -UserProfile $UserProfile -SubscriptionName $SubscriptionName

      .NOTES
      this is where you put in extra notes.

  #>
  param
  (
    [Parameter(Mandatory)]
    $UserProfile,
    [Parameter(Mandatory)]
    [String]$Subscriptionid,
    [Parameter(Mandatory)]
    [String]$ResourceGroupName
  )
  $null = Select-AzureRmProfile -Profile $UserProfile -Verbose 
  $null = Get-AzureRmSubscription -SubscriptionId $Subscriptionid -TenantId $userprofile.Context.Tenant.TenantId -WarningAction SilentlyContinue -Verbose | Set-AzureRmContext -Verbose 
  if($ResourceGroupName)
  {
    Get-AzureRmVM -ResourceGroupName $ResourceGroupName -verbose 
  } 
  else 
  {
    Get-AzureRmVM -Verbose 
  }
}