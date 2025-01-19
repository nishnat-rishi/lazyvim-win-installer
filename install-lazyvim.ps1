
# ---------------------------------------
# LazyVim + Dependencies Installer Script
# ---------------------------------------
# Run this script as Administrator in PowerShell (preferably PowerShell 7).
# This script is untested; please tailor to your environment if needed.

# 1. Check for Admin Privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()) `
    .IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Please run this script as Administrator." -ForegroundColor Red
    Exit
}

# 2. Function to check if a command exists
function Test-CommandExists {
    param ($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'silentlycontinue'
    try {
        Get-Command $command -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
    finally {
        $ErrorActionPreference = $oldPreference
    }
}

# 3. Check for winget
if (-not (Test-CommandExists winget)) {
    Write-Host "Winget (App Installer) is not found. Please install it from the Microsoft Store (App Installer) or update Windows." -ForegroundColor Red
    Exit
}

# 4. Array of packages to install via winget
#    Adjust these IDs if winget changes them in the future.
$wingetPackages = @(
    # Terminal + PowerShell
    "Microsoft.WindowsTerminal",
    "Microsoft.PowerShell",

    # Essential Tools
    "Git.Git",
    "TDM-GCC.TDM-GCC",      # For C compiler (treesitter)

    # LazyVim recommended CLI Tools
    "junegunn.fzf",         # fzf
    "BurntSushi.ripgrep",   # ripgrep
    "sharkdp.fd",           # fd
    "JesseDuffield.lazygit",# lazygit

    # Lua Requirements
    "rjpcomputing.luaforwindows",  # Lua 5.1
    "DEVCOM.LuaJIT",               # LuaJIT + Luarocks (2.1)
    
    # Neovim 0.9 (or above)
    "Neovim.Neovim"
)

Write-Host "`n--- Installing packages via winget ---" -ForegroundColor Cyan
foreach ($pkgId in $wingetPackages) {
    Write-Host "Installing/Upgrading: $pkgId ..." -ForegroundColor Yellow
    winget install -e --id $pkgId --accept-source-agreements --accept-package-agreements
    Write-Host ""
}

function Setup-NodeWithNVM {
    Write-Host "`n--- Setting up Node.js with NVM ---" -ForegroundColor Cyan
    
    # Check if NVM is already installed
    if (-not (Test-CommandExists nvm)) {
        Write-Host "NVM not found. Installing NVM..." -ForegroundColor Yellow
        
        # Download and run the NVM installer
        $nvmInstaller = Join-Path $env:TEMP "nvm-setup.exe"
        $nvmUrl = "https://github.com/coreybutler/nvm-windows/releases/latest/download/nvm-setup.exe"
        
        try {
            Invoke-WebRequest -Uri $nvmUrl -OutFile $nvmInstaller
            Start-Process -FilePath $nvmInstaller -ArgumentList "/SILENT" -Wait
            
            # Refresh environment variables
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            
            Write-Host "NVM installation complete. Please restart your terminal after the script finishes." -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to install NVM. Error: $_" -ForegroundColor Red
            Write-Host "Please install NVM manually from: https://github.com/coreybutler/nvm-windows/releases" -ForegroundColor Yellow
            return $false
        }
    } else {
        Write-Host "NVM is already installed." -ForegroundColor Green
    }
    
    # Check if Node.js is already installed via NVM
    $nodeVersion = nvm list | Select-String "current"
    if (-not $nodeVersion) {
        Write-Host "Installing Node.js LTS version via NVM..." -ForegroundColor Yellow
        
        # Install and use latest LTS version
        nvm install lts
        nvm use lts
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Node.js LTS version installed and set as default." -ForegroundColor Green
        } else {
            Write-Host "Failed to install Node.js via NVM." -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "Node.js is already installed via NVM: $nodeVersion" -ForegroundColor Green
    }
    
    # Verify Node.js installation
    if (Test-CommandExists node) {
        $version = node --version
        Write-Host "Node.js version $version is active." -ForegroundColor Green
        return $true
    } else {
        Write-Host "Node.js installation could not be verified." -ForegroundColor Red
        return $false
    }
}

Setup-NodeWithNVM

# 5. Verify some key commands
Write-Host "`n--- Verifying Key Installs ---" -ForegroundColor Cyan

# PowerShell 7
if (Test-CommandExists pwsh) {
    Write-Host "PowerShell 7 is installed and in PATH." -ForegroundColor Green
} else {
    Write-Host "PowerShell 7 not found in PATH yet. You may need to restart or log out/in." -ForegroundColor Red
}

# Git
if (Test-CommandExists git) {
    $gitVersion = git --version
    Write-Host "Git installed: $gitVersion" -ForegroundColor Green
} else {
    Write-Host "Git not found in PATH." -ForegroundColor Red
}

# Neovim
if (Test-CommandExists nvim) {
    $nvimVersion = nvim --version | Select-Object -First 1
    Write-Host "Neovim installed: $nvimVersion" -ForegroundColor Green
} else {
    Write-Host "Neovim not found in PATH." -ForegroundColor Red
}

# Lua
if (Test-CommandExists lua) {
    $luaVersion = lua -v 2>&1
    Write-Host "Lua installed: $luaVersion" -ForegroundColor Green
} else {
    Write-Host "Lua not found in PATH." -ForegroundColor Red
}

# LuaJIT
if (Test-CommandExists luajit) {
    $luajitVersion = luajit -v 2>&1
    Write-Host "LuaJIT installed: $luajitVersion" -ForegroundColor Green
} else {
    Write-Host "LuaJIT not found in PATH." -ForegroundColor Red
}

# 6. Optionally check if nvm is installed; if so, use it to manage Node
if (Test-CommandExists nvm) {
    Write-Host "NVM found. Installing/using Node.js 20..." -ForegroundColor Yellow
    nvm install 20
    nvm use 20
}

# 7. Function to install JetBrainsMono Nerd Font (v3.x)
function Install-Font {
    param (
        [string]$FontUrl,
        [string]$ToolsDir
    )
    
    Write-Host "`n--- Installing JetBrainsMono Nerd Font ---" -ForegroundColor Cyan
    
    $fontZip = Join-Path $ToolsDir "JetBrainsMono.zip"
    Invoke-WebRequest -Uri $FontUrl -OutFile $fontZip
    
    $extractDir = Join-Path $ToolsDir "JetBrainsMono"
    if (Test-Path $extractDir) {
        Remove-Item $extractDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $extractDir | Out-Null
    
    Expand-Archive -Path $fontZip -DestinationPath $extractDir -Force
    
    # Get all *.ttf files
    $ttfFiles = Get-ChildItem -Path $extractDir -Filter '*.ttf' -Recurse
    $shell = New-Object -ComObject Shell.Application
    $fontsFolder = $shell.Namespace(0x14)  # Windows Fonts folder
    
    foreach ($font in $ttfFiles) {
        Write-Host "Installing font: $($font.Name)" -ForegroundColor Yellow
        $fontsFolder.CopyHere($font.FullName)
    }
    
    Remove-Item $fontZip -Force
    Remove-Item $extractDir -Recurse -Force
    
    Write-Host "JetBrainsMono Nerd Font installation complete!" -ForegroundColor Green
}

# 8. Create a local Tools directory and install the Nerd Font
$toolsDir = Join-Path $env:USERPROFILE "AppData\Local\Tools"
if (-not (Test-Path $toolsDir)) {
    New-Item -ItemType Directory -Path $toolsDir | Out-Null
}

# Use the latest Nerd Fonts release link (v3.x). Adjust if needed.
$fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/JetBrainsMono.zip"
Install-Font -FontUrl $fontUrl -ToolsDir $toolsDir

# 9. Update Windows Terminal Settings
function Update-WindowsTerminalSettings {
    Write-Host "`n--- Updating Windows Terminal Settings ---" -ForegroundColor Cyan
    
    # The Windows Terminal settings.json location can differ on older builds or if installed from source
    $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (-not (Test-Path $settingsPath)) {
        # If you installed Terminal via winget (Store-based), you might have a different path:
        $settingsPath = "$env:LOCALAPPDATA\Microsoft\Windows Terminal\Settings\settings.json"
    }
    
    if (-not (Test-Path $settingsPath)) {
        Write-Host "Could not locate Windows Terminal settings.json. Skipping font config." -ForegroundColor Red
        return
    }

    $settingsRaw = Get-Content -Path $settingsPath -Raw
    $settingsJson = $settingsRaw | ConvertFrom-Json

    # Option A: Set font in 'defaults' so that all profiles use JetBrainsMono Nerd Font
    # -------------------------------------------------------------------------------
    if (-not $settingsJson.profiles.defaults.font) {
        $settingsJson.profiles.defaults | Add-Member -Type NoteProperty -Name "font" -Value @{ face = "JetBrainsMono Nerd Font Mono" }
    } else {
        $settingsJson.profiles.defaults.font.face = "JetBrainsMono Nerd Font Mono"
    }

    # Optionally set some extra terminal preferences:
    if (-not $settingsJson.profiles.defaults.padding) {
        $settingsJson.profiles.defaults | Add-Member -Type NoteProperty -Name "padding" -Value "0"
    }
    if (-not $settingsJson.profiles.defaults.scrollbarState) {
        $settingsJson.profiles.defaults | Add-Member -Type NoteProperty -Name "scrollbarState" -Value "hidden"
    }

    # If you prefer specifically setting the profile for "PowerShell 7" only,
    # you can search for the pwsh profile by name or GUID. For simplicity,
    # we're just changing the defaults.

    $newJson = $settingsJson | ConvertTo-Json -Depth 32
    Set-Content -Path $settingsPath -Value $newJson
    Write-Host "Windows Terminal settings updated to use JetBrainsMono Nerd Font." -ForegroundColor Green
}

Update-WindowsTerminalSettings

# 10. Configure lazygit (optional default config)
Write-Host "`n--- Configuring lazygit ---" -ForegroundColor Cyan
$lazygitConfig = Join-Path $env:APPDATA "lazygit"
if (-not (Test-Path $lazygitConfig)) {
    New-Item -ItemType Directory -Path $lazygitConfig | Out-Null
}

$defaultLazygitConfig = @"
gui:
  theme:
    activeBorderColor:
      - green
      - bold
    inactiveBorderColor:
      - white
    optionsTextColor:
      - blue
"@

$lazygitYml = Join-Path $lazygitConfig "config.yml"
$defaultLazygitConfig | Out-File -FilePath $lazygitYml -Encoding UTF8

# 11. Backup existing Neovim config and clone LazyVim “starter”
Write-Host "`n--- Setting up LazyVim Configuration ---" -ForegroundColor Cyan
$nvimConfig = Join-Path $env:LOCALAPPDATA "nvim"
if (Test-Path $nvimConfig) {
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $backupName = "nvim_backup_$timestamp"
    Rename-Item -Path $nvimConfig -NewName $backupName
    Write-Host "Existing Neovim config found. Backed up to: $backupName" -ForegroundColor Yellow
}

git clone https://github.com/LazyVim/starter "$nvimConfig"
if (Test-Path (Join-Path $nvimConfig ".git")) {
    Remove-Item -Path (Join-Path $nvimConfig ".git") -Recurse -Force
    Write-Host "Cloned LazyVim starter and removed .git directory." -ForegroundColor Green
}

# 12. Add "vim" alias to both PowerShell 7 and legacy Windows PowerShell profiles
Write-Host "`n--- Adding 'vim' alias for Neovim ---" -ForegroundColor Cyan
$pwsh7Profile = "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
$pwsh7Dir = Split-Path $pwsh7Profile

if (-not (Test-Path $pwsh7Dir)) {
    New-Item -ItemType Directory -Path $pwsh7Dir -Force | Out-Null
}
if (-not (Test-Path $pwsh7Profile)) {
    New-Item -ItemType File -Path $pwsh7Profile -Force | Out-Null
}
if (-not (Select-String -Path $pwsh7Profile -Pattern 'Set-Alias vim nvim' -Quiet)) {
    Add-Content $pwsh7Profile "`nSet-Alias vim nvim"
}

# Legacy Windows PowerShell (5.1) profile
if (-not (Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}
if (-not (Select-String -Path $PROFILE -Pattern 'Set-Alias vim nvim' -Quiet)) {
    Add-Content $PROFILE "`nSet-Alias vim nvim"
}

# 13. Final Messages and Launch Windows Terminal
Write-Host "`n--- Installation Complete! ---" -ForegroundColor Green
Write-Host "Close & re-open your terminal (or log out/in) to ensure all PATH changes take effect." -ForegroundColor Yellow
Write-Host "The first Neovim (vim) startup may take a bit to install all LazyVim plugins." -ForegroundColor Yellow
Write-Host "Enjoy your new Neovim + LazyVim setup!" -ForegroundColor Cyan

# Small pause
Start-Sleep -Seconds 3

# Attempt to launch Windows Terminal with PowerShell 7
try {
    if (Test-CommandExists wt) {
        Start-Process wt -ArgumentList "new-tab", "--profile", "PowerShell"
    } else {
        Write-Host "Windows Terminal not found by 'wt' command. Please start it manually." -ForegroundColor Red
        # Fallback to launching pwsh directly
        if (Test-CommandExists pwsh) {
            Start-Process pwsh
        }
    }
} catch {
    Write-Host "Could not launch Windows Terminal. Please start it manually." -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
}
