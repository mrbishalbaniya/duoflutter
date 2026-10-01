# One command: local Django API + Duo Mobile on a USB-connected Android phone.
#   1. Detects the physical Android device and this PC's Wi-Fi/LAN IPv4.
#   2. Writes that IP into env/local.json (API_BASE_URL). WS_BASE_URL stays empty so
#      AppConfig derives ws://<same host>:8000 from the API URL.
#   3. Starts Django (../DuoBackend/runserver.ps1, binds 0.0.0.0:8000) in a new window.
#   4. Verifies the phone can reach the API. Only if blocked, adds a Windows Firewall
#      inbound rule for TCP 8000 (UAC prompt). Then runs `flutter run`.
# Usage: .\run_local.ps1                 (auto-detect everything)
#        .\run_local.ps1 -Device 2c3324a0 -Ip 192.168.1.5 -NoBackend
param([string]$Device = "", [string]$Ip = "", [int]$Port = 8000, [switch]$NoBackend)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
$Backend = Join-Path $PSScriptRoot "..\DuoBackend"

# --- 1. Android device ---
if (-not $Device) {
    # Out-String + parentheses: PowerShell 5.1 needs the whole JSON text and enumerates the array.
    $Device = ((flutter devices --machine --device-timeout 20 | Out-String | ConvertFrom-Json) |
        Where-Object { $_.targetPlatform -like "android*" -and -not $_.emulator } |
        Select-Object -First 1).id
    if (-not $Device) {   # fallback: first USB device adb reports as ready (not an emulator)
        $Device = (adb devices | Select-String '^(\S+)\s+device\s*$' |
            ForEach-Object { $_.Matches[0].Groups[1].Value } | Where-Object { $_ -notlike "emulator-*" } |
            Select-Object -First 1)
    }
    if (-not $Device) { Write-Host "No physical Android device found. Check USB debugging." -ForegroundColor Red; exit 1 }
}
Write-Host "Android device: $Device" -ForegroundColor Cyan

# --- 2. PC LAN IPv4 (interface that owns the default route; skips WSL/Hyper-V/APIPA) ---
if (-not $Ip) {
    $route = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue |
        Sort-Object { $_.RouteMetric + $_.InterfaceMetric } | Select-Object -First 1
    if ($route) {
        $Ip = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $route.InterfaceIndex |
            Where-Object { $_.IPAddress -notlike "169.254.*" } | Select-Object -First 1).IPAddress
    }
    if (-not $Ip) {
        $Ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
            $_.IPAddress -match '^(192\.168|10\.)' -and $_.InterfaceAlias -notmatch 'vEthernet|WSL|Loopback' } |
            Select-Object -First 1).IPAddress
    }
    if (-not $Ip) { Write-Host "Could not detect a LAN IPv4 address. Pass -Ip." -ForegroundColor Red; exit 1 }
}
$ApiUrl = "http://${Ip}:$Port/api"
Write-Host "PC IP: $Ip  ->  API_BASE_URL=$ApiUrl" -ForegroundColor Cyan

$envFile = Join-Path $PSScriptRoot "env\local.json"
$cfg = Get-Content $envFile -Raw | ConvertFrom-Json
if ($cfg.API_BASE_URL -ne $ApiUrl) {
    $cfg.API_BASE_URL = $ApiUrl
    $cfg | ConvertTo-Json | Set-Content $envFile -Encoding ascii
    Write-Host "Updated env/local.json" -ForegroundColor Yellow
}

# --- 3. Django ---
# Exactly ONE Django must own the port. A second `manage.py runserver` bound to
# 127.0.0.1 can coexist with ours on 0.0.0.0 (Windows allows it): the browser then
# talks to one process and the phone to the other, and because the dev channel
# layer is in-memory, chat messages and call signals never cross between them.
$listeners = @(Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
foreach ($l in $listeners | Where-Object { $_.LocalAddress -in @('127.0.0.1', '::1') }) {
    $proc = Get-CimInstance Win32_Process -Filter "ProcessId=$($l.OwningProcess)" -ErrorAction SilentlyContinue
    if ($proc -and $proc.CommandLine -match 'manage\.py\s+runserver') {
        Write-Host "Stopping localhost-only Django (PID $($proc.ProcessId)); it splits realtime between web and phone." -ForegroundColor Yellow
        Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue
        if ($proc.ParentProcessId) {
            $parent = Get-CimInstance Win32_Process -Filter "ProcessId=$($proc.ParentProcessId)" -ErrorAction SilentlyContinue
            if ($parent -and $parent.CommandLine -match 'manage\.py\s+runserver') { Stop-Process -Id $parent.ProcessId -Force -ErrorAction SilentlyContinue }
        }
    } elseif ($proc) {
        Write-Host "Port $Port on localhost is used by another program ($($proc.Name)). Stop it first." -ForegroundColor Red; exit 1
    }
}
Start-Sleep -Milliseconds 500

function Test-Api { try { Invoke-WebRequest "http://127.0.0.1:$Port/api/" -UseBasicParsing -TimeoutSec 2 | Out-Null; $true }
                   catch { [bool]$_.Exception.Response } }   # any HTTP status = server is up
if (-not $NoBackend -and -not (Test-Api)) {
    Write-Host "Starting Django on 0.0.0.0:$Port ..." -ForegroundColor Cyan
    Start-Process powershell -WorkingDirectory $Backend -ArgumentList "-NoExit", "-File", (Join-Path $Backend "runserver.ps1")
    $deadline = (Get-Date).AddSeconds(60)
    while (-not (Test-Api)) {
        if ((Get-Date) -gt $deadline) { Write-Host "Django did not start within 60s. Check its window." -ForegroundColor Red; exit 1 }
        Start-Sleep -Seconds 2
    }
}
Write-Host "Django is up." -ForegroundColor Green

# --- 4. Phone -> PC reachability ---
function Test-Phone { "$(adb -s $Device shell "toybox nc -w 3 $Ip $Port </dev/null >/dev/null 2>&1 && echo OK || echo FAIL" 2>$null)".Trim() -eq "OK" }
if (-not (Test-Phone)) {
    # Only now touch the firewall: add an inbound rule for the dev port (asks for admin once).
    $ruleName = "Duo Django Dev (TCP $Port)"
    if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
        Write-Host "Phone blocked; adding firewall rule '$ruleName' (UAC prompt)..." -ForegroundColor Yellow
        $cmd = "New-NetFirewallRule -DisplayName '$ruleName' -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow -Profile Private,Public"
        try { Start-Process powershell -Verb RunAs -Wait -ArgumentList "-NoProfile", "-Command", $cmd }
        catch { Write-Host "Firewall rule not added. Run as admin: $cmd" -ForegroundColor Red }
    }
}
if (Test-Phone) { Write-Host "Phone can reach ${Ip}:$Port" -ForegroundColor Green }
else { Write-Host "WARNING: phone could not reach ${Ip}:$Port. Same Wi-Fi? Firewall? " -ForegroundColor Red }

flutter pub get
flutter run -d $Device --dart-define-from-file=env/local.json
