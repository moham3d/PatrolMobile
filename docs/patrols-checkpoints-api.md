# Patrols & Checkpoints API Documentation

## Overview
The Patrols & Checkpoints API manages patrol templates, patrol runs, checkpoint definitions, and checkpoint visits within the PatrolShield system.

**Base URL**: `https://api.millio.space`  
**Authentication**: JWT Bearer Token required  
**Headers**: `Authorization: Bearer <token>`, `Content-Type: application/json`

---

## Patrol Templates API

### GET /patrol-templates
**Description**: List patrol templates with filtering  
**Permission**: `patrols:view`

**Query Parameters**:
- `site_id` (integer, optional): Filter by site
- `active_only` (boolean, optional): Show only active templates (default: true)
- `page` (integer, optional): Page number (default: 1)
- `per_page` (integer, optional): Items per page (default: 20, max: 100)

**Response (200)**:
```json
{
  "templates": [
    {
      "id": 1,
      "name": "Morning Perimeter Check",
      "description": "Complete perimeter security check",
      "site_id": 1,
      "site_name": "Downtown Office",
      "estimated_duration": "01:30:00",
      "checkpoint_count": 8,
      "is_active": true,
      "created_at": "2024-01-15T10:30:00Z",
      "frequency": "daily",
      "priority": "high",
      "checkpoints": [
        {
          "id": 1,
          "name": "Main Entrance",
          "sequence_order": 1,
          "required": true
        }
      ]
    }
  ],
  "total": 1,
  "page": 1,
  "per_page": 20
}
```

---

### POST /patrol-templates
**Description**: Create new patrol template  
**Permission**: `patrols:manage`

**Request Body**:
```json
{
  "name": "Evening Security Round",
  "description": "Comprehensive evening security patrol",
  "site_id": 1,
  "estimated_duration": "02:00:00",
  "frequency": "daily",
  "priority": "medium",
  "is_active": true,
  "checkpoints": [
    {
      "checkpoint_id": 1,
      "sequence_order": 1,
      "required": true,
      "estimated_duration": "00:05:00"
    },
    {
      "checkpoint_id": 2,
      "sequence_order": 2,
      "required": true,
      "estimated_duration": "00:10:00"
    }
  ],
  "settings": {
    "gps_verification_required": true,
    "photo_evidence_required": false,
    "notes_required": false
  }
}
```

**Response (201)**:
```json
{
  "id": 2,
  "name": "Evening Security Round",
  "description": "Comprehensive evening security patrol",
  "site_id": 1,
  "estimated_duration": "02:00:00",
  "checkpoint_count": 2,
  "is_active": true,
  "created_at": "2024-01-21T15:30:00Z",
  "settings": {
    "gps_verification_required": true,
    "photo_evidence_required": false,
    "notes_required": false
  }
}
```

---

### GET /patrol-templates/{id}
**Description**: Get specific patrol template details  
**Permission**: `patrols:view`

**Response (200)**:
```json
{
  "id": 1,
  "name": "Morning Perimeter Check",
  "description": "Complete perimeter security check",
  "site_id": 1,
  "site_name": "Downtown Office",
  "estimated_duration": "01:30:00",
  "checkpoint_count": 8,
  "is_active": true,
  "created_at": "2024-01-15T10:30:00Z",
  "checkpoints": [
    {
      "id": 1,
      "name": "Main Entrance",
      "zone_name": "Entrance Zone",
      "sequence_order": 1,
      "required": true,
      "estimated_duration": "00:05:00",
      "scan_method": "qr",
      "coordinates": {
        "latitude": 40.7128,
        "longitude": -74.0060
      }
    }
  ],
  "statistics": {
    "total_runs": 156,
    "average_completion_time": "01:25:00",
    "completion_rate": 98.5,
    "last_run": "2024-01-21T08:30:00Z"
  }
}
```

---

## Patrol Runs API

### POST /patrol-runs/start
**Description**: Start a new patrol run  
**Permission**: `patrols:view` or assigned guard

**Request Body**:
```json
{
  "template_id": 1,
  "guard_id": 1,
  "shift_id": 5,
  "notes": "Starting morning patrol"
}
```

**Response (201)**:
```json
{
  "run_id": 1,
  "template_id": 1,
  "template_name": "Morning Perimeter Check",
  "guard_id": 1,
  "guard_name": "John Doe",
  "started_at": "2024-01-21T08:30:00Z",
  "status": "in_progress",
  "estimated_completion": "2024-01-21T10:00:00Z",
  "checkpoints": [
    {
      "checkpoint_id": 1,
      "name": "Main Entrance",
      "sequence_order": 1,
      "required": true,
      "status": "pending"
    }
  ]
}
```

---

### POST /patrol-runs/{run_id}/checkpoints/visit
**Description**: Record checkpoint visit during patrol  
**Permission**: `patrols:view` or assigned guard

**Request Body**:
```json
{
  "checkpoint_id": 1,
  "latitude": 40.7128,
  "longitude": -74.0060,
  "scan_method": "qr",
  "scan_code": "QR123456",
  "notes": "All clear, no issues observed",
  "photo_evidence": ["file_id_1", "file_id_2"]
}
```

**Response (200)**:
```json
{
  "visit_id": 1,
  "checkpoint_id": 1,
  "checkpoint_name": "Main Entrance",
  "visited_at": "2024-01-21T08:35:00Z",
  "location": {
    "latitude": 40.7128,
    "longitude": -74.0060
  },
  "scan_verified": true,
  "gps_verified": true,
  "next_checkpoint": {
    "id": 2,
    "name": "Parking Garage",
    "sequence_order": 2
  }
}
```

---

### POST /patrol-runs/{run_id}/end
**Description**: Complete patrol run  
**Permission**: `patrols:view` or assigned guard

**Request Body**:
```json
{
  "completion_notes": "Patrol completed successfully, no incidents",
  "issues_found": [
    {
      "description": "Burnt out light in parking area",
      "location": "Parking Zone B",
      "severity": "low"
    }
  ]
}
```

**Response (200)**:
```json
{
  "run_id": 1,
  "completed_at": "2024-01-21T09:45:00Z",
  "status": "completed",
  "duration": "01:15:00",
  "checkpoints_visited": 8,
  "checkpoints_total": 8,
  "completion_rate": 100,
  "issues_reported": 1
}
```

---

## Checkpoints API

### GET /checkpoints/
**Description**: List checkpoints with filtering  
**Permission**: `checkpoints:view`

**Query Parameters**:
- `skip` (integer): Records to skip (default: 0)
- `limit` (integer): Max records (default: 100)
- `site_id` (integer, optional): Filter by site
- `zone_id` (integer, optional): Filter by zone
- `is_active` (boolean, optional): Filter by active status

**Response (200)**:
```json
{
  "checkpoints": [
    {
      "id": 1,
      "name": "Main Entrance Scanner",
      "description": "Primary entrance checkpoint with QR scanner",
      "site_id": 1,
      "zone_id": 1,
      "zone_name": "Main Entrance",
      "scan_method": "qr",
      "scan_code": "QR123456",
      "coordinates": {
        "latitude": 40.7128,
        "longitude": -74.0060
      },
      "is_active": true,
      "created_at": "2024-01-15T10:30:00Z",
      "visit_count": 145,
      "last_visit": "2024-01-21T08:35:00Z"
    }
  ],
  "total": 1
}
```

---

### POST /checkpoints/
**Description**: Create new checkpoint  
**Permission**: `checkpoints:manage` (admin/manager)

**Request Body**:
```json
{
  "name": "Emergency Exit - North",
  "description": "North side emergency exit checkpoint",
  "site_id": 1,
  "zone_id": 3,
  "scan_method": "nfc",
  "scan_code": "NFC789012",
  "coordinates": {
    "latitude": 40.7135,
    "longitude": -74.0055
  },
  "is_active": true,
  "settings": {
    "gps_accuracy_required": "high",
    "photo_required": false,
    "notes_required": true
  }
}
```

**Response (201)**:
```json
{
  "id": 9,
  "name": "Emergency Exit - North",
  "description": "North side emergency exit checkpoint",
  "site_id": 1,
  "zone_id": 3,
  "scan_method": "nfc",
  "scan_code": "NFC789012",
  "coordinates": {
    "latitude": 40.7135,
    "longitude": -74.0055
  },
  "is_active": true,
  "created_at": "2024-01-21T16:00:00Z"
}
```

---

### POST /checkpoints/{checkpoint_id}/visit
**Description**: Record standalone checkpoint visit  
**Permission**: `checkpoints:visit`

**Query Parameters**:
- `latitude` (float): GPS latitude
- `longitude` (float): GPS longitude
- `notes` (string, optional): Visit notes
- `patrol_id` (integer, optional): Associated patrol run
- `scan_method` (string): Scanning method used

**Request Body**:
```json
{
  "scan_code": "QR123456",
  "photo_evidence": ["file_id_1"]
}
```

**Response (200)**:
```json
{
  "visit_id": 1,
  "checkpoint_id": 1,
  "visited_at": "2024-01-21T14:30:00Z",
  "guard_id": 1,
  "guard_name": "John Doe",
  "location": {
    "latitude": 40.7128,
    "longitude": -74.0060
  },
  "scan_verified": true,
  "gps_verified": true
}
```

