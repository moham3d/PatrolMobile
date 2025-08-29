# Mobile API Documentation

## Overview
The Mobile API provides optimized endpoints for mobile applications with offline capabilities, sync functionality, and mobile-specific features for guards in the field.

**Base URL**: `https://api.millio.space`  
**Authentication**: JWT Bearer Token required  
**Headers**: `Authorization: Bearer <token>`, `Content-Type: application/json`  
**Mobile Headers**: `X-Mobile-Version`, `X-Platform`, `X-Device-ID`

---

## Mobile API v1 (`/mobile/v1`)

### Authentication

#### POST /mobile/v1/auth/login
**Description**: Mobile login with device registration  
**Authentication**: None required

**Request Headers**:
- `X-Mobile-Version`: App version (e.g., "1.2.3")
- `X-Platform`: Platform (android/ios)
- `X-Device-ID`: Unique device identifier

**Request Body**:
```json
{
  "username": "john_guard",
  "password": "secure_password",
  "device_info": {
    "device_name": "Samsung Galaxy S21",
    "os_version": "Android 12",
    "app_version": "1.2.3",
    "push_token": "fcm_token_here"
  }
}
```

**Response (200)**:
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "token_type": "bearer",
  "expires_in": 3600,
  "user": {
    "id": 1,
    "username": "john_guard",
    "full_name": "John Doe",
    "role": "guard",
    "permissions": ["patrols:view", "checkpoints:visit"]
  },
  "device_registered": true,
  "offline_data": {
    "last_sync": "2024-01-21T08:00:00Z",
    "sync_required": false
  }
}
```

---

#### GET /mobile/v1/auth/profile
**Description**: Get mobile user profile  
**Authentication**: Bearer Token required

**Response (200)**:
```json
{
  "id": 1,
  "username": "john_guard",
  "full_name": "John Doe",
  "role": "guard",
  "assigned_sites": [
    {
      "site_id": 1,
      "site_name": "Downtown Office",
      "access_level": "full"
    }
  ],
  "mobile_settings": {
    "gps_tracking_enabled": true,
    "offline_mode_enabled": true,
    "photo_quality": "medium",
    "sync_frequency": "real_time"
  },
  "current_shift": {
    "shift_id": 5,
    "site_id": 1,
    "status": "in_progress",
    "clocked_in_at": "2024-01-21T08:05:00Z"
  }
}
```

---

#### POST /mobile/v1/auth/refresh
**Description**: Refresh mobile token  
**Authentication**: Bearer Token required

**Response (200)**:
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "expires_in": 3600,
  "sync_data_available": true
}
```

---

#### GET /mobile/v1/auth/app-info
**Description**: Get app configuration and features  
**Authentication**: Bearer Token required

**Response (200)**:
```json
{
  "app_config": {
    "features_enabled": {
      "offline_mode": true,
      "gps_tracking": true,
      "photo_upload": true,
      "panic_button": true
    },
    "limits": {
      "max_photo_size": 5242880,
      "max_offline_days": 7,
      "sync_batch_size": 50
    }
  },
  "server_info": {
    "api_version": "1.0.0",
    "maintenance_mode": false,
    "force_update_required": false
  }
}
```

---

### Emergency & Panic

#### POST /mobile/v1/emergency/sos
**Description**: Trigger SOS emergency alert  
**Authentication**: Bearer Token required

**Request Body**:
```json
{
  "location": {
    "latitude": 40.7128,
    "longitude": -74.0060,
    "accuracy": 5.0
  },
  "alert_type": "panic",
  "severity": "critical",
  "message": "Emergency assistance needed",
  "silent": false
}
```

**Response (200)**:
```json
{
  "alert_id": 1,
  "triggered_at": "2024-01-21T14:30:00Z",
  "status": "active",
  "response_team_notified": true,
  "estimated_response_time": "00:05:00",
  "contact_numbers": [
    "+1-555-SECURITY",
    "+1-555-EMERGENCY"
  ]
}
```

---

#### GET /mobile/v1/emergency/contacts
**Description**: Get emergency contact information  
**Authentication**: Bearer Token required

**Response (200)**:
```json
{
  "emergency_contacts": [
    {
      "name": "Security Control Room",
      "phone": "+1-555-SECURITY",
      "type": "primary",
      "available_24_7": true
    },
    {
      "name": "Site Manager",
      "phone": "+1-555-MANAGER",
      "type": "secondary",
      "available_hours": "08:00-18:00"
    }
  ],
  "procedures": [
    {
      "scenario": "Medical Emergency",
      "steps": [
        "Press panic button",
        "Call 911 if severe",
        "Contact security control room",
        "Secure the area"
      ]
    }
  ]
}
```

---

### Patrols (Mobile v1)

#### GET /mobile/v1/patrols/assigned
**Description**: Get patrols assigned to current user  
**Authentication**: Bearer Token required

**Query Parameters**:
- `status` (string, optional): Filter by status (scheduled, in_progress, completed)
- `date` (date, optional): Filter by date (YYYY-MM-DD)

