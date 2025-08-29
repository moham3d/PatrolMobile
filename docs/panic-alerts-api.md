# Panic Alerts API Documentation

## Overview
The Panic Alerts API manages emergency alert systems, real-time notifications, and crisis response workflows within the PatrolShield system.

**Base URL**: `https://api.millio.space`  
**Authentication**: JWT Bearer Token required  
**Headers**: `Authorization: Bearer <token>`, `Content-Type: application/json`

---

## Alert Status and Severity

### Alert Status
- `triggered`: Alert just triggered, awaiting response
- `acknowledged`: Alert acknowledged by supervisor/control room
- `responding`: Response team dispatched/en route
- `resolved`: Situation resolved successfully
- `false_alarm`: Determined to be false alarm

### Severity Levels
- `low`: Non-critical alert, standard response
- `medium`: Moderate priority, expedited response
- `high`: High priority, immediate response required
- `critical`: Life-threatening emergency, all resources mobilized

---

## Core Alert Operations

### POST /panic/trigger
**Description**: Trigger panic alert from guard device  
**Permission**: Any authenticated user

**Request Body**:
```json
{
  "location": {
    "latitude": 40.7128,
    "longitude": -74.0060,
    "accuracy": 5.0
  },
  "severity": "high",
  "alert_type": "panic",
  "message": "Security threat detected, need immediate backup",
  "silent": false,
  "additional_info": {
    "shift_id": 5,
    "patrol_id": 1,
    "checkpoint_id": 3,
    "witnesses_present": true,
    "threat_level": "medium"
  }
}
```

**Response (201)**:
```json
{
  "alert_id": 1,
  "triggered_at": "2024-01-21T14:30:00Z",
  "status": "triggered",
  "severity": "high",
  "location": {
    "latitude": 40.7128,
    "longitude": -74.0060,
    "address": "123 Business Ave, Downtown"
  },
  "response_info": {
    "control_room_notified": true,
    "supervisors_notified": true,
    "estimated_response_time": "00:03:00",
    "responder_count": 2
  },
  "alert_code": "PA-2024-001"
}
```

---

### PUT /panic/{alert_id}/acknowledge
**Description**: Acknowledge panic alert (supervisors/control room)  
**Permission**: `panic:manage` or supervisor role

**Request Body**:
```json
{
  "acknowledged_by": "supervisor_john",
  "response_plan": "dispatching_security_team",
  "estimated_arrival": "2024-01-21T14:35:00Z",
  "notes": "Security team dispatched, ETA 5 minutes"
}
```

**Response (200)**:
```json
{
  "alert_id": 1,
  "acknowledged_at": "2024-01-21T14:31:00Z",
  "acknowledged_by": "supervisor_john",
  "status": "acknowledged",
  "response_time": "00:01:00",
  "next_actions": [
    "Security team en route",
    "Monitor guard location",
    "Prepare backup resources"
  ]
}
```

---

### PUT /panic/{alert_id}/resolve
**Description**: Mark alert as resolved  
**Permission**: `panic:manage` or supervisor role

**Request Body**:
```json
{
  "resolution_type": "resolved",
  "resolution_notes": "False alarm - equipment malfunction caused alert. Guard is safe.",
  "actions_taken": [
    "Contacted guard via radio",
    "Verified guard safety",
    "Identified equipment issue",
    "Scheduled maintenance"
  ],
  "follow_up_required": true,
  "follow_up_actions": ["Equipment inspection", "Guard debriefing"]
}
```

**Response (200)**:
```json
{
  "alert_id": 1,
  "resolved_at": "2024-01-21T14:45:00Z",
  "resolved_by": "supervisor_john",
  "status": "resolved",
  "total_duration": "00:15:00",
  "resolution_type": "resolved",
  "follow_up_ticket_id": 123
}
```

---

### PUT /panic/{alert_id}/status
**Description**: Update alert status with notes  
**Permission**: `panic:manage` or supervisor role

**Query Parameters**:
- `new_status` (string): New status value
- `notes` (string, optional): Status update notes

**Request Body**:
```json
{
  "status_notes": "Response team on scene, investigating situation",
  "location_update": {
    "latitude": 40.7130,
    "longitude": -74.0058
  },
  "additional_resources": ["medical_team", "police_backup"]
}
```

**Response (200)**:
```json
{
  "alert_id": 1,
  "status": "responding",
  "updated_at": "2024-01-21T14:38:00Z",
  "status_history": [
    {
      "status": "triggered",
      "timestamp": "2024-01-21T14:30:00Z",
      "updated_by": "system"
    },
    {
      "status": "acknowledged", 
      "timestamp": "2024-01-21T14:31:00Z",
      "updated_by": "supervisor_john"
    },
    {
      "status": "responding",
      "timestamp": "2024-01-21T14:38:00Z",
      "updated_by": "supervisor_john"
    }
  ]
}
```

---

## Alert Monitoring

### GET /panic/active
**Description**: Get all active panic alerts  
**Permission**: `panic:view` or supervisor role

