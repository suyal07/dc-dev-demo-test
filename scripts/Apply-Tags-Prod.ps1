# Apply-Tags-Prod.ps1
# Final optimized script with timeout protection, safety checks, and managed environment handling

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "FINAL Production Resource Tagging Script" -ForegroundColor Cyan
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

# Resource types that commonly don't support tagging - skip these
$skipResourceTypes = @(
    "Microsoft.Sql/servers/databases/schemas",
    "Microsoft.Sql/servers/databases/tables",
    "Microsoft.Sql/servers/databases/master",
    "Microsoft.App/managedEnvironments/certificates",
    "Microsoft.ContainerRegistry/registries/webhooks",
    "Microsoft.Web/sites/slots"
)

# SPECIFIC PRODUCTION resource groups to tag
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
$skippedResources = 0

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
    
    # Collect managed environments for a post-pass, tag others inline
    $managedEnvs = @()
    foreach ($resource in $resources) {
        $totalResources++
        Write-Host "`n    🏷️ Tagging: $($resource.name)" -ForegroundColor White
        Write-Host "       Type: $($resource.type)" -ForegroundColor Gray

        # Defer managed environment tagging to a post-pass
        if ($resource.type -eq 'Microsoft.App/managedEnvironments') {
            $managedEnvs += @{ Name = $resource.name; ResourceGroup = $rg.Name }
            Write-Host "       ⏭️ Deferred: Will tag managed environment in post-pass" -ForegroundColor Yellow
            continue
        }
        
        # Check if this resource type should be skipped
        if ($skipResourceTypes -contains $resource.type) {
            Write-Host "       ⏭️ Skipping: Resource type doesn't support tagging" -ForegroundColor Yellow
            $skippedResources++
            continue
        }
        
        # Build tag pairs in the format key=value for Azure CLI
        $tagPairs = @()
        foreach ($tag in $rg.Tags.GetEnumerator()) {
            $tagPairs += "$($tag.Key)=$($tag.Value)"
        }

        try {
            # Apply ALL tags at once - with timeout protection
            $job = Start-Job -ScriptBlock {
                param($resourceId, $tags)
                # Suppress normal output so only the exit code is returned
                $null = az resource tag --ids $resourceId --tags $tags -o none --only-show-errors 2>$null
                return $LASTEXITCODE
            } -ArgumentList $resource.id, $tagPairs
            
            # Wait for job completion with 30 second timeout
            $completed = Wait-Job -Job $job -Timeout 30
            if ($completed) {
                $exitCode = Receive-Job -Job $job
                Remove-Job -Job $job
                
                # Handle case where Receive-Job might return an array
                if ($exitCode -is [System.Array]) { $exitCode = $exitCode[-1] }
                
                if ($exitCode -eq 0) {
                    Write-Host "       ✅ Applied all $($rg.Tags.Count) tags successfully" -ForegroundColor Green
                    $successfullyTagged++
                } else {
                    Write-Host "       ❌ Failed to apply tags (exit code: $exitCode)" -ForegroundColor Red
                    $failedToTag++
                }
            } else {
                Write-Host "       ⏱️ Timeout after 30 seconds - likely unsupported resource type" -ForegroundColor Yellow
                Remove-Job -Job $job -Force
                $skippedResources++
            }
        }
        catch {
            Write-Host "       ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
            $failedToTag++
        }
        
        # Small delay between resources
        Start-Sleep -Milliseconds 200
    }

    # Post-pass: tag collected managed environments
    if ($managedEnvs.Count -gt 0) {
        Write-Host "\n    🔄 Post-pass: Tagging managed environments (${($managedEnvs.Count)})" -ForegroundColor Cyan
        $tagPairsME = @()
        foreach ($tag in $rg.Tags.GetEnumerator()) { $tagPairsME += "$($tag.Key)=$($tag.Value)" }
        foreach ($me in $managedEnvs) {
            Write-Host "       Managed Environment: $($me.Name)" -ForegroundColor White
            $azArgs = @('containerapp','env','update','-g',$me.ResourceGroup,'-n',$me.Name,'--tags') + $tagPairsME + @('-o','none','--only-show-errors')
            $null = & az @azArgs
            if ($LASTEXITCODE -eq 0) {
                Write-Host "       ✅ Tagged managed environment successfully" -ForegroundColor Green
                $successfullyTagged++
            } else {
                Write-Host "       ❌ Failed to tag managed environment" -ForegroundColor Red
                $failedToTag++
            }
            Start-Sleep -Milliseconds 200
        }
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
Write-Host "  ⏭️ Skipped (unsupported): $skippedResources" -ForegroundColor Yellow
Write-Host "  ❌ Failed to tag: $failedToTag" -ForegroundColor $(if ($failedToTag -gt 0) { "Red" } else { "Green" })

$taggedPercentage = if ($totalResources -gt 0) { [math]::Round(($successfullyTagged / ($totalResources - $skippedResources)) * 100, 1) } else { 0 }
Write-Host "  📈 Success rate: $taggedPercentage%" -ForegroundColor $(if ($taggedPercentage -ge 90) { "Green" } elseif ($taggedPercentage -ge 70) { "Yellow" } else { "Red" })

if ($failedToTag -eq 0 -and $successfullyTagged -gt 0) {
    Write-Host "`n🎉 PRODUCTION TAGGING COMPLETED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "   All supported production resources have been tagged according to standards." -ForegroundColor Green
} elseif ($totalResources -eq 0) {
    Write-Host "`n⚠️ NO RESOURCES FOUND IN PRODUCTION RESOURCE GROUPS" -ForegroundColor Yellow
    Write-Host "   Verify that the production resource groups exist and contain resources." -ForegroundColor Yellow
} else {
    Write-Host "`n✅ PRODUCTION TAGGING COMPLETED WITH MIXED RESULTS" -ForegroundColor Yellow
    Write-Host "   Most resources were tagged successfully. Some may need manual verification." -ForegroundColor Yellow
}

Write-Host "`n📋 Next step: Run './scripts/Verify-Tags-Prod.ps1' to validate tag compliance" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan
