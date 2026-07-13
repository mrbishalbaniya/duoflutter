# Android APK install guide

## "App not installed — package conflicts with an existing package"

This means Android found `com.duo.duo_mobile` already installed (or restored) with a **different signing key** than the APK you are installing.

Common causes:

1. **GitHub CI builds were debug-signed** (each build used a different temporary key).
2. An older build was installed from **USB debug**, **Firebase**, or **Play Store**.
3. The app still exists in a **work profile**, **Dual Apps**, or **Secure Folder**.
4. **Google Play auto-restore** reinstalled the app after you uninstalled it.

## Fix on your phone

### 1. Remove every copy of Duo

On the phone:

1. Settings → Apps → **Duo** → Uninstall.
2. Repeat for **Dual Apps / Second Space / Secure Folder / Work profile** if you use them.
3. Open **Play Store → Profile → Manage apps & device** and uninstall Duo if it appears there.

### 2. Disable auto-restore (recommended)

Play Store → Profile → Settings → General → turn off **Restore apps** (wording varies by device).

### 3. Reboot the phone

Restart before installing the APK again.

### 4. Download a fresh APK

Do **not** reuse an old file from Downloads.

Latest release:

https://github.com/mrbishalbaniya/duoflutter/releases/latest/download/app-release.apk

The file should be about **70+ MB**. If it is only a few KB, the download failed.

### 5. Install with ADB (best error messages)

Connect USB debugging, then on a computer:

```bash
adb devices
adb shell pm list packages | grep duo
adb shell pm list packages -u | grep duo
adb uninstall com.duo.duo_mobile
adb install -r path/to/app-release.apk
```

If `pm list packages` still shows `com.duo.duo_mobile`, the app is not fully removed.

## Permanent fix in CI (maintainers)

Release builds must use **one stable keystore** via GitHub Actions secrets:

| Secret | Description |
|--------|-------------|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded `.jks` file |
| `KEYSTORE_PASSWORD` | Keystore password |
| `KEY_PASSWORD` | Key password |
| `KEY_ALIAS` | Key alias |

### Create a keystore (once)

```bash
keytool -genkeypair -v \
  -keystore upload-keystore.jks \
  -alias duo-release \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass YOUR_STORE_PASSWORD \
  -keypass YOUR_KEY_PASSWORD \
  -dname "CN=Duo, OU=Mobile, O=Duo, L=Kathmandu, ST=Bagmati, C=NP"
```

Encode for GitHub secret:

```bash
# Linux / macOS
base64 -w0 upload-keystore.jks

# Windows PowerShell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks"))
```

Add the output to repo **Settings → Secrets and variables → Actions**.

After secrets are set, new releases are signed with the same key and upgrades install without uninstalling.

**Important:** If users already have a debug-signed GitHub build installed, they must uninstall **once** before installing the first properly signed release.
