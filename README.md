# Duo Mobile

React Native (Expo) mobile app for **Duo** — mirrors the DuoFrontend web experience and connects to **DuoBackend**.

## Stack

- **Expo SDK 56** + **Expo Router** (file-based navigation)
- **TypeScript**
- **Plus Jakarta Sans** + **Inter** (same as web)
- Design tokens from `DuoFrontend/app/globals.css` (`#e84a7a` primary, dark luxury palette)

## Screens

| Screen | Route | Web equivalent |
|--------|-------|----------------|
| Login | `/login` | `app/login/page.tsx` |
| Register | `/register` | `app/register/page.tsx` |
| Match (swipe) | `/(tabs)/match` | `DiscoverExperience.tsx` |
| Discover lists | `/(tabs)/discover` | `DiscoverMatchesPage.tsx` |
| Chat list | `/(tabs)/chat` | `message.tsx` sidebar |
| Chat thread | `/chat/[id]` | `message.tsx` thread |
| Map | `/(tabs)/map` | `app/map/page.tsx` |
| Profile | `/(tabs)/profile` | `app/profile/page.tsx` |
| Settings | `/settings` | `SettingsPage.tsx` |
| Verify | `/verify` | `VerificationFlow.tsx` (stub) |
| Match celebration | `/celebration` | `match/celebration/page.tsx` |

Bottom tab bar matches web: **Discover · Chat · Match (FAB) · Map · Profile**

## Setup

### 1. Start DuoBackend

```bash
cd D:\8sem\DuoBackend
# activate venv, then:
python manage.py runserver 8001
```

### 2. Configure API URL

Create `.env` in `DuoMobile`:

```env
# Physical device: use your PC's LAN IP
EXPO_PUBLIC_API_URL=http://192.168.1.100:8001/api

# Android emulator:
# EXPO_PUBLIC_API_URL=http://10.0.2.2:8001/api

# iOS simulator / same machine:
EXPO_PUBLIC_API_URL=http://localhost:8001/api
```

Also add your machine IP to Django `CORS_ALLOWED_ORIGINS` and `ALLOWED_HOSTS`.

### 3. Run the app

```bash
cd D:\8sem\DuoMobile
npm install
npm start
```

Press `a` for Android emulator, `i` for iOS simulator, or scan QR with Expo Go.

## Project structure

```
DuoMobile/
├── app/                    # Expo Router screens
│   ├── (tabs)/             # Main tab navigation
│   ├── chat/[id].tsx       # Chat thread
│   ├── login.tsx
│   ├── register.tsx
│   ├── settings.tsx
│   └── verify.tsx
├── components/
│   ├── navigation/         # Custom Duo tab bar
│   └── ui/                 # Buttons, avatars, etc.
├── constants/theme.ts      # Colors, fonts, spacing
├── contexts/               # Auth + Theme
├── lib/
│   ├── api.ts              # DuoBackend REST client (SecureStore tokens)
│   ├── config.ts
│   └── mediaUrl.ts
└── types/index.ts
```

## API coverage

The mobile client implements the core flows:

- Auth: login, register, JWT refresh, logout
- Profiles: get/update, discover feed
- Matching: swipe, matches, liked-by-you, likes-you
- Chat: conversations, messages, send
- Verification: status (camera flow stub)
- Settings: theme, password change

## Next steps (not yet implemented)

- [ ] `expo-camera` liveness verification (port `VerificationFlow.tsx`)
- [ ] `react-native-maps` on Map screen
- [ ] WebSocket chat (`lib/chatWebSocket.ts`)
- [ ] Full 11-step registration wizard
- [ ] Gesture-based swipe cards (Reanimated)
- [ ] eSewa premium subscription
- [ ] Google Sign-In

## Related projects

- `D:\8sem\DuoFrontend` — Next.js web app
- `D:\8sem\DuoBackend` — Django REST API (`/api/docs/`)
