# PatrolShield Mobile App Development Instructions
## For Site Managers, Supervisors & Guards

**Target Users:** Site managers, supervisors, and security guards  
**Core Features:** SOS Emergency Button + Checkpoint Scanning (QR/NFC)  
**API Base:** https://api.millio.space  
**Backend Documentation:** `docs/comprehensive-api-documentation.md`, `docs/access_matrix.csv`, `docs/openapi.json`

---

## 📋 Required Reading Before Development

**MANDATORY:** Before starting any Flutter mobile development work, you MUST read and understand the complete backend API capabilities documented in:

- **`docs/comprehensive-api-documentation.md`** - All 293+ backend API endpoints and capabilities
- **`docs/access_matrix.csv`** - Role-based permissions for site managers, supervisors, guards
- **`docs/openapi.json`** - OpenAPI specification for all endpoints

### Key Backend Capabilities for Mobile App:
- **Mobile API (v1)** - Optimized for Flutter mobile apps with:
  - Mobile-optimized authentication with extended 24-hour tokens
  - Lightweight response schemas (≤15 fields per object)
  - Role-based access control (site manager > supervisor > guard)
  - Flutter patrol management with GPS integration using `geolocator`
  - Flutter incident reporting with media capture using `image_picker`
  - **Emergency/panic alert system** with real-time broadcasting via `web_socket_channel`
  - **Checkpoint scanning** with QR/NFC validation and verification
  - Offline sync capabilities using `sqflite` and conflict resolution
  - Flutter performance monitoring with device performance metrics

---

## 🎯 Mobile App Scope & User Roles

### Target User Types & Permissions (Based on access_matrix.csv):

#### 1. **Site Managers** (Highest Access)
- Full access to all site operations and analytics
- Can manage supervisors and guards
- Emergency management and escalation oversight
- Complete checkpoint and patrol monitoring
- Incident creation, assignment, and resolution

#### 2. **Supervisors** (Intermediate Access) 
- Monitor and manage guards under their supervision
- Create and assign patrol routes and checkpoints
- Incident reporting and initial response
- Emergency response coordination
- Limited administrative functions

#### 3. **Guards** (Field Access)
- **Primary Focus:** SOS Emergency Button + Checkpoint Scanning
- Execute assigned patrol routes
- Scan checkpoints (QR/NFC) during patrols
- Report incidents with multimedia evidence
- Emergency alert triggering
- Basic communication with supervisors

---

## 🚨 Priority Features for MVP

### 1. **Emergency SOS System** (Critical Priority)
- **One-Touch SOS Button** - Prominent emergency button on all screens
- **Automatic Location Broadcasting** - GPS coordinates sent with emergency alerts
- **Real-Time Alert Distribution** - Immediate notifications to supervisors/managers
- **Emergency Escalation** - Automatic escalation if no response
- **Emergency Contact Integration** - Direct dialing to emergency services

### 2. **Checkpoint Scanning System** (Core Functionality)
- **QR Code Scanning** - Using `qr_code_scanner` package
- **NFC Tag Reading** - Using `nfc_manager` package  
- **Checkpoint Verification** - Real-time validation against backend
- **Patrol Progress Tracking** - Visual progress indicators
- **Offline Checkpoint Logging** - Queue scans when offline, sync when connected

### 3. **Simple Authentication & Navigation**
- **Role-Based Login** - Different interfaces for managers/supervisors/guards
- **Biometric Authentication** - Fingerprint/Face ID for quick access
- **Simplified Navigation** - Role-appropriate menu systems
- **Auto-Login** - Secure token storage for seamless access

---

## 📱 Essential Flutter Packages for PatrolShield Mobile

