function Get-VITAzureNSG
{
  param
  (
    [Parameter(Mandatory)]
    $UserProfile,
    [Parameter(Mandatory)]
    [string]$SubId,
    [Parameter(Mandatory)]
    $NSG        
  )
  $null = Select-AzureRmProfile -Profile $UserProfile -Verbose 
  $null = Get-AzureRmSubscription -SubscriptionId $Subid -TenantId $userprofile.Context.Tenant.TenantId -WarningAction SilentlyContinue -Verbose  | Set-AzureRmContext -Verbose 
    
  $rules = @()
  foreach($rule in ($NSG.Rules | Where-Object {$_.Priority -ge '100' -and $_.Priority -le '4096'} -Verbose ))
  {
    $rules += New-AzureRmNetworkSecurityRuleConfig -Name ($rule.name -replace '\W','') -Access $rule.Action -Protocol $rule.Protocol `
    -Direction $rule.Type -Priority $rule.Priority -SourceAddressPrefix ($rule.SourceAddressPrefix -Replace '_','') `
    -SourcePortRange $rule.SourcePortRange -DestinationAddressPrefix ($rule.DestinationAddressPrefix -Replace '_','') `
    -DestinationPortRange $rule.DestinationPortRange -Verbose 
  }
  $rules
    
}