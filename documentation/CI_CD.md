# DuoMobile CI/CD

See the full platform guide: [../documentation/CI_CD_GUIDE.md](../documentation/CI_CD_GUIDE.md)

## Quick start

1. Add Android signing secrets for release builds (optional — debug signing used otherwise).
2. Push to `main` — analyze, test, build APK + AAB, upload artifacts.
3. Create a GitHub Release to attach signed builds to the release page.

## Android signing secrets

| Secret | Description |
|--------|-------------|
| `ANDROID_KEYSTORE_BASE64` | `base64` of your `.jks` file |
| `KEYSTORE_PASSWORD` | Keystore password |
| `KEY_PASSWORD` | Key password |
| `KEY_ALIAS` | Key alias |

Copy `android/key.properties.example` → `android/key.properties` for local signed builds.

## Workflows

- `flutter.yml` — analyze, test, APK/AAB, Firebase distribution
- `quality.yml` — analyze, format, tests
- `security.yml` — gitleaks, dependency audit
- `version.yml` — changelog
- `release.yml` — signed artifacts → GitHub Release

## Local CI commands

```bash
flutter pub get
flutter analyze
dart format --set-exit-if-changed lib test
flutter test
flutter build apk --release
flutter build appbundle --release
```

## Download latest APK from CI

1. GitHub → Actions → **Flutter** workflow → latest run.
2. Artifacts → `duo-android-apk`.
