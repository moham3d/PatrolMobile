# patrol_shield_admin

PatrolShield Admin Dashboard (Flutter Web)

## Getting Started

### 1. Install Flutter SDK
Follow the official guide: https://docs.flutter.dev/get-started/install

### 2. Get Dependencies
```sh
flutter pub get
```

### 3. Generate Model Files
```sh
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### 4. Run the Web App (Development)
```sh
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000

```

### 5. Build for Production
```sh
flutter build web
```

### 5b. Build Android APK
```sh
flutter build apk
```

### 6. Serve Production Build
You can serve the `build/web` directory with any static file server, e.g.:
```sh
npx serve build/web
```

### 7. Environment Configuration
Edit `.env` for API and app settings:
```
API_BASE_URL=http://localhost:8000
WS_BASE_URL=ws://localhost:8000
APP_NAME=PatrolShield Admin
APP_VERSION=1.0.0
```

---

For more details, see [docs/comprehensive-api-documentation.md](../docs/comprehensive-api-documentation.md).