**Response (200)**:
```json
{
  "active_alerts": [
    {
      "alert_id": 1,
      "triggered_at": "2024-01-21T14:30:00Z",
      "guard_id": 1,
      "guard_name": "John Doe",
      "site_id": 1,
      "site_name": "Downtown Office",
      "severity": "high",
      "status": "responding",
      "location": {
        "latitude": 40.7128,
        "longitude": -74.0060,
        "address": "123 Business Ave"
      },
      "time_elapsed": "00:08:00",
      "responders": [
        {
          "name": "Security Team Alpha",
          "eta": "00:02:00",
          "contact": "+1-555-SECURITY"
        }
      ]
    }
  ],
  "alert_summary": {
    "total_active": 1,
    "critical_alerts": 0,
    "high_priority": 1,
    "average_response_time": "00:01:30"
  }
}
```

---

### GET /panic/alerts
**Description**: Get panic alerts with filtering  
**Permission**: `panic:view` or supervisor role

**Query Parameters**:
- `guard_id` (integer, optional): Filter by guard
- `status` (string, optional): Filter by status
- `severity` (string, optional): Filter by severity
- `start_date` (datetime, optional): Filter from date
- `end_date` (datetime, optional): Filter to date
- `page` (integer, optional): Page number (default: 1)
- `size` (integer, optional): Page size (default: 20, max: 100)

**Response (200)**:
```json
{
  "alerts": [
    {
      "alert_id": 1,
      "guard_id": 1,
      "guard_name": "John Doe",
      "site_id": 1,
      "site_name": "Downtown Office",
      "triggered_at": "2024-01-21T14:30:00Z",
      "resolved_at": "2024-01-21T14:45:00Z",
      "severity": "high",
      "status": "resolved",
      "resolution_type": "false_alarm",
      "response_time": "00:01:00",
      "total_duration": "00:15:00",
      "responders_count": 2
    }
  ],
  "pagination": {
    "total": 1,
    "page": 1,
    "size": 20,
    "total_pages": 1
  }
}
```

---

### GET /panic/{alert_id}
**Description**: Get detailed alert information  
**Permission**: `panic:view` or guard who triggered alert

**Response (200)**:
```json
{
  "alert_id": 1,
  "guard_id": 1,
  "guard_info": {
    "name": "John Doe",
    "role": "guard",
    "contact": "+1-555-GUARD",
    "current_shift": {
      "shift_id": 5,
      "started_at": "2024-01-21T08:00:00Z"
    }
  },
  "site_info": {
    "site_id": 1,
    "name": "Downtown Office",
    "address": "123 Business Ave",
    "emergency_contacts": [
      {
        "name": "Security Control",
        "phone": "+1-555-SECURITY"
      }
    ]
  },
  "alert_details": {
    "triggered_at": "2024-01-21T14:30:00Z",
    "severity": "high",
    "status": "resolved",
    "message": "Security threat detected, need immediate backup",
    "location": {
      "latitude": 40.7128,
      "longitude": -74.0060,
      "accuracy": 5.0,
      "address": "123 Business Ave, Downtown"
    }
  },
  "response_timeline": [
    {
      "timestamp": "2024-01-21T14:30:00Z",
      "event": "alert_triggered",
      "details": "Panic button pressed by guard"
    },
    {
      "timestamp": "2024-01-21T14:31:00Z",
      "event": "alert_acknowledged",
      "user": "supervisor_john",
      "details": "Acknowledged by supervisor"
    },
    {
      "timestamp": "2024-01-21T14:33:00Z",
      "event": "responders_dispatched",
      "details": "Security team dispatched"
    },
    {
      "timestamp": "2024-01-21T14:45:00Z",
      "event": "alert_resolved",
      "user": "supervisor_john",
      "details": "Resolved as false alarm"
    }
  ],
  "responders": [
    {
      "name": "Security Team Alpha",
      "contact": "+1-555-SECURITY",
      "dispatched_at": "2024-01-21T14:33:00Z",
      "arrived_at": "2024-01-21T14:38:00Z",
      "response_time": "00:05:00"
    }
  ]
}
```

---

## Mobile-Optimized Endpoints

### POST /panic/mobile/trigger
**Description**: Mobile-optimized panic trigger  
**Permission**: Any authenticated user

**Request Body**:
```json
{
  "location": {
    "latitude": 40.7128,
    "longitude": -74.0060,
    "accuracy": 3.5
  },
  "severity": "critical",
  "silent": false,
  "device_info": {
    "battery_level": 45,
    "signal_strength": -75,
    "device_id": "mobile_device_123"
  }
}
```

**Response (201)**:
```json
{
  "alert_id": 1,
  "alert_code": "PA-2024-001",
  "triggered_at": "2024-01-21T14:30:00Z",
  "status": "triggered",
  "emergency_contacts": [
    {
      "name": "Security Control",
      "phone": "+1-555-SECURITY"
    }
  ],
  "instructions": [
    "Stay calm and safe",
    "Help is on the way",
    "Keep your device on"
  ]
}
```

