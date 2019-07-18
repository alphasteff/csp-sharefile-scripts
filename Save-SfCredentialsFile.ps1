<#
    .SYNOPSIS
    Creates a ShareFile credentials file using the New-SfClient command

    .DESCRIPTION
    This script creates a ShareFile creentials file, using the New-SfClient command
    from the ShareFile PowerShell SDK. The created file can then be used with the
    other csp-sharefile-scripts, such as Get-CspShareFileReport.ps1.

    By default it will write the credentials file to sfcreds.sfps, in the users home
    directory (e.g. C:\Users\Stuart\sfcreds.sfps

    It accepts one parameter to specify a different output file:
      -File c:\tmp\different_file_name.sfps

    .EXAMPLE
    Save-SfCreentialsFile <-File c:\tmp\different_file_name.sfps>

    .NOTES
    This script required the Citrix ShareFile PowerShell SDK to be installed.
    
    ** USE AT OWN RISK - NO WARANTY PROVIDED **

    Author. Stuart Parkington, Lead SE, CSP EMEA

    .LINK
    https://link-to-github-docs-page
    The first link is opened by Get-Help -Online Save-SFCredentials

    .INPUTS
    None

    .OUTPUTS
    ShareFile credentials file, by default at %HOMEDRIVE%%HOMEPATH%%, unless specified via
    command line variable -File
#>


[CmdletBinding()]
param (
  [string]$File = ('{0}{1}\sfcreds.sfps' -f $env:HOMEDRIVE, $env:HOMEPATH)

)

if ( Get-PSSnapin -Registered | Select-String -Pattern ShareFile) {
  Write-Verbose -Message 'ShareFile Snapin registered.'
} else {
  Write-Verbose -Message 'ShareFile Snapin not registered. Aborting!' -Verbose
  exit
}

# Ensure the ShareFile PowerShell Snap-in is loaded
if ( (Get-PSSnapin -Name ShareFile -ErrorAction SilentlyContinue) -eq $null )
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
  Write-Verbose -Message ('ShareFile credentials file {0} already exists' -f $File) -Verbose 
} else {
  Try {
    $null = New-SfClient -Name $File
  } catch { 
    Write-Verbose -Message ('Error creating ShareFile credentials file {0}.' -f $File) -Verbose
    exit
  }
  Write-Verbose -Message ('ShareFile credentials file {0} sucessfully saved.' -f $File) -Verbose
}
