$CloudServiceName = ''
$Subnet2Name = 'Subnet-2'
$Subnet1Name = 'Subnet-1'
$VnetName = ''
#$AusEastRegionStr = 'Australia East'
$AusEastRegionStr = 'australiaeast'
Import-Module -Name azure
$null = Add-AzureAccount
$subscription = (Get-AzureSubscription | Out-GridView -Title 'Select the Azure subscription that you want to use ...' -PassThru).SubscriptionName
function Write-Color
{
  param(
    [String[]]$Text, 
    [ConsoleColor[]]$Color = "White", 
    [int]$StartTab = 0, 
    [int] $LinesBefore = 0,
    [int] $LinesAfter = 0
  ) 
  $DefaultColor = $Color[0]
  if ($LinesBefore -ne 0) 
  {  
    for ($i = 0; $i -lt $LinesBefore; $i++) 
    { 
      Write-Host "`n" -NoNewline 
    } 
  } # Add empty line before
  if ($StartTab -ne 0) 
  {  
    for ($i = 0; $i -lt $StartTab; $i++) 
    { 
      Write-Host "`t" -NoNewLine 
    } 
  }  # Add TABS before text
  if ($Color.Count -ge $Text.Count) 
  {
    for ($i = 0; $i -lt $Text.Length; $i++) 
    { 
      Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewLine 
    } 
  } 
  else 
  {
    for ($i = 0; $i -lt $Color.Length ; $i++) 
    { 
      Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewLine 
    }
    for ($i = $Color.Length; $i -lt $Text.Length; $i++) 
    { 
      Write-Host $Text[$i] -ForegroundColor $DefaultColor -NoNewLine 
    }
  }
  Write-Host
  if ($LinesAfter -ne 0) {  for ($i = 0; $i -lt $LinesAfter; $i++) 
    { 
      Write-Host "`n" 
    } 
  }  # Add empty line after
}
function Get-TestStorage
{
  <#
      .SYNOPSIS
      This Function will create the Storage accounts required for the testing of Migration Tool

      .DESCRIPTION
      There is an expection that the standard Azure Connections are already open, so you will need to import-module azure along with adding accounts

      .PARAMETER StorageName
      Name of the New Storage Account

      .PARAMETER Region
      Azure Region name for the new Storage Account

      .PARAMETER Type
      Azure Storage Type

      .PARAMETER create
      a Switch to Create the storage account (doesn't confirm if it already exists)

      .EXAMPLE
      Get-TestStorage -StorageName 'apeteststdsge2017' -Region 'Australia East' -Type 'Standard_LRS' -create

      Creates a new Storage account called apeteststdsge2017 with Standard storage in Sydney
    
      .EXAMPLE
      Get-TestStorage -StorageName 'apetestprmsge2017' -Region 'Australia East' -Type 'Premium_LRS' -create

      Creates a new Storage account called apetestprmsge2017 with Premium storage in Sydney

      .LINK
      URLs to related sites
      The first link is opened by Get-Help -Online Get-TestStorage

      .INPUTS
      List of input types that are accepted by this function.

      .OUTPUTS
      List of output types produced by this function.
  #>


  param
  (
    [Parameter(Mandatory)][string]$StorageName,
    [Parameter(Mandatory)][string]$Region,
    [Parameter(Mandatory)][string]$Type,
    [switch]$create
  )
  if ($create)
  {
    $CurrentStdStorageAccount = New-AzureStorageAccount -StorageAccountName $StorageName -Label $StorageName -Location $Region -Type $Type
  }
  else
  {
    Get-AzureStorageAccount -StorageAccountName $StorageName
  }
}
function Set-TestVnet
{
  <#
      .SYNOPSIS
      This function is used to create the required VNets and Subnets for the testing of the Vigilant.IT Migration Tool

      .DESCRIPTION
      This function is used to create the required VNets and Subnets for the testing of the Vigilant.IT Migration Tool

      .PARAMETER Region
      Needs to the Azure Region Names, no validation in place will error if incorrect name

      .PARAMETER VNet1Name
      Name of VNet1

      .PARAMETER VN1Subnet1
      Address Space of Subnet1, VNet 1

      .PARAMETER VN1subnet2
      Address Space of Subnet2, VNet 1

      .PARAMETER VN1Subnet1Name
      Name of Subnet1, VNet 1

      .PARAMETER VN1subnet2Name
      Name of Subnet2, VNet 1

      .PARAMETER VN1AddressSpace
      Address Space for VNet 1

      .PARAMETER Vnet2Name
      Name of VNet2

      .PARAMETER VN2Subnet1
      Address Space of Subnet1, VNet2

      .PARAMETER VN2subnet2
      Address Space of Subnet2, VNet2

      .PARAMETER VN2Subnet1Name
      Name of Subnet1, VNet 2

      .PARAMETER VN2subnet2Name
      Name of Subnet2, VNet 2

      .PARAMETER VN2AddressSpace
      Address Space for VNet 2

      .PARAMETER DNSPrim
      IP Address for Primary DNS Server

      .PARAMETER DNSSec
      IP Address for Secondary DNS Server

      .EXAMPLE
      Set-TestVnet    -Region 'Australia East' `
                      -VNet1Name '20160822vnet' `
                      -VN1Subnet1 '10.0.0.0/25' `
                      -VN1subnet2 '10.0.1.0/25' `
                      -VN1Subnet1Name 'Subnet-1' `
                      -VN1subnet2Name 'Subnet-2' `
                      -VN1AddressSpace '10.0.0.0/23' `
                      -Vnet2Name 'Group a20160829-CS a20160829-CS' `
                      -VN2Subnet1 '10.1.0.0/24' `
                      -VN2subnet2 '10.1.1.0/24' `
                      -VN2Subnet1Name 'default' `
                      -VN2subnet2Name 'FrontEnd' `
                      -VN2AddressSpace '10.1.0.0/16' `
                      -DNSPrim '8.8.8.8' `
                      -DNSSec '8.8.4.4'

      .LINK
      URLs to related sites
      The first link is opened by Get-Help -Online Set-TestVnet

      .INPUTS
      List of input types that are accepted by this function.

      .OUTPUTS
      List of output types produced by this function.
  #>
  param
  (
    [Parameter(Mandatory)][string]$Region,
    [Parameter(Mandatory)][string]$VNet1Name,
    [Parameter(Mandatory)][string]$VN1Subnet1,
    [Parameter(Mandatory)][string]$VN1subnet2,
    [Parameter(Mandatory)][string]$VN1Subnet1Name,
    [Parameter(Mandatory)][string]$VN1subnet2Name,
    [Parameter(Mandatory)][string]$VN1AddressSpace,
    [Parameter(Mandatory)][string]$Vnet2Name,
    [Parameter(Mandatory)][string]$VN2Subnet1,
    [Parameter(Mandatory)][string]$VN2subnet2,
    [Parameter(Mandatory)][string]$VN2Subnet1Name,
    [Parameter(Mandatory)][string]$VN2subnet2Name,
    [Parameter(Mandatory)][string]$VN2AddressSpace,
    [Parameter(Mandatory)][string]$DNSPrim,
    [Parameter(Mandatory)][string]$DNSSec
  )
  $NetConfigXML = "$env:TEMP\NetworkConfig.xml"
  $vNetxml = (@'
<?xml version="1.0" encoding="utf-8"?>
<NetworkConfiguration xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://schemas.microsoft.com/ServiceHosting/2011/07/NetworkConfiguration">
  <VirtualNetworkConfiguration>
    <Dns>
      <DnsServers>
        <DnsServer name="Primary" IPAddress="{0}" />
        <DnsServer name="Sec" IPAddress="{1}" />
      </DnsServers>
    </Dns>
    <VirtualNetworkSites>
      <VirtualNetworkSite name="{2}" Location="{3}">
        <AddressSpace>
          <AddressPrefix>{4}</AddressPrefix>
        </AddressSpace>
        <Subnets>
          <Subnet name="{5}">
            <AddressPrefix>{6}</AddressPrefix>
          </Subnet>
          <Subnet name="{7}">
            <AddressPrefix>{8}</AddressPrefix>
          </Subnet>
        </Subnets>
        <DnsServersRef>
          <DnsServerRef name="Primary" />
          <DnsServerRef name="Sec" />
        </DnsServersRef>
      </VirtualNetworkSite>
      <VirtualNetworkSite name="{9}" Location="{10}">
        <AddressSpace>
          <AddressPrefix>{10}</AddressPrefix>
        </AddressSpace>
        <Subnets>
          <Subnet name="{11}">
            <AddressPrefix>{12}</AddressPrefix>
          </Subnet>
          <Subnet name="{13}">
            <AddressPrefix>{14}</AddressPrefix>
          </Subnet>
        </Subnets>
      </VirtualNetworkSite>
    </VirtualNetworkSites>
  </VirtualNetworkConfiguration>
</NetworkConfiguration>
'@ -f $DNSPrim, $DNSSec, $VNet1Name, $Region, $VN1AddressSpace, $VN1Subnet1Name, $VN1Subnet1, $VN1subnet2Name, $VN1subnet2, $Vnet2Name, $VN2AddressSpace, $VN2Subnet1Name, $VN2Subnet1, $VN2subnet2Name)

  $vNetxml | Out-File -FilePath $NetConfigXML

  Set-AzureVNetConfig -ConfigurationPath $NetConfigXML

}
function New-TestVM
{
  <#
      .SYNOPSIS
      This function allows for the creation of VM's configured to test the Migration Tool

      .DESCRIPTION
      This function allows for the creation of VM's configured to test the Migration Tool

      .PARAMETER VMName
      Name of VM

      .PARAMETER ServiceName
      ASM Service Name

      .PARAMETER InstanceSize
      Size of VM to be created, needs to follow standards for Azure Service Manager (ASM)

      .PARAMETER PrimarySubNet
      Primary Subnet to use

      .PARAMETER SecondarySubnet
      Secondary Subnet to use

      .PARAMETER AvailabilitySet
      If Availability Set required name of

      .PARAMETER VNET
      VNet Object ot use

      .PARAMETER Location
      Azure Region name, no validation

      .PARAMETER username
      Username to use

      .PARAMETER password
      Password to use on VM, standard String, not Secure String

      .PARAMETER windows
      Switch for Windows type OS.

      .PARAMETER PortSSH
      Open the ports for SSH

      .PARAMETER PortRDP
      Open ports for RDP

      .PARAMETER PortPowerShell
      Open Ports for PowerShell (WinRM)

      .PARAMETER PortHttp
      Open ports for Http requests (80)

      .PARAMETER Porthttps
      Open ports for HTTPS requests (443)

      .PARAMETER SecondNIC
      Switch to enable 2nd NIC

      .PARAMETER PortLBHttp
      Open Ports for Load Balancer HTTP (80)

      .PARAMETER PortLBHttps
      Open ports for Load Balancer HTTPS (443)

      .PARAMETER PortLBSSH
      Open ports for Load Balancer SSH (22)

      .PARAMETER NumberDataDisks
      Number of Data Disks to attach

      .PARAMETER StorageName
      Name of Storage Account to utilise

      .PARAMETER staticIP
      IPAddress for Static IP

      .PARAMETER ILBName
      Name of Internal Load Balancer

      .PARAMETER elbName
      Name of external Load Balancer

      .PARAMETER pip
      Enables Private IP

      .EXAMPLE
      New-TestVM -VMName "a-VM01" `
      -ServiceName "a-cs" `
      -InstanceSize "Standard_F2" `
      -PrimarySubNet "Subnet-1" `
      -SecondarySubnet "Subnet-2" `
      -AvailabilitySet "a-AS" `
      -VNET 'vnet' `
      -Location "Australia East" `
      -username "TestUserVM1" `
      -password "Passw0rd" `
      -windows `
      -PortSSH `
      -PortRDP `
      -PortPowerShell `
      -PortHttp `
      -Porthttps `
      -NumberDataDisks 2 `
      -StorageName $CurrentStdStorageAccount.Label

      Creates a simple VM.

      .NOTES
      This function could have bugs please provide feedback to steve.hosking@vigilant.it if you find any.

      .LINK
      URLs to related sites
      The first link is opened by Get-Help -Online New-TestVM

      .INPUTS
      List of input types that are accepted by this function.

      .OUTPUTS
      List of output types produced by this function.
  #>


  param
  (
    [Parameter(Mandatory)][string]$VMName,
    [Parameter(Mandatory)][string]$ServiceName,
    [Parameter(Mandatory)][string]$InstanceSize,
    [Parameter(Mandatory)][string]$PrimarySubNet,
    [Parameter(Mandatory)][string]$SecondarySubnet,
    [Parameter(Mandatory)][string]$AvailabilitySet,
    [Parameter(Mandatory)][string]$VNET,
    [Parameter(Mandatory)][string]$Location,
    [Parameter(Mandatory)][string]$username,
    [Parameter(Mandatory)][string]$password,
    [switch]$windows,
    [switch]$PortSSH,
    [switch]$PortRDP,
    [switch]$PortPowerShell,
    [switch]$PortHttp,
    [switch]$Porthttps,
    [switch]$SecondNIC,
    [switch]$PortLBHttp,
    [switch]$PortLBHttps,
    [switch]$PortLBSSH,
    [Parameter(Mandatory)][int]$NumberDataDisks,
    [Parameter(Mandatory)][string]$StorageName,
    [string]$staticIP,
    [string]$ILBName,
    [string]$elbName,
    [switch]$pip
  )
  $HTTPStr = 'HTTP'
  $SSHStr = 'SSH'
  $HTTPSStr = 'HTTPS'
  $TCPstr = 'tcp'
  Set-AzureSubscription -SubscriptionName $subscription -CurrentStorageAccountName $StorageName

  if($windows)
  {
    $family = 'Windows Server 2012 R2 Datacenter'
  }
  else
  {
    $family = 'Ubuntu Server 17.04 DAILY'
  }
  $image = Get-AzureVMImage | Where-Object {$_.ImageFamily -eq $family} | Sort-Object -Property PublishedDate -Descending | Select-Object -ExpandProperty ImageName -First 1

  New-AzureService -ServiceName $ServiceName -Location $Location

  #Start to configure the VM
  $vmconf = New-AzureVMConfig -Name $VMName -InstanceSize $InstanceSize -ImageName $image -AvailabilitySetName $AvailabilitySet | Set-AzureSubnet -SubnetNames $PrimarySubNet
  #region Ports
  if($portrdp) {$vmconf | Add-AzureEndpoint -Protocol $TCPstr -LocalPort 3389 -PublicPort 3389 -Name 'Remote Desktop'}
  if($portPowerShell){$vmconf | Add-AzureEndpoint -Protocol $TCPstr -LocalPort 5986 -PublicPort 5986  -Name 'PowerShell'}
  if($PortHttp) {$vmconf | Add-AzureEndpoint -Protocol $TCPstr -LocalPort 80   -PublicPort 80  -Name $HTTPStr}
  if($porthttps){$vmconf | Add-AzureEndpoint -Protocol $TCPstr -LocalPort 443  -PublicPort 443 -Name $HTTPSStr}
  if($portssh){$vmconf | Add-AzureEndpoint -Protocol $TCPstr -LocalPort 22   -PublicPort 22 -Name $SSHStr}
  if($portlbhttp){$vmconf | Add-AzureEndpoint -Protocol $TCPstr -LocalPort 80   -PublicPort 80    -Name 'Http80' -LBSetName 'HTTP-LB' -ProbePort 80  -ProbeProtocol $TCPstr}
  if($portlbhttps){$vmconf | Add-AzureEndpoint -Protocol $TCPstr -LocalPort 443  -PublicPort 443   -Name $HTTPSStr  -LBSetName 'HTTPS1'  -ProbePort 443 -ProbeProtocol $TCPstr}
  if($portlbssh){$vmconf | Add-AzureEndpoint -Protocol $TCPstr -LocalPort 22   -PublicPort 22 -Name $SSHStr -LBSetName 'SSH-LB'  -ProbePort 22  -ProbeProtocol $TCPstr}
  #endregion ports
  
  #region LBs
  if($ilbname)
  {
    $vmconf | Add-AzureEndpoint -Name 'TCP-1433-1433-2' -Lbset 'lbset' -Protocol $TCPstr -LocalPort 1433 -PublicPort 1433 -DefaultProbe -InternalLoadBalancerName $iLbName
    $vmconf | Add-AzureEndpoint -Name 'TCP-80-80' -Lbset 'lbset2' -Protocol $TCPstr -LocalPort 80 -PublicPort 80 -ProbePath '/healthprobe.aspx' -ProbePort 80 -ProbeProtocol $HTTPStr -InternalLoadBalancerName $iLbName
  }
    
  #endregion LBs
  if ($staticIP) {$vmconf | Set-AzureStaticVNetIP -IPAddress $staticip}
  if ($pip) {$vmconf | Set-AzurePublicIP -PublicIPName ($VMName + 'PIP') -DomainNameLabel ExtraPIP}
  if($SecondNIC){$vmconf | Add-AzureNetworkInterfaceConfig -Name 'ExNIC' -SubnetName $SecondarySubnet}
  
  if($NumberDataDisks -ge 1)
  {
    $cout = 0
    while ($cout -lt $NumberDataDisks)
    {
      $vmconf | Add-AzureDataDisk -CreateNew -DiskSizeInGB 120 -DiskLabel ($VMName + '_Data1') -LUN $cout
      $cout++
    }
  }
  if($windows)
  {
    $vmconf | Add-AzureProvisioningConfig -Windows -AdminUsername $username -Password $password
  }
  else
  {
    $vmconf | Add-AzureProvisioningConfig -Linux -LinuxUser $username -Password $password
  }

  New-AzureVM -ServiceName $ServiceName -VNetName $vnet -VMs $vmconf
}
function New-NSG
{
  <#
      .SYNOPSIS
      Creates a new Network Security Group for the use in Vigilant.IT's migration tool

      .DESCRIPTION
      Creates a new Network Security Group for the use in Vigilant.IT's migration tool

      .PARAMETER NSGName
      Name of the new Network Security Group

      .PARAMETER NSGLabel
      Descriptive label for the Network Security Group

      .PARAMETER region
      Needs to the Azure Region Names, no validation in place will error if incorrect name

      .PARAMETER vnc
      Open the ports for VNC

      .EXAMPLE
      new-NSG -NSGName 'NSG-FrontEnd' -NSGLabel 'Front end subnet NSG' -region 'australiaeast'
      
      Creates a new NSG in Sydney

      .LINK
      URLs to related sites
      The first link is opened by Get-Help -Online New-NSG

      .INPUTS
      List of input types that are accepted by this function.

      .OUTPUTS
      List of output types produced by this function.
  #>


  [CmdletBinding()]
  param
  (
    [string]$NSGName,
    [string]$NSGLabel,
    [string]$region,
    [switch]$vnc
  )
  $WildCardStr = '*'
  $InBoundStr = 'Inbound'
  $TCPstr = 'TCP'
  $Allowstr = 'Allow'
  $nsg = New-AzureNetworkSecurityGroup -Name $NSGName -Location $region -Label $NSGLabel
  Set-AzureNetworkSecurityRule -NetworkSecurityGroup $nsg -Name RDP -Action $Allowstr -Protocol $TCPstr -Type $InBoundStr -Priority 100 -SourceAddressPrefix *  -SourcePortRange $WildCardStr -DestinationAddressPrefix $WildCardStr -DestinationPortRange '3389'
  Set-AzureNetworkSecurityRule -NetworkSecurityGroup $nsg -Name HTTP -Action $Allowstr -Protocol $TCPstr -Type $InBoundStr -Priority 110 -SourceAddressPrefix *  -SourcePortRange $WildCardStr -DestinationAddressPrefix $WildCardStr -DestinationPortRange '80'
  if($vnc){Set-AzureNetworkSecurityRule -NetworkSecurityGroup $nsg -Name VNC -Action $Allowstr -Protocol $TCPstr -Type $InBoundStr -Priority 120 -SourceAddressPrefix *  -SourcePortRange $WildCardStr -DestinationAddressPrefix $WildCardStr -DestinationPortRange '5900'}
}
function New-TestVnets
{  
  New-NSG -NSGName 'NSG-FrontEnd' -NSGLabel 'Front end subnet NSG' -region $AusEastRegionStr
  New-NSG -NSGName 'NSG-VM' -NSGLabel 'VM NSG' -region $AusEastRegionStr
  Set-TestVnet -Region $AusEastRegionStr `
  -VNet1Name $VnetName `
  -VN1Subnet1 '10.0.0.0/25' `
  -VN1subnet2 '10.0.1.0/25' `
  -VN1Subnet1Name $Subnet1Name `
  -VN1subnet2Name $Subnet2Name `
  -VN1AddressSpace '10.0.0.0/23' `
  -Vnet2Name 'Group a20160829-CS a20160829-CS' `
  -VN2Subnet1 '10.1.0.0/24' `
  -VN2subnet2 '10.1.1.0/24' `
  -VN2Subnet1Name 'default' `
  -VN2subnet2Name 'FrontEnd' `
  -VN2AddressSpace '10.1.0.0/16' `
  -DNSPrim '8.8.8.8' `
  -DNSSec '8.8.4.4'
  Add-AzureInternalLoadBalancer -ServiceName $CloudServiceName -InternalLoadBalancerName 'ilb-001' -SubnetName $Subnet1Name -StaticVNetIPAddress '10.0.0.50'
}
function New-TestCase1Env
{
  $CurrentStdStorageAccount = get-TestStorage -StorageName 'apeteststdsge2017' -Region $AusEastRegionStr -Type 'Standard_LRS' -create

  #create VM1
  $VM1 = New-TestVM -VMName 'VM01-test' `
  -ServiceName $CloudServiceName `
  -InstanceSize 'Standard_F2' `
  -PrimarySubNet $Subnet1Name `
  -SecondarySubnet $Subnet2Name `
  -AvailabilitySet 'AS-test' `
  -VNET $VnetName `
  -Location $AusEastRegionStr `
  -username 'TestUserVM1' `
  -password 'Passw0rd' `
  -windows `
  -PortSSH `
  -PortRDP `
  -PortPowerShell `
  -PortHttp `
  -Porthttps `
  -NumberDataDisks 2 `
  -StorageName $CurrentStdStorageAccount.Label   
}