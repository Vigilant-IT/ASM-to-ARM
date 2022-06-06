function convert-VITAzureSize{
  param( 
    [Parameter(Mandatory)]
    $vmsize
  )
  switch ($vmsize)
  {
    'ExtraSmall'{$vmsize = 'Standard_A0'}
    'Small' {$VMSize = 'Standard_A1'}
    'Medium' {$VMSize = 'Standard_A2'}
    'Large' {$VMSize = 'Standard_A3'}
    'ExtraLarge' {$VMSize = 'Standard_A4'}
    'A5' {$VMSize = 'Standard_A5'}
    'A6' {$VMSize = 'Standard_A6'}
    'A7' {$VMSize = 'Standard_A7'}
    'A8' {$VMSize = 'Standard_A8'}
    'A9' {$VMSize = 'Standard_A9'}
    'A10' {$VMSize = 'Standard_A10'}
    'A11' {$VMSize = 'Standard_A11'}
  }
  $vmsize
}