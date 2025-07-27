# Apply-Tags-Simple.ps1
# Simple script to apply tags properly to Azure resources

param(
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId = "931b98ea-0e07-4d52-a37a-3b8fa4985688"
)

# Set subscription context
Write-Host "Setting subscription context..." -ForegroundColor Yellow
az account set --subscription $SubscriptionId

# Define tags for core resource group
$coreTags = @{
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

# Define tags for source resource group
$sourceTags = @{
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

function Apply-TagsToResource {
    param(
        [string]$ResourceId,
        [hashtable]$Tags
    )
    
    # Build the tags parameter string
    $tagParams = @()
    foreach ($key in $Tags.Keys) {
        $tagParams += "$key=`"$($Tags[$key])`""
    }
    
    # Apply tags using az tag create command
    $tagString = $tagParams -join " "
    $cmd = "az tag create --resource-id `"$ResourceId`" --tags $tagString"
    
    Write-Host "  Executing: $cmd" -ForegroundColor DarkGray
    $result = Invoke-Expression $cmd 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        return $true
    } else {
        Write-Host "  Error: $result" -ForegroundColor Red
        return $false
    }
}

# Process core resource group
Write-Host "`nProcessing resource group: datacatalyst-demo-dev-core-test-rg" -ForegroundColor Cyan

# Get all resources
$coreResources = az resource list --resource-group "datacatalyst-demo-dev-core-test-rg" --query "[].{id:id, name:name, type:type}" | ConvertFrom-Json

Write-Host "Found $($coreResources.Count) resources in core resource group" -ForegroundColor Yellow

$successCount = 0
foreach ($resource in $coreResources) {
    Write-Host "`nTagging: $($resource.name)" -ForegroundColor Gray
    Write-Host "  Type: $($resource.type)" -ForegroundColor DarkGray
    
    if (Apply-TagsToResource -ResourceId $resource.id -Tags $coreTags) {
        Write-Host "  ✓ Tagged successfully" -ForegroundColor Green
        $successCount++
    } else {
        Write-Host "  ✗ Failed to tag" -ForegroundColor Red
    }
    
    Start-Sleep -Milliseconds 300
}

# Process source resource group
Write-Host "`n`nProcessing resource group: datacatalyst-demo-dev-source-test-rg" -ForegroundColor Cyan

$sourceResources = az resource list --resource-group "datacatalyst-demo-dev-source-test-rg" --query "[].{id:id, name:name, type:type}" | ConvertFrom-Json

Write-Host "Found $($sourceResources.Count) resources in source resource group" -ForegroundColor Yellow

foreach ($resource in $sourceResources) {
    Write-Host "`nTagging: $($resource.name)" -ForegroundColor Gray
    Write-Host "  Type: $($resource.type)" -ForegroundColor DarkGray
    
    if (Apply-TagsToResource -ResourceId $resource.id -Tags $sourceTags) {
        Write-Host "  ✓ Tagged successfully" -ForegroundColor Green
        $successCount++
    } else {
        Write-Host "  ✗ Failed to tag" -ForegroundColor Red
    }
    
    Start-Sleep -Milliseconds 300
}

# Summary
$totalResources = $coreResources.Count + $sourceResources.Count
Write-Host "`n========================================"  -ForegroundColor Cyan
Write-Host "Tagging Summary:" -ForegroundColor Cyan
Write-Host "  Total resources: $totalResources" -ForegroundColor White
Write-Host "  Successfully tagged: $successCount" -ForegroundColor Green
Write-Host "  Failed: $($totalResources - $successCount)" -ForegroundColor Red
Write-Host "========================================`n" -ForegroundColor Cyan

# Verify tags on a sample resource
Write-Host "Verifying tags on datacatalyst-demo-core-test-vnet..." -ForegroundColor Yellow
$vnetTags = az resource show --ids "/subscriptions/931b98ea-0e07-4d52-a37a-3b8fa4985688/resourceGroups/datacatalyst-demo-dev-core-test-rg/providers/Microsoft.Network/virtualNetworks/datacatalyst-demo-core-test-vnet" --query "tags" -o json | ConvertFrom-Json

Write-Host "`nCurrent tags on VNet:" -ForegroundColor Cyan
$vnetTags | ConvertTo-Json
