#!/usr/bin/env pwsh

Write-Host "Installing dependencies for script.ps1..." -ForegroundColor Cyan

$missing = @()

$wget = Get-Command wget -ErrorAction SilentlyContinue
if (-not $wget) {
    $missing += "wget"
}

$pdfimages = Get-Command pdfimages -ErrorAction SilentlyContinue
if (-not $pdfimages) {
    $missing += "poppler-utils"
}

if ($missing.Count -eq 0) {
    Write-Host "All dependencies are already installed!" -ForegroundColor Green
    exit 0
}

Write-Host "Missing dependencies: $($missing -join ', ')" -ForegroundColor Yellow

$os = Get-OSIdentifier

switch ($os) {
    "Debian" -or "Ubuntu" -or "Debian" {
        Write-Host "Detected Debian/Ubuntu-based system" -ForegroundColor Cyan
        Write-Host "Run the following command:" -ForegroundColor Yellow
        Write-Host "sudo apt update && sudo apt install -y wget poppler-utils" -ForegroundColor White
    }
    "RedHat" -or "CentOS" -or "Fedora" {
        Write-Host "Detected RHEL/CentOS/Fedora-based system" -ForegroundColor Cyan
        Write-Host "Run the following command:" -ForegroundColor Yellow
        Write-Host "sudo dnf install -y wget poppler-utils" -ForegroundColor White
    }
    "Arch" {
        Write-Host "Detected Arch Linux" -ForegroundColor Cyan
        Write-Host "Run the following command:" -ForegroundColor Yellow
        Write-Host "sudo pacman -S wget poppler" -ForegroundColor White
    }
    "macOS" {
        Write-Host "Detected macOS" -ForegroundColor Cyan
        Write-Host "Run the following command:" -ForegroundColor Yellow
        Write-Host "brew install wget poppler" -ForegroundColor White
    }
    default {
        Write-Host "Could not detect OS. Install wget and poppler-utils manually." -ForegroundColor Red
    }
}

function Get-OSIdentifier {
    if (Test-Path "/etc/os-release") {
        . "/etc/os-release"
        return $ID
    }
    if (Test-Path "/etc/redhat-release") {
        return "RedHat"
    }
    if ($IsMacOS) {
        return "macOS"
    }
    return "Unknown"
}
