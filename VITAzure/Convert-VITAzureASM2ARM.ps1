Class oDisk
{
  [bool]$OS
  [object]$disk
  oDisk($inos, $indisk)
  {
    $this.os = $inos
    $this.disk = $indisk
  }
}

Function Convert-VITAzureASM2ARM
{
  <#
      .SYNOPSIS
      Takes all the source inventory and migrates the ASM cloud service to ARM

      .DESCRIPTION

      .PARAMETER UserProfile
      this is a UserProfile object to be used

      .PARAMETER SubscriptionName
      Name of the Subscription to be used

      .PARAMETER resourceGroupName
      Parameter which allows for specification of an Azure Resource Group Name to be used

      .PARAMETER Region
      Parameter which allows for specification of an Azure region (location) in which to create the resource group

      .EXAMPLE
      Migrate-VITAzureASM2ARM -UserProfile $UserProfile -SubscriptionName $SubscriptionName -resourceGroupName $resourceGroupName -Region $Region

      .NOTES
      this is where you put in extra notes.

  #>
  param
  (
    [Parameter(Mandatory)]
    $SourceCreds,
    [Parameter(Mandatory)]
    $SourceARMUserProfile,
    [Parameter(Mandatory)]
    [String]$SourceSubscriptionId,
    [Parameter(Mandatory)]
    $TargetUserProfile,
    [Parameter(Mandatory)]
    $targetCreds,
    [Parameter(Mandatory)]
    [String]$TargetSubscriptionId,
    [Parameter(Mandatory)]
    [String]$resourceGroupName,
    [Parameter(Mandatory)]
    [String]$Region,
    [Parameter(Mandatory)]
    [switch]$PowerUpResponse,
    [Parameter(Mandatory)]
    [switch]$AzCopyOverWrite,
    [Parameter(Mandatory)]
    $sourceUserprofile,
    [Parameter(Mandatory)]
    $SourceSubscription,
    [Parameter(Mandatory)]
    $TargetSubscription,
    [Parameter(Mandatory)]
    $SourceResourceGroup,
    [Parameter(Mandatory)]
    $ClassicVMResources
  )

  $PSDefaultParameterValues['*:Verbose'] = $true

  $rg = get-VITAzureResourceGroup -RgName $resourceGroupName -region $Region -UserProfile $TargetUserProfile -SubID $TargetSubscriptionId
  foreach($ClassicVMResource in $ClassicVMResources)
  {
    if($ClassicVMResource.ResourceType -eq 'Microsoft.Compute/virtualMachines')
    {
      $VMSize = $ClassicVMResource.Properties.hardwareProfile.vmsize
    }
    else
    {
      $vmsize = convert-VITAzureSize -vmsize $ClassicVMResource.Properties.hardwareProfile.size  
    }
    if((get-member -InputObject $ClassicVMResource.properties.hardwareprofile | Select-Object -ExpandProperty name) -contains 'availabilitySet')
    {
      $availabilityset = $ClassicVMResource.properties.hardwareprofile.availabilitySet    
    }
    else
    {
      $availabilityset = ''
    }
    $newvm = New-VITAzureVM -availset $availabilityset -ResGroupName $resourceGroupName -Region $Region -vmsize $vmsize -vmname $ClassicVMResource.name -UserProfile $TargetUserProfile -SubscriptionId $TargetSubscriptionId
    $diag = $false
    if($ClassicVMResource.ResourceType -eq 'Microsoft.classicCompute/virtualMachines')
    {
      #Remove-VITClassicExts -UserProfile $sourceUserProfile -SubName $SourceSubscription.SubscriptionName -ClassicVms $ClassicVMResource -creds $SourceCreds -Verbose
      if($ClassicVMResource.Properties.InstanceView.PowerState -ne 'Stopped') {Stop-VITVM -UserProfile $SourceUserProfile -Subid $SourceSubscriptionId -VMName $ClassicVMResource.name -RGName $ClassicVMResource.ResourceGroupName -PowerBackUp:$powerUpResponse -Verbose }
    }
    else
    {
      if($ClassicVMResource.Properties.InstanceView.PowerState -ne 'Stopped') {Stop-VITVM -UserProfile $SourceUserProfile -Subid $SourceSubscriptionId -VMName $ClassicVMResource.name -RGName $ClassicVMResource.ResourceGroupName -PowerBackUp:$powerUpResponse -Verbose -ARM}
    }
    if($ClassicVMResource.ResourceType -eq 'Microsoft.classicCompute/virtualMachines')
    {
      $osdisks = $ClassicVMResource.Properties.StorageProfile.OperatingSystemDisk
    }
    else
    { 
      $osdisks = $ClassicVMResource.Properties.StorageProfile.osDisk
    }
    $disks = @()
    foreach($osdisk in $OSDisks)
    {
      $disks += [oDisk]::new($true,$osdisk)
    }
    foreach($datadisk in $ClassicVMResource.Properties.storageProfile.dataDisks)
    {
      $disks += [oDisk]::new($false,$datadisk)
    }
    $newdisk = move-VITAzureDisk -SourceUserProfile $sourceUserprofile `
    -SourceSubid $SourceSubscriptionId `
    -SourceResGrp $ClassicVMResource.ResourceGroupName `
    -TargetUserProfile $TargetUserProfile `
    -TargetSubId $TargetSubscriptionId `
    -rg $rg `
    -Region $Region `
    -AzCopyOverWrite:$true `
    -Disk $disks 
      
    foreach ($nd in $newdisk)
    {
      if($nd.type -eq 'Windows')
      { 
        $newvm = Set-AzureRmVMOSDisk -vm $newvm -name $nd.VHDFileName -VhdUri $nd.vhduri -CreateOption Attach -Windows -Verbose 
      }
      elseif($nd.type -eq 'linux')
      {
        $newvm = Set-AzureRmVMOSDisk -vm $newvm -name $nd.VHDFileName -VhdUri $nd.vhduri -CreateOption Attach -Linux -Verbose 
      }
      elseif($nd.type -eq 'Data')
      {
        $newvm = add-AzureRmVMDataDisk -VM $newvm -name $nd.VHDFileName -VhdUri $nd.vhduri -Lun $nd.lun -DiskSizeInGB $nd.size -CreateOption Attach -Verbose 
      }
    }
    if ($diag) # will always be true if Primium storage exists. need to fix but not a high priority.
    {
      New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name 'bootdiagnostics' -Type Standard_GRS -Location $region -Verbose 
    }
    if ($powerUpResponse)
    {
      if($ClassicVMResource.ResourceType -eq 'Microsoft.classicCompute/virtualMachines')
      {
        Start-AzureVM -servicename $ClassicVMResource.properties.hardwareprofile.deploymentname -Name $ClassicVMResource.name -Verbose 
      }
      else
      {
        Start-AzureRmVM -Name $ClassicVMResource.name -ResourceGroupName $ClassicVMResource.ResourceGroupName
      }
    }
    
    
    $VNetName = $ClassicVMResource.properties.networkprofile.virtualnetwork
    $NicName = $ClassicVMResource.name + '-nic'
    if($VNetName.id)
    {
      $newvnet = new-VITAzureVNet -SourceUserProfile $sourceUserprofile `
      -SourceSubid $SourceSubscriptionId `
      -vnetname $VNetName `
      -SourceResGrp $ClassicVMResource.ResourceGroupName `
      -region $region `
      -TargetResGrp $resourceGroupName `
      -TargetUserProfile $TargetUserProfile `
      -TargetSubID $TargetSubscriptionId
    }
    else 
    {
      $subnet = New-AzureRmVirtualNetworkSubnetConfig -Name 'BackEnd' -AddressPrefix '10.250.200.0/24' -Verbose 
      $newvnet = New-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName -name 'Mig-vNet' -Location $region -AddressPrefix @('10.0.200.0/21') -DnsServer @('8.8.8.8','8.8.4.4') -Subnet $subnet -Force -Verbose 
    }
    
    $ExistingNSG = $ClassicVMResource.Properties.NetworkProfile.networkSecurityGroup
    if($ExistingNSG)
    {
      $nsg = Get-AzureNetworkSecurityGroup -Name $existingnsg.name -Detailed -Verbose 
      $nsgrules = Get-VITAzureNSG -UserProfile $SourceUserProfile -Subid $SourceSubscriptionId -NSG $nsg
      $newnsg = New-AzureRmNetworkSecurityGroup -Name ($nsg.name -replace '\W') -Location $region -ResourceGroupName $resourceGroupName -SecurityRules $nsgrules -Force -Verbose 
    }

    if($ClassicVMResource.Properties.HardwareProfile.Size -match 'Basic')
    {
      $pipname = $ClassicVMResource.Name + '-nsg'
      
      $nsgName = $ClassicVMResource.Name + '-NSG'
      $IPAddress = $ClassicVMResource.Properties.InstanceView.PublicIpAddresses
      $DomainNameLabel = 'p' + $ClassicVMResource.Name.ToLower() -replace '\W',''
      $publicip = New-AzureRmPublicIpAddress -name $pipname -ResourceGroupName $resourceGroupName -Location $region -AllocationMethod Dynamic -DomainNameLabel $domainnamelabel -Force -Verbose 
      if ([string]$ClassicVMResource.Properties.InstanceView.instanceIpAddresses)
      {
        $ExPublicIP = New-AzureRmPublicIpAddress -Name $ClassicVMResources.Properties.networkProfile.instanceIps.name -ResourceGroupName $resourceGroupName -Location $region -AllocationMethod Static -DomainNameLabel $ClassicVMResource.Properties.networkProfile.instanceIps.domainNameLabel -force -Verbose 
      }
      $rules = @()
      $rulesPriority = 100
      foreach ($EndPoint in $ClassicVMResource.Properties.NetworkProfile.InputEndpoints)
      {
        $name = ($EndPoint.endpointname -replace '\W')
        $rules += New-AzureRmNetworkSecurityRuleConfig -Name $name `
        -Description "Allow inbound to Azure $name" `
        -Access allow `
        -Protocol ($EndPoint.Protocol.substring(0,1).toupper()+$EndPoint.Protocol.substring(1).tolower()) `
        -Direction Inbound `
        -Priority $rulesPriority `
        -SourceAddressPrefix * `
        -SourcePortRange * `
        -DestinationAddressPrefix * `
        -DestinationPortRange $EndPoint.privatePort -Verbose 
        $rulesPriority++
      }
      $nsg = New-AzureRmNetworkSecurityGroup -Name $nsgName -Location $region -ResourceGroupName $resourceGroupName -SecurityRules $rules -force -Verbose 
      $PrivateIpAddressOption = $null
      if ($ClassicVMResource.Properties.networkProfile.virtualNetwork.staticIpAddress)
      {
        $PrivateIpAddressOption = $ClassicVMResource.Properties.networkProfile.virtualNetwork.staticIpAddress
      }
      $nic = New-AzureRmNetworkInterface -name $NicName -ResourceGroupName $resourceGroupName -Location $region -Subnet $subnet -PrivateIpAddress $PrivateIpAddressOption -PublicIpAddress $publicip -NetworkSecurityGroup $nsg -Verbose 
    }

    if($ClassicVMResource.properties.networkProfile.inputEndpoints.internalLoadBalancerName.Length -gt 2)
    {
      $ILBAvailabilitySet = $ClassicVMResource.Properties.HardwareProfile.availabilitySet[0]
      $ILBBEPoolConfigName = 'ilb-be-pool'
      $internalLBName = $ClassicVMResource.ResourceGroupName + '-int'
      $IntLBFEIPConfigName = 'int-fe-IP'
      $BEInt = 10
      $StaticVNetIPAddress = $ClassicVMResource.properties.networkProfile.inputEndpoints.internalLoadBalancerProfile[0].staticVirtualNetworkIPAddress
      $subnetname = $ClassicVMResource.properties.networkProfile.inputEndpoints.internalLoadBalancerProfile[0].subnetName
      $subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $subnetname -VirtualNetwork $newvnet -Verbose 
      $intLBFrontendIPConfig = New-AzureRmLoadBalancerFrontendIpConfig -Name $IntLBFEIPConfigName -PrivateIpAddress $StaticVNetIPAddress -Subnet $subnet -Verbose 
      $intLB = New-AzureRmLoadBalancer -name $internalLBName -ResourceGroupName $resourceGroupName -Location $region -FrontendIpConfiguration $intLBFrontendIPConfig -Force -Verbose 

      $IntLBrules = $ClassicVMResource.Properties.NetworkProfile.InputEndpoints | Where-Object {$_.loadBalancedEndpointSetName -and $_.internalLoadBalancerName -ne $null}
      $ProbeInt = 10
      foreach($IntLBRule in ($IntLBrules | Group-Object publicPort, protocol))
      {
        $probename = 'Int-probe' + $ProbeInt
        $beaddresspool = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name $IntLBRule.group[0].LBBackendPoolConfigName -Verbose 
        $requestpath = [string]$IntLBRule.group[0].probe.path
        $internalLB = Get-AzureRmLoadBalancer -name $internalLBName -ResourceGroupName $ClassicVMResource.ResourceGroupName -Verbose 
        $internalLB.BackendAddressPools.Add($beaddresspool)
        if($IntLBRule.group[0].probe.protocol -eq 'tcp')
        {
          $healthprobe = New-AzureRmLoadBalancerProbeConfig -name $probename -Protocol Tcp -Port ([string]$IntLBRule.group[0].probe.port) -IntervalInSeconds ([string]$IntLBRule.group[0].probe.interval) -ProbeCount ([string]$IntLBRule.group[0].probe.timeout) -Verbose 
        }
        else
        {
          $healthprobe = New-AzureRmLoadBalancerProbeConfig -name $probename -RequestPath $requestpath -Protocol http -Port ([string]$IntLBRule.group[0].probe.port) -IntervalInSeconds ([string]$IntLBRule.group[0].probe.interval) -ProbeCount ([string]$IntLBRule.group[0].probe.timeout) -Verbose 
        }
        $internalLB.Probes.Add($healthprobe)
        if([string]$IntLBRule.group[0].enabledirectserverreturn -eq 'true')
        {
          $internalLB | Add-AzureRmLoadBalancerRuleConfig -name $IntLBRule.group[0].endpointName -BackendAddressPool $beaddresspool -FrontendIpConfiguration $intLBFrontendIPConfig -Protocol ([string]$IntLBRule.group[0].protocol) -EnableFloatingIP -FrontendPort ([string]$intlbrule.group[0].publicport) -BackendPort ([string]$intlbrule.group[0].privateport) -probe $healthprobe -Verbose 
        }
        else
        {
          $internalLB | Add-AzureRmLoadBalancerRuleConfig -name $IntLBRule.group[0].endpointName -BackendAddressPool $beaddresspool -FrontendIpConfiguration $intLBFrontendIPConfig -Protocol ([string]$IntLBRule.group[0].protocol) -FrontendPort ([string]$intlbrule.group[0].publicport) -BackendPort ([string]$intlbrule.group[0].privateport) -probe $healthprobe -Verbose 
        }
        $internalLB | Set-AzureRmLoadBalancer -Verbose 
      }
      $ExtInt = 1
      foreach ($ExtLBCSVMGrp in ($ClassicVMResource.properties.networkProfile.inputEndpoints.internalLoadBalancerName) | Group-Object availabilitySet)
      {
        $lbrules = @()
        $natrules = @()
        $DomainNameLabel = ($resourceGroupName.tolower()) + 'ext' + $ExtInt -replace '\W',''
        $PublicIPName = $resourceGroupName + '-lb' + $ExtInt
        $ExternalLBname = $resourceGroupName + '-ext' + $ExtInt
        $ExtLBFrontendIPConfigName = 'ext-fe-IP' + $ExtInt
        $NATExLBBackendPoolConfigName = 'NAT-ext-pool' + $ExtInt
        $LBBackendPoolConfigName = 'ext-be-pool' + $ExtInt
        $publicIP = New-AzureRmPublicIpAddress -Name $PublicIPName -ResourceGroupName $resourceGroupName -Location $region -AllocationMethod Static -DomainNameLabel $DomainNameLabel -Force -Verbose 
        $ExtLBFrontendIPConfig = New-AzureRmLoadBalancerFrontendIpConfig -Name $ExtLBFrontendIPConfigName -PublicIpAddress $PublicIP -Verbose 
        $NATLBBackendPoolConfig = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name $NATExLBBackendPoolConfigName -Verbose 
        $ExternalLB = New-AzureRmLoadBalancer -Name $ExternalLBname -ResourceGroupName $resourceGroupName -Location $region -FrontendIpConfiguration $ExtLBFrontendIPConfig -BackendAddressPool $NATLBBackendPoolConfig -Force -Verbose 
        $BEInt = 10
        $ExternalLBRules = $ExtLBCSVMGrp.group.properties.networkProfile.inputEndpoints | where-object {$_.loadBalancedEndpointSetName -and $_.internalLoadBalancerName -eq $null}
        $probein = 10
        foreach($ExtLBRule in ($ExternalLBRules | Group-Object publicPort, Protocol))
        {
          $probname = "Ext-Probe$probeint"
          $beaddresspool = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name $ExtLBRule.group[0].LBBackendPoolConfigName -Verbose 
          $requestpath = [string]$extLBRule.group[0].probe.path
          $ExternalLB.BackendAddressPools.Add($beaddresspool)
          if($ExtLBRule.group[0].probe.protocol -eq 'tcp')
          {
            $healthprobe = New-AzureRmLoadBalancerProbeConfig -name $probname -Protocol Tcp -Port ([string]$ExtLBRule.group[0].probe.port) -IntervalInSeconds ([string]$ExtLBRule.group[0].probe.interval) -ProbeCount ([string]$extlbrule.group[0].probe.timeout) -Verbose 
          }
          else
          {
            $healthprobe = New-AzureRmLoadBalancerProbeConfig -name $probname -RequestPath $requestpath -Protocol Http -Port ([string]$ExtLBRule.group[0].probe.port) -IntervalInSeconds ([string]$ExtLBRule.group[0].probe.interval) -ProbeCount ([string]$extlbrule.group[0].probe.timeout) -Verbose 
          }
          $ExternalLB.Probes.Add($healthprobe)
          $externallb | Add-AzureRmLoadBalancerRuleConfig -name $ExtLBRule.group[0].LBBackendPoolConfigName -BackendAddressPool $beaddresspool -FrontendIpConfiguration $ExtLBFrontendIPConfig -Protocol ([string]$ExtLBRule.group[0].protocol) -FrontendPort ([string]$ExtLBRule.group[0].publicPort) -BackendPort ([string]$ExtLBRule.group[0].privatePort) -Probe $healthprobe -Verbose 
          $ExternalLB | Set-AzureRmLoadBalancer -Verbose 
          $probeint++
        }
        $natlbint = 1
        $natLB = Get-AzureRmLoadBalancer -name $ExternalLBname -ResourceGroupName $ClassicVMResource.ResourceGroupName -Verbose 
        foreach ($nat in ($ExternalLBRules | Where-Object {$_.endpointName}))
        {
          $natibnatname = ($nat.endpointname -replace '\W','') + $natlbint
          $natibnatname = $natibnatname -join ' '
          $NatLB | Add-AzureRmLoadBalancerInboundNatPoolConfig -name $natibnatname -FrontendIpConfiguration $ExtLBFrontendIPConfig -Protocol $nat.protocol -frontendport $nat.publicport -BackendPort $nat.privateport -Verbose 
          $natlb | Set-AzureRmLoadBalancer -Verbose 
          $natlbint++
        }
        $extint++
      }
      

    }
    $vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName -Verbose 
    $nic = New-AzureRmNetworkInterface -Name $NICName -ResourceGroupName $resourceGroupName -Location $region -Subnet $vnet.Subnets[0] -Verbose 
    $newvm = Add-AzureRMVMNetworkInterface -VM $newVM -Id $nic.Id -Primary -Verbose 
    if($ClassicVMResource.Properties.networkProfile.virtualNetwork.length -ne 0)
    {
      foreach ($exnic in $ClassicVMResource.Properties.networkProfile.virtualNetwork.networkInterfaces)
      {
        $NicName = $ExNic.interfaceName -replace '\s'
        $IPAddress = ($ExNic).IpConfigurations.Address
        $SubnetID = Get-AzureRmVirtualNetworkSubnetConfig -Name $ExNic.subnetName -VirtualNetwork $vNet -Verbose 
        $TargetExNic = New-AzureRmNetworkInterface -Name $NICName -ResourceGroupName $resourceGroupName -Location $region -Subnet $SubnetID -PrivateIpAddress $IPAddress -Verbose 
        $newvm = Add-AzureRmVMNetworkInterface -VM $newvm -id $TargetExNic.Id -Verbose 
      }
    
    }
    new-azurermvm -ResourceGroupName $resourceGroupName -Location $region -vm $newvm -DisableBginfoExtension -Verbose 
  }
  $PSDefaultParameterValues['*:Verbose'] = $false
}