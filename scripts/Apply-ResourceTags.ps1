# Apply-ResourceTags.ps1
# Script to apply tags to all resources in specified resource groups

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
    
    # Convert tags to Azure CLI format - each tag needs to be a separate argument
    $tagArray = @()
    foreach ($key in $tags.Keys) {
        $tagArray += "$key=$($tags[$key])"
    }
    
    # First, tag the resource group itself
    Write-Host "  Tagging resource group..." -ForegroundColor Gray
    # Clear existing tags first to avoid the concatenation issue
    az group update --name $rgName --tags @() --output none
    # Now apply the new tags
    az group update --name $rgName --tags @tagArray --output none
    
    # Get all resources in the resource group
    Write-Host "  Getting resources..." -ForegroundColor Gray
    $resources = az resource list --resource-group $rgName --query "[].{id:id, name:name, type:type}" | ConvertFrom-Json
    
    $totalResources += $resources.Count
    Write-Host "  Found $($resources.Count) resources" -ForegroundColor Gray
    
    # Tag each resource
    foreach ($resource in $resources) {
        Write-Host "  Tagging: $($resource.name) [$($resource.type)]" -ForegroundColor Gray
        
        try {
            # Some resource types don't support tags, so we wrap in try-catch
            # First clear existing tags to avoid concatenation
            az resource update --ids $resource.id --set tags={} --output none 2>$null
            # Now apply new tags
            az resource update --ids $resource.id --set tags=@tagArray --output none 2>$null
            if ($LASTEXITCODE -eq 0) {
                $taggedResources++
                Write-Host "    ✓ Tagged successfully" -ForegroundColor Green
            } else {
                Write-Host "    ✗ Resource type doesn't support tags or error occurred" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "    ✗ Error: $_" -ForegroundColor Red
        }
        
        # Small delay to avoid rate limiting
        Start-Sleep -Milliseconds 500
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Tagging Summary:" -ForegroundColor Cyan
Write-Host "  Total resources found: $totalResources" -ForegroundColor White
Write-Host "  Successfully tagged: $taggedResources" -ForegroundColor Green
Write-Host "  Failed/Unsupported: $($totalResources - $taggedResources)" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan
