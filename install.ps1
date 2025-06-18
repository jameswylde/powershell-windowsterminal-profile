#Requires -RunAsAdministrator
#Requires -Version 7.0

<#
.SYNOPSIS
    Automated install script for Powershell & Windows terminal

.DESCRIPTION
    Installs and configures a PS7, Windows Terminal, and various PowerShell modules and fonts - baseline for winget installs

.PARAMETER SkipModules
    Skip PowerShell module installation (default: $false)

.EXAMPLE
    .\Install.ps1
    Run standard installation

.EXAMPLE
    .\Install.ps1 -SkipModules
    Run installation without PowerShell modules installs
#>

[CmdletBinding()]
param(
    [ValidateSet('Install','Uninstall')]
    [string]$Mode = 'Install',
    [switch]$SkipModules,
    [switch]$Interactive
)

# Global configuration
$script:Config = @{
    BackupPath = "$env:USERPROFILE\PowerShellSetupBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    AssetsPath = "$env:USERPROFILE\AppData\Local\PowerShellTerminalAssets"
}

# Logging functions
function Write-StatusLine {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [ValidateSet('Success', 'Error', 'AlreadyInstalled')]
        [string]$Status,
        [switch]$IsSubStep,
        [string]$AdditionalInfo = ""
    )

    # Fixed width for all lines
    $totalWidth = 70
    $prefix = if ($IsSubStep) { "      └─ " } else { "" }
    $fullMessage = "$prefix$Message"

    # statuses
    $baseStatusText = switch ($Status) {
        'Success' { "✓" }
        'Error' { "✗" }
        'AlreadyInstalled' { "✓" }
    }

    $statusText = $baseStatusText
    if ($AdditionalInfo -and $Status -eq 'AlreadyInstalled') {
        $statusText += " ($AdditionalInfo)"
    }

    # Calculate the position where status should start (same for all lines)
    $statusStartPos = $totalWidth - $baseStatusText.Length

    # Calculate dots needed to reach that position
    $dotsNeeded = $statusStartPos - $fullMessage.Length
    if ($dotsNeeded -lt 1) { $dotsNeeded = 1 }
    $dots = "." * $dotsNeeded

    $messageColor = if ($IsSubStep) { 'DarkGray' } else { 'White' }
    Write-Host $fullMessage -NoNewline -ForegroundColor $messageColor

    Write-Host $dots -NoNewline -ForegroundColor DarkGray

    $statusColor = switch ($Status) {
        'Success' { 'Green' }
        'Error' { 'Red' }
        'AlreadyInstalled' { 'Green' }
    }
    Write-Host $statusText -ForegroundColor $statusColor
}

function Install-WinGet {
    Write-Host ""
    Write-Host "    Installing WinGet package manager" -NoNewline -ForegroundColor White
    $dots = "." * (70 - "    Installing WinGet package manager".Length - 2)
    Write-Host $dots -NoNewline -ForegroundColor DarkGray

    try {
        $hasPackageManager = Get-AppPackage -Name "Microsoft.DesktopAppInstaller" -ErrorAction SilentlyContinue
        $hasWingetExe = Test-Path "C:\Users\$env:Username\AppData\Local\Microsoft\WindowsApps\winget.exe"

        if (-not $hasPackageManager -or -not $hasWingetExe) {
            $releases_url = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $releases = Invoke-RestMethod -Uri $releases_url -ErrorAction Stop
            $latestRelease = $releases.assets | Where-Object { $_.browser_download_url.EndsWith("msixbundle") } | Select-Object -First 1

            if (-not $latestRelease) {
                throw "Could not find WinGet"
            }

            Add-AppxPackage -Path $latestRelease.browser_download_url -ErrorAction Stop
            Write-Host " ✓" -ForegroundColor Green
        } else {
            Write-Host " ✓ (Already installed)" -ForegroundColor Green
        }

        return $true
    }
    catch {
        Write-Host " ✗" -ForegroundColor Red
        return $false
    }
}

