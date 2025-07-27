# Apply-ResourceTags-Fixed.ps1
# Script to apply tags to all resources in specified resource groups - Fixed version

param(
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId = "931b98ea-0e07-4d52-a37a-3b8fa4985688"
)

# Define tags for each resource group
$resourceGroupTags = @{
    "datacatalyst-demo-dev-core-test-rg" = @{
        "Application" = "datacatalyst-demo"
        "Client" = "nowvertical"
        "CostCenter" = "123cc"
        "DataSensitivity" = "internal"
        "Environment" = "dev"
        "Lifecycle" = "active"
        "ManagedBy" = "nowvertical"
        "Project" = "datacatalyst"
        "Solution" = "data-integration"
        "Tier" = "core"
        "ResourceGroupType" = "Core"
    }
    "datacatalyst-demo-dev-source-test-rg" = @{
        "Application" = "datacatalyst-demo"
        "Client" = "nowvertical"
        "CostCenter" = "456cc"
        "DataSensitivity" = "sensitive"
        "Environment" = "dev"
        "Lifecycle" = "active"
        "ManagedBy" = "nowvertical"
        "Project" = "datacatalyst"
        "Solution" = "data-integration"
        "Tier" = "source"
        "ResourceGroupType" = "Source"
    }
}

# Set subscription context
Write-Host "Setting subscription context..." -ForegroundColor Yellow
az account set --subscription $SubscriptionId

$totalResources = 0
$taggedResources = 0

foreach ($rgName in $resourceGroupTags.Keys) {
    Write-Host "`nProcessing resource group: $rgName" -ForegroundColor Cyan
    
    # Get tags for this resource group
    $tags = $resourceGroupTags[$rgName]
    
    # Convert tags to JSON format for Azure CLI
    $tagsJson = $tags | ConvertTo-Json -Compress
    
    # First, tag the resource group itself
    Write-Host "  Tagging resource group..." -ForegroundColor Gray
    $result = az group update --name $rgName --set tags=$tagsJson --output none 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    ✓ Resource group tagged successfully" -ForegroundColor Green
    } else {
        Write-Host "    ✗ Failed to tag resource group: $result" -ForegroundColor Red
    }
    
    # Get all resources in the resource group
    Write-Host "  Getting resources..." -ForegroundColor Gray
    $resources = az resource list --resource-group $rgName --query "[].{id:id, name:name, type:type}" | ConvertFrom-Json
    
    $totalResources += $resources.Count
    Write-Host "  Found $($resources.Count) resources" -ForegroundColor Gray
    
    # Tag each resource
    foreach ($resource in $resources) {
        Write-Host "  Tagging: $($resource.name) [$($resource.type)]" -ForegroundColor Gray
        
        # Use az tag update command which is more reliable
        $result = az tag update --resource-id $resource.id --operation Replace --tags @tags 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $taggedResources++
            Write-Host "    ✓ Tagged successfully" -ForegroundColor Green
        } else {
            # Some resources don't support tags, try with resource update
            $result2 = az resource update --ids $resource.id --set tags=$tagsJson --output none 2>&1
            if ($LASTEXITCODE -eq 0) {
                $taggedResources++
                Write-Host "    ✓ Tagged successfully (via resource update)" -ForegroundColor Green
            } else {
                Write-Host "    ✗ Resource type doesn't support tags or error occurred" -ForegroundColor Yellow
            }
        }
        
        # Small delay to avoid rate limiting
        Start-Sleep -Milliseconds 500
    }
}

Write-Host "`n========================================"  -ForegroundColor Cyan
Write-Host "Tagging Summary:" -ForegroundColor Cyan
Write-Host "  Total resources found: $totalResources" -ForegroundColor White
Write-Host "  Successfully tagged: $taggedResources" -ForegroundColor Green
Write-Host "  Failed/Unsupported: $($totalResources - $taggedResources)" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

# Verify tags on a sample resource
Write-Host "`nVerifying tags on a sample resource..." -ForegroundColor Yellow
$sampleResource = az resource list --resource-group "datacatalyst-demo-dev-core-test-rg" --query "[0]" | ConvertFrom-Json
if ($sampleResource) {
    Write-Host "Sample resource: $($sampleResource.name)" -ForegroundColor Cyan
    $tags = az tag list --resource-id $sampleResource.id --query "properties.tags" | ConvertFrom-Json
    Write-Host "Current tags:" -ForegroundColor Cyan
    $tags | Format-Table -AutoSize
}
