# Azure Storage Architecture

## Overview

Nivor Systems required a storage architecture capable of supporting different enterprise workloads while maintaining security, availability, cost efficiency and clear separation of responsibilities.

Instead of using a single Storage Account for every workload, the storage environment was separated into three accounts based on their access patterns, availability requirements and security needs.

The implementation includes:

- Web application assets using Azure Blob Storage
- Corporate shared files using Azure Files
- Long-term backup storage using Azure Blob Storage
- Microsoft Entra ID authentication
- Azure RBAC for data-plane authorization
- User Delegation SAS for temporary access
- Lifecycle Management policies
- Storage redundancy strategies
- Soft delete and versioning
- Encryption at rest and in transit
- Resource tagging and governance

---

# Architecture

```text
rg-production
│
├── stnivweb01
│   └── Blob Storage
│       └── web-assets
│           ├── Private container
│           ├── Web-Designers RBAC
│           ├── User Delegation SAS
│           └── Lifecycle Management
│
├── stnivfiles01
│   └── Azure Files
│       └── company-share
│           ├── projects/
│           ├── shared/
│           └── templates/
│
└── stnivbackup01
    └── Blob Storage
        └── general-backups
            ├── Private container
            ├── Soft delete
            ├── Versioning
            ├── Immutability support
            └── Lifecycle Management
```

Each Storage Account was designed independently according to the requirements of its workload.

---

# Storage Account Design

| Storage Account | Service | Redundancy | Access Tier | Purpose |
|---|---|---|---|---|
| `stnivweb01` | Azure Blob Storage | LRS | Hot | Web application assets |
| `stnivfiles01` | Azure Files | ZRS | Transaction Optimized | Corporate shared files |
| `stnivbackup01` | Azure Blob Storage | GRS | Cold | Long-term backups |

This separation allows each workload to use its own redundancy, security, lifecycle and access configuration.

---

# 1. Web Application Storage

## Business Requirement

Nivor Systems requires storage for web application assets such as images, documents and static content.

These objects are accessed frequently and can be recreated or redeployed if necessary.

The main requirements were:

- Low storage cost
- Fast access
- Private data by default
- Controlled developer access
- Temporary external access when required
- Automatic lifecycle management

## Implementation

Storage Account:

`stnivweb01`

Configuration:

- Azure Blob Storage
- Standard performance
- Locally Redundant Storage (LRS)
- Hot access tier
- Switzerland North region
- Secure transfer required
- Minimum TLS 1.2
- Anonymous Blob access disabled
- Storage Account Key access disabled
- Microsoft Entra authorization preferred

A private Blob container was created:

`web-assets`

---

## Web Storage RBAC

A Microsoft Entra security group was created:

`Web-Designers`

The group received:

`Storage Blob Data Contributor`

The role was scoped specifically to:

`web-assets`

rather than the complete Storage Account.

This ensures that members can manage the required Blob data without automatically receiving access to future containers.

```text
Web-Designers
      │
      │ Storage Blob Data Contributor
      ▼
web-assets
      │
      ├── Read
      ├── Write
      └── Delete
```

This implementation follows the principle of least privilege.

---

# Management Plane vs Data Plane

During implementation, an important Azure authorization distinction was validated.

Having the `Contributor` role over a Storage Account allows an administrator to manage the Azure resource but does not automatically provide access to the data stored inside it.

```text
Management Plane
Contributor
     │
     ├── Configure Storage Account
     ├── Configure networking
     ├── Manage resource settings
     └── Deploy resources

Data Plane
Storage Blob Data Contributor
     │
     ├── Read blobs
     ├── Upload blobs
     ├── Modify blobs
     └── Delete blobs
```

This behavior was validated when access to Blob data was initially denied despite having administrative permissions over the Azure resource.

A dedicated Blob data role was required before the objects could be accessed.

---

# Temporary Blob Access

The `web-assets` container remained private.

To provide temporary access to an individual Blob without exposing the entire container, a User Delegation SAS was generated.

The SAS was configured with:

- Read-only permission
- HTTPS-only access
- Short expiration period
- Microsoft Entra ID authorization

Storage Account Key access remained disabled.

```text
Microsoft Entra ID
        │
        ▼
User Delegation Key
        │
        ▼
Temporary SAS
        │
        ▼
Private Blob
```

Testing confirmed:

- Direct anonymous Blob URL → Access denied
- SAS URL → Access granted
- Container remained private

This avoids distributing Storage Account Keys and provides temporary, scoped access to individual objects.

---

# Web Asset Lifecycle Management

A Lifecycle Management policy was configured for:

`web-assets/`

The policy automatically changes storage tiers according to the age of the Blob.

```text
HOT
 │
 │ 30 days
 ▼
COOL
 │
 │ 90 days
 ▼
COLD
 │
 │ 365 days
 ▼
DELETE
```

The policy applies only to base Block Blobs under the `web-assets/` prefix.

This prevents the rule from affecting future containers within the same Storage Account.

The lifecycle strategy reduces long-term storage costs while maintaining fast access to recently modified content.

---

# 2. Corporate File Storage

## Business Requirement

Nivor Systems requires centralized shared file storage for internal company documents.

Unlike web assets, these files must behave similarly to a traditional enterprise file server.

Azure Files was selected because it provides managed file shares accessible using protocols such as SMB.

---

## Implementation

Storage Account:

`stnivfiles01`

Configuration:

- Azure Files
- Standard HDD storage
- Pay-as-you-go file shares
- Zone-Redundant Storage (ZRS)
- Switzerland North region
- Secure transfer required
- SMB encryption in transit enabled
- Minimum TLS 1.2
- Anonymous access disabled
- Storage Account Key access normally disabled
- Microsoft Entra authorization preferred
- Soft delete enabled for file shares

File Share:

`company-share`

Directory structure:

```text
company-share/
├── projects/
├── shared/
└── templates/
```

---

# Azure Files Redundancy

ZRS was selected for the corporate file workload.

ZRS replicates data synchronously across multiple availability zones within the Azure region.

This provides greater resilience than LRS against a datacenter or availability-zone failure while keeping the workload within the same region.

The design intentionally separates infrastructure resilience from backup and recovery mechanisms.

```text
ZRS
│
├── Zone 1
├── Zone 2
└── Zone 3
```

A deletion performed by an authorized user can still be replicated across the redundant copies.

For this reason, redundancy is not considered a replacement for backup or soft-delete capabilities.

---

# Azure Files Authorization

A Microsoft Entra security group was created:

`Access-to-shared-files`

Azure Files introduced an additional authorization challenge during the implementation.

Access through Azure Files can involve different authentication and authorization mechanisms depending on whether the data is accessed through SMB, REST APIs or the Azure Portal.

The following roles were evaluated during testing:

- Storage File Data SMB Share Contributor
- Storage File Data Privileged Contributor

The laboratory demonstrated that Azure resource permissions and Azure Files data permissions are separate authorization layers.

Identity-based SMB authentication can additionally require configuration of a supported directory service such as:

- Active Directory Domain Services
- Microsoft Entra Domain Services
- Microsoft Entra Kerberos

Because deploying a complete directory authentication architecture was outside the scope of this storage laboratory, Storage Account Key access was temporarily enabled to validate the File Share and create the test directory structure.

After validation, Shared Key access was disabled again.

This troubleshooting process provided practical experience with the distinction between Azure resource management permissions, data-plane permissions and SMB authentication.

---

# 3. Backup Storage

## Business Requirement

Nivor Systems requires durable storage for production backups.

The workload has different characteristics from the web and corporate file workloads:

- Backups are rarely accessed
- Recent backups must remain immediately available
- Historical backups can tolerate slower recovery
- Data must survive regional infrastructure failures
- Accidental deletion must be recoverable
- Long-term storage costs should be minimized

---

# Implementation

Storage Account:

`stnivbackup01`

Configuration:

- Azure Blob Storage
- Standard performance
- Geo-Redundant Storage (GRS)
- Cold default access tier
- Switzerland North primary region
- Secure transfer required
- Minimum TLS 1.2
- Anonymous access disabled
- Storage Account Key access disabled
- Microsoft Entra authorization preferred
- Microsoft-managed encryption keys

Container:

`general-backups`

Access level:

`Private`

Backup administrators require an explicit Blob data-plane role to access the contents.

For laboratory administration:

`Storage Blob Data Contributor`

was assigned at the `general-backups` container scope.

---

# Backup Redundancy

GRS was selected because backups have higher durability requirements than web assets.

GRS maintains copies in the primary Azure region and asynchronously replicates data to a secondary geographic region.

This protects against large-scale regional infrastructure failure.

However:

> Redundancy is not backup.

If data is intentionally deleted or modified, those operations can also affect replicated copies.

For this reason, GRS was combined with additional data-protection mechanisms.

---

# Backup Data Protection

The following protections were configured:

### Blob Soft Delete

Retention:

`30 days`

Deleted blobs remain recoverable during the retention period.

### Container Soft Delete

Retention:

`30 days`

Deleted containers can be recovered during the configured retention period.

### Blob Versioning

Enabled.

Previous versions of modified blobs are preserved, allowing earlier data states to be recovered.

### Version-Level Immutability Support

Enabled.

This prepares the Storage Account for WORM-style retention policies where Blob versions can be protected against modification or deletion for a defined period.

---

# Backup Lifecycle Management

Backups initially use the Cold tier because they are rarely accessed but must remain immediately retrievable.

A lifecycle rule was created for:

`general-backups/`

```text
COLD
 │
 │ 180 days
 ▼
ARCHIVE
 │
 │ 730 days
 ▼
DELETE
```

The policy applies only to base Block Blobs under the `general-backups/` prefix.

Recent backups therefore remain online in the Cold tier.

Historical backups are moved to Archive to reduce storage costs.

After two years, expired backups are automatically deleted.

---

# Archive and Rehydration

Archive storage is an offline tier.

Archived Blobs cannot be accessed immediately.

Before accessing archived data, the Blob must be rehydrated to an online tier such as Hot or Cool.

```text
ARCHIVE
    │
    │ Rehydrate
    ▼
HOT / COOL
    │
    ▼
Data available
```

Rehydration can take hours and generates additional retrieval costs.

For this reason, Archive is appropriate for historical backups but unsuitable for workloads requiring immediate recovery.

The lifecycle policy also prevents recently rehydrated Blobs from immediately returning to Archive.

---

# Security Design

The storage architecture follows several security principles.

## Private by Default

Blob containers were configured without anonymous access.

## Microsoft Entra ID

Microsoft Entra ID and Azure RBAC are preferred over Storage Account Keys wherever possible.

## Shared Key Restrictions

Storage Account Key access was disabled on Blob workloads.

It was temporarily enabled during Azure Files troubleshooting and disabled again after validation.

## Least Privilege

Data roles were scoped to individual containers or file shares where practical instead of granting access across entire Storage Accounts.

## Encryption in Transit

Secure transfer is required and TLS 1.2 is enforced.

SMB encryption in transit was enabled for Azure Files.

## Encryption at Rest

Azure Storage encryption using Microsoft-managed keys protects stored data.

Customer-managed keys were evaluated but not implemented because the laboratory does not have a compliance requirement requiring independent key ownership.

---

# Encryption Design

Microsoft-managed keys were selected for the current implementation.

Azure therefore handles the encryption key lifecycle automatically.

Customer-managed keys would be considered if Nivor Systems required:

- Independent control over encryption keys
- Custom key rotation policies
- Regulatory or compliance requirements
- Integration with Azure Key Vault or Managed HSM

Customer-managed keys provide additional control but also introduce operational responsibility.

Loss or deletion of a required encryption key could make encrypted data inaccessible.

For a production CMK implementation, Key Vault protections such as soft delete and purge protection would therefore be critical.

---

# Resource Tagging

All Storage Accounts follow a consistent tagging model.

| Tag | Example |
|---|---|
| Company | Nivor Systems |
| CostCenter | IT |
| Environment | Production |
| Owner | Nico |
| Workload | Web / CorporateFiles / Backup |

Using consistent tag keys allows resources to be filtered, governed and analyzed across the environment.

Different values for `Workload` identify the purpose of each Storage Account without changing the organization's tagging standard.

---

# Resource Protection

The production Resource Group is protected using a `CanNotDelete` resource lock.

Because the lock is inherited by resources below the Resource Group, it prevented administrative operations that required deletion during the laboratory.

The lock had to be deliberately removed, the required administrative change performed, and the lock recreated afterward.

This demonstrated that resource locks operate independently from Azure RBAC permissions.

Even highly privileged users cannot simply bypass an inherited delete lock.

---

# Cost Considerations

The environment was designed to minimize laboratory costs.

Measures include:

- Standard storage instead of Premium where high performance is unnecessary
- LRS for replaceable web assets
- ZRS only where zone resilience provides business value
- GRS only for critical backup data
- Cold storage for rarely accessed backups
- Archive for long-term retention
- Lifecycle policies for automatic tier transitions
- Small laboratory files only
- Defender for Storage not enabled
- Private Endpoints deferred until the networking implementation
- Pay-as-you-go Azure Files instead of provisioned performance

A monthly Azure budget and cost alerts configured in the governance implementation remain active.

Budget alerts provide notifications but do not automatically stop Azure resources.

---

# Validation

The implementation was validated through practical tests.

### Blob Storage

- Confirmed `web-assets` container is private
- Confirmed anonymous Blob URL access is denied
- Confirmed RBAC-based Blob access
- Confirmed `Web-Designers` receives Blob permissions through group membership
- Confirmed RBAC scope is limited to `web-assets`
- Generated and tested a User Delegation SAS
- Confirmed SAS access works without enabling Shared Key
- Configured and validated Lifecycle Management policy

### Azure Files