---

### GET /panic/mobile/status/{alert_id}
**Description**: Get minimal alert status for mobile  
**Permission**: Guard who triggered alert

**Response (200)**:
```json
{
  "alert_id": 1,
  "status": "responding",
  "time_elapsed": "00:08:00",
  "help_status": "Security team en route, ETA 2 minutes",
  "contact_available": true,
  "safe_to_move": false
}
```

---

## Statistics and Analytics

### GET /panic/statistics
**Description**: Get panic alert statistics  
**Permission**: `analytics:view` or supervisor role

**Query Parameters**:
- `start_date` (date, optional): Statistics from date
- `end_date` (date, optional): Statistics to date
- `site_id` (integer, optional): Filter by site

**Response (200)**:
```json
{
  "summary": {
    "total_alerts": 45,
    "resolved_alerts": 43,
    "false_alarms": 38,
    "genuine_emergencies": 5,
    "false_alarm_rate": 84.4
  },
  "response_metrics": {
    "average_response_time": "00:02:15",
    "average_resolution_time": "00:12:30",
    "fastest_response": "00:00:45",
    "slowest_response": "00:05:20"
  },
  "trends": {
    "alerts_by_day": [
      {"date": "2024-01-15", "count": 3},
      {"date": "2024-01-16", "count": 1},
      {"date": "2024-01-17", "count": 2}
    ],
    "alerts_by_severity": {
      "low": 5,
      "medium": 15,
      "high": 20,
      "critical": 5
    },
    "alerts_by_time_of_day": {
      "morning": 8,
      "afternoon": 12,
      "evening": 15,
      "night": 10
    }
  }
}
```

---

## Emergency Response Integration

### GET /panic/emergency/responders
**Description**: Get active emergency responders  
**Permission**: `panic:manage` or supervisor role

**Response (200)**:
```json
{
  "available_responders": [
    {
      "team_id": "SECURITY_ALPHA",
      "name": "Security Team Alpha",
      "status": "available",
      "location": {
        "latitude": 40.7125,
        "longitude": -74.0055
      },
      "contact": "+1-555-SECURITY",
      "specializations": ["security", "first_aid"],
      "eta_to_sites": {
        "site_1": "00:03:00",
        "site_2": "00:08:00"
      }
    }
  ],
  "emergency_services": [
    {
      "service": "police",
      "contact": "911",
      "non_emergency": "+1-555-POLICE"
    },
    {
      "service": "medical",
      "contact": "911",
      "non_emergency": "+1-555-MEDICAL"
    }
  ]
}
```

---

### POST /panic/{alert_id}/escalate
**Description**: Escalate alert to higher authorities  
**Permission**: `panic:manage` or supervisor role

**Request Body**:
```json
{
  "escalation_level": "police",
  "reason": "Genuine security threat confirmed",
  "urgent": true,
  "additional_info": "Armed intruder reported, guard safety confirmed"
}
```

**Response (200)**:
```json
{
  "alert_id": 1,
  "escalated_at": "2024-01-21T14:35:00Z",
  "escalation_level": "police",
  "escalated_to": [
    {
      "service": "police",
      "contact": "911",
      "reference_number": "POL-2024-001"
    }
  ],
  "new_status": "escalated",
  "estimated_external_response": "00:08:00"
}
```

---

## Integration Examples

### Complete Alert Response Flow
```javascript
const handlePanicAlert = async (alertData) => {
  // Trigger alert
  const alertResponse = await fetch('/panic/trigger', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(alertData)
  });
  
  const alert = await alertResponse.json();
  
  // Set up real-time monitoring
  const ws = new WebSocket(`wss://api.millio.space/ws/panic/${alert.alert_id}`);
  
  ws.onmessage = (event) => {
    const update = JSON.parse(event.data);
    updateAlertStatus(update);
  };
  
  return alert;
};

// Acknowledge alert
const acknowledgeAlert = async (alertId, responseData) => {
  const response = await fetch(`/panic/${alertId}/acknowledge`, {
    method: 'PUT',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(responseData)
  });
  
  return response.json();
};
```

### Mobile Emergency Button
```javascript
const triggerEmergency = async () => {
  const location = await getCurrentLocation();
  const deviceInfo = await getDeviceInfo();
  
  try {
    const response = await fetch('/panic/mobile/trigger', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
        'X-Device-ID': deviceInfo.deviceId
      },
      body: JSON.stringify({
        location: location,
        severity: 'critical',
        silent: false,
        device_info: deviceInfo
      })
    });
    
    const alert = await response.json();
    
    // Show emergency UI
    showEmergencyInterface(alert);
    
    // Start status monitoring
    monitorAlertStatus(alert.alert_id);
    
    return alert;
  } catch (error) {
    // Handle offline mode
    await storeOfflineEmergency({
      location,
      timestamp: new Date().toISOString(),
      deviceInfo
    });
    
    showOfflineEmergencyUI();
  }
};
```