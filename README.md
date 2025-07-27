# Deployment Steps/Flow
1. Deploy the setupTemplate.json file first, which is responsible for deploying two Resource Groups and a Key Vault.
2. Create the required secrets which are to referenced in the mainTemplate.json (in our case DB user and Password).
3. Post this, Initate the deployments from mainTemplate.json file which will spin up all the resources.

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

### 11. Apply Resource Tags

After all resources are deployed, apply consistent tags to enable cost tracking, compliance, and resource management.

**To apply tags:**
```powershell
pwsh -File scripts/Apply-Tags.ps1
```

See [scripts/README.md](scripts/README.md) for more details about the tagging approach and customization options.