**Response (200)**:
```json
{
  "assigned_patrols": [
    {
      "patrol_id": 1,
      "template_name": "Morning Perimeter Check",
      "site_name": "Downtown Office",
      "scheduled_time": "2024-01-21T10:00:00Z",
      "status": "scheduled",
      "priority": "high",
      "estimated_duration": "01:30:00",
      "checkpoint_count": 8,
      "offline_data_available": true
    }
  ],
  "next_patrol": {
    "patrol_id": 2,
    "scheduled_time": "2024-01-21T14:00:00Z",
    "template_name": "Afternoon Safety Check"
  }
}
```

---

#### POST /mobile/v1/patrols/{patrol_id}/start
**Description**: Start assigned patrol  
**Authentication**: Bearer Token required

**Request Body**:
```json
{
  "location": {
    "latitude": 40.7128,
    "longitude": -74.0060,
    "accuracy": 5.0
  },
  "notes": "Starting patrol on time"
}
```

**Response (200)**:
```json
{
  "patrol_run_id": 1,
  "started_at": "2024-01-21T10:05:00Z",
  "status": "in_progress",
  "checkpoints": [
    {
      "checkpoint_id": 1,
      "name": "Main Entrance",
      "sequence_order": 1,
      "scan_method": "qr",
      "scan_code": "QR123456",
      "coordinates": {
        "latitude": 40.7128,
        "longitude": -74.0060
      },
      "required": true,
      "status": "pending"
    }
  ],
  "offline_mode": false
}
```

---

#### POST /mobile/v1/patrols/{patrol_id}/checkpoints/visit
**Description**: Record checkpoint visit (with offline support)  
**Authentication**: Bearer Token required

**Request Body**:
```json
{
  "checkpoint_id": 1,
  "location": {
    "latitude": 40.7128,
    "longitude": -74.0060,
    "accuracy": 3.5
  },
  "scan_data": {
    "method": "qr",
    "code": "QR123456",
    "scan_time": "2024-01-21T10:10:00Z"
  },
  "notes": "All clear, no issues",
  "photos": [
    {
      "filename": "checkpoint_1.jpg",
      "base64_data": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQ...",
      "size": 245760
    }
  ],
  "offline_id": "offline_visit_123"
}
```

**Response (200)**:
```json
{
  "visit_id": 1,
  "checkpoint_id": 1,
  "visited_at": "2024-01-21T10:10:00Z",
  "scan_verified": true,
  "gps_verified": true,
  "offline_sync": false,
  "next_checkpoint": {
    "checkpoint_id": 2,
    "name": "Parking Garage",
    "distance": 150,
    "bearing": 45
  }
}
```

---

### Sync Operations

#### POST /mobile/v1/sync/upload
**Description**: Upload offline data to server  
**Authentication**: Bearer Token required

**Request Body**:
```json
{
  "sync_timestamp": "2024-01-21T15:00:00Z",
  "data": {
    "checkpoint_visits": [
      {
        "offline_id": "offline_visit_123",
        "checkpoint_id": 1,
        "visited_at": "2024-01-21T10:10:00Z",
        "location": {
          "latitude": 40.7128,
          "longitude": -74.0060
        },
        "scan_data": {
          "method": "qr",
          "code": "QR123456"
        },
        "notes": "Offline visit",
        "photos": ["base64_encoded_photo"]
      }
    ],
    "incidents": [],
    "gps_tracks": [
      {
        "timestamp": "2024-01-21T10:05:00Z",
        "latitude": 40.7128,
        "longitude": -74.0060,
        "accuracy": 5.0
      }
    ]
  }
}
```

**Response (200)**:
```json
{
  "sync_result": {
    "processed_items": 15,
    "successful_uploads": 14,
    "failed_uploads": 1,
    "conflicts": [],
    "server_timestamp": "2024-01-21T15:01:00Z"
  },
  "failed_items": [
    {
      "offline_id": "offline_visit_124",
      "error": "Checkpoint not found",
      "retry_allowed": true
    }
  ]
}
```

---

#### POST /mobile/v1/sync/download
**Description**: Download latest data for offline use  
**Authentication**: Bearer Token required

**Request Body**:
```json
{
  "last_sync": "2024-01-21T08:00:00Z",
  "requested_data": ["sites", "checkpoints", "patrol_templates", "shifts"]
}
```

**Response (200)**:
```json
{
  "sync_data": {
    "timestamp": "2024-01-21T15:00:00Z",
    "sites": [
      {
        "id": 1,
        "name": "Downtown Office",
        "coordinates": {
          "latitude": 40.7128,
          "longitude": -74.0060
        }
      }
    ],
    "checkpoints": [
      {
        "id": 1,
        "name": "Main Entrance",
        "site_id": 1,
        "scan_method": "qr",
        "scan_code": "QR123456",
        "coordinates": {
          "latitude": 40.7128,
          "longitude": -74.0060
        }
      }
    ],
    "patrol_templates": [],
    "shifts": []
  },
  "next_sync_recommended": "2024-01-21T16:00:00Z"
}
```

