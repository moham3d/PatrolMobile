# Shifts API Documentation

## Overview
The Shifts API manages guard work schedules, clock-in/out operations, break management, and overtime tracking within the PatrolShield system.

**Base URL**: `https://api.millio.space`  
**Authentication**: JWT Bearer Token required  
**Headers**: `Authorization: Bearer <token>`, `Content-Type: application/json`

---

## Shift Status and Types

### Shift Status
- `scheduled`: Shift is planned but not started
- `in_progress`: Guard has clocked in
- `break`: Guard is on break
- `completed`: Shift completed normally
- `cancelled`: Shift was cancelled
- `no_show`: Guard didn't show up

### Check-in Types
- `clock_in`: Start shift
- `clock_out`: End shift
- `break_start`: Start break
- `break_end`: End break
- `overtime_start`: Start overtime
- `overtime_end`: End overtime

---

## Basic Operations

### GET /shifts/active
**Description**: Get active shifts for current user  
**Permission**: Own shifts or `shifts:view`

**Response (200)**:
```json
{
  "active_shifts": [
    {
      "id": 1,
      "site_id": 1,
      "site_name": "Downtown Office",
      "start_time": "2024-01-21T08:00:00Z",
      "end_time": "2024-01-21T16:00:00Z",
      "status": "in_progress",
      "clocked_in_at": "2024-01-21T08:05:00Z",
      "current_break": null,
      "overtime_requested": false,
      "location": {
        "latitude": 40.7128,
        "longitude": -74.0060
      }
    }
  ]
}
```

---

### GET /shifts/
**Description**: List shifts with filtering and pagination  
**Permission**: `shifts:view` or own shifts

**Query Parameters**:
- `limit` (integer): Maximum records (default: 50, max: 200)
- `skip` (integer): Number to skip (default: 0)
- `start_date` (datetime): Filter from date (ISO format)
- `end_date` (datetime): Filter to date (ISO format)
- `status` (string): Filter by status
- `guard_id` (integer): Filter by guard (requires `shifts:view`)
- `site_id` (integer): Filter by site

**Response (200)**:
```json
{
  "shifts": [
    {
      "id": 1,
      "guard_id": 1,
      "guard_name": "John Doe",
      "site_id": 1,
      "site_name": "Downtown Office",
      "start_time": "2024-01-21T08:00:00Z",
      "end_time": "2024-01-21T16:00:00Z",
      "status": "completed",
      "clocked_in_at": "2024-01-21T08:05:00Z",
      "clocked_out_at": "2024-01-21T16:10:00Z",
      "break_duration": "00:30:00",
      "overtime_duration": "00:15:00",
      "total_hours": "08:40:00"
    }
  ],
  "total": 1,
  "skip": 0,
  "limit": 50
}
```

---

### POST /shifts/
**Description**: Create new shift  
**Permission**: `shifts:manage`

**Request Body**:
```json
{
  "guard_id": 1,
  "site_id": 1,
  "start_time": "2024-01-22T08:00:00Z",
  "end_time": "2024-01-22T16:00:00Z",
  "notes": "Regular day shift",
  "patrol_assignments": [
    {
      "patrol_template_id": 1,
      "scheduled_time": "2024-01-22T10:00:00Z"
    },
    {
      "patrol_template_id": 2,
      "scheduled_time": "2024-01-22T14:00:00Z"
    }
  ]
}
```

**Response (201)**:
```json
{
  "id": 2,
  "guard_id": 1,
  "guard_name": "John Doe",
  "site_id": 1,
  "site_name": "Downtown Office",
  "start_time": "2024-01-22T08:00:00Z",
  "end_time": "2024-01-22T16:00:00Z",
  "status": "scheduled",
  "created_at": "2024-01-21T15:30:00Z",
  "patrol_assignments": [
    {
      "patrol_template_id": 1,
      "template_name": "Morning Perimeter Check",
      "scheduled_time": "2024-01-22T10:00:00Z"
    }
  ]
}
```

---

