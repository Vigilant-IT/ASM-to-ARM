Function Connect-VITAzure 
{
  <#
      .SYNOPSIS
      Connects to Azure with the ARM engine

      .DESCRIPTION

      .PARAMETER Username
      this is a string for the email address of the user account in Azure

      .PARAMETER Password
      This is a Secure String to contain the Password for the above user account.

      .EXAMPLE
      Connect-VITAzure -Username demo@mail.com -password (ConvertTo-SecureString 'Password' -AsPlainText -Force)

      .NOTES
      this is where you put in extra notes.

  #>
  param
  (
    [Parameter(Mandatory=$false)]
    [PSCredential]$creds,
    [string]$AzureCloud = 'AzureCloud',
    [Parameter(Mandatory=$false)]
    [string]$StackAadTenantId,
    [parameter(mandatory=$false)]
    [string]$subid
  )
  if($StackAadTenantId)
  {
    Add-AzureRmEnvironment -Name 'AzureStack' `
    -ActiveDirectoryEndpoint "https://login.windows.net/$StackAadTenantId/" `
    -ActiveDirectoryServiceEndpointResourceId "https://azurestack.local-api/"`
    -ResourceManagerEndpoint "https://api.azurestack.local/" `
    -GalleryEndpoint "https://gallery.azurestack.local/" `
    -GraphEndpoint "https://graph.windows.net/" `
    -Verbose
    $AzureCloud = 'AzureStack' 
  }
  if($creds.UserName -ne "dummy")
  {
    $AzureEnv = Get-AzureRmEnvironment $AzureCloud -Verbose 
    Add-AzureRmAccount -Environmentname $AzureEnv -Credential $creds -SubscriptionId $subid
  }
  else
  {
    #Write-Error 'Username not provided'
    Add-AzurermAccount -SubscriptionId $subid
  }
}