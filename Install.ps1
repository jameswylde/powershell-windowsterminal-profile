# github.com/jameswylde
# Installation of Windows Terminal, PS7, Oh-MyPosh, theme, PSModules; Z, PSReadLine, Terminal-Icons, Windows Terminal config

#Requires -RunAsAdministrator

cls; Write-Host "   **************************************   " -ForegroundColor Black -BackgroundColor Yellow; Write-Host "           github.com/jameswylde            " -ForegroundColor Black -BackgroundColor Yellow ; Write-Host "    Please star if you found this useful.   " -ForegroundColor Black -BackgroundColor Yellow ; Write-Host "   **************************************   " -ForegroundColor Black -BackgroundColor Yellow

# Install winget if not present (def on W11)
$hasPackageManager = Get-AppPackage -name "Microsoft.DesktopAppInstaller"
if (!$hasPackageManager) {
    $releases_url = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $releases = Invoke-RestMethod -uri "$($releases_url)"
    $latestRelease = $releases.assets | Where-Object { $_.browser_download_url.EndsWith("msixbundle") } | Select-Object -First 1
    Add-AppxPackage -Path $latestRelease.browser_download_url
}

# Install PS7
Write-Host "`nInstalling Powershell 7 - " -ForegroundColor Yellow -NoNewline; Write-Host "[1-9]" -ForegroundColor Green -BackgroundColor Black
If (!(Test-Path "C:\Program Files\PowerShell\7\pwsh.exe")) {
    winget install --id Microsoft.Powershell --source winget --accept-package-agreements --accept-source-agreements
}
else {
    continue
}

# Install WT
Write-Host "`nInstalling Windows Terminal - " -ForegroundColor Yellow -NoNewline ; Write-Host "[2-9]" -ForegroundColor Green -BackgroundColor Black
if ($env:WT_SESSION) {}
else {
    $choice1 = Read-Host "Install Windows Terminal? [y/n]" 
    switch ($choice1) {
        y {    
            winget install --id=Microsoft.WindowsTerminal -e --accept-package-agreements --accept-source-agreements
        }
        n {continue}
        default {Write-Warning "[y/n] only"}
    }
}

# Install fonts
Write-Host "`nInstalling Caskaydia Cove Nerd fonts - " -ForegroundColor Yellow -NoNewline ; Write-Host "[3-9]" -ForegroundColor Green -BackgroundColor Black
try {
    $shellObject = New-Object -ComObject shell.application
    $fonts = $ShellObject.NameSpace(0x14)
    $fontsToInstallDirectory = ".\fonts\*.ttf"
    $fontsToInstall = Get-ChildItem $fontsToInstallDirectory -Recurse -Include '*.ttf'
    foreach ($f in $fontsToInstall) {
        $fullPath = $f.FullName
        $name = $f.Name
        $userInstalledFonts = "$env:USERPROFILE\AppData\Local\Microsoft\Windows\Fonts"
        if (!(Test-Path "$UserInstalledFonts\$Name")) {
            $Fonts.CopyHere($FullPath)
        }
        else {
            continue
        }
    }
}
catch { Write-Warning $_ }

# Update JSON with user env variables
Write-Host "`nApplying WT.exe settings.json with env variables - " -ForegroundColor Yellow -NoNewline ; Write-Host "[4-9]" -ForegroundColor Green -BackgroundColor Black
$json = Get-Content ".\src\settings.json" | ConvertFrom-Json 
$json.profiles.list[0].startingDirectory = "C:\$env:USERNAME\Documents"
$json | ConvertTo-Json -Depth 15 | Out-File ".\src\setting.json"

# Set PSGallery as trusted
Write-Host "`nSetting PSGallery as trusted repo - " -ForegroundColor Yellow -NoNewline ; Write-Host "[5-9]" -ForegroundColor Green -BackgroundColor Black
Install-PackageProvider -Name NuGet -Force | Out-Null
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

