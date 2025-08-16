# PatrolShield API Documentation
**Version 2.0.0** | **Complete Guide for Frontend & Mobile App Development**

## Table of Contents
1. [Introduction](#introduction)
2. [Authentication](#authentication)
3. [User Management](#user-management)
4. [Roles & Permissions](#roles--permissions)
5. [Site & Location Management](#site--location-management)
6. [Shift Management](#shift-management)
7. [Task Management](#task-management)
8. [Checkpoint System](#checkpoint-system)
9. [Panic Alert System](#panic-alert-system)
10. [Issue Management](#issue-management)
11. [GPS Tracking](#gps-tracking)
12. [File Management](#file-management)
13. [Messages & Communications](#messages--communications)
14. [Notifications](#notifications)
15. [Mobile API v1](#mobile-api-v1)
16. [Analytics & Reporting](#analytics--reporting)
17. [Dashboard System](#dashboard-system)
18. [Events & Webhooks](#events--webhooks)
19. [Integrations](#integrations)
20. [Settings Management](#settings-management)
21. [Performance & Monitoring](#performance--monitoring)
22. [Health & System Status](#health--system-status)
23. [Visitor Management](#visitor-management)
24. [Audit Logs](#audit-logs)
25. [Real-time Features](#real-time-features)
26. [Error Handling](#error-handling)
27. [Flutter Integration Examples](#flutter-integration-examples)

---

## Introduction

PatrolShield is a comprehensive security patrol management system designed for security companies, facilities management, and organizations requiring structured security operations. The system provides:

- **Multi-role User Management**: Admin, Manager, Supervisor, Guard roles with granular permissions
- **Site & Location Hierarchy**: Sites → Locations → Areas for precise geographic organization
- **Shift Management**: Scheduling, clock in/out, overtime tracking with GPS verification
- **Task System**: Replaces traditional patrol system with flexible task management (patrol, inspection, maintenance, etc.)
- **Checkpoint Management**: QR/NFC scanning, GPS verification, photo evidence
- **Panic Alert System**: Emergency response with real-time notifications
- **Issue Tracking**: Incident reporting with evidence and resolution workflow
- **Real-time GPS Tracking**: Live location monitoring and geofencing
- **Mobile Optimization**: Dedicated mobile API with offline sync capabilities
- **Analytics Dashboard**: Performance metrics and reporting
- **Event System**: Webhook-based integrations and real-time notifications
- **Settings Management**: Configurable system settings and preferences
- **Performance Monitoring**: System health and optimization tools
- **Visitor Management**: Guest registration and tracking system

### Base URL
- **Production**: `https://api.millio.space`
- **Development**: `http://localhost:8000`

### Authentication Methods
1. **JWT Bearer Token** (Primary)
2. **OAuth2 Password Flow** (Login)

### Headers Required
```http
Authorization: Bearer <access_token>
Content-Type: application/json
Accept: application/json
X-API-Version: 2.0
```

---

## Authentication

### POST `/auth/login`
**Description**: Authenticate user and receive access token

**Request Body** (Form data):
```json
{
  "username": "string",
  "password": "string"
}
```

**Response**:
```json
{
  "access_token": "string",
  "token_type": "bearer"
}
```

**Status Codes**:
- `200 OK` - Success
- `401 Unauthorized` - Invalid credentials or inactive user

### POST `/auth/refresh`
**Description**: Refresh access token

**Headers**: `Authorization: Bearer <token>`

**Response**:
```json
{
  "access_token": "string",
  "token_type": "bearer"
}
```

### GET `/auth/me`
**Description**: Get current authenticated user profile with roles and permissions

**Headers**: `Authorization: Bearer <token>`

**Response**:
```json
{
  "id": 1,
  "username": "string",
  "email": "string",
  "full_name": "string",
  "is_active": true,
  "status": "active",
  "employment_date": "2024-01-01T00:00:00Z",
  "job_title": "Security Guard",
  "department": "Security",
  "roles": ["guard"],
  "permissions": ["patrol:read", "issue:create"],
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

### GET `/auth/debug`
**Description**: Debug JWT configuration (development only)

**Response**:
```json
{
  "secret_key_length": 64,
  "access_token_expire_minutes": 30,
  "algorithm": "HS256"
}
```

---

## User Management

### GET `/users/`
**Description**: List all users with pagination and filtering

**Required Permission**: `users:manage`

**Query Parameters**:
- `skip` (int): Number of records to skip (default: 0)
- `limit` (int): Number of records to return (default: 100)

**Response**:
```json
[
  {
    "id": 1,
    "username": "john.doe",
    "email": "john@example.com",
    "full_name": "John Doe",
    "is_active": true,
    "status": "active",
    "employment_date": "2024-01-01T00:00:00Z",
    "job_title": "Security Guard",
    "department": "Security",
    "roles": ["guard"],
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z"
  }
]
```

### POST `/users/`
**Description**: Create a new user

**Required Permission**: `users:manage`

**Request Body**:
```json
{
  "username": "string",
  "email": "user@example.com",
  "password": "string",
  "full_name": "string",
  "is_active": true,
  "status": "active",
  "employment_date": "2024-01-01T00:00:00Z",
  "job_title": "string",
  "department": "string",
  "roles": ["guard"]
}
```

**Response**: Same as GET user

### GET `/users/{user_id}`
**Description**: Get user details by ID

**Required Permission**: `users:manage`

**Response**: Same as GET users list item

### PUT `/users/{user_id}`
**Description**: Update user details

**Required Permission**: `users:manage`

**Request Body**:
```json
{
  "full_name": "string",
  "email": "user@example.com",
  "is_active": true,
  "status": "active",
  "employment_date": "2024-01-01T00:00:00Z",
  "job_title": "string",
  "department": "string",
  "password": "string", // Optional - updates password
  "roles": ["guard", "supervisor"] // Optional - updates roles
}
```

### DELETE `/users/{user_id}`
**Description**: Delete a user (cannot delete own account)

**Required Permission**: `users:manage`

**Response**:
```json
{
  "message": "User deleted successfully"
}
```

### GET `/users/me`
**Description**: Get current user profile (alias for `/auth/me`)

### GET `/users/admin-only`
**Description**: Admin-only endpoint for testing permissions

**Required Permission**: `users:manage`

### GET `/users/{user_id}/shifts`
**Description**: Get shifts for a specific user

**Query Parameters**:
- `start_date` (datetime): Filter shifts from this date
- `end_date` (datetime): Filter shifts until this date  
- `status` (ShiftStatusEnum): Filter by shift status

**Response**: Array of ShiftRead objects (see Shift Management section)

---

## Roles & Permissions

### GET `/roles/`
**Description**: List all roles

**Required Permission**: `roles:manage`

**Response**:
```json
[
  {
    "id": 1,
    "name": "admin",
    "display_name": "Administrator",
    "description": "Full system access",
    "permissions": ["users:manage", "sites:manage", "shifts:manage"],
    "is_active": true,
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z"
  }
]
```

### POST `/roles/`
**Description**: Create a new role

**Required Permission**: `roles:manage`

**Request Body**:
```json
{
  "name": "string",
  "display_name": "string",
  "description": "string",
  "permissions": ["permission1", "permission2"],
  "is_active": true
}
```

### GET `/roles/{role_id}`
**Description**: Get role details by ID

**Required Permission**: `roles:manage`

### PUT `/roles/{role_id}`
**Description**: Update role

**Required Permission**: `roles:manage`

### DELETE `/roles/{role_id}`
**Description**: Delete role

**Required Permission**: `roles:manage`

### Permission Management

#### GET `/permissions/`
**Description**: List all available permissions

**Required Permission**: `permissions:view`

**Response**:
```json
[
  {
    "id": 1,
    "name": "users:manage",
    "display_name": "Manage Users",
    "description": "Create, update, and delete users",
    "category": "user_management",
    "is_active": true
  }
]
```

#### POST `/permissions/`
**Description**: Create a new permission

**Required Permission**: `permissions:manage`

#### GET `/permissions/{permission_id}`
**Description**: Get permission details

#### PUT `/permissions/{permission_id}`
**Description**: Update permission

#### DELETE `/permissions/{permission_id}`
**Description**: Delete permission

---

## Site & Location Management

### GET `/sites/`
**Description**: List all sites

**Required Permission**: `sites:view`

**Response**:
```json
[
  {
    "id": 1,
    "name": "Main Campus",
    "description": "Primary facility location",
    "address": "123 Main St, City, State",
    "latitude": 40.7128,
    "longitude": -74.0060,
    "is_active": true
  }
]
```

### POST `/sites/`
**Description**: Create a new site

**Required Permission**: `sites:manage`

**Request Body**:
```json
{
  "name": "string",
  "description": "string",
  "address": "string",
  "latitude": 40.7128,
  "longitude": -74.0060,
  "is_active": true
}
```

### GET `/sites/{site_id}`
**Description**: Get site details by ID

**Required Permission**: `sites:view`

### PUT `/sites/{site_id}`
**Description**: Update site

**Required Permission**: `sites:manage`

### DELETE `/sites/{site_id}`
**Description**: Delete site

**Required Permission**: `sites:manage`

**Response**:
```json
{
  "detail": "Site deleted"
}
```

### Location Management

#### GET `/sites/locations/`
**Description**: Get all locations

**Required Permission**: `locations:view`

#### GET `/sites/{site_id}/locations/`
**Description**: Get all locations for a specific site

**Required Permission**: `locations:view`

#### POST `/sites/{site_id}/locations/`
**Description**: Create location within a site

**Required Permission**: `locations:manage`

**Request Body**:
```json
{
  "name": "string",
  "description": "string",
  "latitude": 40.7128,
  "longitude": -74.0060,
  "floor_level": "1",
  "qr_code_id": "string",
  "nfc_tag_id": "string"
}
```

**Response**:
```json
{
  "id": 1,
  "site_id": 1,
  "name": "Main Entrance",
  "description": "Primary building entrance",
  "latitude": 40.7128,
  "longitude": -74.0060,
  "floor_level": "1",
  "qr_code_id": "QR_001",
  "nfc_tag_id": "NFC_001"
}
```

#### GET `/sites/locations/{location_id}`
**Description**: Get location by ID

#### PUT `/sites/locations/{location_id}`
**Description**: Update location

#### DELETE `/sites/locations/{location_id}`
**Description**: Delete location

### Area Management

#### GET `/sites/areas/`
**Description**: Get all areas

#### GET `/sites/{site_id}/areas/`
**Description**: Get all areas for locations within a site

#### GET `/sites/locations/{location_id}/areas/`
**Description**: Get areas for a specific location

#### POST `/sites/locations/{location_id}/areas/`
**Description**: Create area within a location

**Request Body**:
```json
{
  "name": "string",
  "description": "string",
  "latitude": 40.7128,
  "longitude": -74.0060,
  "qr_code_id": "string",
  "nfc_tag_id": "string",
  "area_type": "restricted"
}
```

#### GET `/sites/areas/{area_id}`
**Description**: Get area by ID

#### PUT `/sites/areas/{area_id}`
**Description**: Update area

#### DELETE `/sites/areas/{area_id}`
**Description**: Delete area

### Site User Assignment

#### GET `/sites/{site_id}/users`
**Description**: Get all users assigned to a site

**Response**:
```json
[
  {
    "id": 1,
    "username": "john.doe",
    "full_name": "John Doe",
    "email": "john@example.com",
    "job_title": "Security Guard",
    "department": "Security",
    "roles": [
      {
        "id": 1,
        "name": "guard",
        "description": "Security Guard Role"
      }
    ]
  }
]
```

#### POST `/sites/{site_id}/users/{user_id}`
**Description**: Assign user to site

#### DELETE `/sites/{site_id}/users/{user_id}`
**Description**: Remove user assignment from site

#### GET `/sites/{site_id}/available-users`
**Description**: Get users not assigned to this site

#### GET `/sites/{site_id}/shifts`
**Description**: Get shifts for a specific site

**Query Parameters**:
- `date` (datetime): Filter shifts for specific date

---

## Shift Management

Shift management handles scheduling, time tracking, and attendance for security personnel.

### Shift Status Values
- `scheduled` - Shift is scheduled but not started
- `in_progress` - Guard has clocked in
- `break` - Guard is on break
- `completed` - Shift completed successfully
- `cancelled` - Shift was cancelled
- `no_show` - Guard didn't show up

### Check-in Types
- `clock_in` - Start of shift
- `clock_out` - End of shift
- `break_start` - Start of break
- `break_end` - End of break
- `overtime_start` - Start of overtime
- `overtime_end` - End of overtime

### GET `/shifts/active`
**Description**: Get active shifts for current user

**Response**:
```json
[
  {
    "id": 1,
    "guard_id": 1,
    "site_id": 1,
    "scheduled_start": "2024-08-16T08:00:00Z",
    "scheduled_end": "2024-08-16T16:00:00Z",
    "actual_start": "2024-08-16T08:05:00Z",
    "actual_end": null,
    "status": "in_progress",
    "title": "Morning Security Shift",
    "notes": "Standard patrol shift",
    "break_duration": 0,
    "overtime_approved": false,
    "created_at": "2024-08-15T10:00:00Z",
    "updated_at": "2024-08-16T08:05:00Z"
  }
]
```

### POST `/shifts/`
**Description**: Create a new shift

**Required Permission**: `shift:create`

**Request Body**:
```json
{
  "guard_id": 1,
  "site_id": 1,
  "scheduled_start": "2024-08-16T08:00:00Z",
  "scheduled_end": "2024-08-16T16:00:00Z",
  "title": "Morning Security Shift",
  "notes": "Standard patrol shift"
}
```

### GET `/shifts/{shift_id}`
**Description**: Get detailed shift information

**Response**: Extended shift object with checkins and performance data

### PUT `/shifts/{shift_id}`
**Description**: Update shift details

**Required Permission**: `shift:update`

### DELETE `/shifts/{shift_id}`
**Description**: Cancel a shift (sets status to cancelled)

**Required Permission**: `shift:delete`

### Clock In/Out Operations

#### POST `/shifts/{shift_id}/clock-in`
**Description**: Clock in for a shift

**Request Body**:
```json
{
  "latitude": "40.7128",
  "longitude": "-74.0060",
  "location_accuracy": "5.0",
  "location_name": "Main Entrance",
  "notes": "On time for shift"
}
```

**Response**:
```json
{
  "message": "Successfully clocked in",
  "shift": { /* Updated shift object */ },
  "checkin": {
    "id": 1,
    "checkin_type": "clock_in",
    "shift_id": 1,
    "user_id": 1,
    "timestamp": "2024-08-16T08:05:00Z",
    "latitude": "40.7128",
    "longitude": "-74.0060",
    "location_accuracy": "5.0",
    "location_name": "Main Entrance",
    "notes": "On time for shift",
    "created_at": "2024-08-16T08:05:00Z"
  }
}
```

#### POST `/shifts/{shift_id}/clock-out`
**Description**: Clock out from a shift

#### POST `/shifts/{shift_id}/break-start`
**Description**: Start a break

**Request Body**:
```json
{
  "notes": "15 minute break"
}
```

#### POST `/shifts/{shift_id}/break-end`
**Description**: End a break

#### POST `/shifts/{shift_id}/overtime/request`
**Description**: Request overtime

**Request Body**:
```json
{
  "reason": "Extra security needed for event",
  "estimated_hours": 2.0
}
```

#### POST `/shifts/{shift_id}/overtime/approve`
**Description**: Approve or deny overtime

**Required Permission**: `shift:overtime_approve`

**Query Parameters**:
- `approved` (bool): Whether to approve overtime
- `approval_notes` (string): Notes about approval/denial

### Scheduling

#### POST `/shifts/schedule/recurring`
**Description**: Create recurring shifts

**Required Permission**: `shift:schedule`

**Request Body**:
```json
{
  "site_id": 1,
  "guard_ids": [1, 2, 3],
  "start_date": "2024-08-16T00:00:00Z",
  "end_date": "2024-08-30T00:00:00Z",
  "shift_pattern": "daily",
  "hours_per_shift": 8,
  "notes": "Regular security schedule"
}
```

#### POST `/shifts/schedule/auto-assign`
**Description**: Automatically assign guards to shifts

**Required Permission**: `shift:schedule`

**Query Parameters**:
- `site_id` (int): Site ID
- `start_date` (datetime): Schedule start
- `end_date` (datetime): Schedule end
- `shift_hours` (int): Hours per shift (default: 8)
- `guards_per_shift` (int): Guards per shift (default: 1)
- `preferred_guards` (list[int]): Preferred guard IDs
- `exclude_guards` (list[int]): Guards to exclude

#### POST `/shifts/conflicts/resolve`
**Description**: Resolve scheduling conflicts

**Request Body**:
```json
{
  "shift_ids": [1, 2, 3],
  "resolution_strategy": "auto"
}
```

---

## Task Management

The task system provides flexible work assignment and tracking, replacing traditional patrol-only systems with support for various task types.

### Task Types
- `general` - General tasks
- `patrol` - Security patrol tasks
- `inspection` - Equipment/facility inspections
- `maintenance` - Maintenance work
- `security` - Security-specific tasks
- `training` - Training activities
- `emergency` - Emergency response tasks

### Task Status Values
- `pending` - Task assigned but not started
- `in_progress` - Task currently being worked on
- `completed` - Task finished successfully
- `cancelled` - Task was cancelled

### Priority Levels
- `low` - Low priority
- `medium` - Medium priority
- `high` - High priority
- `urgent` - Urgent priority

### GET `/tasks/`
**Description**: List tasks with filtering

**Query Parameters**:
- `site_id` (int): Filter by site
- `task_type` (string): Filter by task type
- `status` (string): Filter by status
- `assigned_to` (int): Filter by assignee

**Response**:
```json
[
  {
    "id": 1,
    "title": "Morning Patrol - Building A",
    "description": "Complete morning security patrol",
    "assigned_to": 1,
    "created_by": 2,
    "due_date": "2024-08-16T12:00:00Z",
    "status": "pending",
    "priority": "medium",
    "task_type": "patrol",
    "site_id": 1,
    "estimated_duration": 60,
    "start_time": "2024-08-16T08:00:00Z",
    "end_time": "2024-08-16T09:00:00Z",
    "completion_percentage": 0,
    "is_recurring": false,
    "recurrence_pattern": null,
    "next_due_date": null,
    "created_at": "2024-08-15T10:00:00Z",
    "updated_at": "2024-08-15T10:00:00Z",
    "checkpoints": [
      {
        "id": 1,
        "task_id": 1,
        "name": "Main Entrance",
        "description": "Check main entrance security",
        "latitude": 40.7128,
        "longitude": -74.0060,
        "area_id": 1,
        "qr_code": "QR_001",
        "nfc_tag": "NFC_001",
        "is_required": true,
        "order_index": 1,
        "created_at": "2024-08-15T10:00:00Z"
      }
    ],
    "checkpoint_visits": []
  }
]
```

### POST `/tasks/`
**Description**: Create a new task

**Required Permission**: `tasks:manage`

**Request Body**:
```json
{
  "title": "string",
  "description": "string",
  "assigned_to": 1, // If null or 0, assigns to current user
  "due_date": "2024-08-16T12:00:00Z",
  "status": "pending",
  "priority": "medium",
  "task_type": "patrol",
  "site_id": 1,
  "estimated_duration": 60,
  "start_time": "2024-08-16T08:00:00Z",
  "end_time": "2024-08-16T09:00:00Z",
  "is_recurring": false,
  "recurrence_pattern": null,
  "next_due_date": null,
  "checkpoints": [
    {
      "name": "Main Entrance",
      "description": "Check main entrance security",
      "latitude": 40.7128,
      "longitude": -74.0060,
      "area_id": 1,
      "qr_code": "QR_001",
      "nfc_tag": "NFC_001",
      "is_required": true,
      "order_index": 1
    }
  ]
}
```

### GET `/tasks/{task_id}`
**Description**: Get task details with relationships

### PUT `/tasks/{task_id}`
**Description**: Update task

### DELETE `/tasks/{task_id}`
**Description**: Delete task

### Patrol-Specific Endpoints

#### GET `/tasks/patrol`
**Description**: Get patrol-type tasks with enhanced information

**Query Parameters**:
- `site_id` (int): Filter by site

**Response**: Enhanced patrol task objects with guard name, site name, and route coordinates

#### POST `/tasks/patrol`
**Description**: Create a patrol task

**Request Body**: Same as regular task creation but `task_type` is forced to "patrol"

### Task Progress Tracking

#### POST `/tasks/{task_id}/checkpoints/{checkpoint_id}/visit`
**Description**: Record checkpoint visit during task execution

**Request Body**:
```json
{
  "notes": "All clear",
  "evidence_files": "photo1.jpg,photo2.jpg",
  "latitude": 40.7128,
  "longitude": -74.0060
}
```

**Response**:
```json
{
  "id": 1,
  "task_id": 1,
  "checkpoint_id": 1,
  "user_id": 1,
  "visited_at": "2024-08-16T08:15:00Z",
  "notes": "All clear",
  "evidence_files": "photo1.jpg,photo2.jpg",
  "latitude": 40.7128,
  "longitude": -74.0060
}
```

#### GET `/tasks/{task_id}/progress`
**Description**: Get detailed task progress

**Response**:
```json
{
  "task_id": 1,
  "status": "in_progress",
  "completion_percentage": 50,
  "total_checkpoints": 4,
  "completed_checkpoints": 2,
  "start_time": "2024-08-16T08:00:00Z",
  "end_time": null,
  "estimated_duration": 60,
  "checkpoints": [
    {
      "id": 1,
      "name": "Main Entrance",
      "is_required": true,
      "order_index": 1,
      "completed": true
    },
    {
      "id": 2,
      "name": "Parking Lot",
      "is_required": true,
      "order_index": 2,
      "completed": true
    },
    {
      "id": 3,
      "name": "Rear Exit",
      "is_required": true,
      "order_index": 3,
      "completed": false
    }
  ]
}
```

---

## Checkpoint System

The checkpoint system manages physical checkpoints with QR/NFC scanning capabilities, GPS verification, and photo evidence collection.

### Scan Methods
- `qr` - QR code scanning
- `nfc` - NFC tag scanning  
- `gps` - GPS-based verification
- `manual` - Manual check-in

### GET `/checkpoints/`
**Description**: Get checkpoints with filtering and pagination

**Required Permission**: View access varies by role (admin, operations_manager, site_manager, supervisor, guard)

**Query Parameters**:
- `skip` (int): Records to skip (default: 0, max: 1000)
- `limit` (int): Records to return (default: 100, max: 1000)
- `site_id` (int): Filter by site
- `is_active` (bool): Filter by active status
- `order_by_sequence` (bool): Order by sequence (default: true)

**Response**:
```json
[
  {
    "id": 1,
    "site_id": 1,
    "location_id": 1,
    "area_id": 1,
    "name": "Main Entrance",
    "description": "Primary building entrance checkpoint",
    "latitude": 40.7128,
    "longitude": -74.0060,
    "qr_code": "QR_MAIN_001",
    "nfc_tag_id": "NFC_MAIN_001",
    "order_sequence": 1,
    "is_mandatory": true,
    "time_limit_minutes": 5,
    "is_active": true,
    "checkpoint_type": "patrol",
    "created_at": "2024-08-15T10:00:00Z",
    "updated_at": "2024-08-15T10:00:00Z"
  }
]
```

### POST `/checkpoints/`
**Description**: Create a new checkpoint

**Required Permission**: `admin`, `operations_manager`, or `site_manager`

**Request Body**:
```json
{
  "site_id": 1,
  "location_id": 1,
  "area_id": 1,
  "name": "string",
  "description": "string",
  "latitude": 40.7128,
  "longitude": -74.0060,
  "qr_code": "string",
  "nfc_tag_id": "string",
  "order_sequence": 1,
  "is_mandatory": true,
  "time_limit_minutes": 5,
  "is_active": true,
  "checkpoint_type": "patrol"
}
```

### GET `/checkpoints/{checkpoint_id}`
**Description**: Get checkpoint details by ID

### PUT `/checkpoints/{checkpoint_id}`
**Description**: Update checkpoint

### DELETE `/checkpoints/{checkpoint_id}`
**Description**: Delete checkpoint (204 No Content)

### Checkpoint Visits

#### POST `/checkpoints/{checkpoint_id}/visit`
**Description**: Record a checkpoint visit

**Query Parameters**:
- `latitude` (float): GPS latitude
- `longitude` (float): GPS longitude  
- `notes` (string): Visit notes
- `patrol_id` (int): Associated patrol/task ID
- `scan_method` (ScanMethod): How checkpoint was verified

**Response**:
```json
{
  "id": 1,
  "checkpoint_id": 1,
  "user_id": 1,
  "patrol_id": 1,
  "visited_at": "2024-08-16T08:15:00Z",
  "latitude": 40.7128,
  "longitude": -74.0060,
  "notes": "All clear",
  "scan_method": "qr"
}
```

#### GET `/checkpoints/{checkpoint_id}/visits`
**Description**: Get visit history for a checkpoint

**Query Parameters**:
- `limit` (int): Maximum visits to return (default: 50, max: 200)
- `include_photos` (bool): Include photo data

#### POST `/checkpoints/scan/{scan_code}/visit`
**Description**: Visit checkpoint using QR/NFC scan code

#### GET `/checkpoints/scan/{scan_code}`
**Description**: Get checkpoint info by scan code

### Photo Evidence

#### POST `/checkpoints/visits/{visit_id}/photos`
**Description**: Add photo evidence to a checkpoint visit

**Request Body**: Multipart form with file upload
- `file`: Image file
- `caption` (optional): Photo description

**Response**:
```json
{
  "id": 1,
  "checkpoint_id": 1,
  "visit_id": 1,
  "file_path": "/uploads/checkpoints/photo123.jpg",
  "file_type": "image/jpeg",
  "file_size": 1024000,
  "caption": "Main entrance at 8:15 AM",
  "uploaded_at": "2024-08-16T08:15:00Z"
}
```

### Statistics and Validation

#### GET `/checkpoints/statistics`
**Description**: Get checkpoint usage statistics

**Query Parameters**:
- `site_id` (int): Filter by site

#### GET `/checkpoints/sites/{site_id}/validation`
**Description**: Validate checkpoint sequence completion

**Query Parameters**:
- `patrol_id` (int): Patrol to validate

#### GET `/checkpoints/patrols/{patrol_id}/visits`
**Description**: Get all checkpoint visits for a patrol

#### PUT `/checkpoints/sites/{site_id}/sequence`
**Description**: Update checkpoint order sequence

**Request Body**:
```json
[
  {"checkpoint_id": 1, "order_sequence": 1},
  {"checkpoint_id": 2, "order_sequence": 2}
]
```

### Advanced Checkpoint Features

#### POST `/checkpoints/analyze-deviations`
**Description**: Analyze route deviations

#### POST `/checkpoints/calculate-duration`
**Description**: Calculate route duration

#### POST `/checkpoints/optimize-route`
**Description**: Optimize checkpoint route

#### GET `/checkpoints/patrols/{patrol_id}/performance`
**Description**: Get patrol performance metrics

#### GET `/checkpoints/sites/{site_id}/route-efficiency`
**Description**: Analyze route efficiency

#### PUT `/checkpoints/sites/{site_id}/optimize-sequence`
**Description**: Optimize and update checkpoint sequence

---

## Panic Alert System

Emergency alert system for security personnel with real-time notifications and response tracking.

### Alert Severity Levels
- `low` - Low priority alert
- `medium` - Medium priority alert  
- `high` - High priority alert
- `critical` - Critical emergency

### Alert Status Values
- `triggered` - Alert has been triggered
- `acknowledged` - Alert acknowledged by supervisor
- `responding` - Response in progress
- `resolved` - Alert resolved
- `false_alarm` - Determined to be false alarm

### POST `/panic/trigger`
**Description**: Trigger a panic alert (Emergency Endpoint)

**Request Body**:
```json
{
  "reason": "Suspicious activity detected",
  "severity": "high",
  "location_lat": 40.7128,
  "location_lon": -74.0060,
  "location_accuracy": 5.0,
  "location_name": "Main Entrance"
}
```

**Response**:
```json
{
  "id": 1,
  "guard_id": 1,
  "reason": "Suspicious activity detected",
  "severity": "high",
  "status": "triggered",
  "location_lat": 40.7128,
  "location_lon": -74.0060,
  "location_accuracy": 5.0,
  "location_name": "Main Entrance",
  "triggered_at": "2024-08-16T11:00:00Z",
  "acknowledged_at": null,
  "acknowledged_by": null,
  "resolved_at": null,
  "resolved_by": null,
  "resolution_notes": null,
  "response_time_seconds": null,
  "created_at": "2024-08-16T11:00:00Z",
  "updated_at": "2024-08-16T11:00:00Z",
  "is_active": true,
  "response_time": 0
}
```

### PUT `/panic/{alert_id}/acknowledge`
**Description**: Acknowledge panic alert (Supervisors/Admins only)

**Request Body**:
```json
{
  "acknowledgment_notes": "Reviewing situation and dispatching response"
}
```

### PUT `/panic/{alert_id}/resolve`
**Description**: Resolve panic alert (Supervisors/Admins only)

**Request Body**:
```json
{
  "resolution_notes": "False alarm - equipment malfunction",
  "is_false_alarm": true
}
```

### PUT `/panic/{alert_id}/status`
**Description**: Update alert status

**Query Parameters**:
- `new_status` (AlertStatusEnum): New status
- `notes` (string): Additional notes

### GET `/panic/active`
**Description**: Get all active panic alerts (Supervisors/Admins only)

**Response**:
```json
[
  {
    "id": 1,
    "guard_id": 1,
    "severity": "high",
    "status": "triggered",
    "location_name": "Main Entrance",
    "triggered_at": "2024-08-16T11:00:00Z",
    "acknowledged_at": null,
    "is_active": true
  }
]
```

### GET `/panic/alerts`
**Description**: Get panic alerts with filtering and pagination

**Query Parameters**:
- `guard_id` (int): Filter by guard
- `status` (AlertStatusEnum): Filter by status
- `severity` (AlertSeverityEnum): Filter by severity
- `start_date` (datetime): Filter after date
- `end_date` (datetime): Filter before date
- `is_active` (bool): Filter by active status
- `page` (int): Page number (default: 1)
- `size` (int): Page size (default: 50, max: 100)

**Response**:
```json
{
  "alerts": [ /* Array of alert summaries */ ],
  "total": 25,
  "page": 1,
  "size": 50,
  "total_pages": 1
}
```

### GET `/panic/{alert_id}`
**Description**: Get specific panic alert details

### GET `/panic/statistics`
**Description**: Get panic alert statistics

**Query Parameters**:
- `start_date` (datetime): Statistics start date
- `end_date` (datetime): Statistics end date

**Response**:
```json
{
  "total_alerts": 25,
  "active_alerts": 2,
  "resolved_alerts": 20,
  "false_alarms": 3,
  "average_response_time_seconds": 180.5,
  "alerts_by_severity": {
    "critical": 5,
    "high": 10,
    "medium": 8,
    "low": 2
  },
  "alerts_by_status": {
    "triggered": 1,
    "acknowledged": 1,
    "responding": 0,
    "resolved": 20,
    "false_alarm": 3
  }
}
```

### Mobile-Optimized Endpoints

#### POST `/panic/mobile/trigger`
**Description**: Mobile-optimized panic trigger

**Request Body**:
```json
{
  "lat": 40.7128,
  "lon": -74.0060,
  "accuracy": 5.0,
  "reason": "Emergency",
  "severity": "high"
}
```

#### GET `/panic/mobile/status/{alert_id}`
**Description**: Get minimal alert status for mobile

### Emergency Response

#### GET `/panic/emergency/responders`
**Description**: Get active emergency responders

#### GET `/panic/emergency/metrics`
**Description**: Get emergency response performance metrics

#### POST `/panic/{alert_id}/escalate`
**Description**: Manually escalate a panic alert

---

## Issue Management

Issue tracking system for incident reporting with evidence collection and resolution workflow.

### Issue Status Values
- `open` - Issue reported and open
- `in_progress` - Issue being worked on  
- `resolved` - Issue resolved
- `closed` - Issue closed

### Severity Levels
- `low` - Low severity
- `medium` - Medium severity
- `high` - High severity
- `critical` - Critical severity

### GET `/issues/`
**Description**: Get issues with filtering

**Query Parameters**:
- `skip` (int): Records to skip (default: 0, max: 1000)
- `limit` (int): Records to return (default: 100, max: 1000) 
- `status` (string): Filter by status
- `severity` (string): Filter by severity
- `site_id` (int): Filter by site

**Response**:
```json
[
  {
    "id": 1,
    "title": "Broken Window",
    "description": "Window in lobby area is cracked",
    "severity": "medium",
    "status": "open",
    "site_id": 1,
    "location_id": 1,
    "area_id": 1,
    "reported_by": 1,
    "assigned_to": 2,
    "occurred_at": "2024-08-16T09:30:00Z",
    "created_at": "2024-08-16T09:35:00Z",
    "updated_at": "2024-08-16T09:35:00Z"
  }
]
```

### POST `/issues/`
**Description**: Create new issue

**Request Body**:
```json
{
  "title": "string",
  "description": "string", 
  "severity": "medium",
  "site_id": 1,
  "location_id": 1,
  "area_id": 1,
  "assigned_to": 2,
  "occurred_at": "2024-08-16T09:30:00Z"
}
```

### GET `/issues/{issue_id}`
**Description**: Get issue details

### PUT `/issues/{issue_id}`
**Description**: Update issue

### DELETE `/issues/{issue_id}`
**Description**: Delete issue (204 No Content)

### Evidence Management

#### GET `/issues/{issue_id}/evidence`
**Description**: Get evidence files for an issue

#### POST `/issues/{issue_id}/evidence`
**Description**: Upload evidence file

**Request Body**: Multipart form
- `file`: Evidence file (image, video, audio, PDF)
- `description` (optional): Evidence description

**Response**:
```json
{
  "id": 1,
  "issue_id": 1,
  "file_path": "/uploads/issues/evidence123.jpg",
  "file_type": "image/jpeg",
  "uploaded_by": 1,
  "timestamp": "2024-08-16T10:00:00Z",
  "description": "Photo of damaged window"
}
```

### Notes Management

#### GET `/issues/{issue_id}/notes`
**Description**: Get notes for an issue

#### POST `/issues/{issue_id}/notes`
**Description**: Add note to issue

**Request Body**:
```json
{
  "note_text": "Contacted maintenance team for repair estimate"
}
```

**Response**:
```json
{
  "id": 1,
  "issue_id": 1,
  "note_text": "Contacted maintenance team for repair estimate",
  "created_by": 1,
  "timestamp": "2024-08-16T10:30:00Z"
}
```

### Statistics

#### GET `/issues/stats/summary`
**Description**: Get issue statistics summary

**Response**:
```json
{
  "total_issues": 45,
  "by_status": {
    "open": 12,
    "in_progress": 8,
    "resolved": 20,
    "closed": 5
  },
  "by_severity": {
    "critical": 2,
    "high": 8,
    "medium": 25,
    "low": 10
  }
}
```

---

## GPS Tracking

Real-time GPS location tracking for security personnel with geofencing and alert capabilities.

### Location Status Values
- `active` - Normal active status
- `sos` - Emergency/SOS status
- `offline` - Device offline
- `break` - On break
- `patrol` - On patrol

### Alert Types
- `geofence_entry` - Entered restricted area
- `geofence_exit` - Left assigned area
- `sos_triggered` - SOS button pressed
- `offline_timeout` - Device offline too long
- `speed_violation` - Exceeding speed limit

### Geofence Types
- `safe_zone` - Safe operational area
- `restricted_zone` - Restricted access area
- `checkpoint` - Checkpoint boundary
- `patrol_route` - Patrol route boundary

### POST `/gps/location`
**Description**: Submit GPS location update

**Request Body**:
```json
{
  "latitude": 40.7128,
  "longitude": -74.0060,
  "accuracy": 5.0,
  "altitude": 100.0,
  "heading": 45.0,
  "speed": 0.5,
  "status": "patrol",
  "message": "On patrol route"
}
```

**Response**:
```json
{
  "id": 1,
  "guard_id": 1,
  "site_id": 1,
  "latitude": 40.7128,
  "longitude": -74.0060,
  "accuracy": 5.0,
  "altitude": 100.0,
  "heading": 45.0,
  "speed": 0.5,
  "status": "patrol",
  "message": "On patrol route",
  "timestamp": "2024-08-16T12:00:00Z",
  "created_at": "2024-08-16T12:00:00Z"
}
```

### GET `/gps/location/current`
**Description**: Get current location of authenticated user

### GET `/gps/locations/{user_id}`
**Description**: Get location history for specific user

**Query Parameters**:
- `start_date` (datetime): History start date
- `end_date` (datetime): History end date
- `limit` (int): Maximum records

### Geofencing

#### GET `/gps/geofences`
**Description**: Get geofence areas

#### POST `/gps/geofences`
**Description**: Create geofence area

**Request Body**:
```json
{
  "site_id": 1,
  "name": "Main Building Perimeter",
  "description": "Safe zone around main building",
  "center_latitude": 40.7128,
  "center_longitude": -74.0060,
  "radius_meters": 100.0,
  "fence_type": "safe_zone",
  "alert_on_enter": "none",
  "alert_on_exit": "warning"
}
```

### Location Alerts

#### GET `/gps/alerts`
**Description**: Get location-based alerts

#### GET `/gps/alerts/{alert_id}`
**Description**: Get specific alert details

#### PUT `/gps/alerts/{alert_id}/acknowledge`
**Description**: Acknowledge location alert

---

## File Management

File upload and management system with cloud storage integration.

### Storage Providers
- `local` - Local file storage
- `s3` - Amazon S3
- `gcs` - Google Cloud Storage

### GET `/files/`
**Description**: List files with filtering

**Query Parameters**:
- `file_type` (string): Filter by MIME type
- `uploaded_by` (int): Filter by uploader
- `tags` (string): Filter by tags
- `is_public` (bool): Filter by public status

### POST `/files/upload`
**Description**: Upload file

**Request Body**: Multipart form
- `file`: File to upload
- `description` (optional): File description
- `tags` (optional): Comma-separated tags
- `is_public` (optional): Make file public

**Response**:
```json
{
  "id": 1,
  "original_filename": "evidence.jpg",
  "unique_filename": "uuid-generated-name.jpg",
  "file_path": "/uploads/2024/08/16/uuid-generated-name.jpg",
  "file_type": "image/jpeg",
  "file_extension": ".jpg",
  "file_size": 1024000,
  "storage_provider": "local",
  "bucket_name": null,
  "object_key": "2024/08/16/uuid-generated-name.jpg",
  "uploaded_by": 1,
  "uploaded_at": "2024-08-16T12:00:00Z",
  "is_public": false,
  "is_deleted": false,
  "expires_at": null,
  "access_count": 0,
  "last_accessed": null,
  "description": "Evidence photo",
  "tags": "evidence,checkpoint"
}
```

### GET `/files/{file_id}`
**Description**: Get file metadata

### PUT `/files/{file_id}`
**Description**: Update file metadata

### DELETE `/files/{file_id}`
**Description**: Delete file (soft delete)

### GET `/files/{file_id}/download`
**Description**: Download file content

### POST `/files/batch-upload`
**Description**: Batch upload multiple files

### GET `/files/public/{file_id}/download`
**Description**: Get public download URL

### GET `/files/stats/overview`
**Description**: Get file statistics overview

### Admin File Management

#### POST `/files/admin/cleanup`
**Description**: Cleanup expired files (Admin only)

#### GET `/files/admin/orphaned`
**Description**: Find orphaned files (Admin only)

---

## Mobile API v1

### Base Path: `/mobile/v1`

The Mobile API v1 provides optimized endpoints specifically designed for mobile applications with:
- **Version Compatibility**: Automatic feature detection based on app version
- **Lightweight Payloads**: Minimal data transfer for mobile networks
- **Offline Sync Support**: Batch operations and conflict resolution
- **Mobile-Optimized Auth**: Extended token expiry and device registration
- **Push Notification Integration**: Device token management
- **Error Handling**: Mobile-friendly error messages

### Version Headers
All mobile endpoints support versioning through headers:
```http
X-Mobile-Version: 1.1.0
X-Platform: android|ios
X-Device-ID: unique-device-identifier
```

### Mobile Authentication

#### POST `/mobile/v1/auth/login`
**Description**: Mobile-optimized login with device registration and version support

**Request Body**:
```json
{
  "username": "string",
  "password": "string",
  "device_id": "unique-device-id",
  "device_type": "android|ios",
  "fcm_token": "firebase-cloud-messaging-token"
}
```

**Response**:
```json
{
  "access_token": "string",
  "token_type": "bearer",
  "expires_in": 172800,
  "user_id": 1,
  "username": "john.doe",
  "full_name": "John Doe",
  "role": "guard",
  "permissions": ["patrol:read", "issue:create"],
  "site_ids": [1, 2, 3]
}
```

#### GET `/mobile/v1/auth/profile`
**Description**: Get mobile user profile

**Response**:
```json
{
  "id": 1,
  "username": "john.doe",
  "full_name": "John Doe",
  "email": "john@example.com",
  "phone": "+1-555-0123",
  "role": "guard",
  "is_active": true,
  "site_ids": [1, 2, 3]
}
```

#### POST `/mobile/v1/auth/change-password`
**Description**: Change password from mobile app

**Request Body**:
```json
{
  "current_password": "string",
  "new_password": "string"
}
```

#### POST `/mobile/v1/auth/device`
**Description**: Update device information for push notifications

**Request Body**:
```json
{
  "device_id": "string",
  "device_type": "android|ios",
  "fcm_token": "string",
  "app_version": "1.1.0"
}
```

#### POST `/mobile/v1/auth/refresh`
**Description**: Refresh mobile access token

#### POST `/mobile/v1/auth/logout`
**Description**: Mobile logout with push token cleanup

#### GET `/mobile/v1/auth/app-info`
**Description**: Get app configuration and feature flags

**Response**:
```json
{
  "api_version": "1.0",
  "min_app_version": "1.0.0",
  "features": {
    "enhanced_sync": true,
    "bulk_operations": true,
    "offline_photos": true,
    "push_notifications": true,
    "nfc_scanning": true
  },
  "sync_interval": 300,
  "max_offline_days": 7,
  "max_batch_size": 100
}
```

#### GET `/mobile/v1/auth/profile/optimized`
**Description**: Bandwidth-optimized user profile

#### POST `/mobile/v1/auth/device/register`
**Description**: Enhanced device registration with feature detection

#### GET `/mobile/v1/auth/version/check`
**Description**: Check app version compatibility

**Response**:
```json
{
  "current_version": "1.1.0",
  "supported": true,
  "deprecated": false,
  "update_required": false,
  "update_recommended": false,
  "min_version": "1.0.0",
  "features": ["push_notifications", "nfc_scanning"],
  "message": "Version supported"
}
```

### Mobile Emergency

#### GET `/mobile/v1/emergency/contacts`
**Description**: Get emergency contacts

#### GET `/mobile/v1/emergency/info`
**Description**: Get emergency information

#### POST `/mobile/v1/emergency/sos`
**Description**: Trigger SOS alert

#### GET `/mobile/v1/emergency/status/{alert_id}`
**Description**: Get emergency alert status

#### POST `/mobile/v1/emergency/trigger`
**Description**: Trigger emergency alert

#### POST `/mobile/v1/emergency/update/{alert_id}`
**Description**: Update emergency alert status

### Mobile Incidents

#### GET `/mobile/v1/incidents/`
**Description**: Get incidents

#### POST `/mobile/v1/incidents/`
**Description**: Create incident

#### GET `/mobile/v1/incidents/{incident_id}`
**Description**: Get incident details

#### PUT `/mobile/v1/incidents/{incident_id}`
**Description**: Update incident

#### GET `/mobile/v1/incidents/{incident_id}/notes`
**Description**: Get incident notes

#### POST `/mobile/v1/incidents/{incident_id}/notes`
**Description**: Add incident note

### Mobile Patrols

#### GET `/mobile/v1/patrols/assigned`
**Description**: Get assigned patrols

#### POST `/mobile/v1/patrols/{patrol_id}/action`
**Description**: Perform patrol action

#### GET `/mobile/v1/patrols/{patrol_id}/checkpoints`
**Description**: Get patrol checkpoints

#### POST `/mobile/v1/patrols/{patrol_id}/checkpoints/visit`
**Description**: Visit checkpoint

#### POST `/mobile/v1/patrols/{patrol_id}/checkpoints/visit/optimized`
**Description**: Visit checkpoint (optimized)

#### POST `/mobile/v1/patrols/{patrol_id}/end`
**Description**: End patrol

#### GET `/mobile/v1/patrols/{patrol_id}/optimized`
**Description**: Get patrol (optimized)

#### POST `/mobile/v1/patrols/{patrol_id}/start`
**Description**: Start patrol

### Mobile Performance

#### GET `/mobile/v1/performance/health`
**Description**: Mobile health check

#### GET `/mobile/v1/performance/metrics`
**Description**: Get performance metrics

#### GET `/mobile/v1/performance/network-info`
**Description**: Get network optimization info

#### GET `/mobile/v1/performance/optimization-tips`
**Description**: Get optimization tips

#### POST `/mobile/v1/performance/report`
**Description**: Report mobile metrics

### Mobile Sync

#### POST `/mobile/v1/sync/bulk-upload`
**Description**: Bulk upload data

#### POST `/mobile/v1/sync/checkpoint-visits`
**Description**: Sync checkpoint visits

#### POST `/mobile/v1/sync/download`
**Description**: Sync download

#### POST `/mobile/v1/sync/incident-drafts`
**Description**: Sync incident drafts

#### POST `/mobile/v1/sync/resolve-conflicts`
**Description**: Resolve sync conflicts

#### POST `/mobile/v1/sync/upload`
**Description**: Sync upload
```

### Notification Management

#### GET `/notifications/`
**Description**: Get user notifications with pagination

**Query Parameters**:
- `skip` (int): Records to skip (default: 0)
- `limit` (int): Records to return (default: 20, max: 100)
- `unread_only` (bool): Only unread notifications
- `notification_type` (string): Filter by type

**Response**:
```json
[
  {
    "id": 1,
    "recipient_id": 1,
    "title": "New Task Assigned",
    "message": "You have been assigned a new patrol task",
    "notification_type": "task_assignment",
    "priority": "normal",
    "is_read": false,
    "data": {
      "task_id": 123,
      "site_name": "Main Campus"
    },
    "created_at": "2024-08-16T10:00:00Z",
    "read_at": null
  }
]
```

#### POST `/notifications/`
**Description**: Create notification (Admin/System only)

**Request Body**:
```json
{
  "recipient_id": 1,
  "title": "string",
  "message": "string",
  "notification_type": "info",
  "priority": "normal",
  "data": {}
}
```

#### PUT `/notifications/{notification_id}/read`
**Description**: Mark notification as read

#### POST `/notifications/mark-all-read`
**Description**: Mark all notifications as read

#### DELETE `/notifications/{notification_id}`
**Description**: Delete notification

### Message System

#### GET `/messages/`
**Description**: Get messages/communications

**Query Parameters**:
- `recipient_type` (string): "user", "role", "site", "broadcast"
- `is_read` (bool): Filter by read status

#### POST `/messages/`
**Description**: Send message

**Request Body**:
```json
{
  "recipient_type": "user",
  "recipient_id": 1,
  "subject": "string",
  "content": "string",
  "priority": "normal",
  "message_type": "info"
}
```

#### GET `/messages/{message_id}`
**Description**: Get message details

#### PUT `/messages/{message_id}/read`
**Description**: Mark message as read

---

## Real-time Features

### WebSocket Connection
**URL**: `ws://localhost:8000/ws/{user_id}?token={jwt_token}`

**Supported Message Types**:
```json
{
  "type": "notification",
  "data": {
    "id": 1,
    "title": "New Assignment",
    "message": "You have a new patrol assignment",
    "notification_type": "task_assignment"
  }
}

{
  "type": "panic_alert",
  "data": {
    "alert_id": 1,
    "guard_id": 2,
    "severity": "high",
    "location": {
      "latitude": 40.7128,
      "longitude": -74.0060,
      "name": "Main Entrance"
    },
    "triggered_at": "2024-08-16T11:00:00Z"
  }
}

{
  "type": "task_update",
  "data": {
    "task_id": 1,
    "status": "completed",
    "updated_by": "John Doe"
  }
}

{
  "type": "location_update",
  "data": {
    "user_id": 1,
    "latitude": 40.7128,
    "longitude": -74.0060,
    "status": "patrol",
    "timestamp": "2024-08-16T12:00:00Z"
  }
}
```

### Live Endpoints

#### GET `/live/guards/active`
**Description**: Get currently active guards

#### GET `/live/alerts/active`
**Description**: Get active alerts and incidents

#### GET `/live/system/health`
**Description**: System health check

**Response**:
```json
{
  "status": "healthy",
  "database": "connected",
  "redis": "connected",
  "external_services": "operational",
  "timestamp": "2024-08-16T12:00:00Z"
}
```

---

## Analytics & Reporting

### Dashboard Endpoints

**Note**: The following endpoints are part of the Analytics system and Live Monitoring:

#### GET `/analytics/dashboard/overview`
**Description**: Get dashboard overview with detailed statistics

#### GET `/live/dashboard`
**Description**: Get live dashboard data for real-time monitoring

#### GET `/analytics/dashboards`
**Description**: Get available dashboard configurations

For specific dashboard statistics, use the Analytics endpoints listed in the Analytics & Reporting section above.

### Audit Logs

#### GET `/audit/actions`
**Description**: Get available audit actions

#### DELETE `/audit/cleanup`
**Description**: Cleanup old audit logs

#### POST `/audit/log`
**Description**: Create manual audit log entry

#### GET `/audit/logs`
**Description**: Get audit trail

**Query Parameters**:
- `action` (string): Filter by action type
- `user_id` (int): Filter by user
- `start_date` (datetime): Filter from date
- `end_date` (datetime): Filter to date

**Response**:
```json
[
  {
    "id": 1,
    "user_id": 1,
    "action": "login",
    "resource_type": "auth",
    "resource_id": null,
    "ip_address": "192.168.1.100",
    "user_agent": "Mozilla/5.0...",
    "details": {
      "success": true,
      "device_type": "mobile"
    },
    "timestamp": "2024-08-16T08:00:00Z"
  }
]
```

#### GET `/audit/logs/{log_id}`
**Description**: Get specific audit log

#### GET `/audit/metrics`
**Description**: Get audit metrics

#### GET `/audit/resource-types`
**Description**: Get available resource types

#### GET `/audit/resource/{resource_type}/{resource_id}`
**Description**: Get resource audit trail

#### GET `/audit/system/activity`
**Description**: Get system activity summary

#### GET `/audit/users/{user_id}/activity`
**Description**: Get user activity summary

### Settings Management

#### GET `/settings/`
**Description**: Get system settings

#### PUT `/settings/{key}`
**Description**: Update setting value

**Request Body**:
```json
{
  "value": "new_value",
  "description": "Setting description"
}
```

#### GET `/settings/categories/{category}`
**Description**: Get settings by category

---

## Error Handling

### HTTP Status Codes
PatrolShield API implements comprehensive error handling with consistent HTTP status codes:

- `200 OK` - Request successful
- `201 Created` - Resource created successfully  
- `204 No Content` - Request successful, no content returned
- `400 Bad Request` - Invalid request format or missing required fields
- `401 Unauthorized` - Authentication required or invalid credentials
- `403 Forbidden` - Insufficient permissions for the requested operation
- `404 Not Found` - Requested resource not found
- `422 Unprocessable Entity` - Request validation failed
- `500 Internal Server Error` - Server error with descriptive message

### Error Response Format
All error responses follow FastAPI's standard format:

```json
{
  "detail": "Descriptive error message explaining what went wrong"
}
```

For validation errors (422), Pydantic provides detailed field-level errors:
```json
{
  "detail": [
    {
      "loc": ["body", "field_name"],
      "msg": "field required",
      "type": "value_error.missing"
    }
  ]
}
```

### Common Error Scenarios

#### Authentication Errors (401)
```json
{
  "detail": "Incorrect username or password"
}
```
```json
{
  "detail": "Inactive user"
}
```

#### Permission Errors (403)
```json
{
  "detail": "You don't have permission to access this resource"
}
```

#### Validation Errors (400/422)
```json
{
  "detail": "Invalid user assignment: User with ID 123 does not exist"
}
```

#### Server Errors (500)
All server errors include descriptive messages for debugging:
```json
{
  "detail": "Failed to create task: Database connection timeout"
}
```

### Mobile-Specific Error Handling
Mobile API v1 includes enhanced error responses:

```json
{
  "message": "User-friendly error message",
  "code": "ERROR_CODE",
  "severity": "warning|error|critical",
  "retry_after": 30,
  "support_contact": "support@patrolshield.com"
}
```

---

## Flutter Integration Examples

### Complete API Service Setup
```dart
// lib/services/api_service.dart
class ApiService {
  final String baseUrl;
  final Dio _dio;
  String? _token;
  
  ApiService({required this.baseUrl}) : _dio = Dio() {
    _setupInterceptors();
  }
  
  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        options.headers['Content-Type'] = 'application/json';
        options.headers['Accept'] = 'application/json';
        options.headers['X-API-Version'] = '2.0';
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          _handleTokenExpiry();
        }
        handler.next(error);
      },
    ));
  }
  
  void setToken(String token) {
    _token = token;
  }
  
  void _handleTokenExpiry() {
    _token = null;
    // Navigate to login screen
  }
}
```

### Authentication Service
```dart
// lib/services/auth_service.dart
class AuthService {
  final ApiService _apiService;
  
  AuthService(this._apiService);
  
  Future<AuthResponse> login(String username, String password) async {
    try {
      final response = await _apiService._dio.post(
        '${_apiService.baseUrl}/auth/login',
        data: FormData.fromMap({
          'username': username,
          'password': password,
        }),
      );
      
      final authResponse = AuthResponse.fromJson(response.data);
      _apiService.setToken(authResponse.accessToken);
      return authResponse;
    } on DioError catch (e) {
      throw AuthException.fromDioError(e);
    }
  }
  
  Future<User> getCurrentUser() async {
    try {
      final response = await _apiService._dio.get('/auth/me');
      return User.fromJson(response.data);
    } on DioError catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
```

### Task Service
```dart
// lib/services/task_service.dart
class TaskService {
  final ApiService _apiService;
  
  TaskService(this._apiService);
  
  Future<List<Task>> getTasks({
    int? siteId,
    String? taskType,
    String? status,
    int? assignedTo,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (siteId != null) queryParams['site_id'] = siteId;
      if (taskType != null) queryParams['task_type'] = taskType;
      if (status != null) queryParams['status'] = status;
      if (assignedTo != null) queryParams['assigned_to'] = assignedTo;
      
      final response = await _apiService._dio.get(
        '/tasks/',
        queryParameters: queryParams,
      );
      
      return (response.data as List)
          .map((task) => Task.fromJson(task))
          .toList();
    } on DioError catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
  
  Future<Task> createTask(TaskCreate taskData) async {
    try {
      final response = await _apiService._dio.post(
        '/tasks/',
        data: taskData.toJson(),
      );
      return Task.fromJson(response.data);
    } on DioError catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
  
  Future<void> recordCheckpointVisit(
    int taskId,
    int checkpointId,
    CheckpointVisitData visitData,
  ) async {
    try {
      await _apiService._dio.post(
        '/tasks/$taskId/checkpoints/$checkpointId/visit',
        data: visitData.toJson(),
      );
    } on DioError catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
```

### Panic Alert Service
```dart
// lib/services/panic_service.dart
class PanicService {
  final ApiService _apiService;
  
  PanicService(this._apiService);
  
  Future<PanicAlert> triggerAlert({
    String? reason,
    AlertSeverity severity = AlertSeverity.high,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? locationName,
  }) async {
    try {
      final response = await _apiService._dio.post(
        '/panic/trigger',
        data: {
          'reason': reason,
          'severity': severity.name,
          'location_lat': latitude,
          'location_lon': longitude,
          'location_accuracy': accuracy,
          'location_name': locationName,
        },
      );
      return PanicAlert.fromJson(response.data);
    } on DioError catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
  
  Future<List<PanicAlert>> getActiveAlerts() async {
    try {
      final response = await _apiService._dio.get('/panic/active');
      return (response.data as List)
          .map((alert) => PanicAlert.fromJson(alert))
          .toList();
    } on DioError catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
```

### WebSocket Service with Reconnection
```dart
// lib/services/websocket_service.dart
class WebSocketService {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  final StreamController<WebSocketMessage> _messageController = 
      StreamController.broadcast();
  
  Stream<WebSocketMessage> get messages => _messageController.stream;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  
  Future<void> connect(String userId, String token) async {
    try {
      final uri = Uri.parse('ws://localhost:8000/ws/$userId?token=$token');
      _channel = WebSocketChannel.connect(uri);
      
      _channel!.stream.listen(
        (message) {
          _isConnected = true;
          _reconnectAttempts = 0;
          final data = json.decode(message);
          _messageController.add(WebSocketMessage.fromJson(data));
        },
        onError: (error) {
          _isConnected = false;
          _scheduleReconnect(userId, token);
        },
        onDone: () {
          _isConnected = false;
          _scheduleReconnect(userId, token);
        },
      );
    } catch (e) {
      _scheduleReconnect(userId, token);
    }
  }
  
  void _scheduleReconnect(String userId, String token) {
    if (_reconnectAttempts >= _maxReconnectAttempts) return;
    
    _reconnectAttempts++;
    final delay = Duration(seconds: math.pow(2, _reconnectAttempts).toInt());
    
    _reconnectTimer = Timer(delay, () {
      connect(userId, token);
    });
  }
  
  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _messageController.close();
  }
}
```

### Complete Error Handling
```dart
// lib/exceptions/api_exception.dart
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? code;
  final dynamic details;
  
  ApiException({
    required this.statusCode,
    required this.message,
    this.code,
    this.details,
  });
  
  factory ApiException.fromDioError(DioError error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode ?? 500;
      final data = error.response!.data;
      
      String message = 'An error occurred';
      String? code;
      dynamic details;
      
      if (data is Map<String, dynamic>) {
        if (data.containsKey('detail')) {
          if (data['detail'] is String) {
            message = data['detail'];
          } else if (data['detail'] is List) {
            // Pydantic validation errors
            final errors = data['detail'] as List;
            message = errors.isNotEmpty 
                ? errors.first['msg'] ?? 'Validation error'
                : 'Validation error';
            details = errors;
          }
        }
        
        code = data['code'] ?? _getErrorCodeFromStatus(statusCode);
      }
      
      return ApiException(
        statusCode: statusCode,
        message: message,
        code: code,
        details: details,
      );
    } else {
      return ApiException(
        statusCode: 0,
        message: 'Network error: ${error.message}',
        code: 'NETWORK_ERROR',
      );
    }
  }
  
  static String _getErrorCodeFromStatus(int statusCode) {
    switch (statusCode) {
      case 400: return 'BAD_REQUEST';
      case 401: return 'UNAUTHORIZED';
      case 403: return 'FORBIDDEN';
      case 404: return 'NOT_FOUND';
      case 422: return 'VALIDATION_ERROR';
      case 500: return 'SERVER_ERROR';
      default: return 'UNKNOWN_ERROR';
    }
  }
  
  bool get isAuthError => statusCode == 401;
  bool get isPermissionError => statusCode == 403;
  bool get isValidationError => statusCode == 400 || statusCode == 422;
  bool get isServerError => statusCode >= 500;
  bool get isNetworkError => statusCode == 0;
}
```

### Data Models Example
```dart
// lib/models/task.dart
class Task {
  final int id;
  final String title;
  final String? description;
  final int assignedTo;
  final int createdBy;
  final DateTime? dueDate;
  final TaskStatus status;
  final TaskPriority priority;
  final TaskType taskType;
  final int? siteId;
  final int? estimatedDuration;
  final DateTime? startTime;
  final DateTime? endTime;
  final int completionPercentage;
  final bool isRecurring;
  final String? recurrencePattern;
  final DateTime? nextDueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TaskCheckpoint> checkpoints;
  final List<TaskCheckpointVisit> checkpointVisits;
  
  Task({
    required this.id,
    required this.title,
    this.description,
    required this.assignedTo,
    required this.createdBy,
    this.dueDate,
    required this.status,
    required this.priority,
    required this.taskType,
    this.siteId,
    this.estimatedDuration,
    this.startTime,
    this.endTime,
    required this.completionPercentage,
    required this.isRecurring,
    this.recurrencePattern,
    this.nextDueDate,
    required this.createdAt,
    required this.updatedAt,
    required this.checkpoints,
    required this.checkpointVisits,
  });
  
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      assignedTo: json['assigned_to'],
      createdBy: json['created_by'],
      dueDate: json['due_date'] != null 
          ? DateTime.parse(json['due_date'])
          : null,
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == json['priority'],
      ),
      taskType: TaskType.values.firstWhere(
        (e) => e.name == json['task_type'],
      ),
      siteId: json['site_id'],
      estimatedDuration: json['estimated_duration'],
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'])
          : null,
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : null,
      completionPercentage: json['completion_percentage'],
      isRecurring: json['is_recurring'],
      recurrencePattern: json['recurrence_pattern'],
      nextDueDate: json['next_due_date'] != null
          ? DateTime.parse(json['next_due_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      checkpoints: (json['checkpoints'] as List? ?? [])
          .map((c) => TaskCheckpoint.fromJson(c))
          .toList(),
      checkpointVisits: (json['checkpoint_visits'] as List? ?? [])
          .map((v) => TaskCheckpointVisit.fromJson(v))
          .toList(),
    );
  }
}

enum TaskStatus { pending, inProgress, completed, cancelled }
enum TaskPriority { low, medium, high, urgent }
enum TaskType { general, patrol, inspection, maintenance, security, training, emergency }
```

---

## Messages & Communications

### GET `/messages/`
**Description**: Get messages/communications

**Query Parameters**:
- `recipient_type` (string): "user", "role", "site", "broadcast"
- `is_read` (bool): Filter by read status

**Response**:
```json
[
  {
    "id": 1,
    "sender_id": 1,
    "recipient_id": 2,
    "subject": "Patrol Assignment",
    "content": "You have been assigned to patrol site A",
    "message_type": "info",
    "priority": "normal",
    "is_read": false,
    "sent_at": "2024-08-16T10:00:00Z"
  }
]
```

### POST `/messages/`
**Description**: Send message

**Request Body**:
```json
{
  "recipient_type": "user",
  "recipient_id": 1,
  "subject": "string",
  "content": "string",
  "priority": "normal",
  "message_type": "info"
}
```

### GET `/messages/sent/`
**Description**: Get sent messages

### GET `/messages/sos/`
**Description**: Get SOS/emergency messages

### GET `/messages/unread/`
**Description**: Get unread messages

### POST `/messages/voice-call`
**Description**: Initiate voice message call

### GET `/messages/voice-users/`
**Description**: Get available voice users

### GET `/messages/{message_id}`
**Description**: Get message details

### DELETE `/messages/{message_id}`
**Description**: Delete message

### PUT `/messages/{message_id}/read`
**Description**: Mark message as read

---

## Notifications

### GET `/notifications/`
**Description**: Get user notifications with pagination

**Query Parameters**:
- `skip` (int): Records to skip (default: 0)
- `limit` (int): Records to return (default: 20, max: 100)
- `unread_only` (bool): Only unread notifications
- `notification_type` (string): Filter by type

**Response**:
```json
[
  {
    "id": 1,
    "recipient_id": 1,
    "title": "New Task Assigned",
    "message": "You have been assigned a new patrol task",
    "notification_type": "task_assignment",
    "priority": "normal",
    "is_read": false,
    "data": {
      "task_id": 123,
      "site_name": "Main Campus"
    },
    "created_at": "2024-08-16T10:00:00Z",
    "read_at": null
  }
]
```

### POST `/notifications/`
**Description**: Create notification (Admin/System only)

**Request Body**:
```json
{
  "recipient_id": 1,
  "title": "string",
  "message": "string",
  "notification_type": "info",
  "priority": "normal",
  "data": {}
}
```

### GET `/notifications/all`
**Description**: List all notifications (Admin only)

### DELETE `/notifications/cleanup`
**Description**: Cleanup old notifications

### PUT `/notifications/mark-all-read`
**Description**: Mark all notifications as read

### POST `/notifications/retry-failed`
**Description**: Retry failed deliveries

### GET `/notifications/settings`
**Description**: Get notification settings

### PUT `/notifications/settings`
**Description**: Update notification settings

### GET `/notifications/stats`
**Description**: Get notification statistics

### POST `/notifications/test/real-time`
**Description**: Test real-time notification

### GET `/notifications/unread/count`
**Description**: Get unread count

### DELETE `/notifications/{notification_id}`
**Description**: Delete notification

### POST `/notifications/{notification_id}/delivery/confirm`
**Description**: Confirm notification delivery

### PUT `/notifications/{notification_id}/read`
**Description**: Mark notification as read

---

## Analytics & Reporting

### GET `/analytics/`
**Description**: Analytics overview

### GET `/analytics/dashboard/overview`
**Description**: Get dashboard overview detailed

### GET `/analytics/dashboards`
**Description**: Get available dashboards

### GET `/analytics/dashboards/{dashboard_type}`
**Description**: Get dashboard data

### GET `/analytics/guard-performance/{guard_id}`
**Description**: Get guard performance metrics

### GET `/analytics/incident-trends`
**Description**: Get incident trends analysis

### GET `/analytics/issues`
**Description**: Get issue analytics

### GET `/analytics/issues/by-site`
**Description**: Issue count by site

### GET `/analytics/patrol-efficiency`
**Description**: Get patrol efficiency report

### POST `/analytics/reports/export/csv`
**Description**: Export data as CSV

### POST `/analytics/reports/export/pdf`
**Description**: Export report as PDF

### POST `/analytics/reports/generate`
**Description**: Generate custom report

### POST `/analytics/reports/schedule`
**Description**: Schedule recurring report

### GET `/analytics/site-security/{site_id}`
**Description**: Get site security score

---

## Dashboard System

### GET `/dashboards/`
**Description**: Get user dashboards

### POST `/dashboards/`
**Description**: Create dashboard

### POST `/dashboards/from-template`
**Description**: Create dashboard from template

### GET `/dashboards/templates/`
**Description**: Get dashboard templates

### PUT `/dashboards/widgets/{widget_id}`
**Description**: Update widget

### DELETE `/dashboards/widgets/{widget_id}`
**Description**: Delete widget

### GET `/dashboards/widgets/{widget_id}/data`
**Description**: Get widget data

### GET `/dashboards/{dashboard_id}`
**Description**: Get dashboard

### PUT `/dashboards/{dashboard_id}`
**Description**: Update dashboard

### DELETE `/dashboards/{dashboard_id}`
**Description**: Delete dashboard

### POST `/dashboards/{dashboard_id}/clone`
**Description**: Clone dashboard

### GET `/dashboards/{dashboard_id}/export`
**Description**: Export dashboard

### POST `/dashboards/{dashboard_id}/share`
**Description**: Share dashboard

### POST `/dashboards/{dashboard_id}/widgets`
**Description**: Add widget to dashboard

---

## Events & Webhooks

### POST `/events/emit`
**Description**: Emit event

### GET `/events/health`
**Description**: Get event system health

### GET `/events/history`
**Description**: Get event history

### GET `/events/notifications/stats`
**Description**: Get event notification stats

### POST `/events/notifications/trigger`
**Description**: Trigger notification event

### GET `/events/priorities`
**Description**: Get event priorities

### GET `/events/stats`
**Description**: Get event stats

### GET `/events/types`
**Description**: Get event types

### Specific Event Triggers

#### POST `/events/checkpoint/missed`
**Description**: Emit checkpoint missed event

#### POST `/events/incident/created`
**Description**: Emit incident created event

#### POST `/events/panic/triggered`
**Description**: Emit panic triggered event

#### POST `/events/shift/started`
**Description**: Emit shift started event

---

## Integrations

### GET `/integrations/events`
**Description**: List available webhook event types

### GET `/integrations/hr/status`
**Description**: Get HR integration status

### POST `/integrations/hr/sync`
**Description**: Sync HR system

### GET `/integrations/status`
**Description**: Get integration status

### Webhook Management

#### GET `/integrations/webhooks/`
**Description**: List webhooks

#### POST `/integrations/webhooks/register`
**Description**: Register webhook

#### POST `/integrations/webhooks/retry`
**Description**: Retry failed webhooks

#### POST `/integrations/webhooks/test`
**Description**: Test webhook

#### GET `/integrations/webhooks/{webhook_id}`
**Description**: Get webhook

#### PUT `/integrations/webhooks/{webhook_id}`
**Description**: Update webhook

#### DELETE `/integrations/webhooks/{webhook_id}`
**Description**: Delete webhook

#### GET `/integrations/webhooks/{webhook_id}/health`
**Description**: Get webhook health

---

## Settings Management

### GET `/settings/`
**Description**: Get all settings (admin only)

**Query Parameters**:
- `page` (int): Page number
- `per_page` (int): Records per page
- `category` (string): Filter by category
- `is_public` (string): Filter by public/private

### POST `/settings/`
**Description**: Create setting (admin only)

### PUT `/settings/bulk`
**Description**: Bulk update settings (admin only)

### GET `/settings/categories/`
**Description**: Get settings categories

### GET `/settings/category/{category}`
**Description**: Get settings by category

### GET `/settings/defaults/`
**Description**: Get default settings schema

### GET `/settings/export/`
**Description**: Export settings (admin only)

### POST `/settings/initialize`
**Description**: Initialize default settings (admin only)

### GET `/settings/metrics/`
**Description**: Get settings metrics (admin only)

### GET `/settings/public`
**Description**: Get public settings

### GET `/settings/{key}`
**Description**: Get setting by key

### PUT `/settings/{key}`
**Description**: Update setting (admin only)

### DELETE `/settings/{key}`
**Description**: Delete setting (admin only)

### POST `/settings/{key}/reset`
**Description**: Reset setting to default (admin only)

### PATCH `/settings/{key}/value`
**Description**: Update setting value (admin only)

---

## Performance & Monitoring

### DELETE `/performance/cache/clear`
**Description**: Clear cache entries

**Query Parameters**:
- `pattern` (string): Cache key pattern to clear

### POST `/performance/cache/invalidate/{operation}`
**Description**: Invalidate cache by operation type

### GET `/performance/cache/stats`
**Description**: Get cache statistics

### POST `/performance/database/optimize`
**Description**: Optimize database

### GET `/performance/database/stats`
**Description**: Get database statistics

### GET `/performance/health`
**Description**: Performance system health

### GET `/performance/monitoring/cache-clear`
**Description**: Clear monitoring cache

### GET `/performance/stats`
**Description**: Get performance statistics

---

## Health & System Status

### GET `/health`
**Description**: Basic health check

### GET `/health/`
**Description**: Basic health check

### GET `/health/database`
**Description**: Database health check

### GET `/health/detailed`
**Description**: Detailed health check

### GET `/health/liveness`
**Description**: Kubernetes liveness probe

### GET `/health/metrics`
**Description**: Prometheus metrics

### GET `/health/readiness`
**Description**: Kubernetes readiness probe

### GET `/health/redis`
**Description**: Redis health check

### GET `/health/system`
**Description**: System resources health check

---

## Visitor Management

### GET `/visitors/`
**Description**: List visitors

### POST `/visitors/`
**Description**: Create visitor record

### GET `/visitors/{visitor_id}`
**Description**: Get visitor by ID

### PUT `/visitors/{visitor_id}`
**Description**: Update visitor information

### DELETE `/visitors/{visitor_id}`
**Description**: Delete visitor record

---

## Live Monitoring

### GET `/live/alerts/active`
**Description**: Get active alerts

### GET `/live/dashboard`
**Description**: Get live dashboard data

### GET `/live/guards/locations`
**Description**: Get guard locations

### GET `/live/incidents/open`
**Description**: Get open incidents

### GET `/live/patrols/active`
**Description**: Get active patrols

### GET `/live/system/health`
**Description**: Get system health

---

## WebSocket Documentation

### GET `/websocket-docs/endpoints`
**Description**: List all WebSocket endpoints

### GET `/websocket-docs/test-connection/{user_id}`
**Description**: Test WebSocket connection info

---

## Security Best Practices

### Token Management
- Store JWT tokens securely using Flutter Secure Storage
- Implement automatic token refresh
- Clear tokens on logout
- Handle token expiry gracefully

### Network Security
- Use HTTPS in production
- Implement certificate pinning
- Validate SSL certificates
- Handle network timeouts appropriately

### Data Protection
- Never log sensitive information
- Encrypt sensitive data at rest
- Implement proper error handling to avoid data leaks
- Use proper input validation

---

This comprehensive documentation provides complete integration guidance for Flutter frontend and mobile app development with the PatrolShield API, including all discovered endpoints, data models, and best practices for production applications.
