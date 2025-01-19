# Admin check
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Please run this script as Administrator" -ForegroundColor Red
    Exit
}

# Function to check if a command exists
function Test-CommandExists {
    param ($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try { if (Get-Command $command) { return $true } }
    catch { return $false }
    finally { $ErrorActionPreference = $oldPreference }
}

# Function to add to PATH if not exists
function Add-ToPath {
    param(
        [string]$PathToAdd
    )
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*$PathToAdd*") {
        [Environment]::SetEnvironmentVariable(
            "Path",
            "$currentPath;$PathToAdd",
            "User"
        )
        $env:Path = "$env:Path;$PathToAdd"
        Write-Host "Added $PathToAdd to PATH" -ForegroundColor Green
    }
}

# Function to install font
function Install-Font {
    param (
        [string]$FontUrl,
        [string]$ToolsDir
    )
    
    Write-Host "Downloading and installing JetBrainsMono Nerd Font..." -ForegroundColor Yellow
    
    # Download the font
    $fontZip = "$ToolsDir\JetBrainsMono.zip"
    Invoke-WebRequest -Uri $FontUrl -OutFile $fontZip
    
    # Create temp directory for font extraction
    $fontExtractPath = "$ToolsDir\JetBrainsMono"
    New-Item -ItemType Directory -Force -Path $fontExtractPath
    
    # Extract the font
    Expand-Archive -Path $fontZip -DestinationPath $fontExtractPath -Force
    
    # Get all TTF files
    $fonts = Get-ChildItem -Path $fontExtractPath -Filter "*.ttf" -Recurse
    
    # Install each font
    $shell = New-Object -ComObject Shell.Application
    $fontsFolder = $shell.Namespace(0x14) # Windows Fonts folder
    
    foreach ($font in $fonts) {
        Write-Host "Installing font: $($font.Name)" -ForegroundColor Yellow
        $fontsFolder.CopyHere($font.FullName)
    }
    
    # Clean up
    Remove-Item $fontZip -Force
    Remove-Item $fontExtractPath -Recurse -Force
    
    Write-Host "Font installation completed!" -ForegroundColor Green
}

# Function to update Windows Terminal settings
function Update-WindowsTerminalSettings {
    $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    
    # Check if settings file exists
    if (-not (Test-Path $settingsPath)) {
        Write-Host "Windows Terminal settings file not found at expected location" -ForegroundColor Red
        return
    }
    
    # Read current settings
    $settings = Get-Content -Path $settingsPath -Raw | ConvertFrom-Json
    
    # Update PowerShell profile defaults
    if (-not $settings.profiles.defaults.font) {
        $settings.profiles.defaults | Add-Member -Type NoteProperty -Name "font" -Value @{
            face = "JetBrainsMono Nerd Font Mono"
        }
    } else {
        $settings.profiles.defaults.font.face = "JetBrainsMono Nerd Font Mono"
    }
    
    # Set padding and scrollbar state if not already set
    if (-not $settings.profiles.defaults.padding) {
        $settings.profiles.defaults | Add-Member -Type NoteProperty -Name "padding" -Value "0"
    }
    if (-not $settings.profiles.defaults.scrollbarState) {
        $settings.profiles.defaults | Add-Member -Type NoteProperty -Name "scrollbarState" -Value "hidden"
    }
    
    # Save updated settings
    $settings | ConvertTo-Json -Depth 32 | Set-Content -Path $settingsPath
    Write-Host "Windows Terminal settings updated successfully!" -ForegroundColor Green
}

# Check for winget
if (-not (Test-CommandExists winget)) {
    Write-Host "Winget is not installed. Please install the Windows App Installer from the Microsoft Store." -ForegroundColor Red
    Exit
}

# Install PowerShell 7
Write-Host "Installing PowerShell 7..." -ForegroundColor Yellow
winget install -e --id Microsoft.PowerShell --accept-source-agreements --accept-package-agreements

# Check if PowerShell 7 is in PATH
if (-not (Test-CommandExists pwsh)) {
    Write-Host "PowerShell 7 installed but not found in PATH. You may need to restart your terminal." -ForegroundColor Yellow
}

# Install dependencies via winget
$wingetPackages = @(
    "GnuWin32.Make",
    "Git.Git",
    "Microsoft.VisualStudio.2022.BuildTools",
    "MSYS2.MSYS2",  # This will help with gcc
    "rjpcomputing.luaforwindows",  # Lua 5.1
    "DEVCOM.LuaJIT"  # LuaJIT 2.1 (includes LuaRocks)
)

foreach ($package in $wingetPackages) {
    Write-Host "Installing $package..." -ForegroundColor Yellow
    winget install -e --id $package --accept-source-agreements --accept-package-agreements
}

# Verify Lua installation
if (Test-CommandExists lua) {
    $luaVersion = lua -v
    Write-Host "Lua installed: $luaVersion" -ForegroundColor Green
} else {
    Write-Host "Warning: Lua installation might have failed" -ForegroundColor Red
}

# Verify LuaJIT/LuaRocks installation
if (Test-CommandExists luajit) {
    $luajitVersion = luajit -v
    Write-Host "LuaJIT installed: $luajitVersion" -ForegroundColor Green
} else {
    Write-Host "Warning: LuaJIT installation might have failed" -ForegroundColor Red
}

