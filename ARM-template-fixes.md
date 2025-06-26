# ARM Template Validation Issues

This document outlines the validation issues found in the Azure Resource Manager (ARM) templates and proposed fixes.

## 1. Outdated API Versions

### Issue:
Many resources are using API versions that are more than 2 years old (over 730 days).

### Affected Templates:
- **mainTemplate.json**: 
  - Line 106, 167, 191, 239, 308, 332, 368, 408, 448, 475, 505: Using `apiVersion`: `2022-09-01` for `Microsoft.Resources/deployments`
  - Update to: `2023-07-01`

- **setupTemplate.json**:
  - Line 49: Using `apiVersion`: `2022-09-01` for `Microsoft.Resources/deployments`
  - Line 39: Using `apiVersion`: `2021-04-01` for `Microsoft.Resources/resourceGroups` (Not found)
  - Update to: `2023-07-01`

- **functionApp.json**:
  - Line 169, 180: Using `apiVersion`: `2022-09-01` for `Microsoft.Web/sites/basicPublishingCredentialsPolicies`
  - Line 192: Using `apiVersion`: `2022-09-01` for `Microsoft.Web/serverfarms`
  - Line 105: Using `apiVersion`: `2023-12-01` for `Microsoft.Web/sites` (Not found)
  - Update to: `2023-01-01`

- **dependent/actionGroupApim.json**:
  - Line 34: Using `apiVersion`: `2023-01-01` for `Microsoft.Insights/actionGroups`
  - Update to: `2023-05-01` or `2023-08-01-preview`

- **independent/sqlServer.json**:
  - Using `apiVersion`: `2022-05-01-preview` for SQL resources
  - Update to: `2021-11-01` or `2023-05-01-preview`

- **independent/vnet.json**:
  - Line 22: Using `apiVersion`: `2023-05-01` for `Microsoft.Network/virtualNetworks`
  - Update to: `2023-06-01`

## 2. Hardcoded URIs

### Issue:
Templates contain hardcoded references to URIs.

### Affected Templates:
- **mainTemplate.json**:
  - Line 223: Hardcoded reference to `database.windows.net`
  - Solution: Replace with a parameter or variable

- **functionApp.json**:
  - Lines 123, 131: Hardcoded references to `core.windows.net` in connection strings
  - Line 146: Hardcoded reference to `core.windows.net` in blob URL
  - Solution: Replace with parameters or use environment-specific endpoints

## 3. ResourceIds Construction Issues

### Issue:
Incorrect resource ID construction techniques.

### Affected Templates:
- **mainTemplate.json**:
  - Line 540: Using `reference(concat('logAnalyticsWorkspace-', 0)).outputs.workspaceResourceId.value`
  - Solution: Use nested resource references or proper resource ID construction

- **setupTemplate.json**:
  - Line 87: Using `resourceId(subscription().subscriptionId, parameters('keyVaultResourceGroup'), 'Microsoft.KeyVault/vaults', parameters('keyVaultName'))`
  - Solution: Use correct format without subscription() function in direct resourceId calls

- **functionApp.json**:
  - Line 111: Using `concat('/subscriptions/', parameters('subscriptionId'), '/resourceGroups/', parameters('serverFarmResourceGroup'), '/providers/Microsoft.Insights/components/', parameters('name')))`
  - Solution: Use resourceId function instead of concatenation

- **logicApps.json**:
  - Property "id" not using proper resourceId expressions
  - Solution: Replace with resourceId function

## 4. Empty Properties

### Issue:
Several templates have empty arrays or properties.

### Affected Templates:
- **actionGroupApim.json**:
  - Lines 54-61, 70-71: Empty arrays for various receiver types
  - Solution: Remove empty arrays or provide valid values

- **vnet.json**:
  - Lines 36, 37: Empty properties
  - Solution: Remove or provide valid values

- **APIUsageAnalytics.json** and **PlatformCostInsights.json**:
  - Empty properties causing URI construction issues
  - Solution: Fix empty properties

## 5. Unreferenced Parameters

### Issue:
Parameters defined but not used in the templates.

### Affected Templates:
- **mainTemplate.json**:
  - Line 5: Unreferenced parameter `storageAccounts`
  - Solution: Either use or remove the parameter

- **functionApp.json**:
  - Lines 77, 83, 89: Unreferenced parameters `alwaysOn`, `logAnalyticsWorkspaceName`, and `logAnalyticsWorkspaceResourceGroup`
  - Solution: Either use or remove the parameters

- **APIUsageAnalytics.json**:
  - Lines 12, 18: Unreferenced parameters `subscriptionReference` and `coreResourceGroup`
  - Solution: Either use or remove the parameters

## 6. Hardcoded Locations

### Issue:
Locations hardcoded in templates.

### Affected Templates:
- **setupTemplate.json**:
  - Line 27: Location parameter with defaultValue set to "uksouth"
  - Solution: Remove defaultValue or parameterize across all templates

## 7. URI Construction Issues

### Issue:
Improper URI construction in templates.

### Affected Templates:
- **containerApps.json**:
  - Line 179: Using `format` function in `containerAppUrl` output
  - Solution: Use string concatenation or improve format usage

- **APIUsageAnalytics.json** and **PlatformCostInsights.json**:
  - "Cannot bind argument to parameter 'Match' because it is an empty string" errors
  - Solution: Fix empty string handling in URI construction

## 8. Invalid API Version References

### Issue:
References to non-existent API versions.

### Affected Templates:
- **logAnalytics.json**:
  - Using API version `2025-02-01` which doesn't exist
  - Solution: Update to latest valid API version

## Recommended Approach:
1. Start by fixing the API versions across all templates
2. Address hardcoded URIs by using parameters
3. Fix resource ID construction issues
4. Remove empty properties or provide valid values
5. Address unreferenced parameters
6. Remove hardcoded location values
7. Fix URI construction issues
