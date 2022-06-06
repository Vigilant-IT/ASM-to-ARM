<#
    .SYNOPSIS
    C# interface for making calls into the PowerShell scripts.
    .DESCRIPTION
    As this is the interface between c# and PowerShell some strict rules must be followed when using this script:
    * All scripts and files need to be put in a zip file with this script in the root (this can include exe files etc.)
    * No absolute paths. This script folder will not be in a single location when executed. All files within this folder must be accessed relatvily.
    * No installing tools or reaching out to web pages. If you need to have something installed on the system before the script runs it must be in configuration managment scripts.
    * No updating any function parameters in this file without first updating the related C# code or it will fail and be unusable.
    * $APEScriptPath variable contains the path that the scripts are running from do not use $PSScriptRoot.
#>

#To allow debuging of script outside of web interface
if($APEScriptPath -eq $null) { $APEScriptPath = $PSScriptRoot }
Set-Location $PSScriptRoot
#$ErrorActionPreference = "Stop"
Import-Module "$APEScriptPath\VITAzure\VITAzure.psd1" -Force
Import-Module "C:\data\Azure\Azure.psd1"
#import-module Azure
Import-Module AzureRM

class VITDisks 
{
  [string]$ExistingContext
  [string]$NewContext
  [object]$Disk
  [string]$Type
}

class VITStorName
{
  [string]$storname
  [string]$vhdcount
}

<#
    .SYNOPSIS
    Updates the Status Description that shows up to the end user.

    .DESCRIPTION
    This function will update the description displayed to the end user via the web interface. 

    You can only call this via Start-JobFromDB function as it is only available from the background job runner.

    Note: You don't need to include the current job number as this is handled by the c# code.

    .PARAMETER Message
    This is the message that will be disabled to the end user as the current progress.

    .OUTPUTS
    None
#>
function Update-JobStatus
{
    [cmdletbinding()]
    param([Parameter(Mandatory = $true)][string]$Message)

  $Global:JobStatusHelper.UpdateStatus($Message)
}

<#
    .SYNOPSIS
    Retrives Azure Service Manager subscriptions.

    .DESCRIPTION
    This method will retrive all the subscriptiops available for a Azure account.

    .PARAMETER Credential
    PSCredential object to login to Azure with.

    .OUTPUTS
    An array of hashtables with the following keys:
    * Name - Containing the Subscription name.
    * Id - Containing the subscription name.
#>
function Get-ASMSubscriptions{
  [cmdletbinding()]
  param([Parameter(Mandatory = $true)][PSCredential]$Credential)

  $SourceARMUserProfile = Connect-VITAzure -creds $Credential

  $subs = Get-VITAzureSubscriptionList -UserProfile $SourceARMUserProfile

  foreach($s in $subs){
    if($s.SubscriptionName -ne $null)
    {
      @{
        Name = $s.SubscriptionName
        Id = $s.SubscriptionName
      }
    }
  }	
}

<#
    .SYNOPSIS
    Retrives Azure Resource Manager subscriptions.

    .DESCRIPTION
    This method will retrive all the subscriptiops available for a Azure account.

    .PARAMETER Credential
    PSCredential object to login to Azure with.

    .OUTPUTS
    An array of hashtables with the following keys:
    * Name - Containing the Subscription name.
    * Id - Containing the subscription name.
#>
function Get-ARMSubscription{
  [cmdletbinding()]
  param([Parameter(Mandatory = $true)][PSCredential]$Credential)
  
  $SourceARMUserProfile = Connect-VITAzure -creds $Credential

  $subs = Get-VITAzureSubscriptionList -UserProfile $SourceARMUserProfile

  foreach($s in $subs){
    if($s.SubscriptionName -ne $null)
    {
      @{
        Name = $s.SubscriptionName
        Id = $s.SubscriptionName
      }
    }
  }	
}

<#
    .SYNOPSIS
    Retrives a list of virtual machines in a subscription.

    .DESCRIPTION
    This method will return a list of all virtual machines in a subscription.

    .PARAMETER Credential
    PSCredential object to login to Azure with.

    .PARAMETER SubName
    Name of the subscription.

    .OUTPUTS
    An array of hashtables with the following keys:
    * Name - Name of virtual machine.
#>
function Get-ASMVM{
  [cmdletbinding()]
  param([Parameter(Mandatory = $true)][PSCredential]$Credential, 
    [Parameter(Mandatory = $true)][string]$SubId)

  $SourceARMUserProfile = Connect-VITAzure -creds $Credential

  $VMs = Get-VITAzureASMVMList -UserProfile $SourceARMUserProfile -SubscriptionId $Subid
    
  foreach($v in $VMs){
    @{
      Name = $v.Name
    }
  }
}

