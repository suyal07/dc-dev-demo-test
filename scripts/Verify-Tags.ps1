# Verify-Tags.ps1
# Script to verify that all resources have the complete set of common tags

# Define the expected common tags for each resource group type
$coreTags = @{
    "Application" = "datacatalyst-demo"
    "Client" = "nowvertical"
    "CostCenter" = "123cc"
    "DataSensitivity" = "internal"
    "Environment" = "dev"
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
    "Environment" = "dev"
    "Lifecycle" = "active"
    "ManagedBy" = "nowvertical"
    "Project" = "datacatalyst"
    "ResourceGroupType" = "Source"
    "Solution" = "data-integration"
    "Tier" = "source"
}

# Resource groups to check
$resourceGroups = @(
    @{
        Name = "datacatalyst-demo-dev-core-test-rg"
        ExpectedTags = $coreTags
    },
    @{
        Name = "datacatalyst-demo-dev-source-test-rg"
        ExpectedTags = $sourceTags
    }
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Tag Verification Report" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Checking all resources for complete tag coverage...`n"

$totalResources = 0
$resourcesWithAllTags = 0
$resourcesWithMissingTags = 0
$allIssues = @()

foreach ($rg in $resourceGroups) {
    Write-Host "`nChecking Resource Group: $($rg.Name)" -ForegroundColor Yellow
    Write-Host "Expected tags:" -ForegroundColor Gray
    $rg.ExpectedTags.GetEnumerator() | ForEach-Object {
        Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor Gray
    }
    
    # Get all resources in the resource group
    $resources = az resource list --resource-group $rg.Name --query "[].{name:name, type:type, id:id}" | ConvertFrom-Json
    
    if ($resources.Count -eq 0) {
        Write-Host "  No resources found in this resource group." -ForegroundColor Yellow
        continue
    }
    
    Write-Host "`n  Found $($resources.Count) resources" -ForegroundColor Green
    
    foreach ($resource in $resources) {
        $totalResources++
        Write-Host "`n  Checking: $($resource.name)" -ForegroundColor White
        Write-Host "    Type: $($resource.type)" -ForegroundColor Gray
        
        # Get current tags for the resource
        $currentTags = az tag list --resource-id $resource.id --query "properties.tags" | ConvertFrom-Json
        
        $missingTags = @()
        $incorrectTags = @()
        
        # Check each expected tag
        foreach ($expectedTag in $rg.ExpectedTags.GetEnumerator()) {
            if (-not $currentTags.PSObject.Properties[$expectedTag.Key]) {
                $missingTags += $expectedTag.Key
            }
            elseif ($currentTags.$($expectedTag.Key) -ne $expectedTag.Value) {
                $incorrectTags += @{
                    Key = $expectedTag.Key
                    Expected = $expectedTag.Value
                    Actual = $currentTags.$($expectedTag.Key)
                }
            }
        }
        
        # Check for extra tags (not in expected list)
        $extraTags = @()
        if ($currentTags) {
            $currentTags.PSObject.Properties | ForEach-Object {
                if (-not $rg.ExpectedTags.ContainsKey($_.Name)) {
                    $extraTags += $_.Name
                }
            }
        }
        
        # Report findings
        if ($missingTags.Count -eq 0 -and $incorrectTags.Count -eq 0) {
            Write-Host "    ✓ All tags present and correct" -ForegroundColor Green
            $resourcesWithAllTags++
        }
        else {
            $resourcesWithMissingTags++
            
            if ($missingTags.Count -gt 0) {
                Write-Host "    ✗ Missing tags: $($missingTags -join ', ')" -ForegroundColor Red
                $allIssues += @{
                    ResourceGroup = $rg.Name
                    ResourceName = $resource.name
                    ResourceType = $resource.type
                    Issue = "Missing tags"
                    Details = $missingTags -join ', '
                }
            }
            
            if ($incorrectTags.Count -gt 0) {
                Write-Host "    ✗ Incorrect tag values:" -ForegroundColor Red
                foreach ($incorrect in $incorrectTags) {
                    Write-Host "      - $($incorrect.Key): Expected '$($incorrect.Expected)', but found '$($incorrect.Actual)'" -ForegroundColor Red
                    $allIssues += @{
                        ResourceGroup = $rg.Name
                        ResourceName = $resource.name
                        ResourceType = $resource.type
                        Issue = "Incorrect tag value"
                        Details = "$($incorrect.Key): Expected '$($incorrect.Expected)', but found '$($incorrect.Actual)'"
                    }
                }
            }
        }
        
        if ($extraTags.Count -gt 0) {
            Write-Host "    ℹ Extra tags (not in standard set): $($extraTags -join ', ')" -ForegroundColor Yellow
        }
    }
}

# Summary Report
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Summary Report" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total resources checked: $totalResources" -ForegroundColor White
Write-Host "Resources with all correct tags: $resourcesWithAllTags" -ForegroundColor Green
Write-Host "Resources with issues: $resourcesWithMissingTags" -ForegroundColor $(if ($resourcesWithMissingTags -gt 0) { "Red" } else { "Green" })

if ($allIssues.Count -gt 0) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Issues Found" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Cyan
    
    $allIssues | Group-Object -Property Issue | ForEach-Object {
        Write-Host "`n$($_.Name):" -ForegroundColor Yellow
        $_.Group | ForEach-Object {
            Write-Host "  - $($_.ResourceName) ($($_.ResourceType))" -ForegroundColor White
            Write-Host "    Resource Group: $($_.ResourceGroup)" -ForegroundColor Gray
            Write-Host "    Details: $($_.Details)" -ForegroundColor Gray
        }
    }
    
    # Generate fix commands
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Fix Commands" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "To fix the missing or incorrect tags, run the Apply-Tags.ps1 script again:"
    Write-Host "  ./scripts/Apply-Tags.ps1" -ForegroundColor Green
}
else {
    Write-Host "`n✅ All resources have the complete set of common tags!" -ForegroundColor Green
}

# Compliance percentage
$compliancePercentage = if ($totalResources -gt 0) { 
    [math]::Round(($resourcesWithAllTags / $totalResources) * 100, 2) 
} else { 
    0 
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Tag Compliance: $compliancePercentage%" -ForegroundColor $(if ($compliancePercentage -eq 100) { "Green" } else { "Yellow" })
Write-Host "========================================`n" -ForegroundColor Cyan