### GET /shifts/{shift_id}
**Description**: Get specific shift details  
**Permission**: `shifts:view` or own shift

**Response (200)**:
```json
{
  "id": 1,
  "guard_id": 1,
  "guard_name": "John Doe",
  "site_id": 1,
  "site_name": "Downtown Office",
  "start_time": "2024-01-21T08:00:00Z",
  "end_time": "2024-01-21T16:00:00Z",
  "status": "completed",
  "clocked_in_at": "2024-01-21T08:05:00Z",
  "clocked_out_at": "2024-01-21T16:10:00Z",
  "clock_events": [
    {
      "type": "clock_in",
      "timestamp": "2024-01-21T08:05:00Z",
      "location": {"latitude": 40.7128, "longitude": -74.0060}
    },
    {
      "type": "break_start",
      "timestamp": "2024-01-21T12:00:00Z",
      "location": {"latitude": 40.7128, "longitude": -74.0060}
    },
    {
      "type": "break_end",
      "timestamp": "2024-01-21T12:30:00Z",
      "location": {"latitude": 40.7128, "longitude": -74.0060}
    },
    {
      "type": "clock_out",
      "timestamp": "2024-01-21T16:10:00Z",
      "location": {"latitude": 40.7128, "longitude": -74.0060}
    }
  ],
  "patrol_activities": [
    {
      "patrol_id": 1,
      "template_name": "Morning Perimeter Check",
      "started_at": "2024-01-21T10:00:00Z",
      "completed_at": "2024-01-21T10:45:00Z",
      "checkpoints_visited": 8,
      "checkpoints_total": 8
    }
  ],
  "overtime": {
    "requested": true,
    "approved": true,
    "start_time": "2024-01-21T16:00:00Z",
    "end_time": "2024-01-21T16:15:00Z",
    "duration": "00:15:00",
    "reason": "Incident documentation"
  }
}
```

---

## Clock Operations

### POST /shifts/{shift_id}/clock-in
**Description**: Clock in to start shift  
**Permission**: `shifts:checkin` or own shift

**Request Body**:
```json
{
  "latitude": 40.7128,
  "longitude": -74.0060,
  "notes": "Starting shift on time"
}
```

**Response (200)**:
```json
{
  "shift_id": 1,
  "clocked_in_at": "2024-01-21T08:05:00Z",
  "status": "in_progress",
  "location": {
    "latitude": 40.7128,
    "longitude": -74.0060
  },
  "within_geofence": true
}
```

**Error Responses**:
- `400`: Already clocked in
- `400`: Outside geofence area
- `404`: Shift not found

---

### POST /shifts/{shift_id}/clock-out
**Description**: Clock out to end shift  
**Permission**: `shifts:checkout` or own shift

**Request Body**:
```json
{
  "latitude": 40.7128,
  "longitude": -74.0060,
  "notes": "Shift completed successfully"
}
```

**Response (200)**:
```json
{
  "shift_id": 1,
  "clocked_out_at": "2024-01-21T16:10:00Z",
  "status": "completed",
  "total_duration": "08:05:00",
  "regular_hours": "08:00:00",
  "overtime_hours": "00:05:00"
}
```

---

### POST /shifts/{shift_id}/break-start
**Description**: Start break period  
**Permission**: `shifts:checkin` or own shift

**Request Body**:
```json
{
  "latitude": 40.7128,
  "longitude": -74.0060,
  "break_type": "lunch"
}
```

**Response (200)**:
```json
{
  "shift_id": 1,
  "break_started_at": "2024-01-21T12:00:00Z",
  "status": "break",
  "break_type": "lunch"
}
```

---

### POST /shifts/{shift_id}/break-end
**Description**: End break period  
**Permission**: `shifts:checkin` or own shift

**Response (200)**:
```json
{
  "shift_id": 1,
  "break_ended_at": "2024-01-21T12:30:00Z",
  "status": "in_progress",
  "break_duration": "00:30:00"
}
```

---

## Overtime Management

### POST /shifts/{shift_id}/overtime/request
**Description**: Request overtime authorization  
**Permission**: `shifts:checkin` or own shift

**Request Body**:
```json
{
  "estimated_duration": "01:00:00",
  "reason": "Security incident requires documentation",
  "priority": "high"
}
```

**Response (200)**:
```json
{
  "overtime_request_id": 1,
  "shift_id": 1,
  "requested_at": "2024-01-21T15:45:00Z",
  "estimated_duration": "01:00:00",
  "reason": "Security incident requires documentation",
  "status": "pending",
  "auto_approved": false
}
```

---

### POST /shifts/{shift_id}/overtime/approve
**Description**: Approve or deny overtime request  
**Permission**: `shifts:manage`

**Request Body**:
```json
{
  "approved": true,
  "approved_duration": "01:00:00",
  "notes": "Approved for incident documentation"
}
```

**Response (200)**:
```json
{
  "overtime_request_id": 1,
  "approved": true,
  "approved_at": "2024-01-21T15:50:00Z",
  "approved_by": "supervisor_user",
  "approved_duration": "01:00:00"
}
```

---

## Scheduling Operations

### POST /shifts/schedule/recurring
**Description**: Create recurring shift schedule  
**Permission**: `shifts:manage`

**Request Body**:
```json
{
  "guard_id": 1,
  "site_id": 1,
  "pattern": {
    "type": "weekly",
    "days": ["monday", "tuesday", "wednesday", "thursday", "friday"],
    "start_time": "08:00:00",
    "end_time": "16:00:00"
  },
  "start_date": "2024-01-22",
  "end_date": "2024-03-22",
  "patrol_templates": [1, 2]
}
```

**Response (201)**:
```json
{
  "schedule_id": 1,
  "shifts_created": 60,
  "date_range": {
    "start": "2024-01-22",
    "end": "2024-03-22"
  },
  "pattern": {
    "type": "weekly",
    "days": ["monday", "tuesday", "wednesday", "thursday", "friday"]
  }
}
```

---

### POST /shifts/schedule/auto-assign
**Description**: Auto-assign guards to open shifts  
**Permission**: `shifts:manage`

**Request Body**:
```json
{
  "site_id": 1,
  "date_range": {
    "start": "2024-01-22",
    "end": "2024-01-28"
  },
  "criteria": {
    "prefer_experienced": true,
    "balance_hours": true,
    "respect_availability": true
  }
}
```

**Response (200)**:
```json
{
  "assignments_made": 15,
  "shifts_remaining": 3,
  "guards_assigned": [
    {
      "guard_id": 1,
      "guard_name": "John Doe",
      "shifts_assigned": 5
    }
  ]
}
```

---

## Shift Validation

All shift operations include automatic validation:

### GPS Validation
- Clock-in/out must be within site geofence
- Configurable accuracy requirements
- Location history tracking

### Time Validation
- Cannot clock in more than 15 minutes early
- Cannot have overlapping shifts
- Break duration limits enforced

### Business Rules
- Minimum rest period between shifts
- Maximum consecutive work days
- Overtime approval workflows

---

## Integration Examples

### Clock In with GPS Validation
```javascript
const clockIn = async (shiftId, location) => {
  try {
    const response = await fetch(`/shifts/${shiftId}/clock-in`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        latitude: location.latitude,
        longitude: location.longitude,
        notes: 'Starting shift'
      })
    });
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.detail);
    }
    
    return await response.json();
  } catch (error) {
    console.error('Clock in failed:', error.message);
    throw error;
  }
};
```

### Monitor Active Shifts
```javascript
const monitorActiveShifts = async () => {
  const response = await fetch('/shifts/active', {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  
  const { active_shifts } = await response.json();
  
  // Check for overtime requests
  const overtimeRequests = active_shifts.filter(
    shift => shift.overtime_requested && !shift.overtime_approved
  );
  
  return {
    activeShifts: active_shifts,
    pendingOvertimeRequests: overtimeRequests
  };
};
```