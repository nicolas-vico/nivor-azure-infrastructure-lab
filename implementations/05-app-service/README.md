# 05 — Azure App Service

## Overview

This implementation demonstrates the deployment and configuration of an Azure App Service environment for Nivor Systems.

The lab focused on understanding the relationship between Web Apps and App Service Plans, application configuration, managed identities, deployment slots, slot-specific settings, deployment swaps, and scaling options.

All resources were deployed in **Switzerland North** and removed after validation to avoid unnecessary costs.

---

## Architecture

```text
Resource Group: rg-appservice-lab
│
└── App Service Plan
    ├── OS: Linux
    ├── SKU: Premium v3 P0V3
    ├── Region: Switzerland North
    └── Instances: 1
         │
         └── Web App: app-nivor-lab-01
              │
              ├── Production Slot
              │
              ├── Staging Slot
              │
              ├── Environment Variables
              │
              └── System-Assigned Managed Identity
```

---

## Resources

| Resource | Configuration |
|---|---|
| Resource Group | `rg-appservice-lab` |
| Web App | `app-nivor-lab-01` |
| Region | Switzerland North |
| Operating System | Linux |
| Runtime | Python |
| App Service Plan | Premium v3 P0V3 |
| Initial Instance Count | 1 |
| Deployment Slots | Production + Staging |
| Managed Identity | System-assigned |

---

## App Service Plan

The Web App was deployed on a dedicated Azure App Service Plan.

The App Service Plan represents the underlying compute capacity used by one or more App Service applications.

This distinction is important:

```text
App Service Plan
      │
      ├── Web App A
      ├── Web App B
      └── Web App C
```

Applications hosted in the same App Service Plan share the compute capacity provided by that plan.

Scaling the plan therefore changes the compute resources available to the applications hosted on it.

---

## Application Configuration

Application settings were configured using App Service environment variables instead of embedding configuration directly into application code.

Example configuration:

```text
ENVIRONMENT = Production
COMPANY = Nivor Systems
```

This separates application configuration from application code and allows settings to be changed directly through the App Service platform.

---

## Managed Identity

A **system-assigned managed identity** was enabled for the Web App.

Conceptually:

```text
Web App
   │
   │ Managed Identity
   ▼
Microsoft Entra ID
   │
   ├── Azure Key Vault
   ├── Storage Account
   └── Other Azure resources
```

Managed identities allow Azure resources to authenticate to supported services without storing credentials, passwords, or client secrets inside application configuration.

No external resource permissions were assigned during this lab because the objective was to configure and understand the identity mechanism itself.

---

## Deployment Slots

A second deployment slot named:

```text
staging
```

was created alongside the production slot.

Architecture:

```text
App Service Plan
      │
      └── app-nivor-lab-01
            │
            ├── production
            │
            └── staging
```

Both slots run under the same App Service Plan.

Deployment slots provide separate application environments that can be used to validate new application versions before promoting them to production.

---

## Slot-Specific Configuration

The staging environment was configured with:

```text
ENVIRONMENT = Staging
```

The `ENVIRONMENT` setting was configured as a **Deployment Slot Setting**.

This makes the configuration sticky to its respective slot.

Therefore:

```text
Production
ENVIRONMENT = Production

Staging
ENVIRONMENT = Staging
```

During a deployment slot swap, these values remain associated with their original slots instead of being exchanged.

This is useful for environment-specific configuration such as:

- database connection strings
- API endpoints
- environment identifiers
- external service configuration

---

## Deployment Slot Swap

A swap operation was performed between:

```text
staging → production
```

This demonstrated the deployment workflow commonly used with App Service:

```text
Deploy
   ↓
Staging
   ↓
Validate
   ↓
Swap
   ↓
Production
```

Deployment slots reduce deployment risk because a new version can be validated before becoming the production application.

They also provide a fast rollback mechanism by swapping the previous version back into production.

---

## Scaling

