<#
.SYNOPSIS
    Automated one-click setup script for Budget Tracker.
.DESCRIPTION
    Verifies development environment (Flutter, Dart), downloads packages,
    initializes local configuration, and runs verification checks.
#>

param (
    [switch]$Run,
    [string]$Device = "chrome"
)

$ErrorActionPreference = "Stop"
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "    BUDGET TRACKER - AUTOMATED SETUP         " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# 1. Verify Flutter CLI
Write-Host "[1/5] Checking Flutter SDK installation..." -ForegroundColor Yellow
$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterCmd) {
    Write-Host "ERROR: Flutter is not found in your PATH." -ForegroundColor Red
    Write-Host "Please install Flutter from https://flutter.dev and add it to your PATH." -ForegroundColor Red
    exit 1
}
$flutterVersion = flutter --version | Select-Object -First 1
Write-Host "Found Flutter: $flutterVersion" -ForegroundColor Green

# 2. Navigate to project root
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent $scriptDir
if (-not (Test-Path "$projectDir\pubspec.yaml")) {
    $projectDir = "$scriptDir\budget_tracker"
}
Set-Location $projectDir
Write-Host "[2/5] Project directory: $projectDir" -ForegroundColor Yellow

# 3. Install packages
Write-Host "[3/5] Resolving dependencies (flutter pub get)..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: flutter pub get failed." -ForegroundColor Red
    exit 1
}
Write-Host "Dependencies successfully installed." -ForegroundColor Green

# 4. Code Quality & Linter check
Write-Host "[4/5] Running static code analysis..." -ForegroundColor Yellow
flutter analyze --no-fatal-infos
if ($LASTEXITCODE -ne 0) {
    Write-Host "WARNING: Issues found during flutter analyze." -ForegroundColor Yellow
} else {
    Write-Host "Zero issues found! Codebase is healthy." -ForegroundColor Green
}

# 5. Run Verification Suite
Write-Host "[5/5] Running verification test suite..." -ForegroundColor Yellow
dart run test/verify_runner.dart
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Test suite failed." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "    SETUP COMPLETE! READY TO RUN             " -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host "Run with Chrome:   flutter run -d chrome"
Write-Host "Run with Windows:  flutter run -d windows"
Write-Host "Run with Edge:     flutter run -d edge"
Write-Host ""

if ($Run) {
    Write-Host "Launching app on device: $Device..." -ForegroundColor Cyan
    flutter run -d $Device
}
