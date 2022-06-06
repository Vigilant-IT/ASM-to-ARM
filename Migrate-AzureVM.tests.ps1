$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '.Tests.', '.'
. "$here\$sut"

$Global:TestConfig = Get-Content "$here\TestConfig.psd1" -Raw| Invoke-Expression

Describe 'Connect-Azure' {
  Context 'Credential Testing'   {
    It "Will not return anything on success" {
        Connect-Azure -Username $Global:TestConfig["SourceUserName"] -Password $Global:TestConfig["SourcePassword"] -ErrorAction Stop | Should be $null
    }

    It "Will throw on bad username and password" {
      { 
        Connect-Azure -Username "Badusername" -Password "Badpassword" 
      } | Should Throw
    }
  }

  Context 'Testing subscriptions' {
    It "Will not return anything on valid subscription" {
      Connect-Azure -Username $Global:TestConfig["SourceUserName"] -Password $Global:TestConfig["SourcePassword"] -ErrorAction Stop -Subscription $Global:TestConfig["SourceSubscription"] | Should be $null
    }

    It "Will throw on bad subscription name" {
      {
        Connect-Azure -Username $Global:TestConfig["SourceUserName"] -Password $Global:TestConfig["SourcePassword"] -ErrorAction Stop -Subscription "Bad Subscription"
      } | Should Throw
    }
  }

  Context "Testing ASM Authentication" {
    It 'Will not return anything on valid subscription' {
      Connect-Azure -Username $Global:TestConfig["SourceUserName"] -Password $Global:TestConfig["SourcePassword"] -ErrorAction Stop -Subscription $Global:TestConfig["SourceSubscription"] -ASM | Should be $null
    }

    It "Will throw on bad subscription name" {
      {
        Connect-Azure -Username $Global:TestConfig["SourceUserName"] -Password $Global:TestConfig["SourcePassword"] -ErrorAction Stop -Subscription "Bad Subscription" -ASM
      } | Should Throw
    }
  }
}


Describe "Get-SourcediskDetails" {
  Context 'OS Disk' {
      Connect-Azure -Username $Global:TestConfig["SourceUserName"] -Password $Global:TestConfig["SourcePassword"] -ErrorAction Stop -Subscription $Global:TestConfig["SourceSubscription"]
      Connect-Azure -Username $Global:TestConfig["SourceUserName"] -Password $Global:TestConfig["SourcePassword"] -ErrorAction Stop -Subscription $Global:TestConfig["SourceSubscription"] -ASM

    It "Can get os disk" {
      
      $VM = Get-AzureRmResource -ExpandProperties -ResourceType 'Microsoft.ClassicCompute/virtualMachines' -ResourceGroupName $Global:TestConfig["SourceResourceGroup"] | Select-Object -First 1
      (Get-SourceDiskDetails -Disk  $VM.Properties.StorageProfile.OperatingSystemDisk -resourceGroup $Global:TestConfig["SourceResourceGroup"]).DiskType | should be "OS"
    }

   <# It "Can get data disk" {
      $VM = Get-AzureRmResource -ExpandProperties -ResourceType 'Microsoft.ClassicCompute/virtualMachines' -ResourceGroupName $Global:TestConfig["SourceResourceGroup"] | Select-Object -First 1
      
      $disk = $VM.Properties.StorageProfile.dataDisks | Select-Object -First 1
      (Get-SourceDiskDetails -Disk $disk -resourceGroup $Global:TestConfig["SourceResourceGroup"]).DiskType | should be "Data"
    } #>
  }
}

