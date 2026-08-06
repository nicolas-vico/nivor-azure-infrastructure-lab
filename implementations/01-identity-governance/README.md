# Identity and Governance

## Business Scenario

Nivor Systems required an initial Azure identity and governance foundation before deploying production workloads.

The environment needed centralized identity management, role-based access control, cost visibility and governance controls designed around the principle of least privilege.

## Implemented Components

- Microsoft Entra ID users
- Microsoft Entra ID security groups
- Azure RBAC assignments
- Azure subscription budget and alerts
- Azure Resource Group
- Resource tags
- Azure Policy assignment

## Identity Design

| Security group | Assigned role | Scope | Purpose |
|---|---|---|---|
| Azure-Admins | Contributor | Subscription | Manage Azure resources without managing access |
| IT-Support | Reader | Subscription | Inspect resources and assist with troubleshooting without making changes |

Permissions were assigned to security groups rather than directly to individual users.

## Governance

The following governance controls were implemented:

- Monthly Azure budget with actual and forecasted alerts
- Resource classification through tags
- Azure Policy to require the `Environment` tag
- Centralized production Resource Group in Switzerland North

## Technical Decisions

### Contributor instead of Owner

The `Azure-Admins` group received the Contributor role because administrators need to manage resources but should not automatically be able to modify RBAC assignments.

### Group-based access

RBAC roles were assigned to Microsoft Entra security groups. New administrators or support staff can therefore receive the correct permissions by changing group membership.

### Subscription-level scope

The current assignments were applied at subscription level because the laboratory contains a single controlled Azure environment. A production implementation with multiple teams and workloads would normally use narrower scopes where possible.

## Security Considerations

- Principle of least privilege
- No direct RBAC assignments to normal users
- No unnecessary Global Administrator assignments
- Periodic review of elevated access
- Separation between identity roles and Azure resource roles

## Cost

The identity and governance configuration currently has no meaningful direct Azure consumption cost.

A monthly budget of CHF 30 was configured for the Pay-As-You-Go laboratory subscription. Budget alerts notify administrators but do not stop or delete resources.

## Validation

- Confirmed `Azure-Admins` inherits Contributor permissions through group membership
- Confirmed `IT-Support` has Reader access
- Confirmed role assignments use the subscription scope
- Confirmed Azure Policy assignment exists
- Confirmed budget alert thresholds and recipient email

## Lessons Learned

- Microsoft Entra roles and Azure RBAC roles control different administrative planes.
- RBAC permissions are inherited down the Azure resource hierarchy.
- Multiple RBAC assignments are cumulative unless a deny assignment applies.
- Azure Budget provides notifications, not a hard spending limit.
- Azure Policy governs resource configuration, while RBAC governs authorization.

## If This Were Production

- Use Privileged Identity Management for eligible and time-limited administrative access
- Require MFA and Conditional Access for privileged identities
- Reduce RBAC scope to individual Resource Groups or resources when appropriate
- Implement access reviews
- Use naming and tagging standards enforced through Azure Policy
- Maintain emergency access accounts
