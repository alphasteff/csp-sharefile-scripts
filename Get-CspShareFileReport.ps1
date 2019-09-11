<#
    .SYNOPSIS
    Describe purpose of "sumfunc" in 1-2 sentences.

    .DESCRIPTION
    Add a more complete description of what the function does.

    .EXAMPLE
    sumfunc
    Describe what this call does

    .NOTES
    Place additional notes here.

    .LINK
    URLs to related sites
    The first link is opened by Get-Help -Online sumfunc

    .INPUTS
    List of input types that are accepted by this function.

    .OUTPUTS
    List of output types produced by this function.
#>

[CmdletBinding()]
Param(
  [string]$File = ('{0}{1}\sfcreds.sfps' -f $env:HOMEDRIVE, $env:HOMEPATH)
)

function ConvertPSObjectToHashtable
{
  <#
      .SYNOPSIS
      Describe purpose of "ConvertPSObjectToHashtable" in 1-2 sentences.

      .DESCRIPTION
      Add a more complete description of what the function does.

      .PARAMETER InputObject
      Describe parameter -InputObject.

      .EXAMPLE
      ConvertPSObjectToHashtable -InputObject Value
      Describe what this call does

      .NOTES
      Place additional notes here.

      .LINK
      URLs to related sites
      The first link is opened by Get-Help -Online ConvertPSObjectToHashtable

      .INPUTS
      List of input types that are accepted by this function.

      .OUTPUTS
      List of output types produced by this function.
  #>


  param (
    [Parameter(Mandatory=$true,HelpMessage='Input object required',ValueFromPipeline)]
    [object]$InputObject
  )

  process
  {
    if ($null -eq $InputObject) { return $null }

    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string])
    {
      $collection = @(
        foreach ($object in $InputObject) { ConvertPSObjectToHashtable -InputObject $object }
      )

      Write-Output -NoEnumerate -InputObject $collection
    }
    elseif ($InputObject -is [psobject])
    {
      $hash = @{}

      foreach ($property in $InputObject.PSObject.Properties)
      {
        $hash[$property.Name] = ConvertPSObjectToHashtable -InputObject $property.Value
      }

      $hash
    }
    else
    {
      $InputObject
    }
  }
}

function Add-TenantTotals {
  <#
      .SYNOPSIS
      Describe purpose of "Add-TenantTotals" in 1-2 sentences.

      .DESCRIPTION
      Add a more complete description of what the function does.

      .PARAMETER inCount
      Describe parameter -inCount.

      .PARAMETER inUsage
      Describe parameter -inUsage.

      .PARAMETER inStorage
      Describe parameter -inStorage.

      .EXAMPLE
      Add-TenantTotals -inCount Value -inUsage Value -inStorage Value
      Describe what this call does

      .NOTES
      Place additional notes here.

      .LINK
      URLs to related sites
      The first link is opened by Get-Help -Online Add-TenantTotals

      .INPUTS
      List of input types that are accepted by this function.

      .OUTPUTS
      List of output types produced by this function.
  #>


  param (
    [Parameter(Mandatory=$true,HelpMessage='Licenses Status required')]
    [string]$Status,
    [Parameter(Mandatory=$true,HelpMessage='Tenant Count required')]
    [long]$inCount,
    [Parameter(Mandatory=$true,HelpMessage='Total Licenses Used required')]
    [long]$inUsage,
    [Parameter(Mandatory=$true,HelpMessage='Total Zone Usage required')]
    [long]$inStorage
  )
  
  [object]$objTotals = New-Object -TypeName PSObject
  Add-Member -InputObject $objTotals -MemberType NoteProperty -Name 'Account Name' -Value ("Total $Status Licenses ({0})" -f $inCount)
  Add-Member -InputObject $objTotals -MemberType NoteProperty -Name 'Licenses Used' -Value $inUsage
  Add-Member -InputObject $objTotals -MemberType NoteProperty -Name 'Storage Zone' -Value ''
  Add-Member -InputObject $objTotals -MemberType NoteProperty -Name 'Zone Usage (Bytes)' -Value $inStorage
  Add-Member -InputObject $objTotals -MemberType NoteProperty -Name 'Status' -Value $Status
  
  $tenantReport.Add($objTotals)
}

