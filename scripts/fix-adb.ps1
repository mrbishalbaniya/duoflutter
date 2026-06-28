# Fix adb version conflict (C:\adb v32 vs Android SDK v41) and reconnect emulator

$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$platformTools = Join-Path $sdk "platform-tools"
$adb = Join-Path $platformTools "adb.exe"

$env:PATH = "$platformTools;$(Join-Path $sdk 'emulator');" + (
  ($env:PATH -split ';' | Where-Object { $_ -and $_ -notmatch '^C:\\adb$' }) -join ';'
)

Write-Host "Stopping all adb processes..." -ForegroundColor Cyan
Get-Process adb -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

& $adb start-server
Write-Host (& $adb version | Select-Object -First 1)

Write-Host "`nDevices before reconnect:" -ForegroundColor Cyan
& $adb devices -l

& $adb reconnect 2>$null
Start-Sleep -Seconds 2

Write-Host "`nDevices after reconnect:" -ForegroundColor Cyan
& $adb devices -l

if ((& $adb devices) -match "offline") {
  Write-Host ""
  Write-Host "Emulator still offline. In Android Studio: Device Manager -> Pixel_7 -> Cold Boot Now" -ForegroundColor Yellow
  Write-Host "Or remove C:\adb from Windows PATH and keep only Android SDK platform-tools." -ForegroundColor Yellow
}