# Install Neovim
Write-Host "Installing Neovim..." -ForegroundColor Yellow
winget install Neovim.Neovim

# Install Node.js using nvm if available
if (Test-CommandExists nvm) {
    Write-Host "NVM found. Installing/updating Node.js..." -ForegroundColor Yellow
    nvm install 20
    nvm use 20
} else {
    Write-Host "Installing Node.js directly..." -ForegroundColor Yellow
    winget install OpenJS.NodeJS.LTS
}

# Create directory for tools if it doesn't exist
$toolsDir = "$env:USERPROFILE\AppData\Local\Tools"
New-Item -ItemType Directory -Force -Path $toolsDir

# Download and install ripgrep
$rgUrl = "https://github.com/BurntSushi/ripgrep/releases/download/13.0.0/ripgrep-13.0.0-x86_64-pc-windows-msvc.zip"
$rgZip = "$toolsDir\ripgrep.zip"
Invoke-WebRequest -Uri $rgUrl -OutFile $rgZip
Expand-Archive -Path $rgZip -DestinationPath "$toolsDir\ripgrep" -Force
Add-ToPath "$toolsDir\ripgrep"
Remove-Item $rgZip

# Download and install fd
$fdUrl = "https://github.com/sharkdp/fd/releases/download/v8.7.0/fd-v8.7.0-x86_64-pc-windows-msvc.zip"
$fdZip = "$toolsDir\fd.zip"
Invoke-WebRequest -Uri $fdUrl -OutFile $fdZip
Expand-Archive -Path $fdZip -DestinationPath "$toolsDir\fd" -Force
Add-ToPath "$toolsDir\fd"
Remove-Item $fdZip

# Install lazygit
Write-Host "Installing lazygit..." -ForegroundColor Yellow
winget install -e --id JesseDuffield.lazygit

# Create lazygit config directory and config file
$lazygitConfig = "$env:APPDATA\lazygit"
New-Item -ItemType Directory -Force -Path $lazygitConfig

# Create basic lazygit config
@"
gui:
  theme:
    activeBorderColor:
      - green
      - bold
    inactiveBorderColor:
      - white
    optionsTextColor:
      - blue
"@ | Out-File -FilePath "$lazygitConfig\config.yml" -Encoding UTF8

# Backup existing Neovim config if it exists
$nvimConfig = "$env:LOCALAPPDATA\nvim"
if (Test-Path $nvimConfig) {
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    Rename-Item -Path $nvimConfig -NewName "nvim_backup_$timestamp"
    Write-Host "Backed up existing Neovim config to nvim_backup_$timestamp" -ForegroundColor Yellow
}

# Clone LazyVim starter
git clone https://github.com/LazyVim/starter "$nvimConfig"
Remove-Item -Path "$nvimConfig\.git" -Recurse -Force

# Set up PowerShell 7 profile
$pwshProfilePath = "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
$pwshProfileDir = [System.IO.Path]::GetDirectoryName($pwshProfilePath)

# Create PowerShell 7 profile directory if it doesn't exist
if (-not (Test-Path $pwshProfileDir)) {
    New-Item -ItemType Directory -Path $pwshProfileDir -Force
}

# Create PowerShell 7 profile if it doesn't exist
if (-not (Test-Path $pwshProfilePath)) {
    New-Item -ItemType File -Path $pwshProfilePath -Force
}

# Add Neovim alias to PowerShell 7 profile if not already present
$nvimAlias = 'Set-Alias vim nvim'
if (-not (Get-Content $pwshProfilePath | Select-String -Pattern $nvimAlias)) {
    Add-Content $pwshProfilePath $nvimAlias
}

# Also set up for Windows PowerShell (5.1) profile for compatibility
if (-not (Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force
}
if (-not (Get-Content $PROFILE | Select-String -Pattern $nvimAlias)) {
    Add-Content $PROFILE $nvimAlias
}

# Install JetBrainsMono Nerd Font
$fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/JetBrainsMono.zip"
Install-Font -FontUrl $fontUrl -ToolsDir $toolsDir

# Update Windows Terminal settings
Update-WindowsTerminalSettings

Write-Host "`nInstallation completed!" -ForegroundColor Green
Write-Host "Launching Windows Terminal with PowerShell 7..." -ForegroundColor Yellow
Write-Host "First Neovim startup might take a while as it installs plugins." -ForegroundColor Yellow
Write-Host "You can start Neovim by typing 'vim' or 'nvim'" -ForegroundColor Yellow

# Small pause to let user read the messages
Start-Sleep -Seconds 3

# Launch Windows Terminal with PowerShell 7
try {
    # Check if Windows Terminal is installed
    if (Test-CommandExists wt) {
        # Launch Windows Terminal with PowerShell 7
        Start-Process wt -ArgumentList "new-tab", "--profile", "PowerShell"
    } else {
        Write-Host "Windows Terminal not found. Please install it from the Microsoft Store." -ForegroundColor Red
        # Fall back to launching PowerShell 7 directly
        Start-Process pwsh
    }
} catch {
    Write-Host "Could not launch Windows Terminal. Please start it manually." -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
}
