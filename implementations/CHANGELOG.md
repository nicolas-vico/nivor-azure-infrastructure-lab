# Changelog

## Phase 1 - Identity & Governance

**Completed**

- Microsoft Entra ID tenant configured
- Users created
- Security groups created
- Azure RBAC implemented
- Resource Group created
- Budget configured
- Azure Policy configured
- Resource tags applied
- Azure Resource Graph used for resource discovery and validation
- Azure Advisor reviewed

---

## Phase 2 - Azure Storage

**Completed**

- Three StorageV2 accounts deployed for separate workloads
- Azure Blob Storage configured for web assets
- Private blob container created
- Microsoft Entra ID authentication used for storage access
- Storage Blob Data Contributor assigned using Azure RBAC
- Azure Files file share created for corporate files
- Corporate directory structure created
- File share access controlled using security groups and Azure RBAC
- Dedicated storage account created for backups
- Private backup container created
- Blob soft delete enabled
- Blob versioning enabled
- Storage access tiers configured
- Lifecycle management policy implemented
- Backup blobs automatically moved to Archive tier after 180 days
- Backup blobs automatically deleted after 730 days
- Secure transfer required
- TLS 1.2 enforced
- Storage account key access disabled where appropriate
- Microsoft Entra authorization configured as the default portal authentication method
