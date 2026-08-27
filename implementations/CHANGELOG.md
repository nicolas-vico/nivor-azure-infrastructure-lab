# Implementation log

This is the short chronological record of the Nivor Systems lab. The module pages contain the design decisions, evidence and limitations.

## 01 — Identity & Governance · Complete

- Created Microsoft Entra security groups for role-based access.
- Assigned Azure RBAC roles and compared Contributor, Reader and Owner.
- Added a subscription budget and alert thresholds.
- Applied a tag-enforcement Policy and validated compliance.
- Used Azure Resource Graph to inspect resources and tags.

## 02 — Azure Storage · Complete

- Separated web assets, shared files and backups across StorageV2 accounts.
- Created private Blob containers and an Azure Files share.
- Assigned data-plane access through Microsoft Entra groups and Azure RBAC.
- Configured secure transfer, TLS, soft delete and blob versioning.
- Added a lifecycle rule to move older backup data to Archive and later delete it.

## 03 — Azure Compute · Complete

- Deployed a private Linux VM in Switzerland North without a public IP.
- Attached OS and data managed disks.
- Created an incremental OS snapshot before a simulated maintenance task.
- Created a recovery disk from the snapshot and documented the recovery sequence.
- Evaluated availability options and VM Scale Sets without claiming a VMSS deployment.

## 04 — Bicep & Infrastructure as Code · Complete

- Declared a virtual network and child subnet in Bicep.
- Used parameters, variables, parent relationships and outputs.
- Investigated an initial Policy denial and added the required tags.
- Repeated the deployment to check declarative, idempotent behaviour.

## 05 — Azure App Service · Complete

- Deployed a Linux App Service and enabled its system-assigned managed identity.
- Created production and staging slots and tested a slot swap.
- Reviewed scale-up and scale-out choices while keeping the lab at one instance.
- Scoped a Policy exception to the lab resource group after it blocked slot creation.

## 06 — Azure Containers · Complete

- Ran NGINX in Azure Container Instances and validated its public HTTP response.
- Deployed the same workload to Azure Container Apps.
- Configured external ingress, a revision and an HTTP autoscaling rule.
- Compared container health inside Azure with reachability from outside the platform.

## 07 — Azure Networking · Complete

- Built hub and production VNets with separate management, shared, web and data subnets.
- Configured VNet peering and tier-specific NSGs.
- Added a private DNS zone and linked both VNets.
- Configured a Standard Load Balancer without compute backends and documented that test boundary.

## 08 — Monitoring & Recovery · Complete; write-up in progress

- Completed the planned AZ-104 monitoring and recovery practice.
- The resource inventory, validation evidence and lessons are being organised in the module page.
- No undocumented configuration is described as evidence until that write-up is finished.
