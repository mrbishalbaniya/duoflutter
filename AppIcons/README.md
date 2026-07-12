# Duo App Icons

Pre-generated launcher icon pack for Duo Mobile.

## Layout

| Path | Purpose |
|------|---------|
| `playstore.png` | Google Play Store listing (512×512) |
| `appstore.png` | Apple App Store listing (1024×1024) |
| `android/mipmap-*/logo.png` | Android launcher densities |
| `Assets.xcassets/AppIcon.appiconset/` | iOS/macOS/watch icon set |
| `Assets.xcassets/AppIcon.appiconset/_/*.png` | Source PNGs (copy into `.appiconset/` for Xcode) |

## Flutter integration

- **Android:** `logo.png` → `android/app/src/main/res/mipmap-*/ic_launcher.png`
- **iOS:** `Contents.json` + PNGs → `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- **Web / Windows / macOS:** regenerate via `dart run flutter_launcher_icons` using `playstore.png`

## Regenerate web/desktop only

```bash
dart run flutter_launcher_icons
```

Android and iOS are managed from this folder directly (not via `flutter_launcher_icons`).
