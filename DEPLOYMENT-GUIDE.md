# DataCatalyst Infrastructure Deployment Guide

## 🚀 Deployment Commands

### Development Environment
```bash
# 1. Setup (Resource Groups + KeyVault)
az deployment sub create \
  --location uksouth \
  --template-file templates/dev/setupTemplate.json \
  --parameters @parameters/dev/setup.parameters.json

# 2. Main Infrastructure
az deployment sub create \
  --location uksouth \
  --template-file templates/dev/mainTemplate.json \
  --parameters @parameters/dev/main.parameters.json

# 3. Apply Tags
pwsh -File scripts/Apply-Tags.ps1

# 4. Verify Deployment
pwsh -File scripts/Verify-Tags.ps1
```

### Production Environment
```bash
# 1. Setup (Resource Groups + KeyVault)
az deployment sub create \
  --location uksouth \
  --template-file templates/prod/setupTemplate.json \
  --parameters @parameters/prod/setup.parameters.json

# 2. Main Infrastructure  
az deployment sub create \
  --location uksouth \
  --template-file templates/prod/mainTemplate.json \
  --parameters @parameters/prod/main.parameters.json

# 3. Apply Tags (Production-Safe)
pwsh -File scripts/Apply-Tags-Prod.ps1

# 4. Verify Deployment (Production-Safe)
pwsh -File scripts/Verify-Tags-Prod.ps1
```

## 🎯 Environment Differences

### Development Environment
- **Resource Groups**: 
  - `datacatalyst-demo-dev-core-test-rg`
  - `datacatalyst-demo-dev-source-test-rg`
- **Key Vault**: `dc-demo-dev-core-test-kv`
- **Template URLs**: Point to `main` branch
- **Environment Tag**: `dev`

### Production Environment
- **Resource Groups**: 
  - `datacatalyst-demo-prod-core-rg` ✨
  - `datacatalyst-demo-prod-source-rg` ✨
- **Key Vault**: `dc-demo-prod-core-kv` ✨
- **Template URLs**: Point to `main` branch
- **Environment Tag**: `prod` ✨
- **Safety**: Scripts verify `-prod-` identifier before execution

## 🔒 Safety Features

### Production-Only Scripts
- `Apply-Tags-Prod.ps1` (final) and `Verify-Tags-Prod.ps1` have built-in safety checks
- Scripts verify resource group names contain `-prod-` before execution
- Will **stop and exit** if non-production resource groups are detected

### Environment Isolation
- **Separate templates**: Each environment has its own template files
- **Separate parameters**: No shared parameter files between environments
- **Separate scripts**: Production scripts are isolated from dev scripts

## 📋 Resource Naming Conventions

### Development Resources
```
Pattern: datacatalyst-demo-dev-{component}-test-{type}
Examples:
- datacatalyst-demo-dev-core-test-rg
- datacatalyst-demo-dev-src-test-sqlserver
- datacatalyst-demo-dev-core-test-fa
```

### Production Resources
```
Pattern: datacatalyst-demo-prod-{component}-{type}
Examples:
- datacatalyst-demo-prod-core-rg
- datacatalyst-demo-prod-src-sqlserver  
- datacatalyst-demo-prod-core-fa
```

## 🏷️ Tagging Configuration

### Tagging Strategy Guidance
- **Update tag values** in `scripts/Apply-Tags.ps1` and `scripts/Apply-Tags-Prod.ps1`
- **Customize tags** according to your organization's standards
- **Common tag categories** to consider:
  - Application/Project identification
  - Environment (dev, staging, prod)
  - Cost center/billing allocation  
  - Data sensitivity level
  - Lifecycle management
  - Ownership/contact information

### Current Tag Structure
Review and modify the tag definitions in the tagging scripts to match your requirements:
- Core resource tags (internal data sensitivity)
- Source resource tags (sensitive data handling)
- Environment-specific values

## ⚡ Quick Start

### For Development Testing
```bash
# Clone and navigate to project
git clone <repo-url>
cd dc-deployments/dc-dev-demo-test

# Deploy dev environment
az deployment sub create \
  --location uksouth \
  --template-file templates/dev/mainTemplate.json \
  --parameters @parameters/dev/main.parameters.json
```

### For Production Deployment  
```bash
# Deploy production environment
az deployment sub create \
  --location uksouth \
  --template-file templates/prod/mainTemplate.json \
  --parameters @parameters/prod/main.parameters.json

# Apply production tags (final script)
pwsh -File scripts/Apply-Tags-Prod.ps1
```

## 🔧 Configuration Steps

### Before Deployment
1. **Update template branch URLs** in production templates
2. **Configure tagging scripts** with your organization's tag standards
3. **Review parameter files** for correct naming conventions
4. **Ensure KeyVault secrets** are created for SQL credentials

### After Deployment
Follow the configuration guides in `ReadmeFile/` for post-deployment setup:

1. **Function App VNet Configuration**: `FAReadme.md`
2. **Container App Configuration**: `containerconfigreadme.md` 
3. **Event Grid Setup**: `EventGridReadme.md`
4. **App Registration OAuth**: `appregistrationReadme.md`
5. **Dashboard & Diagnostics**: `Dashboard&diagnosticsettingReadme.md`
6. **Subnet Configuration**: `subnetreadme.md`
7. **Storage Account Networking**: `StorageAccountNetworkingReadme.md`
8. **Alert Configuration**: `alertreadme.md`
9. **API Product Creation**: `APIProductCreationReadme.md`
10. **APIM Migration**: `APIMBackup&RestoreReadme.md`

## 🆘 Troubleshooting

### Common Issues

1. **Resource Group Not Found**
   - Ensure you've run the setup template first
   - Check resource group names in parameters match template defaults

2. **KeyVault Access Issues** 
   - Verify KeyVault contains required secrets:
     - `mw-sql-server-admin-user`
     - `mw-sql-server-admin-password`

3. **Template URL Errors**
   - Update branch names in production template variables
   - Check GitHub URLs are accessible

4. **Tag Verification Failures**
   - Run tagging script before verification script
   - Ensure all resources exist before tag verification

### Getting Help

- Check deployment logs in Azure Portal
- Review parameter files for correct resource names
- Ensure all prerequisites are met (KeyVault secrets, etc.)

---

**🎯 This structure provides complete environment isolation with maximum safety and flexibility!**
