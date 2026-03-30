#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Fleet SSH Onboarding for Windows hosts — agent-forge network bootstrap.

.DESCRIPTION
    Sets up OpenSSH Server on a Windows machine and authorizes all fleet SSH keys.
    Designed to be downloaded from GitHub and run on a new Windows host.

    Run in PowerShell as Administrator:
        Set-ExecutionPolicy Bypass -Scope Process -Force
        .\windows-ssh-onboard.ps1

.NOTES
    Author:  agent-forge (speeed76)
    Updated: 2026-03-30
    Fleet:   mac-studio, mac-mini, macbook-pro-2, ubuntu-server
#>

$ErrorActionPreference = "Stop"

# --- Fleet SSH public keys (collected 2026-03-30) ---
$FleetKeys = @(
    @{ Name = "mac-studio";     Key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDZoYnx8/VFr7zV9BNBaRTlUc3mvdHQkgxEBv2HCNFPb pawelgiers@Pawels-Mac-Studio.local" },
    @{ Name = "mac-mini";       Key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJuK6NaDAFyGYNSSBUYJi5viqlH7RcpaWRPnvSVzBfhq pawelgiers@Pawels-Mac-mini.local" },
    @{ Name = "macbook-pro-2";  Key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBIq5iRnYiPUptc8XhwY245iBYUv1vSaiKRG9VfZaBPV pawel.giers@gmail.com" },
    @{ Name = "ubuntu-server";  Key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEwHQJOG6D3YvGzrbOeE5syeaqQyyu25pufxtTaBnkMq pawel@ubuntu-server" }
)

# --- Helpers ---
function Write-Step  { param([string]$Msg) Write-Host "`n==> $Msg" -ForegroundColor Cyan }
function Write-Ok    { param([string]$Msg) Write-Host "    [OK] $Msg" -ForegroundColor Green }
function Write-Skip  { param([string]$Msg) Write-Host "    [SKIP] $Msg" -ForegroundColor Yellow }
function Write-Fail  { param([string]$Msg) Write-Host "    [FAIL] $Msg" -ForegroundColor Red }
function Write-Info  { param([string]$Msg) Write-Host "    $Msg" -ForegroundColor Gray }

# --- Pre-flight checks ---
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Fleet SSH Onboarding — Windows Host Bootstrap" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

Write-Step "Pre-flight: checking system"

# OS info
$os = Get-CimInstance Win32_OperatingSystem
Write-Info "OS:       $($os.Caption) ($($os.Version))"
Write-Info "Hostname: $env:COMPUTERNAME"
Write-Info "User:     $env:USERNAME"
Write-Info "Domain:   $env:USERDOMAIN"

# Confirm running as admin
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Fail "This script must be run as Administrator. Right-click PowerShell -> Run as Administrator."
    exit 1
}
Write-Ok "Running as Administrator"

# Check Windows version (OpenSSH Server requires Win10 1809+ / Server 2019+)
$build = [int](Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuildNumber
if ($build -lt 17763) {
    Write-Fail "Windows build $build is too old. OpenSSH Server requires build 17763+ (Win10 1809 / Server 2019)."
    exit 1
}
Write-Ok "Windows build $build is supported"

# Network info
Write-Step "Pre-flight: checking network"
$tailscaleIP = $null
try {
    $adapters = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -ne "127.0.0.1" }
    foreach ($a in $adapters) {
        $iface = Get-NetAdapter -InterfaceIndex $a.InterfaceIndex -ErrorAction SilentlyContinue
        $label = if ($iface) { $iface.Name } else { "idx:$($a.InterfaceIndex)" }
        Write-Info "  $($a.IPAddress)  ($label)"
        if ($a.IPAddress -match "^100\.") { $tailscaleIP = $a.IPAddress }
    }
} catch {
    Write-Info "Could not enumerate adapters: $_"
}

if ($tailscaleIP) {
    Write-Ok "Tailscale detected: $tailscaleIP"
} else {
    Write-Fail "No Tailscale IP (100.x.x.x) found. Is Tailscale installed and connected?"
    Write-Info "SSH onboarding will continue but remote Tailscale access won't work until Tailscale is up."
}

# ---------------------------------------------------------------
# Step 1: Install OpenSSH Server
# ---------------------------------------------------------------
Write-Step "Step 1/5: OpenSSH Server capability"

$sshCapability = Get-WindowsCapability -Online | Where-Object Name -like "OpenSSH.Server*"

if ($sshCapability.State -eq "Installed") {
    Write-Skip "OpenSSH Server already installed"
} elseif ($sshCapability.State -eq "NotPresent") {
    Write-Info "Installing OpenSSH Server capability..."
    try {
        Add-WindowsCapability -Online -Name "OpenSSH.Server~~~~0.0.1.0" | Out-Null
        Write-Ok "OpenSSH Server installed"
    } catch {
        Write-Fail "Failed to install OpenSSH Server: $_"
        Write-Info "Try manually: Settings -> Apps -> Optional Features -> Add -> OpenSSH Server"
        exit 1
    }
} else {
    Write-Info "OpenSSH Server state: $($sshCapability.State)"
    Write-Fail "Unexpected state. Check Windows Update or install manually."
    exit 1
}

# ---------------------------------------------------------------
# Step 2: Configure and start sshd service
# ---------------------------------------------------------------
Write-Step "Step 2/5: sshd service"

$sshd = Get-Service sshd -ErrorAction SilentlyContinue
if (-not $sshd) {
    Write-Fail "sshd service not found even after install. Reboot may be required."
    exit 1
}

# Set to auto-start
if ($sshd.StartType -ne "Automatic") {
    Set-Service -Name sshd -StartupType Automatic
    Write-Ok "Set sshd startup to Automatic"
} else {
    Write-Skip "sshd startup already Automatic"
}

# Start if not running
if ($sshd.Status -ne "Running") {
    Write-Info "Starting sshd..."
    Start-Service sshd
    Start-Sleep -Seconds 2
    $sshd = Get-Service sshd
    if ($sshd.Status -eq "Running") {
        Write-Ok "sshd is running"
    } else {
        Write-Fail "sshd failed to start. Status: $($sshd.Status)"
        exit 1
    }
} else {
    Write-Skip "sshd already running"
}

# Verify sshd is listening on port 22
$listener = Get-NetTCPConnection -LocalPort 22 -State Listen -ErrorAction SilentlyContinue
if ($listener) {
    Write-Ok "sshd listening on port 22"
} else {
    Write-Fail "Nothing listening on port 22 despite sshd running. Check sshd_config."
}

# ---------------------------------------------------------------
# Step 3: Configure sshd_config — key auth, disable password
# ---------------------------------------------------------------
Write-Step "Step 3/5: sshd_config hardening"

$sshdConfig = "$env:ProgramData\ssh\sshd_config"
if (-not (Test-Path $sshdConfig)) {
    Write-Fail "sshd_config not found at $sshdConfig"
    exit 1
}

$configContent = Get-Content $sshdConfig -Raw
$configChanged = $false

# Ensure PubkeyAuthentication yes
if ($configContent -match "(?m)^\s*PubkeyAuthentication\s+yes") {
    Write-Skip "PubkeyAuthentication already enabled"
} else {
    Write-Info "Enabling PubkeyAuthentication..."
    # Replace commented or wrong value, or append
    if ($configContent -match "(?m)^#?\s*PubkeyAuthentication") {
        $configContent = $configContent -replace "(?m)^#?\s*PubkeyAuthentication\s+\w+", "PubkeyAuthentication yes"
    } else {
        $configContent += "`nPubkeyAuthentication yes`n"
    }
    $configChanged = $true
    Write-Ok "PubkeyAuthentication enabled"
}

# Disable password authentication
if ($configContent -match "(?m)^\s*PasswordAuthentication\s+no") {
    Write-Skip "PasswordAuthentication already disabled"
} else {
    Write-Info "Disabling PasswordAuthentication..."
    if ($configContent -match "(?m)^#?\s*PasswordAuthentication") {
        $configContent = $configContent -replace "(?m)^#?\s*PasswordAuthentication\s+\w+", "PasswordAuthentication no"
    } else {
        $configContent += "`nPasswordAuthentication no`n"
    }
    $configChanged = $true
    Write-Ok "PasswordAuthentication disabled"
}

if ($configChanged) {
    Copy-Item $sshdConfig "$sshdConfig.bak.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Write-Info "Backed up original sshd_config"
    Set-Content $sshdConfig $configContent -Encoding UTF8
    Write-Info "Restarting sshd to apply config..."
    Restart-Service sshd
    Start-Sleep -Seconds 2
    $sshd = Get-Service sshd
    if ($sshd.Status -eq "Running") {
        Write-Ok "sshd restarted with new config"
    } else {
        Write-Fail "sshd failed to restart after config change. Restoring backup..."
        $latestBackup = Get-ChildItem "$env:ProgramData\ssh\sshd_config.bak.*" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($latestBackup) { Copy-Item $latestBackup.FullName $sshdConfig }
        Start-Service sshd
        exit 1
    }
} else {
    Write-Skip "sshd_config unchanged"
}

# ---------------------------------------------------------------
# Step 4: Firewall rule for SSH
# ---------------------------------------------------------------
Write-Step "Step 4/5: Firewall rule for SSH (port 22)"

$existingRule = Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue
if (-not $existingRule) {
    $existingRule = Get-NetFirewallRule -DisplayName "*OpenSSH*" -ErrorAction SilentlyContinue |
        Where-Object { $_.Direction -eq "Inbound" -and $_.Enabled -eq "True" }
}

if ($existingRule) {
    Write-Skip "Firewall rule already exists: $($existingRule.Name -join ', ')"
} else {
    Write-Info "Creating inbound firewall rule for port 22..."
    try {
        New-NetFirewallRule `
            -Name "OpenSSH-Server-In-TCP" `
            -DisplayName "OpenSSH Server (sshd) — Fleet Access" `
            -Enabled True `
            -Direction Inbound `
            -Protocol TCP `
            -Action Allow `
            -LocalPort 22 | Out-Null
        Write-Ok "Firewall rule created"
    } catch {
        Write-Fail "Failed to create firewall rule: $_"
        Write-Info "Manually run: New-NetFirewallRule -Name OpenSSH-Server-In-TCP -DisplayName 'OpenSSH Server' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22"
    }
}

# ---------------------------------------------------------------
# Step 5: Deploy fleet SSH keys
# ---------------------------------------------------------------
Write-Step "Step 5/5: Deploying fleet SSH public keys"

# Determine if current user is an administrator
$isAdmin = (net localgroup Administrators 2>&1) -match [regex]::Escape($env:USERNAME)
if ($isAdmin) {
    Write-Info "User '$env:USERNAME' is in Administrators group"
    Write-Info "Windows requires admin keys in: $env:ProgramData\ssh\administrators_authorized_keys"
    $keyFile = "$env:ProgramData\ssh\administrators_authorized_keys"
} else {
    Write-Info "User '$env:USERNAME' is a standard user"
    $keyFile = "$env:USERPROFILE\.ssh\authorized_keys"
}

# Ensure parent directory exists
$keyDir = Split-Path $keyFile -Parent
if (-not (Test-Path $keyDir)) {
    New-Item -ItemType Directory -Path $keyDir -Force | Out-Null
    Write-Info "Created directory: $keyDir"
}

# Read existing keys (if any)
$existingKeys = @()
if (Test-Path $keyFile) {
    $existingKeys = Get-Content $keyFile | Where-Object { $_.Trim() -ne "" }
    Write-Info "Found $($existingKeys.Count) existing key(s) in $keyFile"
}

$keysAdded = 0
foreach ($entry in $FleetKeys) {
    # Check by the key fingerprint (middle part), not the comment
    $keyParts = $entry.Key -split "\s+"
    $keyFingerprint = $keyParts[1]  # The base64 part

    if ($existingKeys | Where-Object { $_ -match [regex]::Escape($keyFingerprint) }) {
        Write-Skip "$($entry.Name) key already present"
    } else {
        Add-Content -Path $keyFile -Value $entry.Key -Encoding UTF8
        $keysAdded++
        Write-Ok "$($entry.Name) key added"
    }
}

if ($keysAdded -eq 0) {
    Write-Skip "No new keys to add"
}

# Fix permissions on administrators_authorized_keys (Windows ACL requirement)
if ($isAdmin) {
    Write-Info "Setting ACL on administrators_authorized_keys..."
    try {
        icacls $keyFile /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F" | Out-Null
        Write-Ok "ACL set (Administrators + SYSTEM only)"
    } catch {
        Write-Fail "Failed to set ACL: $_"
        Write-Info "Manually run: icacls `"$keyFile`" /inheritance:r /grant `"Administrators:F`" /grant `"SYSTEM:F`""
    }
}

# ---------------------------------------------------------------
# Summary
# ---------------------------------------------------------------
Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "  Onboarding Complete" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Hostname:      $env:COMPUTERNAME" -ForegroundColor White
Write-Host "  SSH user:      $env:USERNAME" -ForegroundColor White
Write-Host "  Tailscale IP:  $tailscaleIP" -ForegroundColor White
Write-Host "  Key file:      $keyFile" -ForegroundColor White
Write-Host "  Fleet keys:    $($FleetKeys.Count) configured ($keysAdded new)" -ForegroundColor White
Write-Host ""
Write-Host "  Test from any fleet machine:" -ForegroundColor Yellow
Write-Host "    ssh $env:USERNAME@$tailscaleIP `"hostname && whoami`"" -ForegroundColor Yellow
if ($tailscaleIP -ne "100.77.204.17") {
    Write-Host "    ssh $env:USERNAME@100.77.204.17 `"hostname && whoami`"" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "  Default shell is cmd.exe. To switch to PowerShell:" -ForegroundColor Gray
Write-Host "    New-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name DefaultShell -Value 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -PropertyType String -Force" -ForegroundColor Gray
Write-Host ""
