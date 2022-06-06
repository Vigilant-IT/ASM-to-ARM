Function Get-VITAzureASMVMInventory
{
  <#
      .SYNOPSIS
      Gets Inventory for specific ASM resource types and displays them as resources

      .DESCRIPTION

      .PARAMETER UserProfile
      this is a UserProfile object to be used

      .PARAMETER SubscriptionName
      Name of the Subscription to be used

      .EXAMPLE
      Get-VITAzureASMVMInventory -UserProfile $UserProfile -SubscriptionName $SubscriptionName

      .NOTES
      this is where you put in extra notes.

  #>
  param
  (
    [Parameter(Mandatory)]
    $UserProfile,
    [Parameter(Mandatory)]
    [string]$SubscriptionId,
    [ValidateSet('Microsoft.ClassicNetwork/virtualNetworks','Microsoft.ClassicCompute/virtualMachines','Microsoft.ClassicStorage','Microsoft.ClassicNetwork/networkSecurityGroups','Microsoft.Compute/virtualMachines')]
    [string]$ResType = 'Microsoft.ClassicCompute/virtualMachines',
    [Parameter(Mandatory)]
    [String]$ResGroup,
    [string]$ResID = '',
    [string]$resname = ''
  )
  $null = Select-AzureRmProfile -Profile $UserProfile -verbose 
  $sub = Get-AzureRmSubscription -SubscriptionId $SubscriptionID -TenantId $userprofile.Context.Tenant.TenantId -WarningAction SilentlyContinue -Verbose | Set-AzureRmContext -Verbose 
  if ($resid -eq '' -or $resname -eq '')
  {
    Get-AzureRmResource -ExpandProperties -ResourceType $ResType -ResourceGroupName $ResGroup -Verbose 
  }
  if ($resid)
  {
    Get-AzureRmResource -ExpandProperties -Resourceid $ResID -Verbose 
  }
  if ($resname)
  {
    Get-AzureRmResource -ExpandProperties -ResourceName $resname -ResourceGroupName $ResGroup -Verbose
  }
}