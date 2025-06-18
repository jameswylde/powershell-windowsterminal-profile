#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Uninstall PowerShell Terminal Setup

.DESCRIPTION
    Removes configurations and restores backups created during installation
    
.PARAMETER RemoveApplications
    Also remove installed applications (PowerShell 7, Windows Terminal, Oh-My-Posh)
    
.EXAMPLE
    .\Uninstall.ps1
    Remove configurations only
    
.EXAMPLE
    .\Uninstall.ps1 -RemoveApplications
    Remove everything including applications
#>

[CmdletBinding()]
param(
    [switch]$RemoveApplications
)

function Write-StatusLine {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('Success', 'Error', 'Warning')]
        [string]$Status,
        
        [string]$AdditionalInfo = ""
    )
    
    # Fixed width for all lines
    $totalWidth = 70
    $fullMessage = $Message
    
    # Calculate status text
    $statusText = switch ($Status) {
        'Success' { "✓" }
        'Error' { "✗" }
        'Warning' { "✓" }
    }
    
    if ($AdditionalInfo) {
        $statusText += " ($AdditionalInfo)"
    }
    
    # Calculate the position where status should start
    $statusStartPos = $totalWidth - $statusText.Length
    
    # Calculate dots needed to reach that position
    $dotsNeeded = $statusStartPos - $fullMessage.Length
    if ($dotsNeeded -lt 1) { $dotsNeeded = 1 }
    $dots = "." * $dotsNeeded
    
    # Write the message part
    Write-Host $fullMessage -NoNewline -ForegroundColor White
    
    # Write the dots
    Write-Host $dots -NoNewline -ForegroundColor DarkGray
    
    # Write the status
    $statusColor = switch ($Status) {
        'Success' { 'Green' }
        'Error' { 'Red' }
        'Warning' { 'Yellow' }
    }
    Write-Host $statusText -ForegroundColor $statusColor
}

function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    switch ($Level) {
        'Info'    { Write-Host $Message -ForegroundColor Cyan }
        'Warning' { Write-Host $Message -ForegroundColor Yellow }
        'Error'   { Write-Host $Message -ForegroundColor Red }
        'Success' { Write-Host $Message -ForegroundColor Green }
    }
}

function Restore-PowerShellProfile {
    Write-Host "Restoring PowerShell profile" -NoNewline -ForegroundColor White
    $dots = "." * (70 - "Restoring PowerShell profile".Length - 2)
    Write-Host $dots -NoNewline -ForegroundColor DarkGray
    
    try {
        $profileDir = Split-Path $PROFILE
        $backupFiles = Get-ChildItem -Path $profileDir -Filter "Microsoft.PowerShell_profile.ps1.backup_*" | Sort-Object LastWriteTime -Descending
        
        if ($backupFiles.Count -gt 0) {
            $latestBackup = $backupFiles[0]
            Copy-Item $latestBackup.FullName -Destination $PROFILE -Force
            Write-Host " ✓ (Restored from backup)" -ForegroundColor Green
        } else {
            Remove-Item $PROFILE -Force -ErrorAction SilentlyContinue
            Write-Host " ✓ (No backup found - removed)" -ForegroundColor Green
        }
    }
    catch {
        Write-Host " ✗" -ForegroundColor Red
    }
}

function Remove-WindowsTerminalConfig {
    Write-Host "Removing Windows Terminal configuration" -NoNewline -ForegroundColor White
    $dots = "." * (70 - "Removing Windows Terminal configuration".Length - 2)
    Write-Host $dots -NoNewline -ForegroundColor DarkGray
    
    try {
        $terminalConfigPath = "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        
        if (Test-Path $terminalConfigPath) {
            $backupPath = "$terminalConfigPath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Move-Item $terminalConfigPath -Destination $backupPath
            Write-Host " ✓ (Backed up)" -ForegroundColor Green
        } else {
            Write-Host " ✓ (Not found)" -ForegroundColor Green
        }
    }
    catch {
        Write-Host " ✗" -ForegroundColor Red
    }
}

function Remove-Assets {
    Write-Host "Removing asset files" -NoNewline -ForegroundColor White
    $dots = "." * (70 - "Removing asset files".Length - 2)
    Write-Host $dots -NoNewline -ForegroundColor DarkGray
    
    try {
        $assetsPath = "$env:USERPROFILE\AppData\Local\PowerShellTerminalAssets"
        $oldAssetsPath = "C:\temp\wt_assets"
        $removed = $false
        
        if (Test-Path $assetsPath) {
            Remove-Item $assetsPath -Recurse -Force
            $removed = $true
        }
        
        if (Test-Path $oldAssetsPath) {
            Remove-Item $oldAssetsPath -Recurse -Force
            $removed = $true
        }
        
        if ($removed) {
            Write-Host " ✓" -ForegroundColor Green
        } else {
            Write-Host " ✓ (Not found)" -ForegroundColor Green
        }
    }
    catch {
        Write-Host " ✗" -ForegroundColor Red
    }
}

function Remove-Applications {
    if (-not $RemoveApplications) {
        Write-Host "Removing applications" -NoNewline -ForegroundColor White
        $dots = "." * (70 - "Removing applications".Length - 2)
        Write-Host $dots -NoNewline -ForegroundColor DarkGray
        Write-Host " ✓ (Skipped)" -ForegroundColor Green
        return
    }
    
    Write-Host "Removing applications" -NoNewline -ForegroundColor White
    $dots = "." * (70 - "Removing applications".Length - 2)
    Write-Host $dots -NoNewline -ForegroundColor DarkGray
    
    try {
        # Remove Oh-My-Posh
        winget uninstall JanDeDobbeleer.OhMyPosh --silent 2>$null
        Write-Host " ✓ (Oh-My-Posh removed)" -ForegroundColor Green
    }
    catch {
        Write-Host " ✗" -ForegroundColor Red
    }
}

# Main uninstall process
try {
    Clear-Host
    Write-Host "Quick start terminal..." -ForegroundColor Green
    Write-Host "https://github.com/jameswylde/powershell-windowsterminal-profile" -ForegroundColor Green
    Write-Host "-----------------------------------------------------------------" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "This will remove the config files." -ForegroundColor Yellow
    if ($RemoveApplications) {
        Write-Host "Removing installed apps too." -ForegroundColor Yellow
    }
    Write-Host ""
    
    $confirm = Read-Host "Continue? (Y/N)"
    if ($confirm -notmatch '^[Yy]') {
        Write-Host "Uninstall cancelled" -ForegroundColor Yellow
        exit 0
    }
    
    Write-Host ""
    Restore-PowerShellProfile
    Remove-WindowsTerminalConfig
    Remove-Assets
    Remove-Applications
    
    Write-Host ""
    Write-Host "You may need to restart your terminal sessions." -ForegroundColor Gray
}
catch {
    Write-Host ""
    Write-Host "Uninstallation failed:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}