function Install-WindowsTerminal {
    Write-Host "    Installing Windows Terminal" -NoNewline -ForegroundColor White
    $dots = "." * (70 - "    Installing Windows Terminal".Length - 2)
    Write-Host $dots -NoNewline -ForegroundColor DarkGray

    try {
        $hasWindowsTerminal = Get-AppPackage -Name "Microsoft.WindowsTerminal" -ErrorAction SilentlyContinue

        if (-not $env:WT_SESSION -or -not $hasWindowsTerminal) {
            $result = winget install --id=Microsoft.WindowsTerminal -e --accept-package-agreements --accept-source-agreements --silent
            # seems -1978335189 is the "alrady installed" exit code from WinGet so will skip if we get that
            if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne -1978335189) {
                throw "WinGet installation failed with exit code $LASTEXITCODE"
            }
            Write-Host " ✓" -ForegroundColor Green
        } else {
            Write-Host " ✓ (Already installed)" -ForegroundColor Green
        }

        return $true
    }
    catch {
        Write-Host " ✗" -ForegroundColor Red
        return $false
    }
}

function Install-Fonts {
    Write-Host "    Installing Nerd Fonts" -NoNewline -ForegroundColor White
    $dots = "." * (70 - "    Installing Nerd Fonts".Length - 2)
    Write-Host $dots -NoNewline -ForegroundColor DarkGray

    try {
        $fontsToInstallDirectory = ".\assets\fonts\"

        if (-not (Test-Path $fontsToInstallDirectory)) {
            return $false
        }

        $fontsToInstall = Get-ChildItem "$fontsToInstallDirectory*.ttf" -ErrorAction SilentlyContinue
        if (-not $fontsToInstall) {
            return $false
        }

        # Use system fonts directory for installation
        $systemFontsDir = "$env:WINDIR\Fonts"
        $userFontsDir = "$env:USERPROFILE\AppData\Local\Microsoft\Windows\Fonts"

        if (-not (Test-Path $userFontsDir)) {
            New-Item -Path $userFontsDir -ItemType Directory -Force | Out-Null
        }

        $installedCount = 0
        foreach ($font in $fontsToInstall) {
            $fontName = $font.Name
            $fontPath = $font.FullName

            # Check if fonts are already installed
            $systemFontExists = Test-Path "$systemFontsDir\$fontName"
            $userFontExists = Test-Path "$userFontsDir\$fontName"

            if (-not $systemFontExists -and -not $userFontExists) {
                try {
                    # Try system installation first
                    Copy-Item $fontPath -Destination $systemFontsDir -Force -ErrorAction Stop

                    # Register font in registry
                    $fontDisplayName = [System.IO.Path]::GetFileNameWithoutExtension($fontName)
                    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
                    New-ItemProperty -Path $regPath -Name "$fontDisplayName (TrueType)" -Value $fontName -PropertyType String -Force | Out-Null

                    $installedCount++
                }
                catch {
                    # Fallback to user installation if abive fails
                    try {
                        Copy-Item $fontPath -Destination $userFontsDir -Force

                        # Register font in user registry
                        $fontDisplayName = [System.IO.Path]::GetFileNameWithoutExtension($fontName)
                        $regPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
                        if (-not (Test-Path $regPath)) {
                            New-Item -Path $regPath -Force | Out-Null
                        }
                        New-ItemProperty -Path $regPath -Name "$fontDisplayName (TrueType)" -Value "$userFontsDir\$fontName" -PropertyType String -Force | Out-Null

                        $installedCount++
                    }
                    catch {
                    }
                }
            }
        }

        if ($installedCount -gt 0) {
            Write-Host " ✓" -ForegroundColor Green
        } else {
            Write-Host " ✓ (Already installed)" -ForegroundColor Green
        }

        return $true
    }
    catch {
        Write-Host " ✗" -ForegroundColor Red
        return $false
    }
}