---

## Mobile API v2 (`/mobile/v2`)

### Enhanced Patrols

#### GET /mobile/v2/patrols/templates
**Description**: List optimized patrol templates  
**Authentication**: Bearer Token required

**Query Parameters**:
- `site_id` (integer, optional): Filter by site
- `limit` (integer, optional): Max results (default: 20)

**Response (200)**:
```json
{
  "templates": [
    {
      "id": 1,
      "name": "Morning Perimeter Check",
      "site_id": 1,
      "estimated_duration": "01:30:00",
      "checkpoint_count": 8,
      "offline_available": true,
      "last_updated": "2024-01-15T10:30:00Z"
    }
  ]
}
```

---

#### POST /mobile/v2/patrols/start
**Description**: Start patrol with enhanced tracking  
**Authentication**: Bearer Token required

**Request Body**:
```json
{
  "template_id": 1,
  "location": {
    "latitude": 40.7128,
    "longitude": -74.0060,
    "accuracy": 3.0
  },
  "shift_id": 5,
  "offline_mode": false
}
```

**Response (201)**:
```json
{
  "run_id": 1,
  "started_at": "2024-01-21T10:00:00Z",
  "template": {
    "id": 1,
    "name": "Morning Perimeter Check",
    "checkpoints": [
      {
        "id": 1,
        "name": "Main Entrance",
        "sequence": 1,
        "scan_method": "qr",
        "required": true
      }
    ]
  },
  "navigation": {
    "current_checkpoint": 1,
    "route_optimized": true,
    "total_distance": 2.3
  }
}
```

---

#### POST /mobile/v2/patrols/sync
**Description**: Batch sync patrol visits  
**Authentication**: Bearer Token required

**Request Body**:
```json
{
  "visits": [
    {
      "run_id": 1,
      "checkpoint_id": 1,
      "visited_at": "2024-01-21T10:10:00Z",
      "location": {
        "latitude": 40.7128,
        "longitude": -74.0060
      },
      "scan_verified": true,
      "offline_id": "visit_1"
    }
  ]
}
```

**Response (200)**:
```json
{
  "processed": 5,
  "successful": 5,
  "failed": 0,
  "conflicts": [],
  "next_sync_token": "sync_token_123"
}
```

---

## Offline Capabilities

### Data Storage
The mobile app maintains offline copies of:
- Assigned patrol templates
- Checkpoint information and scan codes
- Site maps and coordinates
- Emergency contact information

### Sync Strategy
1. **Real-time sync** when online
2. **Batch sync** when connectivity restored
3. **Conflict resolution** for overlapping data
4. **Compression** for large data transfers

### Offline Operations
- Start and complete patrols
- Visit checkpoints with scan verification
- Take photos and notes
- Record GPS tracks
- Trigger emergency alerts (queued for sync)

---

## Error Handling

### Network Errors
```json
{
  "error": "network_error",
  "message": "Unable to connect to server",
  "offline_mode_available": true,
  "retry_after": 30
}
```

### Sync Conflicts
```json
{
  "error": "sync_conflict", 
  "message": "Data conflict detected",
  "conflicts": [
    {
      "type": "checkpoint_visit",
      "local_data": {...},
      "server_data": {...},
      "resolution_options": ["use_local", "use_server", "merge"]
    }
  ]
}
```

---

## Integration Examples

### Complete Mobile Patrol Flow
```javascript
// Start patrol
const startPatrol = async (templateId) => {
  const location = await getCurrentLocation();
  
  const response = await fetch('/mobile/v2/patrols/start', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
      'X-Mobile-Version': '1.2.3',
      'X-Platform': 'android'
    },
    body: JSON.stringify({
      template_id: templateId,
      location: location
    })
  });
  
  return response.json();
};

// Visit checkpoint
const visitCheckpoint = async (runId, checkpointId, scanCode) => {
  const location = await getCurrentLocation();
  const photo = await capturePhoto();
  
  const visitData = {
    checkpoint_id: checkpointId,
    location: location,
    scan_data: {
      method: 'qr',
      code: scanCode,
      scan_time: new Date().toISOString()
    },
    photos: [photo],
    offline_id: generateOfflineId()
  };
  
  if (isOnline()) {
    return await syncVisitToServer(runId, visitData);
  } else {
    return await storeVisitOffline(visitData);
  }
};
```

### Offline Data Management
```javascript
const syncOfflineData = async () => {
  const offlineData = await getStoredOfflineData();
  
  if (offlineData.length === 0) return;
  
  const response = await fetch('/mobile/v1/sync/upload', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      sync_timestamp: new Date().toISOString(),
      data: offlineData
    })
  });
  
  const result = await response.json();
  
  // Clear successfully synced data
  await clearSyncedOfflineData(result.successful_uploads);
  
  // Handle failed uploads
  if (result.failed_uploads.length > 0) {
    await scheduleRetrySync(result.failed_items);
  }
};
```