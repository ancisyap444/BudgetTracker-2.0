<#
.SYNOPSIS
    Automated pre-commit and quality assurance check script.
.DESCRIPTION
    Runs dart format, flutter analyze, automated test suites, and dry-run web build.
    Optionally installs a git pre-commit hook with -InstallHook.
#>

param (
    [switch]$InstallHook,
    [switch]$BuildCheck
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent $scriptDir
if (-not (Test-Path "$projectDir\pubspec.yaml")) {
    $projectDir = "$scriptDir\budget_tracker"
}

# Handle Git Hook installation
if ($InstallHook) {
    Write-Host "Installing pre-commit Git hook..." -ForegroundColor Cyan
    $repoRoot = (git rev-parse --show-toplevel 2>$null)
    if (-not $repoRoot) {
        Write-Host "ERROR: Not inside a git repository." -ForegroundColor Red
        exit 1
    }
    $hookFile = "$repoRoot\.git\hooks\pre-commit"
    $hookContent = @"
#!/bin/sh
echo "Running pre-commit checks..."
pwsh -File "$scriptDir\check.ps1"
if [ `$? -ne 0 ]; then
    echo "Pre-commit checks failed! Aborting commit."
    exit 1
fi
"@
    Set-Content -Path $hookFile -Value $hookContent -NoNewline
    Write-Host "Pre-commit hook successfully installed at: $hookFile" -ForegroundColor Green
    exit 0
}

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "   BUDGET TRACKER - QUALITY ASSURANCE CHECK  " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

Set-Location $projectDir

# 1. Format Check / Auto-format
Write-Host "[1/4] Checking Dart code formatting..." -ForegroundColor Yellow
dart format --line-length 80 lib test
Write-Host "Code formatting complete." -ForegroundColor Green

# 2. Static Analysis
Write-Host "[2/4] Running flutter analyze..." -ForegroundColor Yellow
flutter analyze --no-fatal-infos
if ($LASTEXITCODE -ne 0) {
    Write-Host "FAILED: flutter analyze found issues." -ForegroundColor Red
    exit 1
}
Write-Host "Static analysis passed with 0 issues!" -ForegroundColor Green

# 3. Test Runner
Write-Host "[3/4] Running automated test suite..." -ForegroundColor Yellow
dart run test/verify_runner.dart
if ($LASTEXITCODE -ne 0) {
    Write-Host "FAILED: Test suite failed." -ForegroundColor Red
    exit 1
}
Write-Host "Test suite passed successfully!" -ForegroundColor Green

# 4. Optional Build Verification
if ($BuildCheck) {
    Write-Host "[4/4] Verifying production build (flutter build web)..." -ForegroundColor Yellow
    flutter build web --release
    if ($LASTEXITCODE -ne 0) {
        Write-Host "FAILED: Web build failed." -ForegroundColor Red
        exit 1
    }
    Write-Host "Production web build succeeded!" -ForegroundColor Green
} else {
    Write-Host "[4/4] Skipping full build verification (pass -BuildCheck to enable)." -ForegroundColor Gray
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "   ALL CHECKS PASSED - READY TO COMMIT       " -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