The scaling capabilities of the App Service Plan were reviewed.

### Scale Up

Scale up changes the compute tier or instance size.

```text
Smaller instance
       ↓
Larger instance
```

This can provide additional:

- CPU
- memory
- platform capabilities
- scaling limits
- App Service features

Scale up can therefore be required either for additional performance or to unlock capabilities unavailable in lower pricing tiers.

### Scale Out

Scale out changes the number of running instances.

```text
1 instance
    ↓
2 instances
    ↓
3 instances
```

The selected Premium v3 plan supported multiple instances.

Three scaling approaches were reviewed:

### Manual

A fixed number of instances is configured manually.

### Automatic

Azure manages scale-out and scale-in based on application traffic.

### Rules Based

Custom autoscale rules can be defined using metrics or schedules.

Example:

```text
CPU > 70%
    ↓
Add instance

CPU < 30%
    ↓
Remove instance
```

The lab remained at **one instance** to avoid unnecessary compute costs.

---

## Networking Concepts

The App Service networking options were also reviewed conceptually.

### VNet Integration

Used when the App Service needs outbound connectivity toward resources accessible through a virtual network.

```text
App Service
     │
     │ outbound
     ▼
VNet
     │
     ▼
Private Resource
```

### Private Endpoint

Used when clients need private inbound access to the App Service.

```text
VNet
 │
 │ private inbound access
 ▼
Private Endpoint
 │
 ▼
App Service
```

A useful distinction is:

```text
App Service → VNet
VNet Integration

VNet → App Service
Private Endpoint
```

These networking components were not deployed during this lab and will be explored separately as part of the networking implementation.

---

## Azure Policy Interaction

During deployment slot creation, an existing Azure Policy blocked the operation.

The policy required resources to contain:

```text
Environment = Production
```

This conflicted with the creation of a staging environment.

The lab resource group was therefore excluded from the restrictive policy assignment.

This demonstrated an important governance consideration:

> A technically valid Azure Policy can create operational problems when its scope or required values are too restrictive.

A more flexible enterprise design would enforce the presence of an `Environment` tag while allowing approved values such as:

```text
Production
Staging
Development
Test
```

This preserves governance without preventing legitimate multi-environment architectures.

---

## Cost Management

The App Service Plan used for the lab was a paid Premium v3 tier because deployment slots required functionality unavailable in lower tiers used for basic testing.

To minimize cost:

- only one instance was deployed
- no scale-out operation was executed
- resources were used only for the duration of the lab
- the entire resource group was deleted after validation

The cleanup removed the App Service Plan and therefore stopped the associated compute billing.

---

## Screenshots

### App Service Overview

![App Service Overview](screenshots/01-app-service-overview.png)

Shows the deployed Linux Web App, runtime, App Service Plan, region, and hosting configuration.

### Deployment Slots

![Deployment Slots](screenshots/02-deployment-slots.png)

Shows the production and staging slots running under the same App Service Plan.

### Scale Out Options

![Scale Out Options](screenshots/03-scale-out-options.png)

Shows the App Service Plan scaling configuration and the Manual, Automatic, and Rules Based scaling methods.

---

## Key Concepts Practiced

- Azure App Service
- App Service Plans
- Linux Web Apps
- Application settings
- Environment variables
- System-assigned managed identities
- Deployment slots
- Slot-specific settings
- Deployment slot swaps
- Scale up
- Scale out
- Automatic scaling
- Rules-based autoscale
- Azure Policy interaction
- Cost-aware resource lifecycle management

---

## Cleanup

After validation, the complete lab resource group was deleted:

```text
rg-appservice-lab
```

This removed the Web App, deployment slots, and App Service Plan to prevent ongoing compute charges.

---

## Result

The lab successfully demonstrated the deployment and operational management of an Azure App Service application.

The implementation covered application hosting, environment separation, identity, deployment strategies, scaling, governance interaction, and resource lifecycle management using a production-oriented Azure administration workflow.