<#
    .SYNOPSIS
    Retrives Resource groups in a subscription.

    .DESCRIPTION
    Retrives Resource groups in a subscription.

    .PARAMETER Credential
    PSCredential object to login to Azure with.

    .PARAMETER SubName
    Name of the subscription.

    .OUTPUTS
    An array of hashtables with the following keys:
    * Name - Name of resource group.

#>
function Get-Resourcegroup {
  [cmdletbinding()]
  param([Parameter(Mandatory = $true)][PSCredential]$Credential, 
    [Parameter(Mandatory = $true)][string]$SubID)

  $TargetUserProfile = Connect-VITAzure -creds $Credential

  $groups = Get-VITAzureRGs -UserProfile $TargetUserProfile -Subscriptionid $SubId

  foreach($g in $groups){
    @{
      Name = $g.ResourceGroupName
    }
  }
}

<#
    .SYNOPSIS
    Retrives all regions that are accessable from a subscription

    .DESCRIPTION
    Retrives all regions that are accessable from a subscription

    .PARAMETER Credential
    PSCredential object to login to Azure with.

    .PARAMETER SubName
    Name of the subscription.

    .OUTPUTS
    An array of hashtables with the following keys:
    * Name - Display name of the region (displayed in ui).
    * Id - The id of the region (used by script to select region).

#>
function Get-Region {
  [cmdletbinding()]
  param([Parameter(Mandatory = $true)][PSCredential]$Credential, 
    [Parameter(Mandatory = $true)][string]$Subid)

  $TargetUserProfile = Connect-VITAzure -creds $Credential

  $regions = Get-VITAzureRegions -UserProfile $TargetUserProfile -SubscriptionID $SubId

  foreach($r in $regions){
    @{
      Name = $r.DisplayName
      Id = $r.Location
    }
  }
}

<#
    .SYNOPSIS
    Creates a new resource group.

    .DESCRIPTION
    Creates a new resource group.

    .PARAMETER Credential
    PSCredential object to login to Azure with.

    .PARAMETER SubName
    Name of the subscription.

    .PARAMETER ResourceGroupName
    Name of resource group to create.

    .PARAMETER Location
    Location the resource group will be created in. Run Get-Region to get list of regions 
    and pass the Id property of the hash table to this parameter not the displayt name.

    .OUTPUTS
    None
#>
function New-ResourceGroup {
  [cmdletbinding()]
  param([Parameter(Mandatory = $true)][PSCredential]$Credential, 
    [Parameter(Mandatory = $true)][string]$SubId,
    [Parameter(Mandatory = $true)][string]$ResourceGroupName,
    [Parameter(Mandatory = $true)][string]$Location)

    $TargetUserProfile = Connect-VITAzure -creds $Credential

    New-VITAzureResourceGroup -Profile $TargetUserProfile -SubscriptionId $SubId -ResourceGroupName $ResourceGroupName -Location $Location
}

<#
    .SYNOPSIS
    Runs the complete migration

    .DESCRIPTION
    This method is what runs on the background worker process and completes the migration.

    .PARAMETER SourceCredential
    Credentials to login to subscription containing ASM vm.

    .PARAMETER SourceSubscriptionName
    Name of subscription containing ASM vm.

    .PARAMETER DestCredential
    Credentials for subscription holding where vm will be copied to (ARM).

    .PARAMETER TargetSubscriptionName
    Name of the subscription where the vm will be copied to (ARM)

    .PARAMETER ResourceGroupName
    Name of the resource group the vm will be copied to.

    .PARAMETER VMName
    Name of virtual machine to copy.

    .PARAMETER TargetRegion
    Region ID resource group is a member of.

    .PARAMETER PowerUpResponse
    Should VM be powered up at the end of the migration.

    .PARAMETER AzCopyOverWrite
    Should AZcopy overwrite the vm. This should be set to $true or it hangs at the moment.

    .OUTPUTS
    Nothing

