# Installation Guide

## System Requirements

### Minimum Requirements
- **Operating System**: Windows 10 version 1903 or Windows 11
- **PowerShell**: Version 5.1 or higher (PowerShell 7 will be installed if not present)
- **Disk Space**: 500MB free space
- **Memory**: 4GB RAM recommended
- **Network**: Internet connection for downloading components

### Supported Configurations
- Windows 10/11 with Windows Terminal
- Windows Subsystem for Linux (WSL) - optional
- Azure PowerShell environments
- Development workstations and servers

## Pre-Installation Steps

### 1. Verify Prerequisites
```powershell
# Check PowerShell version
$PSVersionTable.PSVersion

# Check OS version
[System.Environment]::OSVersion.Version

# Check execution policy
Get-ExecutionPolicy
```

### 2. Set Execution Policy (if needed)
```powershell
# For current user only (recommended)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or for local machine (requires admin)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

### 3. Run as Administrator
Right-click PowerShell and select "Run as Administrator" - this is required for:
- Installing applications via WinGet
- Installing fonts system-wide
- Modifying system directories

## Installation Methods

### Method 1: Standard Installation
```powershell
# Clone or download the repository
# Navigate to the claude directory
cd path\to\claude

# Run the installer
.\Install.ps1
```

### Method 2: Interactive Installation
```powershell
# Provides customization options during installation
.\Install.ps1 -Interactive
```

### Method 3: Dry Run (Preview Only)
```powershell
# See what would be installed without making changes
.\Install.ps1 -DryRun
```

### Method 4: Selective Installation
```powershell
# Skip PowerShell modules if you want to install them manually
.\Install.ps1 -SkipModules
```

## Installation Process

The installer performs these steps in order:

### Step 1: System Validation
- Checks PowerShell version
- Validates OS compatibility
- Verifies disk space
- Tests internet connectivity
- Confirms administrator privileges

### Step 2: Package Manager Setup
- Installs/updates WinGet if needed
- Configures PSGallery as trusted repository

### Step 3: Core Applications
- Installs PowerShell 7 (if not present)
- Installs Windows Terminal (if not present)
- Installs Oh-My-Posh prompt engine

### Step 4: Fonts and Assets
- Installs CaskaydiaCove Nerd Font
- Copies icon files to assets directory
- Sets up directory structure

### Step 5: PowerShell Configuration
- Backs up existing profile
- Installs enhanced PowerShell profile
- Installs required modules:
  - PSReadLine 2.2.6
  - Terminal-Icons 0.8.0
  - Z 1.1.3

### Step 6: Terminal Configuration
- Configures Windows Terminal settings
- Sets up multiple terminal profiles
- Applies custom color schemes and themes

## Installation Locations

### Application Installations
- **PowerShell 7**: `C:\Program Files\PowerShell\7\`
- **Windows Terminal**: Microsoft Store app location
- **Oh-My-Posh**: `%LOCALAPPDATA%\Programs\oh-my-posh\`

### Configuration Files
- **PowerShell Profile**: `%USERPROFILE%\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`
- **Terminal Settings**: `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_*\LocalState\settings.json`
- **Oh-My-Posh Theme**: `%LOCALAPPDATA%\Programs\oh-my-posh\themes\wylde.omp.json`

### Asset Files
- **Main Assets Directory**: `%USERPROFILE%\AppData\Local\PowerShellTerminalAssets\`
- **Terminal Icons**: `%USERPROFILE%\AppData\Local\PowerShellTerminalAssets\*.png`
- **Lab Scripts**: `%USERPROFILE%\AppData\Local\PowerShellTerminalAssets\lab_az.ps1`

### Fonts
- **User Fonts**: `%USERPROFILE%\AppData\Local\Microsoft\Windows\Fonts\`
- **System Fonts**: `C:\Windows\Fonts\` (if installed system-wide)

## Post-Installation

### 1. Restart Terminal
Close all PowerShell and Windows Terminal windows and reopen them to load the new configuration.

### 2. Verify Installation
Run the test script to ensure everything installed correctly:
```powershell
.\scripts\helpers\Test-Installation.ps1
```

### 3. First Run
The first time you open PowerShell, you may see:
- Oh-My-Posh loading message
- Module import notifications
- Font loading (if running for the first time)

This is normal and subsequent launches will be faster.

## Troubleshooting Installation Issues

### Common Issues and Solutions

#### WinGet Installation Fails
```powershell
# Manually install WinGet from Microsoft Store
# Or download from GitHub releases
# Then re-run: .\Install.ps1 -Mode Repair
```

#### PowerShell Module Installation Timeout
```powershell
# Increase timeout or install modules manually
Install-Module PSReadLine -Force -Scope CurrentUser
Install-Module Terminal-Icons -Force -Scope CurrentUser  
Install-Module z -Force -Scope CurrentUser
```

#### Font Installation Issues
```powershell
# Check if fonts exist in the assets directory
Get-ChildItem .\assets\fonts\

# Manually install fonts through Windows Settings
# Settings > Personalization > Fonts > Drag and drop font files
```

#### Permission Errors
- Ensure running as Administrator
- Check file/folder permissions
- Temporarily disable antivirus if it's blocking installations

#### Windows Terminal Not Found
```powershell
# Install manually from Microsoft Store
# Or use WinGet directly:
winget install Microsoft.WindowsTerminal
```

### Repair Installation
If installation fails or components are missing:
```powershell
.\Install.ps1 -Mode Repair
```

### Clean Reinstall
If you need to start over:
```powershell
# Uninstall first
.\scripts\Uninstall.ps1

# Then reinstall
.\Install.ps1
```

## Enterprise/Organization Deployment

### Silent Installation
For automated deployment across multiple machines:
```powershell
# Run without any user interaction
.\Install.ps1 -Confirm:$false
```

### Customization for Organizations
1. Modify `configs/powershell/Microsoft.PowerShell_profile.ps1` for company standards
2. Update `configs/terminal/settings.json` with corporate branding
3. Replace `configs/oh-my-posh/themes/wylde.omp.json` with company theme
4. Pre-stage the installation files on network shares

### Group Policy Considerations
- Execution Policy settings
- Software installation permissions
- Windows Terminal policy settings
- PowerShell module installation policies

## Security Considerations

### What Gets Downloaded
- WinGet (if not installed): From Microsoft GitHub releases
- PowerShell 7: Via WinGet from Microsoft
- Windows Terminal: Via WinGet from Microsoft Store
- Oh-My-Posh: Via WinGet from official source
- PowerShell Modules: From PowerShell Gallery

### Verification
The installer:
- Uses official package managers (WinGet, PowerShell Gallery)
- Installs only from trusted sources
- Creates backups before modifying configurations
- Logs all actions for audit purposes

### Permissions Required
- Administrator rights for application installation
- File system write access for configuration
- Registry access for font installation
- Network access for downloading components

---

Need help? Check the [troubleshooting guide](troubleshooting.md) or run the test script to identify specific issues.