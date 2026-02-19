#!/usr/bin/env pwsh

function Test-CommandExists {
    param([string]$Command)
    $exists = $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
    if (-not $exists) {
        Write-Error "Error: $Command is required but not installed."
        exit 1
    }
}

Test-CommandExists -Command "wget"

$doc_id = Read-Host "Eisage Thema"
$thema_check = Read-Host "Des thema[y/N]"
$photo_check = Read-Host "Katevase fotografia[y/N]"
$down_check = Read-Host "Katevase thema[y/N]"

if ($doc_id -notmatch "^[0-9]+$") {
    Write-Error "Error: lathos ID"
    exit 1
}

$downloaded_file = "document_${doc_id}.pdf"

Write-Host "Downloading thema: $doc_id..."
wget -q --show-progress -O "$downloaded_file" "https://trapeza.iep.edu.gr/public/showfile.php/?id=${doc_id}&filetype=subject"

if ($LASTEXITCODE -ne 0 -or -not (Test-Path $downloaded_file)) {
    Write-Error "Error: Failed to download thema"
    exit 1
}

if ($thema_check -eq "y") {
    # tdf removed - user can manually process PDF if needed
}

if ($photo_check -eq "y") {
    $outputDir = "$env:USERPROFILE\Desktop\trapeza"
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    pdfimages -all $downloaded_file "$outputDir\document_${doc_id}"
}

if ($down_check -ne "y") {
    Remove-Item $downloaded_file
}
