# PatrolShield Mobile Application

A Flutter mobile application for security patrol management, designed for guards, supervisors, and site managers.

## Features

- **Role-based Authentication**: Support for Guards, Supervisors, and Site Managers
- **Emergency SOS System**: One-touch emergency alerts with GPS location
- **Checkpoint Scanning**: QR code and NFC tag scanning for patrol verification
- **Real-time Communication**: WebSocket integration for live updates
- **Offline Support**: Local data storage and sync capabilities

## Getting Started

### Prerequisites

- Flutter SDK 3.0.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code
- Android device or emulator
- iOS device or simulator (for iOS development)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/moham3d/PatrolMobile.git
cd PatrolMobile
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate code files:
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

4. Run the application:
```bash
flutter run
```

## API Configuration

The app connects to the PatrolShield backend API:
- **Production**: https://api.millio.space
- **API Version**: 2.0
- **Mobile API**: /mobile/v1

## Project Structure

```
lib/
├── core/
│   ├── constants/          # App constants and configuration
│   ├── exceptions/         # Custom exception classes
│   ├── router/            # App routing configuration
│   ├── services/          # Core services (API, storage)
│   └── theme/             # App theming
├── features/
│   ├── auth/              # Authentication feature
│   ├── dashboard/         # Main dashboard
│   ├── emergency/         # SOS and emergency features
│   └── checkpoints/       # Checkpoint scanning
└── shared/
    ├── widgets/           # Reusable widgets
    └── utils/             # Utility functions
```

## Development Checklist

Following the development roadmap in `.github/mobile-development-instructions.md`:

### Phase 1: Foundation & Emergency Features ✅
- [x] Flutter Project Initialization
- [x] Project structure setup
- [x] Essential packages configuration
- [x] API service layer implementation
- [ ] Role-based authentication system
- [ ] SOS emergency button implementation
- [ ] Emergency response & escalation

### Phase 2: Checkpoint Scanning & Core Features
- [ ] QR/NFC checkpoint implementation
- [ ] Patrol progress & checkpoint management
- [ ] Offline checkpoint logging
- [ ] Real-time features & communication

### Phase 3: Enhanced Features & Polish
- [ ] Incident reporting & media
- [ ] Performance & battery optimization
- [ ] Testing & quality assurance
- [ ] Production deployment preparation

## Key Dependencies

- **dio**: HTTP client for API communication
- **flutter_riverpod**: State management
- **go_router**: Declarative routing
- **flutter_secure_storage**: Secure token storage
- **geolocator**: GPS location services
- **qr_code_scanner**: QR code scanning
- **nfc_manager**: NFC tag reading
- **web_socket_channel**: Real-time communication

## User Roles & Permissions

Based on `docs/access_matrix.csv`:

- **Guards**: SOS alerts, checkpoint scanning, incident reporting
- **Supervisors**: Guard monitoring, emergency response, patrol management
- **Site Managers**: Full site operations, analytics, user management

## License

This project is proprietary software for PatrolShield Security Management System.

To build the release APK, run:
gradlew assembleRelease

To build the debug APK, run:
gradlew assembleDebug