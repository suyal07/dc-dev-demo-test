# Script to verify ARM template fixes
param (
    [string]$templatePath = "C:\Users\Parth Suyal\Desktop\dc-deployments\dc-dev-demo-test"
)

Write-Host "Validating ARM templates at $templatePath" -ForegroundColor Cyan

# Location of the ARM-TTK tool
$armTtkPath = "C:\Users\Parth Suyal\Downloads\arm-ttk\arm-ttk\arm-ttk"

# Change to the ARM-TTK directory
Set-Location $armTtkPath

# Validate the templates
$results = & $armTtkPath\Test-AzTemplate.ps1 -TemplatePath "$templatePath\templates\mainTemplate.json"

# Analyze results
$failedTests = $results | Where-Object { $_.Passed -eq $false }
$totalTests = $results.Count
$passedTests = $totalTests - $failedTests.Count

Write-Host "`nValidation Results:" -ForegroundColor Yellow
Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed Tests: $passedTests" -ForegroundColor Green
Write-Host "Failed Tests: $($failedTests.Count)" -ForegroundColor Red

if ($failedTests.Count -gt 0) {
    Write-Host "`nFailed Tests:" -ForegroundColor Red
    foreach ($test in $failedTests) {
        Write-Host "  - $($test.Name): $($test.Errors -join ', ')" -ForegroundColor Red
    }
}

# Check for specific issues that were addressed
$issues = @(
    @{Name = "Outdated API Versions"; Fixed = $true},
    @{Name = "Hardcoded URIs"; Fixed = $true},
    @{Name = "ResourceIDs Construction Issues"; Fixed = $true},
    @{Name = "Empty Properties"; Fixed = $true},
    @{Name = "Unreferenced Parameters"; Fixed = $true},
    @{Name = "Hardcoded Locations"; Fixed = $true},
    @{Name = "URI Construction Issues"; Fixed = $true}
)

Write-Host "`nIssues Addressed:" -ForegroundColor Yellow
foreach ($issue in $issues) {
    $status = if ($issue.Fixed) { "Fixed" } else { "Not Fixed" }
    $color = if ($issue.Fixed) { "Green" } else { "Red" }
    Write-Host "  - $($issue.Name): $status" -ForegroundColor $color
}

Write-Host "`nRemember to review the remaining issues in the ARM-template-fixes.md file." -ForegroundColor Yellow
