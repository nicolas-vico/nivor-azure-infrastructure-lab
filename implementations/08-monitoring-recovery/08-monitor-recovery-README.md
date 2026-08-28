# 08 - Monitor & Recovery

This implementation covers the monitoring and recovery components of the Nivor Systems Azure environment. The objective was to work with real Azure telemetry, validate monitoring data with KQL, and complete an end-to-end backup and restore workflow using Azure Backup.

The lab was designed to remain cost-conscious while still demonstrating practical administration skills relevant to the Microsoft AZ-104 exam.

---

## Objectives

- Configure and validate Azure monitoring data.
- Work with Azure Monitor, Log Analytics and KQL.
- Understand diagnostic settings and ingestion behaviour.
- Configure Azure Backup using a Recovery Services vault.
- Protect a Trusted Launch Linux virtual machine.
- Create a real recovery point.
- Perform and validate a full VM restore.
- Document operational issues instead of hiding unsuccessful steps.
- Clean up temporary resources after validation.

---

## Monitoring

### Azure Monitor and Log Analytics

Monitoring was implemented using Azure Monitor and a Log Analytics workspace.

The lab included:

- Diagnostic settings.
- Log Analytics queries.
- Azure Activity Log integration.
- KQL validation.
- Review of resource metrics and operational telemetry.

A key distinction reinforced during the lab was that the Azure Activity Log existing at subscription level does not automatically mean that the `AzureActivity` table will contain data inside a Log Analytics workspace.

To query subscription activity through Log Analytics, the Activity Log must first be exported to the workspace through a subscription-level diagnostic setting.

Example validation query:

```kusto
AzureActivity
| sort by TimeGenerated desc
```

Diagnostic settings can require time before data becomes available in the workspace. An empty query immediately after configuration does not necessarily indicate that the configuration is incorrect.

---

## Monitoring Issue Encountered

While validating Storage Account telemetry, Azure Monitor Metrics Explorer was used to try to display transaction metrics.

The chart remained loading and did not successfully display the expected data during the lab.

Rather than hiding the failed validation or repeatedly changing the environment without understanding the cause, the monitoring workflow continued through Log Analytics and KQL.

This was kept as part of the implementation because real infrastructure work often includes incomplete telemetry, ingestion delays, portal behaviour and troubleshooting rather than perfectly successful demonstrations.

The incident also reinforced an important operational lesson:

> A monitoring configuration should be validated through more than one interface whenever possible.

---

## Azure Backup and Recovery

A separate temporary resource group was used for the recovery lab:

```text
rg-monitor-recovery-lab
```

### Recovery Services Vault

Recovery Services vault:

```text
rsv-niv-backup-01
```

Configuration:

- Region: Switzerland North
- Backup storage redundancy: LRS
- Immutability: Disabled
- Public network access: Enabled for the lab

LRS was intentionally selected because this was a disposable training environment. A production design would choose redundancy based on recovery, durability and regional resilience requirements.

Immutability was intentionally left disabled to avoid unnecessary cleanup complications in a temporary lab environment.

---

## Protected Virtual Machine

Temporary VM:

```text
vm-niv-backup-test-01
```

Configuration included:

- Ubuntu Server 24.04 LTS Gen2
- Trusted Launch
- Standard_D2s_v3
- Standard HDD OS disk
- No public IP
- Existing production VNet:
  - `vnet-niv-prod-swn-01`
  - `snet-servers-01`

The VM was intentionally temporary because the selected compute size was relatively expensive for a lab environment.

---

## Backup Policy

The first attempt used a Standard backup policy.

Azure returned a validation error indicating that the Standard policy was not supported for the Trusted Launch virtual machine used in the lab.

The configuration was therefore changed to an Enhanced policy:

```text
bp-niv-lab-enhanced
```

This provided a useful practical example of adapting the backup design to the capabilities and requirements of the protected workload.

---

## Backup Validation

After backup protection was configured:

1. Backup pre-check completed successfully.
2. An on-demand backup was triggered with **Backup now**.
3. Azure created a valid recovery point.
4. The backup job completed successfully.

The resulting recovery point was:

- Consistency: File-system consistent
- Recovery type: Snapshot and Vault-Standard

This demonstrates an important distinction:

Azure Backup is not simply equivalent to keeping a standalone managed disk snapshot. The recovery workflow is managed by Azure Backup and the Recovery Services vault, with recovery points governed by the selected backup policy.

---

## Restore Validation

A restore was performed from the newly created recovery point.

The restore job completed successfully and produced a second virtual machine:

```text
vm-niv-backup-restored-01
```

Both the original and restored virtual machines were then visible simultaneously in Azure.

This completed the full validation path:

```text
VM
  ↓
Backup Policy
  ↓
Recovery Services Vault
  ↓
Backup
  ↓
Recovery Point
  ↓
Restore
  ↓
Recovered VM
```

The restore step was particularly important because a successful backup job alone does not prove that a workload can actually be recovered.

---

## Recovery Point Consistency

The created recovery point was reported as:

```text
File-system Consistent
```

The distinction between recovery point consistency types is important:

- **Crash-consistent** — represents disk state similar to an unexpected power loss.
- **File-system consistent** — ensures filesystem state has been flushed and captured consistently.
- **Application-consistent** — also coordinates supported applications so their internal state is captured consistently.

The recovery point generated in this lab was file-system consistent.

---

## Evidence

Suggested screenshot sequence for the backup and recovery section:

```text
01-...
02-backup-vm-protection-overview.png
03-backup-restore-jobs-completed.png
04-backup-protection-success.png
05-vm-recovery-point.png
06-original-and-restored-vms.png
```

The final screenshots demonstrate:

- VM backup protection.
- Successful backup configuration.
- Completed backup and restore jobs.
- Successful recovery point creation.
- Enhanced backup policy.
- File-system-consistent recovery point.
- Original and restored VMs running side by side.

Before publishing screenshots, sensitive identifiers such as Subscription IDs, Tenant IDs, Object IDs, SAS tokens, keys or secrets should be removed or redacted.

---

## Cost and Operational Decisions

Several decisions were made specifically to keep the lab controlled and realistic:

- LRS was used for the temporary Recovery Services vault.
- Immutability was disabled because the vault was disposable.
- The backup VM existed only for the duration of the test.
- No public IP was assigned.
- Existing network infrastructure was reused.
- Temporary compute and restore resources were removed immediately after validation.
- Backup data was deleted before removing the Recovery Services vault.

The lab also reinforced that stopping or deleting a VM does not automatically eliminate every possible Azure cost. Managed disks, recovery points, snapshots and backup storage must also be considered during cleanup.

---

## Cleanup

After the restore was validated and evidence captured:

1. Backup protection was stopped.
2. Backup data and recovery points were deleted.
3. The original VM was removed.
4. The restored VM was removed.
5. Associated temporary disks and NICs were removed.
6. Temporary backup resources were deleted.
7. The shared production VNet was preserved.

The shared network infrastructure was intentionally not deleted:

```text
vnet-niv-prod-swn-01
```

This was pre-existing infrastructure and was not part of the disposable recovery lab.

---

## Key Lessons

This implementation reinforced several AZ-104 concepts:

- Azure Monitor and Log Analytics are related but distinct components.
- Diagnostic settings determine where platform telemetry is exported.
- Log ingestion is not always immediate.
- The Azure Activity Log must be explicitly exported to Log Analytics if it is to be queried through `AzureActivity`.
- Backup policy controls protection behaviour and retention.
- Trusted Launch VM support can affect which backup policy type is valid.
- Recovery points can have different consistency levels.
- Azure Backup is broader than simply creating a managed disk snapshot.
- A backup should be validated through restore, not only through job success.
- Recovery Services vault dependencies must be removed before deleting the vault.
- Temporary infrastructure should be cleaned up deliberately to avoid unnecessary cost.
- Real infrastructure work includes troubleshooting incomplete or delayed telemetry rather than hiding it.

---

## Result

The Monitor & Recovery implementation successfully demonstrated both sides of operational administration:

**Monitoring**
- Azure Monitor
- Diagnostic settings
- Log Analytics
- KQL
- Activity Log integration
- Troubleshooting telemetry behaviour

**Recovery**
- Recovery Services vault
- Enhanced backup policy
- VM protection
- On-demand backup
- Recovery point validation
- Full VM restore
- Post-restore verification
- Controlled cleanup

This completes the practical Monitor & Recovery implementation for the Nivor Systems AZ-104 infrastructure project.