### Core Packages
```yaml
dependencies:
  # HTTP & API Communication
  dio: ^5.3.2                          # HTTP client with interceptors
  
  # State Management & Navigation  
  riverpod: ^2.4.6                     # State management
  go_router: ^12.1.1                   # Declarative routing
  
  # Security & Storage
  flutter_secure_storage: ^9.0.0       # Secure token storage
  local_auth: ^2.1.6                   # Biometric authentication
  crypto: ^3.0.3                       # Encryption utilities
  
  # Location & GPS
  geolocator: ^10.1.0                  # GPS location services
  permission_handler: ^11.0.1          # Runtime permissions
  
  # Emergency & Communication
  web_socket_channel: ^2.4.0           # Real-time WebSocket
  firebase_messaging: ^14.7.3          # Push notifications
  flutter_local_notifications: ^16.1.0 # Local notifications
  emergency_dialer: ^1.0.0             # Emergency dialing
  
  # Scanning & NFC
  qr_code_scanner: ^1.0.1              # QR code scanning
  nfc_manager: ^3.3.0                  # NFC tag reading/writing
  
  # Media & Camera
  camera: ^0.10.5+5                    # Camera control
  image_picker: ^1.0.4                 # Image selection
  
  # Offline Storage & Sync
  sqflite: ^2.3.0                      # SQLite database
  hive: ^2.2.3                         # Lightweight storage
  connectivity_plus: ^5.0.1            # Network monitoring
  
  # UI & UX
  flutter_map: ^6.1.0                  # Interactive maps
  cached_network_image: ^3.3.0         # Image caching
  lottie: ^2.7.0                       # Animations for SOS
```

---

## 📋 Mobile Development Checklist

> **Mark each box `[x]` only when the corresponding task is complete, tested with real backend, and merged.**

### Phase 1: Foundation & Emergency Features (Week 1-2)

#### Week 1: Project Setup & Authentication

- [x] **Day 1-2: Flutter Project Initialization**
    - [x] Initialize Flutter project with proper folder structure
    - [x] Configure development environment (Android Studio, VS Code)
    - [x] Set up essential packages (dio, riverpod, go_router)
    - [x] Configure API service layer for https://api.millio.space
    - [x] **Deliverables:** Project initialized, packages configured, API service ready

- [x] **Day 3-5: Role-Based Authentication System**
    - [x] Implement login with role detection (manager/supervisor/guard)
    - [x] Create secure token storage with flutter_secure_storage
    - [x] Build biometric authentication with local_auth
    - [x] Implement automatic token refresh mechanism
    - [x] Create role-based navigation routing
    - [x] **Deliverables:** Complete auth system, role-based UI, biometric login

#### Week 2: Emergency SOS System (Critical Priority)

- [ ] **Day 1-3: SOS Emergency Button Implementation**
    - [ ] Create prominent SOS button widget (always visible)
    - [ ] Implement one-touch emergency activation
    - [ ] Build automatic GPS location capture with geolocator
    - [ ] Create emergency alert payload structure
    - [ ] Implement real-time alert broadcasting via WebSocket
    - [ ] **Deliverables:** Working SOS button, location capture, alert broadcasting

- [ ] **Day 4-5: Emergency Response & Escalation**
    - [ ] Build emergency contact integration
    - [ ] Implement automatic escalation workflow
    - [ ] Create emergency response tracking
    - [ ] Add emergency cancel/resolve functionality
    - [ ] Implement emergency history logging
    - [ ] **Deliverables:** Complete emergency system, escalation, response tracking

### Phase 2: Checkpoint Scanning & Core Features (Week 3-4)

#### Week 3: Checkpoint Scanning System

- [ ] **Day 1-3: QR/NFC Checkpoint Implementation**
    - [ ] Implement QR code scanning with qr_code_scanner
    - [ ] Create NFC tag reading with nfc_manager
    - [ ] Build checkpoint verification against backend API
    - [ ] Implement checkpoint validation workflow
    - [ ] Create scanning feedback (success/error states)
    - [ ] **Deliverables:** Working QR/NFC scanning, checkpoint verification

- [ ] **Day 4-5: Patrol Progress & Checkpoint Management**
    - [ ] Build patrol route display with flutter_map
    - [ ] Create checkpoint progress tracking
    - [ ] Implement patrol completion workflow
    - [ ] Add checkpoint status indicators
    - [ ] Create patrol history and reporting
    - [ ] **Deliverables:** Patrol tracking, progress indicators, completion workflow

#### Week 4: Offline Support & Data Sync

