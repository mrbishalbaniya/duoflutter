# Duo Self-Hosted OTA Update System

Enterprise-grade over-the-air updates for Duo Mobile **without Google Play**.

## Architecture

```
GitHub push (main)
  → GitHub Actions (analyze, test, build APK)
  → GitHub Release (app-release.apk)
  → DuoBackend OTA API (publish + activate)
  → Flutter app checks GET /api/app/version/
  → Update dialog → download → SHA256 verify → install
```

## Backend (`DuoBackend/update/`)

### API

| Endpoint | Auth | Purpose |
|----------|------|---------|
| `GET /api/app/version/` | Public | Version check with `installed_version` + `build_number` |
| `GET /api/app/version/history/` | Public | Published release history |
| `POST /api/app/version/download/` | Public | Increment download counter |
| `POST /api/app/version/publish/` | `X-OTA-Token` | CI/admin publish APK |

### Example response

```json
{
  "latest_version": "1.0.8",
  "minimum_version": "1.0.5",
  "build_number": 108,
  "apk_url": "https://duobackend.onrender.com/media/apk/duo-v1.0.8-b108.apk",
  "release_notes": ["Improved chat", "Settings redesign"],
  "force_update": false,
  "soft_update": true,
  "emergency_update": false,
  "file_size": "52.1 MB",
  "checksum_sha256": "abc123...",
  "update_available": true,
  "update_blocked": false
}
```

### Admin

Django admin → **App versions**

- Upload APK / set external URL
- Publish, activate, rollback, deactivate
- Force / soft / emergency flags
- Minimum supported version

### Storage backends

Set `OTA_STORAGE_BACKEND`:

| Value | Use case |
|-------|----------|
| `local` | Dev (`MEDIA_ROOT/media/apk/`) |
| `s3` | Amazon S3 |
| `r2` | Cloudflare R2 (`OTA_S3_ENDPOINT_URL`) |
| `spaces` | DigitalOcean Spaces |

Env vars: `OTA_S3_BUCKET_NAME`, `OTA_S3_ACCESS_KEY_ID`, `OTA_S3_SECRET_ACCESS_KEY`, `OTA_S3_REGION_NAME`, `OTA_S3_ENDPOINT_URL`, `OTA_S3_CUSTOM_DOMAIN`.

### Required secrets (Render)

```
OTA_PUBLISH_TOKEN=<long-random-token>
```

Run migration after deploy:

```bash
python manage.py migrate update
```

## Flutter (`lib/features/update/`)

| Module | Role |
|--------|------|
| `repositories/update_repository.dart` | API client |
| `services/update_services.dart` | Check, download (resume), SHA256, install |
| `providers/update_providers.dart` | Riverpod state machine |
| `presentation/dialogs/update_dialog.dart` | Material 3 update UI |
| `presentation/widgets/update_bridge.dart` | Startup auto-check |
| `presentation/sections/settings_update_section.dart` | Manual check + history |

### Behaviour

- **Startup**: checks every 24h (cached in Hive)
- **Soft update**: user can tap *Later* (ignored version stored)
- **Force / emergency**: blocking dialog, no dismiss
- **Download**: pause, resume, cancel, progress, ETA, speed
- **Security**: HTTPS only, SHA256 validation, downgrade blocked server-side
- **Install**: `REQUEST_INSTALL_PACKAGES` + system installer

## CI/CD

`DuoMobile/.github/workflows/flutter.yml` on `main`:

1. Analyze, format, test
2. Build signed APK/AAB
3. Publish GitHub Release
4. Call `publish-ota-release.sh` → DuoBackend
5. Upload `version.json` artifact

### GitHub secret

```
OTA_PUBLISH_TOKEN=<same as Render>
```

## Versioning

- **Semantic version**: `pubspec.yaml` → `version: 1.0.8+108`
- **Build number**: must monotonically increase (`+108`)
- CI tag: `v1.0.8-build.<run>`

## Rollback

Admin → select older published build → **Activate selected release**.

Only one active release per platform/channel.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| No update shown | Ensure active published version has higher `build_number` |
| Install blocked | Enable *Install unknown apps* for Duo |
| Checksum failed | Re-publish APK; verify `OTA_PUBLISH_TOKEN` upload succeeded |
| 404 APK URL | Configure S3/R2 or use GitHub `apk_url` fallback |

## Files

- Backend: `DuoBackend/update/`
- Flutter: `DuoMobile/lib/features/update/`
- CI: `DuoMobile/.github/scripts/publish-ota-release.sh`
- Docs: this file
