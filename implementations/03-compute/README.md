# 03 – Azure Compute Infrastructure

## Overview

This implementation focuses on deploying and managing Azure Virtual Machine infrastructure for **Nivor Systems**.

The objective was to build a production-oriented Linux virtual machine environment while applying concepts related to networking, managed disks, security, resource governance, availability, backup and disaster recovery.

The lab also included a complete snapshot and disk recovery workflow to simulate a maintenance rollback scenario.

---

## Architecture

The compute environment was deployed in:

- **Region:** Switzerland North
- **Resource Group:** `rg-production`
- **Virtual Network:** `vnet-niv-prod-swn-01`
- **Server Subnet:** `snet-servers-01`
- **Operating System:** Linux
- **VM Generation:** Generation 2
- **Security:** Trusted Launch
- **Public IP:** None

The virtual machine was intentionally deployed without a public IP address to reduce unnecessary Internet exposure.

---

## Virtual Machine

A Linux virtual machine was deployed as the primary compute workload.

**VM name**

`server-nivor-1`

Configuration:

| Setting | Configuration |
|---|---|
| Region | Switzerland North |
| OS | Linux |
| VM generation | Gen 2 |
| Architecture | x64 |
| VM size | Standard D2s v3 |
| vCPU | 2 |
| RAM | 8 GiB |
| Security | Trusted Launch |
| Public IP | None |
| Network | `vnet-niv-prod-swn-01` |
| Subnet | `snet-servers-01` |

The VM used private networking and was integrated into the existing production virtual network.

---

## Managed Disks

The VM was configured with separate operating system and data disks.

### OS Disk

The operating system disk used:

- Premium SSD LRS
- 30 GiB
- Platform-managed encryption keys
- Read/write host caching

### Data Disk

A separate managed disk was attached for application or persistent workload data.

This separation allows the lifecycle and performance characteristics of operating system and application data to be managed independently.

---

## Snapshot Strategy

Before performing a simulated maintenance operation, an incremental snapshot of the operating system disk was created.

**Snapshot**

` snap-niv-server01-os-premaintenance-01 `

Configuration:

- Source: VM OS managed disk
- Snapshot type: Incremental
- Storage redundancy: Zone-redundant
- Size: 30 GiB
- Encryption: Platform-managed key
- Security type: Trusted Launch
- Network access: DenyAll

Incremental snapshots were selected because they store changes relative to previous snapshots instead of repeatedly storing the complete disk state.

This can reduce storage consumption when maintaining multiple recovery points.

---

## Recovery Disk

A new managed disk was successfully created from the snapshot to validate the recovery process.

**Recovery disk**

`disk-niv-server01-os-recovery-01`

Configuration:

- Source: `snap-niv-server01-os-premaintenance-01`
- Operating system: Linux
- VM generation: Gen 2
- Architecture: x64
- Size: 32 GiB
- Storage type: Standard HDD LRS
- Availability Zone: Zone 1
- Security: Trusted Launch

The recovery disk was intentionally created using a low-cost storage tier because it was only required to validate the recovery workflow.

In a real production recovery scenario, the disk tier would be selected according to workload performance requirements.

---

## Recovery Workflow

The following recovery procedure was tested:

1. Deploy the production virtual machine.
2. Configure OS and data managed disks.
3. Stop/deallocate the VM before the maintenance operation.
4. Create an incremental snapshot of the OS disk.
5. Configure restricted snapshot network access.
6. Create a new managed disk from the snapshot.
7. Validate the recovered disk configuration.
8. Remove temporary recovery resources after validation.

This demonstrates a basic rollback mechanism that could be used before risky maintenance operations.

---

## Availability and Resilience

Azure availability concepts were also evaluated during the implementation.

### Availability Zones

Availability Zones provide physical separation between datacenters within an Azure region.

For production workloads requiring higher availability, multiple VM instances can be distributed across zones so that the failure of one datacenter does not necessarily interrupt the complete service.

### Virtual Machine Scale Sets

A VM Scale Set configuration was explored with:

- Multiple Availability Zones
- Multiple VM instances
- Health monitoring
- Automatic instance repair
- Scaling capabilities
- Managed identities
- Microsoft Entra ID authentication

The VMSS was **not deployed**, avoiding unnecessary compute costs while still validating the architecture and configuration options through the Azure Portal.

---

## Application Health Monitoring

VM Scale Sets can monitor application health through an endpoint exposed by the workload.

A sample configuration was evaluated using:

- Protocol: HTTP
- Port: 80
- Path: `/`
- Health probe interval: 5 seconds
- Unhealthy threshold: 1

When combined with automatic instance repair, Azure can detect an unhealthy instance and replace it automatically.

This creates a self-healing infrastructure model for horizontally scaled workloads.

---

## Security Decisions

Several security principles were applied throughout the implementation.

### No Public IP

The production VM was deployed without a public IP address.

Administrative access should preferably be performed through controlled mechanisms such as Azure Bastion, VPN connectivity or private administrative networks.

### Trusted Launch

Trusted Launch was enabled to provide additional protection against low-level boot and firmware attacks.

### Encryption

Managed disks and snapshots used Azure platform-managed encryption keys.

### Restricted Snapshot Access

Snapshot network access was configured as:

`DenyAll`

This prevents direct network-based export/import operations unless explicitly enabled.

### Microsoft Entra ID

Microsoft Entra ID authentication was evaluated for VM Scale Set instances instead of relying exclusively on traditional local credentials.

---

## Resource Governance

The infrastructure followed the existing Nivor Systems tagging strategy.

Example tags:

| Tag | Value |
|---|---|
| Company | Nivor Systems |
| Environment | Production |
| CostCenter | IT |
| Owner | Nico |
| Workload | Compute |

Tags provide consistent metadata for governance, cost analysis and resource discovery.

---

## Resource Locks

A `CanNotDelete` resource lock was applied to the production resource group.

The protection was tested by attempting to delete compute resources while the lock was active.

Azure correctly blocked the deletion.

After validating the protection mechanism, the lock was intentionally removed and the temporary compute resources were deleted.

This demonstrated an important operational principle:

> RBAC controls **who can perform an operation**, while resource locks can protect resources against accidental modification or deletion even when the user has sufficient RBAC permissions.

---

## Cost Management

Because this environment runs under a Pay-As-You-Go subscription, cost control was considered throughout the implementation.

The following practices were used:

- VM deallocation when compute was not required.
- Temporary VMSS infrastructure was not deployed.
- Incremental snapshots were preferred.
- Low-cost storage was used for the temporary recovery disk.
- Temporary compute resources were deleted after completing the lab.
- Existing networking and storage infrastructure was reused.

After the lab, the VM, NIC, NSG, managed disks, snapshot and recovery disk were removed.

The existing production VNet and storage accounts were preserved for future infrastructure implementations.

---

## Key Concepts Demonstrated

This implementation demonstrates practical knowledge of:

- Azure Virtual Machines
- Managed Disks
- OS and Data Disk separation
- Disk performance tiers
- Incremental snapshots
- Disk recovery from snapshots
- Availability Zones
- Virtual Machine Scale Sets
- Application Health Monitoring
- Automatic Instance Repair
- Trusted Launch
- Microsoft Entra ID authentication
- Private VM networking
- Resource Locks
- Azure Tags
- Cost-conscious infrastructure management

---

## Screenshots

Evidence captured during the implementation includes:

```text
screenshots/
├── 01-rg-production-compute-resources.png
├── 02-vm-overview.png
├── 03-vm-managed-disks.png
├── 04-os-snapshot.png
├── 05-recovery-disk.png
└── 06-resource-lock-delete-test.png
```

These screenshots document the deployed architecture, storage configuration, snapshot recovery process and governance controls.

---

## Lessons Learned

This implementation reinforced several important Azure administration concepts.

A VM is not a single isolated Azure resource. Its operation depends on multiple components such as virtual networks, network interfaces, network security groups and managed disks.

Snapshots provide a useful recovery mechanism before maintenance operations, but they should not automatically be considered a complete backup strategy.

High availability also requires architectural planning. Availability Zones protect against datacenter-level failures, while VM Scale Sets add horizontal scaling, health monitoring and automatic instance replacement.

Finally, governance controls such as RBAC, tags and resource locks solve different problems and should be combined rather than treated as interchangeable security mechanisms.

---

## Cleanup

All temporary compute resources created for this implementation were deleted after validation to avoid unnecessary Pay-As-You-Go charges.

Persistent infrastructure retained for future labs:

- `vnet-niv-prod-swn-01`
- `stnivweb01`
- `stnivfiles01`
- `stnivbackup01`

This leaves the Azure environment clean while preserving the shared infrastructure required by future Nivor Systems implementations.
