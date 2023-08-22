# Example of a Basic COS deployment w/ KP & AT

This example creates the following infrastructure:
- A new resource group, if one is not passed in.
- A Sysdig and Activity Tracker instances in a resource group and region.
- A new Key Protect instance (with metrics enabled), Key Ring, and Key in a resource group and region.
- A new Cloud Object Storage instance in a resource group and region.
- An IAM Access Policy to allow Key Protect to access COS instance.
- COS bucket-1 with:
  - Encryption
  - Monitoring
  - Activity Tracking
