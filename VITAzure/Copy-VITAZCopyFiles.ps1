function Copy-VITAZCopyFiles
{
  param
  (
    [Parameter(Position=0)]
    [string]$azcopytemp = "$env:USERPROFILE\AppData\Local\Microsoft\Azure\AzCopy",
    [Parameter(Mandatory)]
    [string]$azcopysourceuri,
    [Parameter(Mandatory)]
    [string]$azcopytargeturi,
    [Parameter(Mandatory)]
    [string]$Sourcekey,
    [Parameter(Mandatory)]
    [string]$targetkey,
    [Parameter(Mandatory)]
    [string]$VHDFileName,
    [Parameter(Mandatory)]
    [switch]$AzCopyOverWrite
  )
  if($APEScriptPath -eq $null) { $APEScriptPath = $PSScriptRoot }
  if(Test-Path -path $azcopytemp -Verbose )
  {
    if((Get-ChildItem -Path $azcopytemp -Recurse -Verbose ).count -ne 0)
    {
      remove-item -Path "$azcopytemp\*.*" -Force -ErrorAction SilentlyContinue -Verbose 
    }
  }
  if (($APEScriptPath -split '/' | select-object -last 1) -eq 'vitazure') {$apescriptpath = split-path $APEScriptPath}
  $params = "/source:$azcopysourceuri /dest:$azcopytargeturi /SourceKey:$SourceKey /destkey:$TargetKey /pattern:$VHDFileName"
  if ($AzCopyOverWrite) 
  {
    #$params = $params + ' /y'
  }
  Start-Process -FilePath "$APEScriptPath\Tools\AzCopy\AzCopy.exe" -ArgumentList @($params) -WorkingDirectory "$APEScriptPath\Tools\AzCopy" -Wait -Verbose 
}