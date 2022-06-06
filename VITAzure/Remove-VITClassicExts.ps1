function Remove-VITClassicExts 
{
<#
    .SYNOPSIS
    To migrate a VM from Classic to ARM you need to remove all of the extensions first. this Function completes that task

    .DESCRIPTION

    .PARAMETER UserProfile
    UserProfile is the Azure UserProfile obtained earlier in the script

    .PARAMETER SubName
    Name of the Subscription to be used

    .PARAMETER ClassicVms
    This is expecting an array of Computer objects returned from Azure.

    .EXAMPLE
    Remove-VITClassicExts  -UserProfile $UserProfile -SubName $SubscriptionName -ClassicVms $ClassicVms

    .NOTES
    this is where you put in extra notes.

#>
  param
  (
    [PARAMETER(Mandatory)]
    $UserProfile,
    [PARAMETER(Mandatory)]
    [string]$Subid,
    [PARAMETER(Mandatory)]
    $ClassicVms,
    [Parameter(Mandatory)]
    [pscredential]$creds
  )
  $null = Add-AzureAccount -Environment (Get-AzureRmEnvironment -name AzureCloud -Verbose ) -Credential $creds -Verbose 
  $null = Select-AzureSubscription -SubscriptionId $Subid -Default -Verbose 
  $VM = Get-AzureVM -Name $ClassicVms.Name -ServiceName $ClassicVms.Properties.HardwareProfile.DeploymentName -Verbose 
  $extensions = Get-AzureVMExtension -VM $VM -Verbose 
  foreach($extension in $extensions)
  {
    #Write-Verbose "Removing Extension: " $extension.ExtensionName " From: " $vm.HostName
    Remove-AzureVMExtension -ExtensionName $extension.ExtensionName -Publisher $extension.Publisher -VM $VM -Verbose 
    $VM | Set-AzureVMExtension -Publisher $extension.Publisher -ExtensionName $extension.ExtensionName -Version $extension.Version -Uninstall -Verbose  | Update-AzureVM -Verbose 
  }
}