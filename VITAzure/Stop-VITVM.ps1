Function Stop-VITVM
{
  <#
      .SYNOPSIS
      Powers down the VM defined ensuring that it handles the remain provisioned state.

      .DESCRIPTION

      .PARAMETER UserProfile
      UserProfile is the Azure UserProfile obtained earlier in the script

      .PARAMETER SubName
      Name of the Subscription to be used

      .PARAMETER VMName
      Name of the VM To Stop

      .PARAMETER RGName
      Name of the Resource group the VM is part of.

      .PARAMETER PowerBackUp
      This is a switch to check if you want it powered up or not

      .EXAMPLE
      Stop-VITVM -UserProfile $UserProfile -SubName $SubscriptionName -VMName 'Name of VM' -RGName 'name of Resource Group' -PowerBackUp:$false

      .NOTES
      this is where you put in extra notes.

  #>
  param
  (
    [Parameter(Mandatory)]
    $UserProfile,
    [Parameter(Mandatory)]
    [string]$SubId,
    [Parameter(Mandatory)]
    [string]$VMName,
    [Parameter(Mandatory)]
    [String]$RGName,
    [switch]$PowerBackUp,
    [switch]$ARM
  )
  $null = Select-AzureRmProfile -Profile $UserProfile -Verbose 
  $null = Get-AzureRmSubscription -SubscriptionId $SubId -TenantId $userprofile.Context.Tenant.TenantId -WarningAction SilentlyContinue -Verbose | Set-AzureRmContext -Verbose 
  if($arm)
  {
    Stop-AzureRmVM -Name $vmname -ResourceGroupName $rgname -StayProvisioned:$PowerBackUp -Force -Verbose
  }
  else
  {
    Stop-AzureVM -Name $VMName -ServiceName $rgname -StayProvisioned:$PowerBackUp -Force -Verbose 
  }

}
