# Deployment Steps/Flow

1) Subscription-level setup (Resource Groups + Key Vault)
Deploy the production setup template to create the core and source resource groups and the Key Vault in UK South.

```powershell
az deployment sub create `
  --location uksouth `
  --template-file templates/prod/setupTemplate.json `
  --parameters @parameters/prod/setup.parameters.json
```

2) Create required Key Vault secrets (referenced by main template)
Create the SQL admin username and password secrets in the production Key Vault before running the main deployment.

Note: Replace the placeholders with your actual values; do not commit secrets.

```powershell
# Option A: Set from inline placeholders (recommended only for local execution)
az keyvault secret set `
  --vault-name dc-demo-prod-core-kv `
  --name mw-sql-server-admin-user `
  --value "{{SQL_ADMIN_USERNAME}}"

az keyvault secret set `
  --vault-name dc-demo-prod-core-kv `
  --name mw-sql-server-admin-password `
  --value "{{SQL_ADMIN_PASSWORD}}"

# Option B: Use environment variables for safer handling in scripts
# $SQL_ADMIN_USER and $SQL_ADMIN_PASSWORD should be set in your session beforehand
az keyvault secret set `
  --vault-name dc-demo-prod-core-kv `
  --name mw-sql-server-admin-user `
  --value $env:SQL_ADMIN_USER

az keyvault secret set `
  --vault-name dc-demo-prod-core-kv `
  --name mw-sql-server-admin-password `
  --value $env:SQL_ADMIN_PASSWORD
```

3) Subscription-level main deployment (workloads and services)
Run the main production template to deploy SQL, Log Analytics, Storage Accounts, Container Apps, Function Apps, VNet, APIM, Dashboards, Logic Apps, and Action Groups in the correct dependency order.

```powershell
az deployment sub create `
  --location uksouth `
  --template-file templates/prod/mainTemplate.json `
  --parameters @parameters/prod/main.parameters.json
```
#  Azure Post-Deployment Manual Configuration Guide

After deploying Azure infrastructure and services, a few manual configuration steps are required to ensure everything functions correctly. This guide provides links to individual `README` files that cover these tasks in detail.

---

### 1. Azure Function App – VNet & Environment Variables Configuration

After deploying the Function App, additional configuration is needed for VNet integration and environment variable setup.  
📄 Refer to: [FAReadme.md](./ReadmeFile/FAReadme.md)

---

### 2. Container & Storage Account – Config File, Volume Mount, and Runtime Setup

Following the deployment of a Container App and Storage Account, you need to upload the config file (e.g., `dab-config.json`), mount the volume, and perform container-level configuration.  
📄 Refer to: [containerconfigreadme.md](./ReadmeFile/containerconfigreadme.md)

---

### 3. Event Grid – Webhook Integration

After deploying the Storage Account, Function App, and Webhook code, you need to create an event Grid System Topic and set up an event subscription for real-time notifications.  
📄 Refer to: [EventGridReadme.md](./ReadmeFile/EventGridReadme.md)

---

### 4. App Registration – OAuth2 & API Security

Once all services and infrastructure are deployed, you must create and configure App Registrations to enable secure OAuth2-based access to APIs.  
📄 Refer to: [appregistrationReadme.md](./ReadmeFile/appregistrationReadme.md)

---

### 5. Diagnostic Settings & Cost Management Dashboard Configuration

Before deploying your dashboard, it’s essential to:

- Enable Diagnostic Settings for all relevant services
- Set up Cost Analysis views in Azure Cost Management

These tasks ensure the dashboard is populated correctly.  
📄 Refer to: [Dashboard&diagnosticsettingReadme.md](./ReadmeFile/Dashboard%26diagnosticsettingReadme.md)

---

### 6.  Subnet Configuration (Post VNet Deployment)

After deploying the Virtual Network (VNet), you need to create subnets that will be associated with services like Storage Account, Function App, and others during their configuration.

📄 Refer to: [Subnet Configuration Guide](./ReadmeFile/subnetreadme.md)

---

### 7. Storage Account Networking Configuration

After deploying the Virtual Network (VNet) and Storage Account, you must manually configure networking settings to:

- Restrict access using the VNet and subnet
- Whitelist specific IP addresses (optional)

📄 Refer to: [StorageAccountNetworkingReadme.md](./ReadmeFile/StorageAccountNetworkingReadme.md)

---

### 8. Configure Alerts on Azure
A Log Analytics Workspace is connected to Azure resources with diagnostic settings enabled and logs populated. An Action Group is set up to respond when alerts are triggered.
You can refer to the below README file to configure the alert.

[Alert Configuration Guide](ReadmeFile/alertreadme.md)

---

### 9. API Product Creation Documentation 
This document provides guidance on deploying Azure API Management (APIM) and creating APIs within it, including how to configure and publish a product for the APIs

[Product Setup Guide](ReadmeFile/APIProductCreationReadme.md)

---

### 10. APIM Migration via Backup & Restore

This document outlines the process to migrate Azure API Management (APIM) instances using the backup and restore method. It should be used post-deployment of a new APIM instance when you need to replicate or recover APIs, policies, and configurations from a source environment to a target one.


[APIM Backup & Restore Guide](ReadmeFile/APIMBackup&RestoreReadme.md)

---
### 11. RBAC Model and Access Strategy

This document explains the Azure Role-Based Access Control (RBAC) model implemented in the middleware project, including:
- Granular role assignments for secure access to Function Apps, Key Vaults, and APIM
- Environment-specific access control (Dev, UAT, Prod)
- Least privilege principle and compliance strategy
- Examples of role definitions and scope hierarchies

[RBAC Model & Access Guide](ReadmeFile/Rbac%20readmefile.md)

---
### 12. Backup and Disaster Recovery Strategy

This document provides a detailed overview of the backup and disaster recovery (DR) practices used in the Middleware project to ensure service resilience, continuity, and protection of critical components.

Key areas covered in the guide include:

- Backup and restore processes for Azure API Management (APIM), SQL Databases, Function Apps, Logic Apps, and Azure Data Factory (ADF)
- Use of ARM templates, Git repositories, and geo-redundant storage for cross-region failover
- Continuous monitoring setup using Azure Monitor and Application Insights
- Regional backup architecture using UK South (primary) and UK West (secondary)
- Delete locks and RBAC-based protections to prevent unauthorized or accidental changes

[Backup & DR Guide](ReadmeFile/backup-disaster-recovery.md)


---

### 13. Apply Resource Tags

After all resources are deployed, apply consistent tags to enable cost tracking, compliance, and resource management.

**To apply tags:**
```powershell
pwsh -File scripts/Apply-Tags.ps1
```

See [scripts/README.md](scripts/README.md) for more details about the tagging approach and customization options.

