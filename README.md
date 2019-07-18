# CSP ShareFile Scripts
These scripts have been written to assist Citrix Service Providers utilise the ShareFile API to query usage and status. The scripts marked **(RO)** are read-only and make no amendments, simply making GET requests for data.

**Use at your own risk** as these are not Citrix supported scripts. They have been written by myself as a proof-of-concept.

The scripts require the Citrix ShareFile PowerShell SDK to be installed prior to use. The SDK can be downloaded from [GitHub](https://github.com/citrix/ShareFile-PowerShell) here.

### Scripts
1. [Save-SfCredentialsFile.ps1](docs/Save-SfCredentialsFile.md) - Create a ShareFile Credentials file, using an interactive logon.
2. [Get-CspShareFileReport.ps1](docs/Get-CspShareFileReport.md) - Get the current status of tenant license and storage usage.

### Resources
The following resources may also be of use:
- [Getting started with the ShareFile PowerShell SDK (Citrix Blog)](https://www.citrix.com/blogs/2014/05/16/getting-started-with-the-powershell-sdk/)
- [Creating Basic Scripts with the ShareFile PowerShell SDK (Citrix Blog)](https://www.citrix.com/blogs/2014/05/16/creating-basic-scripts-with-the-sharefile-powershell-sdk/)
