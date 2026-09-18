<#
.SYNOPSIS
    Root runner for Budget Tracker setup.
#>
param (
    [switch]$Run,
    [string]$Device = "chrome"
)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& "$scriptDir\budget_tracker\scripts\setup.ps1" -Run:$Run -Device $Device
