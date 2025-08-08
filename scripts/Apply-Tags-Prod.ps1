# Apply-Tags-Prod.ps1
# Script to apply consistent tags ONLY to specific production resource groups

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Production Resource Tagging Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Applying standardized tags to PRODUCTION resources ONLY..."
Write-Host "Target Resource Groups:" -ForegroundColor Yellow
Write-Host "  - datacatalyst-demo-prod-core-rg" -ForegroundColor Yellow
Write-Host "  - datacatalyst-demo-prod-source-rg" -ForegroundColor Yellow

# Define the expected common tags for each PRODUCTION resource group type
$coreTags = @{
    "Application" = "datacatalyst-demo"
    "Client" = "nowvertical"
    "CostCenter" = "123cc"
    "DataSensitivity" = "internal"
    "Environment" = "prod"
    "Lifecycle" = "active"
    "ManagedBy" = "nowvertical"
    "Project" = "datacatalyst"
    "ResourceGroupType" = "Core"
    "Solution" = "data-integration"
    "Tier" = "core"
}

$sourceTags = @{
    "Application" = "datacatalyst-demo"
    "Client" = "nowvertical"
    "CostCenter" = "456cc"
    "DataSensitivity" = "sensitive"
    "Environment" = "prod"
    "Lifecycle" = "active"
    "ManagedBy" = "nowvertical"
    "Project" = "datacatalyst"
    "ResourceGroupType" = "Source"
    "Solution" = "data-integration"
    "Tier" = "source"
}

# SPECIFIC PRODUCTION resource groups to tag (no wildcards, exact matches)
$productionResourceGroups = @(
    @{
        Name = "datacatalyst-demo-prod-core-rg"
        Tags = $coreTags
        Description = "Core production resources"
    },
    @{
        Name = "datacatalyst-demo-prod-source-rg"
        Tags = $sourceTags
        Description = "Source production resources"
    }
)

$totalResources = 0
$successfullyTagged = 0
$failedToTag = 0

# Safety check: Verify we're only targeting production resource groups
Write-Host "`n🔒 SAFETY CHECK: Verifying target resource groups..." -ForegroundColor Cyan
foreach ($rg in $productionResourceGroups) {
    if ($rg.Name -notmatch "-prod-") {
        Write-Host "❌ SAFETY ERROR: Resource group '$($rg.Name)' does not contain '-prod-' identifier!" -ForegroundColor Red
        Write-Host "❌ STOPPING SCRIPT - Only production resource groups should be targeted!" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Verified: $($rg.Name) is a production resource group" -ForegroundColor Green
}

foreach ($rg in $productionResourceGroups) {
    Write-Host "`n----------------------------------------" -ForegroundColor Yellow
    Write-Host "Processing: $($rg.Name)" -ForegroundColor Yellow
    Write-Host "Purpose: $($rg.Description)" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Yellow
    
    # Check if resource group exists
    $rgExists = az group exists --name $rg.Name
    if ($rgExists -eq "false") {
        Write-Host "  ⚠️ Resource group '$($rg.Name)' does not exist - skipping" -ForegroundColor Yellow
        continue
    }
    
    # Get all resources in the SPECIFIC resource group
    $resources = az resource list --resource-group $rg.Name --query "[].{name:name, type:type, id:id}" | ConvertFrom-Json
    
    if ($resources.Count -eq 0) {
        Write-Host "  📭 No resources found in '$($rg.Name)'" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "  📋 Found $($resources.Count) resources to tag in '$($rg.Name)'" -ForegroundColor Green
    
    foreach ($resource in $resources) {
        $totalResources++
        Write-Host "`n    🏷️ Tagging: $($resource.name)" -ForegroundColor White
        Write-Host "       Type: $($resource.type)" -ForegroundColor Gray
        Write-Host "       Resource Group: $($rg.Name)" -ForegroundColor Gray
        
        # Apply each tag individually to avoid Azure API limitations
        $resourceSuccess = $true
        foreach ($tag in $rg.Tags.GetEnumerator()) {
            try {
                $result = az tag create --resource-id $resource.id --tags "$($tag.Key)=$($tag.Value)" 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "       ✅ Applied: $($tag.Key) = $($tag.Value)" -ForegroundColor Green
                } else {
                    Write-Host "       ❌ Failed: $($tag.Key) = $($tag.Value)" -ForegroundColor Red
                    $resourceSuccess = $false
                }
            }
            catch {
                Write-Host "       ❌ Error: $($tag.Key) = $($tag.Value) - $($_.Exception.Message)" -ForegroundColor Red
                $resourceSuccess = $false
            }
            
            # Small delay to avoid rate limiting
            Start-Sleep -Milliseconds 100
        }
        
        if ($resourceSuccess) {
            $successfullyTagged++
            Write-Host "       ✅ Resource fully tagged" -ForegroundColor Green
        } else {
            $failedToTag++
            Write-Host "       ⚠️ Resource partially tagged" -ForegroundColor Red
        }
        
        # Longer delay between resources
        Start-Sleep -Milliseconds 500
    }
}

# Final Summary Report
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "PRODUCTION TAGGING SUMMARY REPORT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Target Resource Groups:" -ForegroundColor White
foreach ($rg in $productionResourceGroups) {
    Write-Host "  ✓ $($rg.Name)" -ForegroundColor Gray
}
Write-Host ""
Write-Host "Results:" -ForegroundColor White
Write-Host "  📊 Total resources processed: $totalResources" -ForegroundColor White
Write-Host "  ✅ Successfully tagged: $successfullyTagged" -ForegroundColor Green
Write-Host "  ❌ Failed to tag: $failedToTag" -ForegroundColor $(if ($failedToTag -gt 0) { "Red" } else { "Green" })

if ($failedToTag -eq 0 -and $totalResources -gt 0) {
    Write-Host "`n🎉 PRODUCTION TAGGING COMPLETED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "   All production resources have been tagged according to standards." -ForegroundColor Green
} elseif ($totalResources -eq 0) {
    Write-Host "`n⚠️ NO RESOURCES FOUND IN PRODUCTION RESOURCE GROUPS" -ForegroundColor Yellow
    Write-Host "   Verify that the production resource groups exist and contain resources." -ForegroundColor Yellow
} else {
    Write-Host "`n⚠️ PRODUCTION TAGGING COMPLETED WITH ISSUES" -ForegroundColor Yellow
    Write-Host "   Some resources may need manual tag verification." -ForegroundColor Yellow
}

Write-Host "`n📋 Next step: Run './scripts/Verify-Tags-Prod.ps1' to validate tag compliance" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan
