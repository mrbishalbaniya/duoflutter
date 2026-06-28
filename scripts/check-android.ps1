# Check Android setup for Expo (`npm run android`)

$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$adb = "$sdk\platform-tools\adb.exe"
$emulator = "$sdk\emulator\emulator.exe"

Write-Host "`n=== Duo Mobile — Android check ===`n" -ForegroundColor Cyan

if (-not (Test-Path $adb)) {
  Write-Host "ADB not found. Install Android Studio:" -ForegroundColor Red
  Write-Host "  https://developer.android.com/studio`n"
  exit 1
}

Write-Host "ADB:" $adb
& $adb devices -l
Write-Host ""

if (Test-Path $emulator) {
  $avds = & $emulator -list-avds 2>$null
  if ($avds) {
    Write-Host "Virtual devices:" -ForegroundColor Green
    $avds | ForEach-Object { Write-Host "  - $_" }
    Write-Host "`nStart one, then press 'a' in Expo:"
    Write-Host "  & `"$emulator`" -avd $($avds[0])`n"
  } else {
    Write-Host "No Android emulators (AVDs) found." -ForegroundColor Yellow
    Write-Host @"

Create one in Android Studio:
  1. Open Android Studio
  2. More Actions -> Virtual Device Manager (or Tools -> Device Manager)
  3. Create Device -> Pixel 7 -> Download a system image (API 34+)
  4. Finish, then click Play on the new device
  5. In Expo terminal, press 'a' again

Or use your phone (no emulator needed):
  1. Install 'Expo Go' from Play Store
  2. Phone and PC on same Wi-Fi
  3. Scan the QR code shown by 'npm start'

"@
  }

  $studio = "C:\Program Files\Android\Android Studio\bin\studio64.exe"
  if (Test-Path $studio) {
    Write-Host "Open Android Studio Device Manager? (y/n): " -NoNewline
    $ans = Read-Host
    if ($ans -eq "y") { Start-Process $studio }
  }
} else {
  Write-Host "Android emulator not installed. Use Android Studio SDK Manager." -ForegroundColor Yellow
}
