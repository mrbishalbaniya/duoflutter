# duoflutter

Flutter client for **DuoBackend** (`DuoMobile` repo).

> **Note:** The Expo/React Native app lives in [`../DuoMobileRN`](../DuoMobileRN). This folder is Flutter only.

## Architecture

- **Clean Architecture** (feature-first)
- **Riverpod** state management
- **GoRouter** navigation + auth guards
- **Dio** networking (JWT interceptors, refresh, retry queue)
- **Hive** + **flutter_secure_storage** (settings + JWT)

## Run

```bash
cd DuoMobile
flutter pub get
flutter run
```

Defaults to production API: `https://duobackend.onrender.com/api`

Or use `run_prod.ps1` / `run_prod.bat`.

### Local backend

```bash
# Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api --dart-define=WS_BASE_URL=ws://10.0.2.2:8000

# Physical device (LAN IP)
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api --dart-define=WS_BASE_URL=ws://192.168.1.10:8000
```

## Phase 1 — Analysis Summary

Backend is the single source of truth. Auth uses **JWT Bearer** (`access` + `refresh`). Web uses HTTP-only cookies; mobile stores tokens in secure storage.

### Integrated APIs (Phase 1)

| Domain | Endpoints |
|--------|-----------|
| Auth | login, register, refresh, logout, me, OTP, password reset/change |
| Profile | me GET/PUT, discover, visit |
| Matching | swipe, matches, liked-by-you, likes-you, profile-visitors, insights |
| Chat | conversations, messages, typing, ws-ticket, upload, react, delete, settings |
| Wallet | balance, top-up initiate, purchase, subscription plans/status |

### Phase 1 Screens

- Splash, Login, Register, Forgot password
- Bottom nav shell (Discover, Chat, Match, Map placeholder, Profile)
- Match swipe deck + celebration
- Discover tabs (visited / sent / liked you) with premium gating
- Chat list + thread (REST + WebSocket)
- Profile view + edit
- Wallet + Settings

## Remaining (Phase 2+)

- Full 11-step registration wizard (web parity)
- MapLibre globe, layers, activity heatmap WebSocket
- Verification liveness camera flow
- eSewa in-app WebView + deep link return
- FCM push notifications
- Voice messages, reactions UI, reply/delete UX
- Match insights screen
- 3D avatars API integration
- Google Sign-In native
- Photo upload + AI analysis
- SUPERLIKE polish, filters sheet
- Widget/repository test coverage expansion

## Missing / Mobile Gaps

- **eSewa**: backend returns HTML form POST — needs WebView form submit (currently opens payment URL externally)
- **Google OAuth**: backend supports `id_token`; native Google Sign-In not wired yet
- **Map**: no Flutter map implementation yet (placeholder screen)
- **Verification**: camera/liveness not implemented
- **FCM**: device registration endpoints exist; Firebase not configured in app
- **Weather / Avatars / Activity**: APIs analyzed, not yet in UI

## Inconsistencies (Web vs Backend)

- `POST /subscriptions/initiate/` deprecated (410) — web migrated to wallet; mobile follows wallet flow
- Some errors use `detail`, others `error` — Dio client handles both
- Chat conversation IDs should use `public_id` (10-digit), not internal DB id
- Web auth uses Next.js cookie BFF; mobile talks to Django directly with Bearer tokens

## Tests

```bash
flutter test
```
