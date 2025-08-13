#Backup and Disaster Recovery Strategy

##Introduction
Ensuring the resilience and continuity of services is critical. This is achieved through robust backup and disaster recovery strategies implemented across key Azure services.

---

## Key Services and Backup Strategy

## Azure API Management (APIM)

## Backup and Restore
- Backups taken using Azure Resource Manager (ARM) templates
- APIs backed up via “Backup & Restore” method including:
  - API configurations
  - Policies
  - Custom domains
- Secondary backup of APIs is maintained in the Git repository

## Continuous Monitoring
- Azure Monitor**: Alerts and monitoring for APIM health
- Application Insights**: Tracks request performance and diagnostics

## References:
- [Backup and Restore APIM](https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-disaster-recovery-backup-restore?tabs=powershell)
- [APIM High Availability](https://learn.microsoft.com/en-us/azure/api-management/high-availability)

---

## Azure SQL Database

## Backup
- Point-in-Time Restore enabled with differential backups every 12 hours
- Geo-redundant backup storage enabled
- Zone-redundancy enabled across three Azure Availability Zones
- Schema & Table Scripts are stored and versioned in Git

## Continuous Monitoring
- Azure Monitor alerts are set for database performance and availability

## References:
- [SQL Backup Overview](https://learn.microsoft.com/en-us/azure/azure-sql/database/automated-backups-overview?view=azuresql)
- [SQL High Availability with Zones](https://learn.microsoft.com/en-us/azure/azure-sql/database/high-availability-sla-local-zone-redundancy?view=azuresql&tabs=azure-powershell)

---

## Function Apps

## Backup
- Function App code stored in Git Repository
- ARM templates backed up for quick redeployment

## Continuous Monitoring
- Azure Monitor for health/performance
- Application Insights for diagnostics

---

## Logic Apps

## Backup
- ARM Templates with full workflow configurations are backed up

## Continuous Monitoring
- Azure Monitor and Application Insights enabled

---

## Azure Data Factory (ADF)

## Backup
- Regular exports of ADF ARM templates stored securely in a secondary region’s Storage Account
- Secondary backups of pipelines and linked services are stored in 

---

## Regional Backup Strategy

- Primary services are hosted in UK South
- Backups are stored in UK West for cross-region redundancy and failover
- Covers:
  - ARM Templates
  - IaC Pulumi Code
  - DB Scripts
  - Function App Code



Backups are always synchronized with changes to existing resources or creation of new resources.


---

## Resource Protection

## Delete Locks
- Delete locks enabled on all resources to prevent accidental deletion and preserve integrity

## Enhanced RBAC (Custom Restricted Roles)
Custom RBAC roles restrict modification access across critical services:

| Service | Access Restrictions |
|---------|---------------------|
| APIM | No edit access to APIs or policies; can manage products only |
| SQL | No permissions for schema changes or data masking |
| Function Apps | Cannot modify app settings (e.g., connection strings) |
| Logic Apps | Cannot change workflow design |
| Other Services (e.g., NSG, App Gateway, ADF) | Read-only access |



---

## Summary

- Multi-layered backup strategy using ARM, Git, and Storage Accounts
- Cross-region disaster recovery setup for APIM, ADF, Function Apps, and SQL
- Continuous monitoring via Azure Monitor and Application Insights
- Change management and RBAC restrictions enforced for security