---

### GET /checkpoints/{checkpoint_id}/visits
**Description**: Get visit history for checkpoint  
**Permission**: `checkpoints:view`

**Query Parameters**:
- `limit` (integer): Max records (default: 50)
- `include_photos` (boolean): Include photo evidence (default: false)

**Response (200)**:
```json
{
  "visits": [
    {
      "id": 1,
      "visited_at": "2024-01-21T14:30:00Z",
      "guard_id": 1,
      "guard_name": "John Doe",
      "patrol_run_id": 5,
      "scan_verified": true,
      "gps_verified": true,
      "notes": "All clear",
      "photos": [
        {
          "file_id": "file_123",
          "filename": "checkpoint_photo.jpg",
          "url": "/files/file_123/download"
        }
      ]
    }
  ],
  "total": 1
}
```

---

## Scan Methods and Codes

### Available Scan Methods
- `qr`: QR Code scanning
- `nfc`: NFC tag scanning
- `gps`: GPS-only verification
- `manual`: Manual check-in

### Scan Code Formats
- QR Codes: `QR` + 6 digits (e.g., QR123456)
- NFC Tags: `NFC` + 6 digits (e.g., NFC789012)
- GPS: No code required
- Manual: No code required

---

## Statistics and Analytics

### GET /checkpoints/statistics
**Description**: Get checkpoint usage statistics  
**Permission**: `checkpoints:view`

**Query Parameters**:
- `site_id` (integer, optional): Filter by site

**Response (200)**:
```json
{
  "total_checkpoints": 25,
  "active_checkpoints": 23,
  "scan_methods": {
    "qr": 15,
    "nfc": 8,
    "gps": 2
  },
  "visit_statistics": {
    "total_visits": 1250,
    "visits_last_24h": 45,
    "average_visits_per_checkpoint": 50,
    "most_visited": {
      "checkpoint_id": 1,
      "name": "Main Entrance",
      "visit_count": 145
    }
  }
}
```

---

### GET /checkpoints/sites/{site_id}/validation
**Description**: Validate patrol completion  
**Permission**: `checkpoints:view`

**Query Parameters**:
- `patrol_id` (integer, optional): Specific patrol run

**Response (200)**:
```json
{
  "validation_result": {
    "is_complete": true,
    "required_checkpoints": 8,
    "visited_checkpoints": 8,
    "missing_checkpoints": [],
    "completion_percentage": 100,
    "patrol_duration": "01:25:00"
  }
}
```

---

## Route Optimization

### POST /checkpoints/optimize-route
**Description**: Optimize checkpoint visit order  
**Permission**: `patrols:manage`

**Request Body**:
```json
{
  "checkpoint_ids": [1, 2, 3, 4, 5],
  "start_location": {
    "latitude": 40.7128,
    "longitude": -74.0060
  },
  "optimization_criteria": "shortest_path"
}
```

**Response (200)**:
```json
{
  "optimized_route": [
    {
      "checkpoint_id": 1,
      "sequence_order": 1,
      "estimated_travel_time": "00:00:00"
    },
    {
      "checkpoint_id": 3,
      "sequence_order": 2,
      "estimated_travel_time": "00:03:00"
    }
  ],
  "total_distance": 1.2,
  "estimated_duration": "01:15:00"
}
```

---

## Integration Examples

### Start Patrol and Visit Checkpoints
```javascript
const startPatrolWithVisits = async (templateId, guardId) => {
  // Start patrol run
  const runResponse = await fetch('/patrol-runs/start', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      template_id: templateId,
      guard_id: guardId,
      notes: 'Starting patrol'
    })
  });
  
  const patrolRun = await runResponse.json();
  
  // Visit first checkpoint
  const visitResponse = await fetch(`/patrol-runs/${patrolRun.run_id}/checkpoints/visit`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      checkpoint_id: 1,
      latitude: 40.7128,
      longitude: -74.0060,
      scan_method: 'qr',
      scan_code: 'QR123456',
      notes: 'All clear'
    })
  });
  
  return {
    patrolRun,
    firstVisit: await visitResponse.json()
  };
};
```

### Monitor Patrol Progress
```javascript
const monitorPatrolProgress = async (runId) => {
  const response = await fetch(`/patrol-runs/${runId}`, {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  
  const patrol = await response.json();
  
  const progress = {
    completionPercentage: (patrol.checkpoints_visited / patrol.checkpoints_total) * 100,
    timeElapsed: calculateDuration(patrol.started_at),
    estimatedCompletion: patrol.estimated_completion,
    currentCheckpoint: patrol.next_checkpoint
  };
  
  return progress;
};
```