# Oh-My-Posh install, add to default prompt, add theme
Write-Host "`nInstalling Oh-MyPosh & theme - "  -ForegroundColor Yellow -NoNewline ; Write-Host "[6-9]" -ForegroundColor Green -BackgroundColor Black
winget install JanDeDobbeleer.OhMyPosh --accept-package-agreements --accept-source-agreements
try {
    $dest = "C:\Users\$env:Username\AppData\Local\Programs\oh-my-posh\themes"
    if (!(Test-Path -path $dest)) { New-Item $dest -Type Directory }
    Copy-Item ".\src\wylde.omp.json" -Destination $dest
}
catch { Write-Warning $_ }

# Set PS profile
Write-Host "`nApplying Powershell profile - " -ForegroundColor Yellow -NoNewline ; Write-Host "[7-9]" -ForegroundColor Green -BackgroundColor Black
try {
    if (test-path $profile) { Rename-Item $profile -NewName Microsoft.PowerShell_profile.ps1.bak }
}
catch { Write-Warning $_ }
try {
    $dest2 = "C:\Users\$env:Username\Documents\PowerShell"
    [System.IO.Directory]::CreateDirectory($dest2) > $null
    Copy-Item ".\src\Microsoft.PowerShell_profile.ps1" -Destination $dest2 -Force
}
catch { Write-Warning $_ }
try {
    $dest5 = "C:\temp\wt_assets"
    [System.IO.Directory]::CreateDirectory($dest5) > $null
    Get-ChildItem ".\src\icons\" -Recurse -Include '*.png' | Copy-Item -Destination $dest5
}
catch { Write-Warning $_ }

# Install ps modules in PS7
Write-Host "`nInstalling Z,PsReadLine,Terminal-Icons modules - "  -ForegroundColor Yellow -NoNewline ; Write-Host "[8-9]" -ForegroundColor Green -BackgroundColor Black

if ($PSVersionTable.PSVersion.Major -eq 7) {
    try {
        Start-Job -ScriptBlock {
        Install-Module -Name z -RequiredVersion 1.1.3 -Force -Scope CurrentUser -AllowClobber -confirm:$false
        Install-Module -Name Terminal-Icons -RequiredVersion 0.8.0 -Force -Scope CurrentUser -confirm:$false
        Install-Module -Name PSReadLine -RequiredVersion 2.2.6 -Force -AllowPrerelease -Scope CurrentUser -SkipPublisherCheck
        } | Wait-Job | Receive-Job
    }
    catch { Write-Warning $_ }
}
else {
    try {
        Start-Job -ScriptBlock  {
        Start-Process "C:\Program Files\PowerShell\7\pwsh.exe" -ArgumentList { -Command Install-Module -Name z -RequiredVersion 1.1.3 -Force -Scope CurrentUser -AllowClobber -confirm:$false } -NoNewWindow
        Start-Process "C:\Program Files\PowerShell\7\pwsh.exe" -ArgumentList { -Command Install-Module -Name Terminal-Icons -RequiredVersion 0.8.0 -Force -Scope CurrentUser -confirm:$false } -NoNewWindow
        Start-Process "C:\Program Files\PowerShell\7\pwsh.exe" -ArgumentList { -Command Install-Module -Name PSReadLine -RequiredVersion 2.2.6 -Force -AllowPrerelease -Scope CurrentUser -SkipPublisherCheck } -NoNewWindow
        } | Wait-Job | Receive-Job
    }
    catch { Write-Warning $_ }
}

# Set WT settings.json
Write-Host "`nApplying Windows Terminal default settings - " -ForegroundColor Yellow -NoNewline ; Write-Host "[9-9]" -ForegroundColor Green -BackgroundColor Black
try {
    $dest3 = "C:\Users\$env:Username\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\"
    if (!(Test-Path -path $dest3)) { New-Item $dest3 -Type Directory }
    Copy-Item ".\src\settings.json" -Destination $dest3 | Out-Null
}
catch { Write-Warning $_ }
try {
    $dest4 = "C:\Program Files\PowerShell\7"
    if (!(Test-Path -path $dest4)) { New-Item $dest4 -Type Directory }
    Copy-Item ".\src\icons\win.png" -Destination $dest4 | Out-Null
}
catch { Write-Warning $_ }

# Sleep to allow time for jobs in PS7 to complete installing modules - restart WT if you receive any module errors
Start-Sleep -Seconds 30