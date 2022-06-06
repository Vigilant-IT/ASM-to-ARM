

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '.Tests.', '.'
. "$here\$sut"
. "$here\Migrate-AzureVM.ps1"

$Global:TestConfig = Get-Content "$here\TestConfig.psd1" -Raw| Invoke-Expression

#Fake log function. This is injected by C# in real version
function Write-Log {
    parma($message)    

    Write-Host $message
}

#Fake global config which will be injected by c#
$Global:vitconfig = @{
    AzCopyPath = "$here\Tools\AzCopy"
}

Describe "Get-ASMSubscriptions" {
    Context "Correct user credentials" {
        
        It "Logs in and returns subscription" {
            $subs = Get-Subscriptions -Username $Global:TestConfig["SourceUserName"] -Password $Global:TestConfig["SourcePassword"]
        }

        It "Returns expected subscription " {
            $subs = Get-Subscriptions -Username $Global:TestConfig["SourceUserName"] -Password $Global:TestConfig["SourcePassword"]
            $expected = $false

            foreach($s in $subs){
                if($s.Name -eq $Global:TestConfig["SourceSubscription"]) { $expected = $true}
            }

            $expected | should be $true
        }
    }

    Context "Incorrect user credentials" {

        It "Throws when bad password is passed in." {
            {
                Get-Subscriptions -UserName "invalidusername" -Password "invalidpassword"
            } | should throw
        }
    }
}

Describe "Get-VM" {
    Context "Retrive VMs" {

        It "Will get list of VMs" {
            Get-VM -Username $Global:TestConfig["SourceUserName"] -Password $Global:TestConfig["SourcePassword"] -SubName $Global:TestConfig["SourceSubscription"] | Where Name -eq $Global:TestConfig["SourceVM"] | should not be $null
        }
    }
}

Describe "Get-ResourceGroup" {
    Context "Retrive Context Groups" {

        It "Will get list of resource groups"{
            Get-Resourcegroup -Username $Global:TestConfig["TargetUsername"] -Password $Global:TestConfig["TargetPassword"] -SubName $Global:TestConfig["TargetSubscription"] | where Name -eq $Global:TestConfig["TargetResourceGroup"] | should not be $null        
        }
    }
}

Describe "Get-Region" {
    Context "Returns list of regions" {
        It "Will return expected region" {
            Get-Region -Username $Global:TestConfig["TargetUsername"] -Password $Global:TestConfig["TargetPassword"] -SubName $Global:TestConfig["TargetSubscription"] | Where Id -eq $Global:TestConfig["Region"] | should not be $null
        }
    }
}

Describe "Start-Migration" {
    Context "Can Migrate VM" {
        It "Initial Migration Test" {
            Start-Migration -SourceUserName $Global:TestConfig["SourceUsername"] -SourcePassword $Global:TestConfig["SourcePassword"] -SourceSub $Global:TestConfig["SourceSubscription"]  -SourceResourceGroup $Global:TestConfig["SourceResourceGroup"] -TargetUserName $Global:TestConfig["TargetUsername"] -TargetPassword $Global:TestConfig["TargetPassword"] -destSub $Global:TestConfig["TargetSubscription"] -Region $Global:TestConfig["Region"] -TargetResourceGroup $Global:TestConfig["TargetResourceGroup"] -Overwrite $true -PowerUp $false
        }
    }
}

