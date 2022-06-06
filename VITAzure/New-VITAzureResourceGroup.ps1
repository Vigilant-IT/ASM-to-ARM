function New-VITAzureResourceGroup{
    param(
        [Parameter(Mandatory = $true)]
        $UserProfile,
        [Parameter(Mandatory = $true)]
        [string]$Subscriptionid,
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,
        [Parameter(Mandatory = $true)]
        [string]$Location
    )

    $null = Select-AzureRmProfile -Profile $UserProfile -Verbose 
    $null = Get-AzureRmSubscription -Subscriptionid $Subscriptionid -TenantId $userprofile.Context.Tenant.TenantId -WarningAction SilentlyContinue -Verbose  | Set-AzureRmContext -Verbose

    New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location
}