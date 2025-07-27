# Scripts Directory

This directory contains utility scripts for managing Azure resources deployed by the ARM templates.

## Apply-Tags.ps1

This PowerShell script applies consistent tags to all Azure resources in the specified resource groups after deployment.

### Why Use This Script?

- **Simplifies ARM Templates**: Removes the complexity of managing tags within ARM templates
- **Consistent Tagging**: Ensures all resources have the same standardized tags
- **Post-Deployment Flexibility**: Tags can be applied or updated after resources are deployed
- **Bulk Operations**: Tags multiple resources efficiently in one operation

### Usage

After deploying resources using the ARM templates, run:

```powershell
pwsh -File scripts/Apply-Tags.ps1
```

### Tags Applied

#### Core Resource Group (datacatalyst-demo-dev-core-test-rg)
- **Application**: datacatalyst-demo
- **Client**: nowvertical
- **CostCenter**: 123cc
- **DataSensitivity**: internal
- **Environment**: dev
- **Lifecycle**: active
- **ManagedBy**: nowvertical
- **Project**: datacatalyst
- **Solution**: data-integration
- **Tier**: core
- **ResourceGroupType**: Core

#### Source Resource Group (datacatalyst-demo-dev-source-test-rg)
- **Application**: datacatalyst-demo
- **Client**: nowvertical
- **CostCenter**: 456cc
- **DataSensitivity**: sensitive
- **Environment**: dev
- **Lifecycle**: active
- **ManagedBy**: nowvertical
- **Project**: datacatalyst
- **Solution**: data-integration
- **Tier**: source
- **ResourceGroupType**: Source

### Customization

To modify tags for different environments or resource groups, edit the `$coreTags` and `$sourceTags` hashtables in the script.

### Notes

- The script uses `az tag create` command which properly applies individual tags
- A small delay is added between operations to avoid Azure API rate limiting
- The script provides a summary of successful and failed tagging operations
- Tags are applied to ALL resources in the specified resource groups

## Verify-Tags.ps1

This PowerShell script verifies the tags applied to all Azure resources in the specified resource groups, ensuring compliance with expected tag values.

### Why Use This Script?

- **Ensures Compliance**: Confirms that all resources have the expected tags
- **Easy Verification**: Provides a report on tag compliance

### Usage

After running the `Apply-Tags.ps1` script, verify tags by running:

```powershell
pwsh -File scripts/Verify-Tags.ps1
```

### Notes

- The script checks each resource for the expected tag values
- Any discrepancies are highlighted in the output
- Helps maintain consistent resource management across environments
