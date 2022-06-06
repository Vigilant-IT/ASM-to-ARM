function Write-Log {
    param([parameter(mandatory=$true, position=0)]$Message,
    [parameter(mandatory=$false, position=1)][ValidationSet("Info", "Debug", "Warn", "Error")] $Level = "Info", 
    [parameter(mandatory=$false, position=2, ValueFromRemainingArguments=$true)]$Args)

    if($Global:APEGlobal -eq $null)
    {
        Write-Information "[$Level]: $message : $Args"
    }else{
        Switch($Level){
            "Info"  { $Global:APEGlobal.Information($Message, $Args) }
            "Debug" { $Global:APEGlobal.Debug($Message, $Args)} 
            "Warn"  { $Global:APEGlobal.Warning($Message, $Args) } 
            "Error" { $Global:APEGlobal.Error($Message, $Args) } 
        }
    }
}

function Write-VITProgress {
    param([parameter(mandatory=$true, position=0)]$Message)

    if($Global:APEGlobal -eq $null)
    {
        Write-Information "[PROGRESS]: $message"
    }else{
        $Global:APEGlobal.Progress($Message)
    }
}