- Created `company-share`
- Configured ZRS
- Enabled File Share soft delete
- Tested Azure Files data-plane authorization
- Investigated SMB and Microsoft Entra authentication requirements
- Created corporate directory structure
- Returned Shared Key configuration to the hardened state after testing

### Backup Storage

- Created private `general-backups` container
- Uploaded test backup data
- Configured GRS
- Configured 30-day Blob and container soft delete
- Enabled Blob versioning
- Enabled version-level immutability support
- Configured Cold → Archive → Delete lifecycle policy
- Validated RBAC access at container scope

---

# Troubleshooting Experience

Several real administrative issues were encountered during the implementation.

## Contributor Could Not Access Blob Data

**Problem**

The Azure resource could be administered, but Blob data could not be listed.

**Cause**

Azure `Contributor` grants management-plane permissions but does not automatically grant Blob data-plane access.

**Resolution**

Assigned `Storage Blob Data Contributor` at the appropriate container scope.

---

## SAS Generation with Shared Key Disabled

**Problem**

A traditional SAS operation requiring the Storage Account Key could not be used because Shared Key authorization was disabled.

**Resolution**

Generated a User Delegation SAS using Microsoft Entra ID.

This preserved the security decision to keep Storage Account Keys disabled.

---

## Azure Files Access Through Microsoft Entra ID

**Problem**

Azure Files data could not initially be managed through the expected identity-based path despite Azure resource permissions.

**Investigation**

RBAC roles, File Share scope and Azure Files identity-based authentication requirements were reviewed.

**Resolution**

The difference between SMB identity authentication, data-plane RBAC and Azure Portal access was identified.

Shared Key access was temporarily enabled to validate the laboratory File Share without deploying additional directory infrastructure.

---

## Resource Lock Blocking Administrative Changes

**Problem**

An administrative change could not be completed despite privileged RBAC permissions.

**Cause**

The Storage Account inherited a `CanNotDelete` lock from `rg-production`.

**Resolution**

The lock was deliberately removed, the administrative change completed and the lock recreated.

---

# Lessons Learned

This implementation reinforced several important Azure administration concepts:

1. Azure RBAC management roles and Storage data roles control different authorization planes.

2. `Contributor` does not automatically provide access to Blob or File data.

3. RBAC scope should be as narrow as practical.

4. Microsoft Entra groups simplify permission management compared with direct user assignments.

5. Storage Account Keys provide powerful access and should be avoided where identity-based authorization is available.

6. User Delegation SAS provides temporary Blob access without requiring Shared Key authorization.

7. Public network accessibility does not mean anonymous data access.

8. LRS, ZRS and GRS solve infrastructure availability problems, not accidental data deletion.

9. Soft delete and versioning provide recovery capabilities that redundancy alone does not provide.

10. Archive storage reduces long-term costs but introduces recovery delay and retrieval costs.

11. Lifecycle Management can automatically optimize storage costs based on data age.

12. Resource locks operate independently from RBAC and can block privileged administrators from deleting protected resources.

13. Azure Files authentication is more complex than simply assigning an RBAC role because SMB identity authentication can require additional directory configuration.

14. Customer-managed encryption keys provide greater control but also increase operational responsibility.

15. Security features should be enabled according to actual requirements rather than enabling every available option without understanding its operational impact.

---

# If This Were Production

A production implementation would extend this design with:

- Private Endpoints for internal Storage Accounts
- Public network access disabled where possible
- Azure Private DNS integration
- Microsoft Entra Kerberos or Active Directory integration for Azure Files
- Conditional Access and MFA for privileged identities
- Privileged Identity Management
- Dedicated backup operator groups
- Formal immutable backup retention policies
- Azure Key Vault integration where CMK is required
- Key Vault soft delete and purge protection
- Azure Monitor alerts
- Diagnostic settings and centralized logging
- Storage access logging
- More restrictive network firewall rules
- Formal recovery testing
- Defined RPO and RTO requirements
- Infrastructure as Code deployment using Bicep

---

# Skills Demonstrated

This implementation demonstrates practical experience with:

- Azure Storage Accounts
- Azure Blob Storage
- Azure Files
- Storage redundancy
- LRS
- ZRS
- GRS
- Azure RBAC
- Microsoft Entra ID
- Management plane vs data plane authorization
- Azure Storage data roles
- User Delegation SAS
- Storage Account Keys
- Azure Lifecycle Management
- Hot, Cool, Cold and Archive tiers
- Blob soft delete
- Container soft delete
- Blob versioning
- Blob immutability
- Azure Files SMB concepts
- Storage encryption
- Azure resource locks
- Azure resource tagging
- Cost-aware Azure architecture

---

## Status

**Implementation completed.**

The storage foundation is ready to integrate with future Nivor Systems compute, networking, monitoring and backup workloads.