if ( Get-PSSnapin -Registered | Select-String -Pattern ShareFile) {
  Write-Verbose -Message 'ShareFile Snapin registered.'
} else {
  Write-Verbose -Message 'ShareFile Snapin not registered. Aborting!' -Verbose
  exit
}

# Ensure the ShareFile PowerShell Snap-in is loaded
if ( $null -eq (Get-PSSnapin -Name ShareFile -ErrorAction SilentlyContinue) )
{
  Write-Verbose -Message 'Adding ShareFile snapin'
  try {
    Add-PsSnapin -Name ShareFile
  } catch {
    Write-Verbose -Message 'ShareFile snapin could not be added. Aborting!' -Verbose
    exit 
  }
  Write-Verbose -Message 'ShareFile snapin sucessfully added'
}

# Create credentials file if one does not exist by using the New-SfClient command
if (Test-Path -Path $File){
  Write-Verbose -Message ('ShareFile credentials file {0} already exists' -f $File) 
} else {
  Try {
    $null = New-SfClient -Name $File
  } catch { 
    Write-Verbose -Message ('Error creating ShareFile credentials file {0}.' -f $File) -Verbose
    exit
  }
  Write-Verbose -Message ('ShareFile credentials file {0} sucessfully saved.' -f $File) -Verbose
}

#Authenticate
$sfClient = Get-SfClient -Name $File

#Get Tenant License info
$tenants = Send-SfRequest -Client $sfClient -Method GET -Entity Accounts -Navigation Tenants -Expand 'Preferences,Preferences/DefaultZone,UserUsage'

#Get Zone usage
$zoneUsageUri = ('{0}/Accounts/Tenants/ZoneUsage' -f $sfClient.PrimaryDomain.Uri)
$zoneUsageResponse = Invoke-WebRequest -Uri $zoneUsageUri -Headers @{'Authorization'=('Bearer {0}' -f $sfClient.PrimaryDomain.OAuthToken)}

$zoneUsage = $zoneUsageResponse.Content | ConvertFrom-Json

$usageHash = $zoneUsage.TenantsToZones | ConvertPSObjectToHashtable

#Output values
$tenantInfo = $tenants | Select-Object -Property @{N='Account Name'
E={$_.CompanyName}}, @{N='Licenses Used'
E={$_.UserUsage.EmployeeCount}},@{N='Storage Zone'
E={$_.Preferences.DefaultZone.Name}}, @{N='Zone Usage (Bytes)'
E={$usageHash[$_.Id]['ZonesToUsage'][$_.Preferences.DefaultZone.Id].TotalFileSizeBytes}}, @{N='Status'
E={If ($_.IsFreeTrial) {'Trial'} Else {'Paid'}}}

$paidCount = 0
$totalPaid = 0
$totalPaidStorage = 0
$trialCount = 0
$totalTrial = 0
$totalTrialStorage = 0

foreach ( $tenant in $tenantInfo) {
  Switch ( $tenant.Status ) {
    'Paid' {
      $paidCount += 1
      $totalPaid += $tenant.'Licenses Used'
      $totalPaidStorage += $tenant.'Zone Usage (Bytes)'
    }
    'Trial'{
      $trialCount += 1
      $totalTrial += $tenant.'Licenses Used'
      $totalTrialStorage += $tenant.'Zone Usage (Bytes)'
    }
  } 
    
}

$tenantReport = {$tenantInfo}.Invoke()
Add-TenantTotals -Status 'Paid'  -inCount $paidCount -inUsage $totalPaid -inStorage $totalPaidStorage
Add-TenantTotals -Status 'Trial' -inCount $trialCount -inUsage $totalTrial -inStorage $totalTrialStorage

Write-Output -InputObject ($tenantReport)