function Set-PSRepository {
    #Write-Host "Configuring PowerShell Gallery as trusted repository" -NoNewline -ForegroundColor White
    #$dots = "." * (70 - "Configuring PowerShell Gallery as trusted repository".Length - 2)
    #Write-Host $dots -NoNewline -ForegroundColor DarkGray
    
    try {
        # Check if PSGallery is already trusted
        $psGallery = Get-PSRepository -Name 'PSGallery' -ErrorAction SilentlyContinue
        if ($psGallery -and $psGallery.InstallationPolicy -eq 'Trusted') {
            #Write-Host " ✓ (Already trusted)" -ForegroundColor Green
            return $true
        }

        # Check if NuGet already available
        $nugetProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
        if (-not $nugetProvider) {
            $job = Start-Job -ScriptBlock {
                Install-PackageProvider -Name NuGet -Force -Scope CurrentUser -Confirm:$false
            }

            $completed = Wait-Job $job -Timeout 60
            if ($completed) {
                Receive-Job $job | Out-Null
                Remove-Job $job -Force
            } else {
                Remove-Job $job -Force
                throw "NuGet provider installation timed out after 60 seconds"
            }
        }

        # Set PSGallery as trusted
        $job = Start-Job -ScriptBlock {
            Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
        }

        $completed = Wait-Job $job -Timeout 60
        if ($completed) {
            Receive-Job $job | Out-Null
            Remove-Job $job -Force
            #Write-Host " ✓" -ForegroundColor Green
            return $true
        } else {
            Remove-Job $job -Force
            throw "PSGallery configuration timed out after 60 seconds"
        }
    }
    catch {
        Write-Host " ✗" -ForegroundColor Red
        return $false
    }
}

function Install-OhMyPosh {
    Write-Host "    Installing Oh-My-Posh" -NoNewline -ForegroundColor White
    $dots = "." * (70 - "    Installing Oh-My-Posh".Length - 2)
    Write-Host $dots -NoNewline -ForegroundColor DarkGray

    try {
        $result = winget install JanDeDobbeleer.OhMyPosh --accept-package-agreements --accept-source-agreements --silent
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne -1978335189) {
            throw "WinGet installation failed with exit code $LASTEXITCODE"
        }

        # Install my theme
        $themeDest = "C:\Users\$env:Username\AppData\Local\Programs\oh-my-posh\themes"
        if (-not (Test-Path $themeDest)) {
            New-Item -Path $themeDest -ItemType Directory -Force | Out-Null
        }

        $themeSource = ".\configs\oh-my-posh\themes\wylde.omp.json"
        if (Test-Path $themeSource) {
            Copy-Item $themeSource -Destination $themeDest -Force
            # theme installed
        } else {
            # theme not fuond
        }

        Write-Host " ✓" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host " ✗" -ForegroundColor Red
        return $false
    }
}

