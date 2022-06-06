Function Get-VITAzureASMVMList
{
  <#
      .SYNOPSIS
      Gets list of VM's from Subscription

      .DESCRIPTION

      .PARAMETER UserProfile
      this is a UserProfile object to be used

      .PARAMETER SubscriptionName
      Name of the Subscription to be used

      .PARAMETER VMName
      Optional Parameter which allows for selection of VM before execution of script

      .EXAMPLE
      Get-VITAzureASMVMList -UserProfile $UserProfile -SubscriptionName $SubscriptionName

      .EXAMPLE
      Get-VITAzureASMVMList -UserProfile $UserProfile -SubscriptionName $SubscriptionName -vmname 'Name of VM'

      .NOTES
      this is where you put in extra notes.

  #>
  param
  (
    [Parameter(Mandatory)]
    $UserProfile,

    [Parameter(Mandatory)]
    [String]$Subscriptionid,
    [string]$vmname = ''
  )
  $null = Select-AzureRmProfile -Profile $UserProfile -Verbose 
  
  $null = Get-AzureRmSubscription -Subscriptionid $Subscriptionid -TenantId $userprofile.Context.Tenant.TenantId -WarningAction SilentlyContinue -verbose | Set-AzureRmContext -verbose 
  if ($vmname -eq '') 
  {
    Find-AzureRmResource -ExpandProperties -ResourceType 'Microsoft.ClassicCompute/virtualMachines' -Verbose  
  }
  else 
  {
    Find-AzureRmResource -ExpandProperties -ResourceType 'Microsoft.ClassicCompute/virtualMachines' -ResourceNameContains $vmname -Verbose 
  }
}