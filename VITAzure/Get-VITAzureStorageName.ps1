function Get-VITAzureStorageName
{
  param
  (
    [Parameter(Mandatory)]
    [string]$IOtype,
    [Parameter(Mandatory)]
    [string]$DiskType
  )
  $disk = [VITStorName]::new()
  if ($IOType -eq 'Standard' -and $DiskType -eq 'OS') 
  {
    $disk.storname = 'osstd'
    $disk.vhdcount = 40
  }
  elseif ($IOType -eq 'Provisioned' -and $DiskType -eq 'OS') 
  {
    $disk.storname = 'osprm'
    $disk.vhdcount = 16
  }
  elseif ($IOType -eq 'Standard' -and $DiskType -eq 'Data') 
  {
    $disk.storname = 'datastd'
    $disk.vhdcount = 40    
  }
  elseif ($IOType -eq 'Provisioned' -and $DiskType -eq 'OS') 
  {
    $disk.storname = 'dataprm'
    $disk.vhdcount = 16
  }
  return $disk
}