function Install-PowerShellModules {
    Write-Host "    Installing PowerShell modules" -NoNewline -ForegroundColor White
    $dots = "." * (70 - "    Installing PowerShell modules".Length - 2)
    Write-Host $dots -NoNewline -ForegroundColor DarkGray

    if ($SkipModules) {
        Write-Host " ✓ (Skipped)" -ForegroundColor Green
        return $true
    }

    Write-Host " ✓" -ForegroundColor Green

    $modules = @(
        @{ Name = 'z'; Version = '1.1.3' } # pinned
        @{ Name = 'Terminal-Icons'; Version = $null } # latest is fine
        @{ Name = 'PSReadLine'; Version = '2.2.6'; Prerelease = $true } # pinnde
    )

    try {
        $psExe = "pwsh.exe"

        foreach ($module in $modules) {
            # Check if module is already installed (not sure if useful or not... probably cut)
            $checkCommand = "Get-Module -Name '$($module.Name)' -ListAvailable"
            $existingModule = & $psExe -Command $checkCommand 2>$null

            if ($existingModule) {
                Write-StatusLine "Installing module: $($module.Name)" -Status 'AlreadyInstalled' -IsSubStep -AdditionalInfo "Already installed"
                continue
            }

            # Build installs
            if ($module.Version) {
                $installCommand = "Install-Module -Name '$($module.Name)' -RequiredVersion '$($module.Version)' -Force -Scope CurrentUser -AllowClobber"
            } else {
                $installCommand = "Install-Module -Name '$($module.Name)' -Force -Scope CurrentUser -AllowClobber"
            }

            if ($module.Prerelease) {
                $installCommand += " -AllowPrerelease -SkipPublisherCheck"
            }

            # Execute
            $job = Start-Job -ScriptBlock ([scriptblock]::Create("& '$psExe' -Command `"$installCommand`""))
            $completed = Wait-Job $job -Timeout 300

            if ($completed) {
                #$output = Receive-Job $job
                #$error = Receive-Job $job -ErrorVariable jobErrors
                if ($job.State -eq 'Completed' -and -not $jobErrors) {
                    Write-StatusLine "Installing module: $($module.Name)" -Status 'Success' -IsSubStep
                } else {
                    Write-StatusLine "Installing module: $($module.Name)" -Status 'Error' -IsSubStep
                }
            } else {
                Write-StatusLine "Installing module: $($module.Name)" -Status 'Error' -IsSubStep
            }

            Remove-Job $job -Force
        }

        return $true
    }
    catch {
        Write-Host " ✗" -ForegroundColor Red
        return $false
    }
}

function Set-PowerShellProfile {
    Write-Host "    Configuring PowerShell profile" -NoNewline -ForegroundColor White
    $dots = "." * (70 - "    Configuring PowerShell profile".Length - 2)
    Write-Host $dots -NoNewline -ForegroundColor DarkGray


    try {
        # Backup existing profile
        if (Test-Path $PROFILE) {
            $backupName = "Microsoft.PowerShell_profile.ps1.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            $backupPath = Join-Path (Split-Path $PROFILE) $backupName
            Copy-Item $PROFILE -Destination $backupPath

        }

        # Ensure profile directory exists
        $profileDir = Split-Path $PROFILE
        if (-not (Test-Path $profileDir)) {
            New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
        }

        # Copy new profile
        $profileSource = ".\configs\powershell\Microsoft.PowerShell_profile.ps1"
        if (Test-Path $profileSource) {
            Copy-Item $profileSource -Destination $PROFILE -Force

            # Unblock the profile
            try {
                Unblock-File -Path $PROFILE -ErrorAction SilentlyContinue
            }
            catch {
                # carry on - should probably check if this is needed
            }

            Write-Host " ✓" -ForegroundColor Green
        } else {
            Write-Host " ✗" -ForegroundColor Red
            return $false
        }

        return $true
    }
    catch {
        Write-Host " ✗" -ForegroundColor Red
        return $false
    }
}

function Set-WindowsTerminalConfig {
    Write-Host "    Configuring Windows Terminal" -NoNewline -ForegroundColor White
    $dots = "." * (70 - "    Configuring Windows Terminal".Length - 2)
    Write-Host $dots -NoNewline -ForegroundColor DarkGray

    try {
        # Create assets directory and copy icons - leftovers from my own version with custom profiles and icons, could probably remove the icon assets
        if (-not (Test-Path $script:Config.AssetsPath)) {
            New-Item -Path $script:Config.AssetsPath -ItemType Directory -Force | Out-Null
        }

        $iconsSource = ".\assets\icons"
        if (Test-Path $iconsSource) {
            Get-ChildItem "$iconsSource\*.png" | Copy-Item -Destination $script:Config.AssetsPath -Force
        }

        # build wt paths from user env vars
        $terminalConfigPath = "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
        if (-not (Test-Path $terminalConfigPath)) {
            New-Item -Path $terminalConfigPath -ItemType Directory -Force | Out-Null
        }

        # change paths in settings.json
        $settingsSource = ".\configs\terminal\settings.json"
        if (Test-Path $settingsSource) {
            $settingsContent = Get-Content $settingsSource -Raw | ConvertFrom-Json

            # Update paths to use the assets directory
            foreach ($profile in $settingsContent.profiles.list) {
                if ($profile.icon -and $profile.icon.StartsWith("C:\temp\wt_assets\")) {
                    $iconName = Split-Path $profile.icon -Leaf
                    $profile.icon = Join-Path $script:Config.AssetsPath $iconName
                }
                if ($profile.backgroundImage -and $profile.backgroundImage.StartsWith("C:\temp\wt_assets\")) {
                    $iconName = Split-Path $profile.backgroundImage -Leaf
                    $profile.backgroundImage = Join-Path $script:Config.AssetsPath $iconName
                }
                if ($profile.startingDirectory -eq "C:\Users\") {
                    $profile.startingDirectory = "$env:USERPROFILE\Documents"
                }
            }

            # Update lab script path - probs needs cutting too, leftovers from personal version
            foreach ($profile in $settingsContent.profiles.list) {
                if ($profile.commandline -and $profile.commandline.Contains("C:\temp\lab_az.ps1")) {
                    $profile.commandline = $profile.commandline.Replace("C:\temp\lab_az.ps1", (Join-Path $script:Config.AssetsPath "lab_az.ps1"))
                }
            }

            $settingsContent | ConvertTo-Json -Depth 15 | Out-File (Join-Path $terminalConfigPath "settings.json") -Encoding UTF8
            Write-Host " ✓" -ForegroundColor Green
        } else {
            Write-Host " ✗" -ForegroundColor Red
            return $false
        }

        # see above
        $labScriptSource = ".\scripts\lab_az.ps1"
        if (Test-Path $labScriptSource) {
            Copy-Item $labScriptSource -Destination $script:Config.AssetsPath -Force
        }

        return $true
    }
    catch {
        Write-Host " ✗" -ForegroundColor Red
        return $false
    }
}

# installation function junction
function Start-Installation {
    param([string]$Mode)

    if (-not $Interactive) {
        $confirm = Read-Host "Proceed? (y/n)"
        if ($confirm -notmatch '^[Yy]') {
            return $false
        }
    }

    $steps = @(
        { Install-WinGet },
        { Install-WindowsTerminal },
        { Install-Fonts },
        { Set-PSRepository },
        { Install-OhMyPosh },
        { Install-PowerShellModules },
        { Set-PowerShellProfile },
        { Set-WindowsTerminalConfig }
    )

    $successful = 0
    $total = $steps.Count

    for ($i = 0; $i -lt $steps.Count; $i++) {
        $stepNumber = $i + 1
        Write-Progress -Activity "Running..." -Status "Step $stepNumber of $total" -PercentComplete (($stepNumber / $total) * 100)

        if (& $steps[$i]) {
            $successful++
        } else {
            #
        }
    }

    Write-Progress -Activity "Running..." -Completed

    if ($successful -eq $total) {
        return $true
    } else {
        Write-Host ""
        Write-Host "Installation completed with $($total - $successful) failures. Check log for details." -ForegroundColor Yellow
        return $false
    }
}

# Script entry point
try {
    Clear-Host
    Write-Host "-----------------------------------------------------------------" -ForegroundColor Yellow
    Write-Host "    github.com/jameswylde/powershell-windowsterminal-profile" -ForegroundColor yellow
    Write-Host "-----------------------------------------------------------------" -ForegroundColor Yellow
    Write-Host ""


    $success = Start-Installation -Mode $Mode

    if ($success) {
        Write-Host ""
        Write-Host "-----------------------------------------------------------------" -ForegroundColor Yellow
        Write-Host "    C:\Users\$env:Username\AppData\Local\Programs\oh-my-posh\themes\wylde.omp.json" -ForegroundColor Yellow
        Write-Host "    $env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" -ForegroundColor Yellow
        Write-Host "    $PROFILE" -ForegroundColor Yellow
        Write-Host "-----------------------------------------------------------------" -ForegroundColor Yellow
        Write-Host ""

        exit 0
    } else {
        #Write-Host "`nInstallation completed with some errors" -ForegroundColor Yellow  | useless as print above with no - need to readd logging too
        exit 1
    }
}
catch {
    Write-Host ""
    Write-Host "Installation failed with unexpected error: " -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}