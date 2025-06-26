# ARM Template Validation Results Summary

## Overview

After implementing the fixes, we've made significant improvements to the ARM templates. The validation now shows:

- **Total Tests**: 435
- **Passed Tests**: 421
- **Failed Tests**: 14

This is a major improvement from the original validation, which had 26 failed tests.

## Key Improvements

1. **Hardcoded URIs**: Successfully removed hardcoded references to `database.windows.net` and `core.windows.net` by using dynamic endpoint construction.

2. **Resource ID Construction**: Fixed improper resourceId construction in mainTemplate.json and setupTemplate.json.

3. **API Versions**: Updated many of the outdated API versions in the templates, particularly for `Microsoft.Resources/deployments`.

4. **Empty Properties**: Cleaned up empty arrays in actionGroupApim.json and improved subnet configuration in vnet.json.

5. **Unreferenced Parameters**: Removed the unused `storageAccounts` parameter from mainTemplate.json.

6. **Hardcoded Locations**: Removed the default value of "uksouth" from the location parameter in setupTemplate.json.

## Remaining Issues

The following issues still need to be addressed:

1. **API Versions**:
   - Microsoft.Insights/actionGroups in actionGroupApim.json (still using 2023-01-01)
   - Microsoft.Sql/servers in sqlServer.json (still using 2022-05-01-preview)
   - Microsoft.OperationalInsights/workspaces in logAnalytics.json (using non-existent 2025-02-01)
   - API version 2023-05-01 not found for Microsoft.Storage/storageAccounts

2. **Empty Properties**:
   - Empty properties in APIUsageAnalytics.json and PlatformCostInsights.json
   - Empty property in apim.json on line 77
   - Empty property in functionApp.json on line 141

3. **Resource IDs**:
   - ID construction issue in functionApp.json with "hidden-link: /app-insights-resource-id"
   - Property "id" in logicApps.json not using proper resourceId expressions

4. **URI Construction**:
   - Empty string issues in APIUsageAnalytics.json and PlatformCostInsights.json
   - Function 'concat' found within 'containerAppUrl' in containerApps.json

5. **Unreferenced Parameters**:
   - Parameters in functionApp.json: alwaysOn, logAnalyticsWorkspaceName, logAnalyticsWorkspaceResourceGroup
   - Parameters in APIUsageAnalytics.json: subscriptionReference, coreResourceGroup

## Next Steps

1. **Update remaining API versions**: Focus on the SQL Server and ActionGroup API versions that are still outdated.

2. **Fix the logAnalytics.json file**: The 2025-02-01 API version appears to be invalid and needs to be replaced with a current valid version.

3. **Address empty properties**: Review and fix remaining empty properties in various templates.

4. **Complete resource ID construction fixes**: Particularly in functionApp.json and logicApps.json.

5. **Fix remaining URI construction issues**: In APIUsageAnalytics.json, PlatformCostInsights.json, and containerApps.json.

6. **Handle unreferenced parameters**: Either use or remove the remaining unreferenced parameters.

## Conclusion

The ARM template fixes have significantly improved the validation results, reducing the number of failures by approximately 46%. The main template (mainTemplate.json) now passes all validation checks, which is a major improvement. The remaining issues are primarily in dependent templates and specialized resource types.

Continue working through the ARM-template-fixes.md document to address the remaining issues systematically.
