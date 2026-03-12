#!/usr/bin/env pwsh
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Ensure-PopplerTools {
    $needed = @("pdfimages","pdfunite")

    foreach ($cmd in $needed) {
        if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
            Write-Host "Installing Poppler (requires admin)…"
            Start-Process -Verb RunAs winget install -e --id oschwartz10612.Poppler -Wait
            break
        }
    }

    foreach ($cmd in $needed) {
        if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
            Throw "Required tool '$cmd' not found even after install."
        }
    }
}
Ensure-PopplerTools

$form = New-Object System.Windows.Forms.Form
$form.Text = "τράπεζα θεμάτων downloader"
$form.Size = New-Object System.Drawing.Size(320, 380)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

$lblId = New-Object System.Windows.Forms.Label
$lblId.Text = "ΘΕΜΑΤΑ:"
$lblId.Location = New-Object System.Drawing.Point(20, 20)
$lblId.AutoSize = $true

$txtId = New-Object System.Windows.Forms.TextBox
$txtId.Location = New-Object System.Drawing.Point(20, 40)
$txtId.Size = New-Object System.Drawing.Size(260, 20)

function New-ToggleButton($text, $x, $y) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $text
    $btn.Location = New-Object System.Drawing.Point($x, $y)
    $btn.Size = New-Object System.Drawing.Size(260, 35)
    $btn.BackColor = [System.Drawing.Color]::LightGray
    $btn.FlatStyle = "Flat"
    $btn.Tag = $false
    $btn.Add_Click({
        if ($this.Tag -eq $false) {
            $this.Tag = $true
            $this.BackColor = [System.Drawing.Color]::SteelBlue
            $this.ForeColor = [System.Drawing.Color]::White
        } else {
            $this.Tag = $false
            $this.BackColor = [System.Drawing.Color]::LightGray
            $this.ForeColor = [System.Drawing.Color]::Black
        }
    })
    return $btn
}

$btn1 = New-ToggleButton "φωτογραφία" 20 90
$btn2 = New-ToggleButton "προβολή"    20 135
$btn3 = New-ToggleButton "λήψη"       20 180
$btn4 = New-ToggleButton "συγχώνευση" 20 225
$btn5 = New-ToggleButton "λύση" 20 270

$btnOK = New-Object System.Windows.Forms.Button
$btnOK.Text = "OK"
$btnOK.Location = New-Object System.Drawing.Point(20, 315)
$btnOK.Size = New-Object System.Drawing.Size(260, 30)
$btnOK.Add_Click({
    $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Close()
})

$form.Controls.AddRange(@($lblId, $txtId, $btn1, $btn2, $btn3, $btn4, $btn5, $btnOK))
if ($form.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
    exit 0
}

$raw_input    = $txtId.Text.Trim()
$photo_check  = [bool]$btn1.Tag
$view_check   = [bool]$btn2.Tag
$down_check   = [bool]$btn3.Tag
$merge_check  = [bool]$btn4.Tag
$solution_check = [bool]$btn5.Tag
# Parse and validate all IDs
$doc_ids = $raw_input -split '\s+' | Where-Object { $_ -ne '' }

if ($doc_ids.Count -eq 0) {
    exit 1
}

foreach ($id in $doc_ids) {
    if ($id -notmatch "^[0-9]+$") {
        exit 1
    }
}

$outputDir1 = "$env:USERPROFILE\Desktop\trapeza\documents"
if (-not (Test-Path $outputDir1)) {
    New-Item -ItemType Directory -Path $outputDir1 -Force | Out-Null
}

$downloaded_subjects = @()
$downloaded_solutions = @()
$pair_files = @()

foreach ($doc_id in $doc_ids) {

    $subject = "$outputDir1\subject_${doc_id}.pdf"
    $solution = "$outputDir1\solution_${doc_id}.pdf"

    try {


        Invoke-WebRequest `
            -Uri "https://trapeza.iep.edu.gr/public/showfile.php/?id=${doc_id}&filetype=subject" `
            -OutFile $subject `
            -ErrorAction Stop

        $downloaded_subjects += $subject

        if ($solution_check) {


            Invoke-WebRequest `
                -Uri "https://trapeza.iep.edu.gr/public/showfile.php/?id=${doc_id}&filetype=solution" `
                -OutFile $solution `
                -ErrorAction Stop

            $downloaded_solutions += $solution

            $pair = "$outputDir1\pair_${doc_id}.pdf"

            & pdfunite $subject $solution $pair

            if ($LASTEXITCODE -ne 0) { exit 1 }

            $pair_files += $pair
        }

    } catch {
        exit 1
    }
}
# Merge if requested (requires qpdf)
$view_target = $null

if ($solution_check) {

    $targets = $pair_files

} else {

    $targets = $downloaded_subjects

}

if ($merge_check -and $targets.Count -gt 1) {

    $ids_joined = $doc_ids -join "_"
    $merged_file = "$outputDir1\merged_${ids_joined}.pdf"

    & pdfunite @targets $merged_file

    if ($LASTEXITCODE -ne 0) { exit 1 }

    $view_target = $merged_file

} else {

    $view_target = $targets[0]

}

if ($view_check -and $view_target) {
    Start-Process $view_target
    Start-Sleep -Seconds 5
}

if ($photo_check) {
    $outputDir = "$env:USERPROFILE\Desktop\trapeza\photos"
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    foreach ($f in $downloaded_files) {
        $base = [System.IO.Path]::GetFileNameWithoutExtension($f)
        pdfimages -all $f "$outputDir\$base"
    }
}

if (-not $down_check) {

    foreach ($f in $downloaded_subjects) { Remove-Item $f -ErrorAction SilentlyContinue }
    foreach ($f in $downloaded_solutions) { Remove-Item $f -ErrorAction SilentlyContinue }
    foreach ($f in $pair_files) { Remove-Item $f -ErrorAction SilentlyContinue }

    if ($merged_file) {
        Remove-Item $merged_file -ErrorAction SilentlyContinue
    }
}
