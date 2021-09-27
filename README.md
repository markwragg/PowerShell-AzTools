# PowerShell-AzTools
A set of tools wrapped around various Az module commands that make them more useful.

## Tools

| Module         | Cmdlet                               | Description                                                                                                                                                  |
| -------------- | ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Azure          | Get-APIManagementExpiringCertificate | Retrieves the SSL certificates assigned to each of the API Management resources across all subscriptions.                                                    |
| Azure          | Get-AppGatewayExpiringCertificate    | Retrieves the SSL certificates assigned to each of the App Gateways across all subscriptions.                                                                |
| Azure          | Get-AppInsightsUsage                 | Returns the retention, cap and usage information for one or more AppInsights accounts.                                                                       |
| Azure          | Get-AppServiceCertificate            | Retrieves the App Service Certificates for the current subscription.                                                                                         |
| Azure          | Get-NSGIPWhitelist                   | Script to retrieve the IP Whitelists on the NSGs.                                                                                                            |
| Azure          | Get-VNETAddressSpace                 | Retrieve VNET address space details.                                                                                                                         |
| Storage        | Add-StorageVNETAccess                | Use to add a VNET and all of its subnets to the list of permitted networks for a specified Storage Account.                                                  |
| Storage        | Compare-StorageBlobs                 | Compares Blobs from one path to another within the same storage container to show those that contain matching file names.                                    |
| Storage        | Get-StorageBlobs                     | Retrieves all Blobs a specified storage container and returns their name, length and last modified date.                                                     |
| Storage        | Move-StorageBlobs                    | Moves Blobs from one path to another within the same storage container and/or removes blobs from the source path that already exist in the destination path. |
| VirtualMachine | Get-DiskEncryptionStatus             | Retrieve disk encryption status for all disks.                                                                                                               |
| VirtualMachine | Get-OldDiskSnapshot                  | Retrieve disk snapshots older than the specified number of days.                                                                                             |
| VirtualMachine | Get-VMBackupStatus                   | Retrieve VM backup status for all VMs.                                                                                                                       |
| VirtualMachine | Get-VmCertificateExists              | Script to check if a certificate exists on one or more VMs via PS Remoting.                                                                                  |
| VirtualMachine | Get-VMDiskEncryptionStatus           | Retrieve disk encryption status for all VMs.                                                                                                                 |
| VirtualMachine | Get-VmIP                             | Returns the private IP addresses for all VMs in the current subscription.                                                                                    |
| VirtualMachine | New-VMDiskSnapshot                   | Creates disk snapshots for each disk of each VM or for a specified VM or VM/s (by partial name match).                                                       |
| VirtualMachine | Remove-OldDiskSnapshot               | Removes disk snapshots older than the specified number of days (45 by default).                                                                              |



