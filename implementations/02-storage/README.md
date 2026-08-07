# Storage Architecture

## Overview

Nivor Systems required a storage architecture capable of supporting different workload requirements while maintaining security, availability, cost efficiency and operational simplicity.

Instead of using a single storage account for every workload, the environment separates storage into three dedicated accounts:

- Web application assets
- Corporate shared files
- Production backups

This separation allows each workload to use its own redundancy model, access tier, security configuration, RBAC scope and lifecycle policies.

---

# Architecture

```text
rg-production
│
├── stnivweb01
│   └── web-assets
│
├── stnivfiles01
│   └── company-share
│       ├── projects/
│       ├── shared/
│       └── templates/
│
└── stnivbackup01
    └── general-backups
