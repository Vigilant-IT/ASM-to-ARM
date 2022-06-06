function write-logs
{
  param
  (
    [Parameter(Mandatory)]
    [string]$AIKey,
    [Parameter(Mandatory,ValueFromPipeline)]
    $inputobject,
    [switch]$Print
  )
  #$scriptpath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)
  #$scriptpath = "C:\Data\PoshScripts"
  #$ai = "$scriptpath\Microsoft.ApplicationInsights.dll"
  #[Reflection.Assembly]::LoadFile($ai) | Out-Null
  #$telclient = New-Object "Microsoft.ApplicationInsights.TelemetryClient"
  #$telclient.InstrumentationKey = $AIKey
  $type = (Get-Member -InputObject $inputobject).TypeName[0]
  if(($type) -like "System.Management.Automation.error*")
  {
    #$TelException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"
    #$TelException.Exception = $_.Exception
    #$TelClient.TrackException($TelException)
    #$TelClient.Flush()
    #if($Print){$inputobject}
  }
  elseif(($type) -like "System.Management.Automation.info*")
  {
    #$telclient.TrackEvent("[$(([datetime]::now).ToLongTimeString())]" + $inputobject.Messagedata + ", in script:" + $inputobject.Source)
    #$telclient.Flush()
    #if($Print){$inputobject}
  }
  elseif(($type) -like "System.Management.Automation.*" -and ($type) -notlike "System.Management.Automation.PSCustomObject")
  {
    #$inputobject
    #$telclient.TrackEvent("[$(([datetime]::now).ToLongTimeString())]" + $inputobject.Message + ", in script:" + $inputobject.InvocationInfo.ScriptName)
    #$telclient.Flush()
    #if($Print){$inputobject}
  }
  else
  {
    $inputobject
  }
}