- [ ] **Day 1-3: Offline Checkpoint Logging**
    - [ ] Set up local SQLite database with sqflite
    - [ ] Implement offline checkpoint scanning and queuing
    - [ ] Create data synchronization service
    - [ ] Build conflict resolution for offline data
    - [ ] Implement connectivity monitoring
    - [ ] **Deliverables:** Offline capability, data sync, conflict resolution

- [ ] **Day 4-5: Real-Time Features & Communication**
    - [ ] Implement WebSocket connection for live updates
    - [ ] Create real-time patrol status sharing
    - [ ] Build push notifications with firebase_messaging
    - [ ] Implement location sharing during active patrols
    - [ ] Create basic in-app messaging for emergencies
    - [ ] **Deliverables:** Real-time updates, notifications, basic communication

### Phase 3: Enhanced Features & Polish (Week 5-6)

#### Week 5: Incident Reporting & Media

- [ ] **Day 1-3: Incident Creation & Documentation**
    - [ ] Build incident reporting form
    - [ ] Implement photo/video capture with camera/image_picker
    - [ ] Create incident categorization (based on user role)
    - [ ] Build incident workflow management
    - [ ] Add incident location tagging
    - [ ] **Deliverables:** Incident reporting, media capture, workflow

- [ ] **Day 4-5: Performance & Battery Optimization**
    - [ ] Implement background location optimization
    - [ ] Create intelligent sync scheduling with workmanager
    - [ ] Build battery usage monitoring
    - [ ] Optimize image compression and caching
    - [ ] Implement performance monitoring
    - [ ] **Deliverables:** Performance optimization, battery efficiency

#### Week 6: Testing & Production Readiness

- [ ] **Day 1-3: Testing & Quality Assurance**
    - [ ] Implement unit tests for critical features
    - [ ] Create integration tests for SOS and scanning
    - [ ] Build widget tests for key components
    - [ ] Test offline/online sync scenarios
    - [ ] Perform security testing (auth, data storage)
    - [ ] **Deliverables:** Comprehensive testing suite

- [ ] **Day 4-5: Production Deployment Preparation**
    - [ ] Prepare app store metadata and screenshots
    - [ ] Configure production API endpoints
    - [ ] Set up crash reporting and analytics
    - [ ] Create beta testing with Firebase App Distribution
    - [ ] Finalize app permissions and security
    - [ ] **Deliverables:** Production-ready app, store submission prep

---

## 🚦 Critical Success Criteria

### For Guards (Primary Users):
- **SOS button must work in under 3 seconds** from any screen
- **Checkpoint scanning must work offline** and sync when connected
- **Simple, intuitive UI** - minimal training required
- **Battery efficient** - full shift usage without charging

### For Supervisors:
- **Real-time visibility** into guard locations and checkpoint progress
- **Immediate emergency notifications** with location data
- **Simple patrol assignment** and monitoring capabilities

### For Site Managers:
- **Complete operational oversight** of all site activities
- **Emergency response coordination** and escalation management
- **Comprehensive reporting** and analytics dashboard

---

## 🔧 Development Guidelines

### API Integration Rules:
- **NO mock data** - Always use real backend API at https://api.millio.space
- **Real JWT authentication** - Use actual login endpoints with role validation
- **Real-time features** - Use actual WebSocket connections
- **Proper error handling** - Handle all backend error responses
- **Role-based permissions** - Respect access_matrix.csv restrictions

### Code Quality Standards:
- **API-first development** - Build service layer before UI
- **Offline-first design** - All features must work offline where possible
- **Security by design** - Encrypt sensitive data, secure storage
- **Performance optimized** - Efficient battery usage, fast response times
- **Accessible design** - Easy to use in field conditions

### Testing Requirements:
- **Real backend testing** - Test all features with actual API
- **Offline scenario testing** - Verify offline/online sync works
- **Emergency flow testing** - Critical path testing for SOS features
- **Role-based testing** - Verify permissions work correctly
- **Field testing** - Test in actual security environments

---

**Remember: This mobile app is mission-critical for security personnel. Every feature must be reliable, fast, and work in emergency situations.**