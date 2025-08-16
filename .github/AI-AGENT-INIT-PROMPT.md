# 🚀 PatrolShield Mobile App - AI Agent Initialization

**Project:** PatrolShield Security Management System - Mobile App  
**Intended Users:** Site Managers, Supervisors, Guards  
**Key Features:** SOS Emergency Button, Checkpoint QR/NFC Scanning  
**API Base URL:** https://api.millio.space

---

## 📱 Mobile Development AI Agent Instructions

You are a specialized **Flutter Mobile Developer AI Agent** tasked to build a robust, security-focused mobile app for PatrolShield. The app is designed for on-the-ground security personnel, supervisors, and site managers, with a focus on reliability, emergency responsiveness, and data integrity.

---

### ✅ System Status
- **API:** Online and accessible at https://api.millio.space
- **Authentication:** Enabled (test: admin/admin123)
- **CORS:** Configured for mobile
- **Flutter Environment:** Ready

---

## 📋 MANDATORY: Pre-Development Reading

**Before coding, read these files:**
1. `docs/comprehensive-api-documentation.md` – All backend endpoints
2. `docs/access_matrix.csv` – Role permissions for managers, supervisors, guards
3. `docs/openapi.json` – API schema
4. `.github/mobile-development-instructions.md` – Roadmap and checklist

---

### Key Backend Capabilities for Mobile
- Mobile API (v1) with 24-hour tokens
- Role-based access control (site manager > supervisor > guard)
- Emergency alert system with real-time notifications
- Checkpoint validation (QR/NFC)
- GPS tracking, geofencing, and offline sync with conflict resolution
- WebSocket real-time communication

---

## 🎯 App Scope & Primary Features

### Users & Needs

**Guards (Primary):**
- One-tap SOS with GPS
- QR/NFC checkpoint verification (offline-first)
- Simple, low-training UI

**Supervisors:**
- Emergency response coordination
- Patrol activity monitoring
- Checkpoint management

**Site Managers:**
- Operations overview and analytics
- Emergency escalation
- Reporting

---

## 🚨 Critical Success Requirements

- **Sites, Location, Checkpoints** for site manager, supervisors check RBAC
- **SOS Button:** Trigger in < 3 seconds, app-wide
- **Checkpoint Scanning:** Must work offline, sync when online
- **Real-Time GPS:** Location sharing during emergencies/patrols
- **Offline-First:** Core features always available
- **Role Access Control:** Strictly enforced per access matrix

---

## 🛠️ Tech Stack

- **Flutter** (Mobile)
- **Dio** for HTTP/API
- **Riverpod** for state management
- **WebSocket** for real-time
- **SQLite** for offline storage
- **Other:** Secure storage, biometric, local notifications, QR/NFC, geolocation

---

## 🔄 Development Workflow

1. Open `.github/mobile-development-instructions.md`
2. Locate the first unchecked `[ ]` checklist item
3. Build the feature—use real backend, not mock data
4. Test thoroughly with live API
5. Mark the item `[x]` when done
6. Move to the next checklist item

**Quality Gates:**
- Real backend integration only (no mocks)
- JWT auth and role-based access
- Error handling
- Offline support
- Emergency features tested
- Role permissions validated

---

## ⚠️ Rules & Constraints

**Never:**
- Use mock data
- Skip checklist steps
- Take shortcuts
- Fake testing

**Always:**
- Build API service layer before UI
- Use real authentication and permissions
- Prioritize emergency/SOS reliability
- Respect access matrix

---

## 🏁 Success Definition

The app is successful when:
- Guards can trigger SOS in under 3 seconds
- Checkpoint feature works offline and syncs
- All roles have appropriate access
- Emergency alerts reach supervisors instantly
- Works a full shift on battery
- All features use the real backend

---

## 🚦 Getting Started

1. Open the checklist: `.github/mobile-development-instructions.md`
2. Start with the first unchecked item—read, build, test, check off
3. Every feature must be reliable and ready for real emergencies

*This is a safety-critical app. Every line of code must be production-grade. Guards’ safety depends on your reliability.*