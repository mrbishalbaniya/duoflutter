# Start Expo with Android SDK tools first in PATH (fixes adb v32 vs v41 conflict from C:\adb)

$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$platformTools = Join-Path $sdk "platform-tools"
$emulator = Join-Path $sdk "emulator"

# Remove legacy C:\adb from PATH for this session so SDK adb (v41) is used
$cleanPath = ($env:PATH -split ';' | Where-Object {
  $_ -and $_ -notmatch '^C:\\adb$'
}) -join ';'

$env:PATH = "$platformTools;$emulator;$cleanPath"

Write-Host "Using adb: $(Get-Command adb -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source)" -ForegroundColor Cyan
& adb version | Select-Object -First 1

# Restart adb cleanly
& adb kill-server 2>$null
Start-Sleep -Seconds 1
& adb start-server

$devices = & adb devices
Write-Host $devices

if ($devices -match "offline") {
  Write-Host ""
  Write-Host "Emulator offline - Cold Boot Pixel_7 in Android Studio Device Manager" -ForegroundColor Yellow
}

Set-Location $PSScriptRoot\..

if ($args.Count -gt 0) {
  npx expo start @args
} else {
  npx expo start
}