#>
function Start-JobFromDB{
  [cmdletbinding()]
  param([Parameter(Mandatory = $true)][PSCredential]$SourceCredential, 
    [Parameter(Mandatory = $true)][string]$SourceSubscriptionid, 
    [Parameter(Mandatory = $true)][PSCredential]$DestCredential, 
    [Parameter(Mandatory = $true)][string]$TargetSubscriptionid,
    [Parameter(Mandatory = $true)][string]$ResourceGroupName,
    [Parameter(Mandatory = $true)][string]$VMName,
    [Parameter(Mandatory = $true)][string]$TargetRegion,
    [Parameter(Mandatory = $true)][bool]$PowerUpResponse,
    [Parameter(Mandatory = $true)][bool]$AzCopyOverWrite,
    [Parameter(Mandatory = $true)][String]$NewRGname
  )
  if ($SourceCredential.UserName -eq 'dummy'){Write-Output "Please enter the Microsoft account details for target Subscription"}
  $TargetUserProfile = Connect-VITAzure -creds $DestCredential -subid $TargetSubscriptionid
  $TargetSubscription = Get-VITAzureSubscriptionList -UserProfile $TargetUserProfile -Verbose | Where-Object {$_.Subscriptionid -eq $TargetSubscriptionId}
  
  if ($SourceCredential.UserName -eq 'dummy'){Write-Output "Please enter the Microsoft account details for Source Subscription"}
  $sourceUserprofile = Connect-VITAzure -creds $SourceCredential -subid $SourceSubscriptionid
  $SourceSubscription = Get-VITAzureSubscriptionList -UserProfile $SourceUserProfile -Verbose | Where-Object {$_.Subscriptionid -eq $SourceSubscriptionId}
  $SourceResourceGroup = Get-VITAzureRGs -UserProfile $sourceUserProfile -SubscriptionID $SourceSubscription.SubscriptionID -ResGroupName $ResourceGroupName -Verbose
  $ClassicVMResources = Get-VITAzureASMVMInventory -UserProfile $SourceUserProfile -SubscriptionId $SourceSubscription.SubscriptionID -ResType 'Microsoft.ClassicCompute/virtualMachines' -ResGroup $SourceResourceGroup.ResourceGroupName -Verbose
  if (!$ClassicVMResources)
  {
    $ClassicVMResources = Get-VITAzureASMVMInventory -UserProfile $SourceUserProfile -SubscriptionID $SourceSubscription.SubscriptionID -ResType 'Microsoft.Compute/virtualMachines' -ResGroup $SourceResourceGroup.ResourceGroupName -Verbose
  }
  # try
  #{
    Convert-VITAzureASM2ARM -SourceCreds $SourceCredential -SourceARMUserProfile $sourceUserprofile -SourceSubscriptionID $SourceSubscription.SubscriptionID `
    -TargetUserProfile $TargetUserProfile -TargetSubscriptionID $TargetSubscription.SubscriptionID -targetcreds $DestCredential -resourceGroupName $NewRGname `
    -Region $TargetRegion -PowerUpResponse:$PowerUpResponse -AzCopyOverWrite:$AzCopyOverWrite -TargetSubscription $TargetSubscription -ClassicVMResources $ClassicVMResources `
    -sourceUserprofile $sourceUserprofile -SourceSubscription $SourceSubscription -SourceResourceGroup $SourceResourceGroup -Verbose
    #$output | ForEach-Object {$telclient.TrackEvent($_.message);$telclient.Flush()}
  #}
  #catch
  #{
    #write-logs -AIKey $appInsightsKey -inputobject $_ -print
   # $_
   # $PSDefaultParameterValues['*:Verbose'] = $false
  #}

}

function test-SHTestscript{
#$azcreds = Get-Credential
  Start-JobFromDB -SourceCredential $azcreds `
  -SourceSubscriptionid '' `
  -DestCredential $azcreds `
  -TargetSubscriptionid '' `
  -NewRGname '' `
  -ResourceGroupName '' `
  -VMName '' `
  -TargetRegion 'australiaeast' `
  -PowerUpResponse $false `
  -AzCopyOverWrite $true
  }


  function Get-UDVariable {
  get-variable | where-object {(@(
    "FormatEnumerationLimit",
    "MaximumAliasCount",
    "MaximumDriveCount",
    "MaximumErrorCount",
    "MaximumFunctionCount",
    "MaximumVariableCount",
    "PGHome",
    "PGSE",
    "PGUICulture",
    "PGVersionTable",
    "PROFILE",
    "PSSessionOption",
    "psISE",
    "psUnsupportedConsoleApplications",
    "aliases",
    "azcreds"
    ) -notcontains $_.name) -and `
    (([psobject].Assembly.GetType('System.Management.Automation.SpecialVariables').GetFields('NonPublic,Static') | Where-Object FieldType -eq ([string]) | ForEach-Object GetValue $null)) -notcontains $_.name
    }
}