class newDisk
{
  [string]$azcopySourceuri
  [string]$azcopyTargeturi
  [string]$sourcekey
  [string]$targetKey
  [string]$vhdfilename
  [string]$vhduri
  [string]$size
  [int]$lun
  [string]$type
  newDisk($azcopysuri, $azcopyturi, $skey, $tkey, $vhdfile, $vhduri, $s, $l,$t)
  {
    $this.azcopySourceuri = $azcopysuri
    $this.azcopyTargeturi = $azcopyturi
    $this.sourcekey = $skey
    $this.targetKey = $tkey
    $this.vhdfilename = $vhdfile
    $this.vhduri = $vhduri
    $this.size = $s
    $this.lun = $l
    $this.type = $t
  }
}

function move-VITAzureDisk
{
  param
  ([Parameter(Mandatory)]
    $SourceUserProfile,
    [string]
    [Parameter(Mandatory)]
    $SourceSubId,
    [Parameter(Mandatory)]
    $SourceResGrp,
    [Parameter(Mandatory)]
    $TargetUserProfile,
    [string]
    [Parameter(Mandatory)]
    $TargetSubId,
    [Parameter(Mandatory)]
    $rg,
    [string]
    [Parameter(Mandatory)]
    $Region,
    [switch]
    [Parameter(Mandatory)]
    $AzCopyOverWrite,
    [Parameter(Mandatory)]
    $Disks
  )
  $newdisk = @()
  foreach ($disk in $disks)
  {
    $OSDisk = $disk.os
    #this is where you were working to consolidate the below in.
    if($disk.disk.storageAccount.id)
    {
      $SourceStorage = Get-VITAzureASMVMInventory -UserProfile $SourceUserProfile -SubscriptionId $SourceSubId -ResID $disk.disk.storageAccount.id -resgroup $SourceResGrp
      $sourcestorage = $SourceStorage | Where-Object {$_.ResourceId -eq $disk.disk.storageAccount.id}
      $sourcekey = get-VITAzureStoreKeys -UserProfile $SourceUserProfile -Subid $SourceSubId -StoreName $SourceStorage.name -resGrpName $SourceResGrp
      $VHDFileName = $disk.disk.vhdUri -split '/' | Select-Object -last 1
      $azcopysourceuri = $disk.disk.vhduri -replace "/$VHDFileName"
    }
    else
    {
      $SourceStorage = Get-VITAzureASMVMInventory -UserProfile $SourceUserProfile -Subscriptionid $SourceSubId -Resname $disk.disk.vhd.uri.Split('.')[0].split('/')[2] -resgroup $SourceResGrp
      $sourcekey = (get-VITAzureStoreKeys -UserProfile $SourceUserProfile -SubId $SourceSubId -StoreName $SourceStorage.name -resGrpName $SourceResGrp -ARM).value[0]
      $VHDFileName = $disk.disk.vhd.Uri -split '/' | Select-Object -last 1
      $azcopysourceuri = $disk.disk.vhd.uri -replace "/$VHDFileName"
    }
    $SourceContext = New-AzureStorageContext -StorageAccountName $SourceStorage.name -StorageAccountKey $sourcekey -Verbose  
    $disktype = ''
    if($OSDisk)
    {
      $disklbl = 'OS'
      if(get-member -InputObject $disk.disk -name "operatingSystem" -MemberType Properties)
      {
        $disktype = $disk.disk.operatingSystem
      }
      else
      {
        $disktype = $disk.disk.ostype
      }
    }
    else
    {
      $disklbl = 'Data'
      $disktype = 'Data'
      if(get-member -InputObject $disk.disk -name "disksizeGb" -MemberType Properties)
      {
            $disksize = $disk.disk.disksizegb
      }
      else
      {
            $disksize = $disk.disk.disksize
      }
    }
    if(get-member -InputObject $disk.disk -name "iotype" -MemberType Properties)
    {
        $iotype = $disk.disk.iotype
        $storagetype = ($sourceStorage.Properties.AccountType  -replace '-','_')
    }
    else
    {
        $iotype = $SourceStorage.sku.tier
        $storagetype = $SourceStorage.sku.name
    }
    
    $newcontext = New-VITStorage -UserProfile $TargetUserProfile `
    -Subid $TargetSubid `
    -RG $rg `
    -region $Region `
    -StorageKey $SourceKey `
    -StorageName $sourcestorage.Name `
    -IOType $iotype `
    -DiskType $disklbl `
    -StorageType $storagetype
    $diag = ($disk.disk.iotype -eq 'Provisioned')
    $TargetStorageName = $newcontext.Storageaccountname
    $azcopytargeturi = (get-VITAzureStorageEndPoint -UserProfile $TargetUserProfile -Subid $TargetSubId -RGName $rg.ResourceGroupName -StorName $TargetStorageName).AbsoluteUri
    $TargetKey = (get-VITAzureStoreKeys -UserProfile $TargetUserProfile -Subid $TargetSubId -resGrpName $rg.ResourceGroupName -StoreName $TargetStorageName -ARM).value[0]

    $newdisk += [newdisk]::new($azcopysourceuri,$azcopytargeturi, $sourcekey, $targetkey, $VHDFileName, ("$azcopytargeturi/$VHDFileName"), $disksize, $disk.disk.lun, $disktype)
  }
  
    
  $scriptblock = {
    param($nd, $APEScriptPath)
    $azcopytemp = "$env:USERPROFILE\AppData\Local\Microsoft\Azure\AzCopy"
    $jnpath = ("$azcopytemp\$(($nd.VHDFileName).replace('.vhd',''))")
    new-item -path $azcopytemp -Name ($nd.VHDFileName -split '.' | Select-Object -first 1 ) -ItemType Directory
    if (($APEScriptPath -split '\\' | select-object -last 1) -eq 'vitazure') {$apescriptpath = split-path $APEScriptPath}
    $params = "/source:$($nd.azcopysourceuri) /dest:$($nd.azcopytargeturi) /SourceKey:$($nd.SourceKey) /destkey:$($nd.TargetKey) /pattern:$($nd.VHDFileName) /z:$jnpath /v:$($azcopytemp + "\" + $($nd.VHDFileName) + ".log")"
    if ($true) 
    {
      $params = $params + ' /y'
    }
    Start-Process -FilePath "$APEScriptPath\Tools\AzCopy\AzCopy.exe" -ArgumentList @($params) -WorkingDirectory "$APEScriptPath\Tools\AzCopy" -Wait -Verbose 
  }
  $jobs = @()
  foreach ($nd in $newdisk) 
  {
    $tmpJob = Start-Job -ScriptBlock $scriptblock -ArgumentList $nd, $PSScriptRoot -Name $nd.VHDFileName
    $jobs += $tmpJob
  }
  
  While ($jobs.state -contains "Running"){
    $jobRunning = $jobs | Where-Object { $_.State -eq "Running" }
    $jobCompleted = $jobs | Where-Object { $_.State -eq "Completed" }
    write-Debug "$($jobCompleted.Count) jobs completed. $($jobRunning.count) jobs remaining."
    Start-Sleep -Seconds 2
   }

  $newdisk
  
}