Describe "New-TargetStorageAccount" {
  Context "Can create storage account" {
    Connect-Azure -Username $Global:TestConfig["TargetUsername"] -Password $Global:TestConfig["TargetPassword"] -Subscription $Global:TestConfig["TargetSubscription"]
    $prefix = $Global:TestConfig["TargetResourceGroup"].ToLower() -replace "[^a-z0-9]", ""

    BeforeAll {
      $prefix = $Global:TestConfig["TargetResourceGroup"].ToLower() -replace "[^a-z0-9]", ""
      Remove-AzureRmStorageAccount -ResourceGroupName $Global:TestConfig["TargetResourceGroup"] -StorageAccountName "$($prefix)osstd" -ErrorAction SilentlyContinue
      Remove-AzureRmStorageAccount -ResourceGroupName $Global:TestConfig["TargetResourceGroup"] -StorageAccountName "$($prefix)osprm" -ErrorAction SilentlyContinue
      Remove-AzureRmStorageAccount -ResourceGroupName $Global:TestConfig["TargetResourceGroup"] -StorageAccountName "$($prefix)datastd" -ErrorAction SilentlyContinue
      Remove-AzureRmStorageAccount -ResourceGroupName $Global:TestConfig["TargetResourceGroup"] -StorageAccountName "$($prefix)dataprm" -ErrorAction SilentlyContinue
    }

    AfterAll {
      $prefix = $Global:TestConfig["TargetResourceGroup"].ToLower() -replace "[^a-z0-9]", ""
      Remove-AzureRmStorageAccount -ResourceGroupName $Global:TestConfig["TargetResourceGroup"] -StorageAccountName "$($prefix)osstd" -ErrorAction SilentlyContinue
      Remove-AzureRmStorageAccount -ResourceGroupName $Global:TestConfig["TargetResourceGroup"] -StorageAccountName "$($prefix)osprm" -ErrorAction SilentlyContinue
      Remove-AzureRmStorageAccount -ResourceGroupName $Global:TestConfig["TargetResourceGroup"] -StorageAccountName "$($prefix)datastd" -ErrorAction SilentlyContinue
      Remove-AzureRmStorageAccount -ResourceGroupName $Global:TestConfig["TargetResourceGroup"] -StorageAccountName "$($prefix)dataprm" -ErrorAction SilentlyContinue      
    }

    It "Can create Standard OS Account" {
      New-TargetStorageAccount -DiskType "OS" -IOType "Standard" -Region $Global:TestConfig["Region"] -ResourceGroup $Global:TestConfig["TargetResourceGroup"] -storageSKU $Global:TestConfig["TargetStorageSKU"] | out-null
      Get-AzureRmStorageAccount -ResourceGroupName $Global:TestConfig["TargetResourceGroup"] -Name "$($prefix)osstd" | should not be $null
    }

    It "Can use existing Standard OS Account" {
      New-TargetStorageAccount -DiskType "OS" -IOType "Standard" -Region $Global:TestConfig["Region"] -ResourceGroup $Global:TestConfig["TargetResourceGroup"] -storageSKU $Global:TestConfig["TargetStorageSKU"] | should not be $null
    }

    It "Can create Provisioned OS Account" {
      New-TargetStorageAccount -DiskType "OS" -IOType "Provisioned" -Region $Global:TestConfig["Region"] -ResourceGroup $Global:TestConfig["TargetResourceGroup"] -storageSKU $Global:TestConfig["TargetStorageSKU"] | out-null
      Get-AzureRmStorageAccount -ResourceGroupName $Global:TestConfig["TargetResourceGroup"] -Name "$($prefix)osprm" | should not be $null
    }

    It "Can use existing Provisioned OS Account" {
      New-TargetStorageAccount -DiskType "OS" -IOType "Provisioned" -Region $Global:TestConfig["Region"] -ResourceGroup $Global:TestConfig["TargetResourceGroup"] -storageSKU $Global:TestConfig["TargetStorageSKU"] | should not be $null
    }

    It "Can create Standard Data Account" {
      New-TargetStorageAccount -DiskType "Data" -IOType "Standard" -Region $Global:TestConfig["Region"] -ResourceGroup $Global:TestConfig["TargetResourceGroup"] -storageSKU $Global:TestConfig["TargetStorageSKU"] | out-null
      Get-AzureRmStorageAccount -ResourceGroupName $Global:TestConfig["TargetResourceGroup"] -Name "$($prefix)datastd" | should not be $null
    }

    It "Can use existing Standard Data Account" {
      New-TargetStorageAccount -DiskType "Data" -IOType "Standard" -Region $Global:TestConfig["Region"] -ResourceGroup $Global:TestConfig["TargetResourceGroup"] -storageSKU $Global:TestConfig["TargetStorageSKU"] | should not be $null
    }

    It "Can create Provisioned Data Account" {
      New-TargetStorageAccount -DiskType "Data" -IOType "Provisioned" -Region $Global:TestConfig["Region"] -ResourceGroup $Global:TestConfig["TargetResourceGroup"] -storageSKU $Global:TestConfig["TargetStorageSKU"] | out-null
      Get-AzureRmStorageAccount -ResourceGroupName $Global:TestConfig["TargetResourceGroup"] -Name "$($prefix)dataprm" | should not be $null
    }

    It "Can use existing Provisioned Data Account" {
      New-TargetStorageAccount -DiskType "Data" -IOType "Provisioned" -Region $Global:TestConfig["Region"] -ResourceGroup $Global:TestConfig["TargetResourceGroup"] -storageSKU $Global:TestConfig["TargetStorageSKU"] | should not be $null
    }
  }
}
