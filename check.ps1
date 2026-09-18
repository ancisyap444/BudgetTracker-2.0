<#
.SYNOPSIS
    Root runner for Budget Tracker quality checks.
#>
param (
    [switch]$InstallHook,
    [switch]$BuildCheck
)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& "$scriptDir\budget_tracker\scripts\check.ps1" -InstallHook:$InstallHook -BuildCheck:$BuildCheck
