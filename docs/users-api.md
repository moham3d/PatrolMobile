# Users API Documentation

## Overview
The Users API provides comprehensive user management functionality including CRUD operations, role assignments, and user profile management.

**Base URL**: `https://api.millio.space`  
**Authentication**: JWT Bearer Token required  
**Headers**: `Authorization: Bearer <token>`, `Content-Type: application/json`  
**Required Permission**: `users:manage` (for write operations), `users:view` (for read operations)

---

## Endpoints

### GET /users/
**Description**: List all users with optional filtering and pagination  
**Permission**: `users:view`

**Query Parameters**:
- `skip` (integer, optional): Number of records to skip (default: 0)
- `limit` (integer, optional): Maximum records to return (default: 100, max: 1000)
- `search` (string, optional): Search users by name, username, or email
- `role` (string, optional): Filter by role (guard, supervisor, manager, admin)
- `is_active` (boolean, optional): Filter by active status
- `site_id` (integer, optional): Filter users assigned to specific site

**Response (200)**:
```json
{
  "users": [
    {
      "id": 1,
      "username": "john_guard",
      "email": "john@example.com",
      "full_name": "John Doe",
      "role": "guard",
      "is_active": true,
      "created_at": "2024-01-15T10:30:00Z",
      "last_login": "2024-01-20T08:15:00Z",
      "assigned_sites": [
        {
          "site_id": 1,
          "site_name": "Downtown Office",
          "access_level": "full"
        }
      ]
    }
  ],
  "total": 1,
  "skip": 0,
  "limit": 100
}
```

**Error Responses**:
- `401`: Unauthorized
- `403`: Insufficient permissions

---

### POST /users/
**Description**: Create a new user  
**Permission**: `users:manage`

**Request Body**:
```json
{
  "username": "jane_supervisor",
  "email": "jane@example.com",
  "full_name": "Jane Smith",
  "password": "secure_password123",
  "role": "supervisor",
  "is_active": true,
  "profile_settings": {
    "notifications_enabled": true,
    "gps_tracking": true,
    "mobile_access": true
  },
  "assigned_sites": [1, 2]
}
```

**Response (201)**:
```json
{
  "id": 2,
  "username": "jane_supervisor",
  "email": "jane@example.com",
  "full_name": "Jane Smith",
  "role": "supervisor",
  "is_active": true,
  "created_at": "2024-01-21T14:20:00Z",
  "permissions": ["users:view", "patrols:manage", "shifts:manage"],
  "assigned_sites": [
    {
      "site_id": 1,
      "site_name": "Downtown Office",
      "access_level": "full"
    },
    {
      "site_id": 2,
      "site_name": "Warehouse Complex", 
      "access_level": "full"
    }
  ]
}
```

**Error Responses**:
- `400`: Username or email already exists
- `422`: Validation error
- `403`: Insufficient permissions

---

### GET /users/{user_id}
**Description**: Get specific user by ID  
**Permission**: `users:view` or own user data

**Path Parameters**:
- `user_id` (integer): User ID

**Response (200)**:
```json
{
  "id": 1,
  "username": "john_guard",
  "email": "john@example.com",
  "full_name": "John Doe",
  "role": "guard",
  "is_active": true,
  "created_at": "2024-01-15T10:30:00Z",
  "last_login": "2024-01-20T08:15:00Z",
  "permissions": ["patrols:view", "checkpoints:visit"],
  "profile_settings": {
    "notifications_enabled": true,
    "gps_tracking": true,
    "mobile_access": true
  },
  "assigned_sites": [
    {
      "site_id": 1,
      "site_name": "Downtown Office",
      "access_level": "full",
      "assigned_at": "2024-01-15T10:30:00Z"
    }
  ],
  "statistics": {
    "total_patrols": 45,
    "completed_checkpoints": 320,
    "average_patrol_duration": "01:25:00",
    "last_patrol": "2024-01-20T06:00:00Z"
  }
}
```

**Error Responses**:
- `404`: User not found
- `403`: Insufficient permissions

---

### PUT /users/{user_id}
**Description**: Update existing user  
**Permission**: `users:manage` or own user data (limited fields)

**Path Parameters**:
- `user_id` (integer): User ID

**Request Body** (admin/manager):
```json
{
  "email": "john.doe@newcompany.com",
  "full_name": "John A. Doe",
  "role": "supervisor",
  "is_active": true,
  "profile_settings": {
    "notifications_enabled": false,
    "gps_tracking": true
  }
}
```

**Request Body** (own profile):
```json
{
  "email": "john.doe@personal.com",
  "full_name": "John A. Doe",
  "profile_settings": {
    "notifications_enabled": false
  }
}
```

**Response (200)**:
```json
{
  "id": 1,
  "username": "john_guard",
  "email": "john.doe@newcompany.com",
  "full_name": "John A. Doe",
  "role": "supervisor",
  "is_active": true,
  "updated_at": "2024-01-21T15:30:00Z",
  "permissions": ["users:view", "patrols:manage", "shifts:manage"]
}
```

**Error Responses**:
- `404`: User not found
- `400`: Email already exists
- `403`: Insufficient permissions
- `422`: Validation error

---

### DELETE /users/{user_id}
**Description**: Delete user (soft delete - marks as inactive)  
**Permission**: `users:manage`

**Path Parameters**:
- `user_id` (integer): User ID

**Response (204)**: No content

**Error Responses**:
- `404`: User not found
- `403`: Insufficient permissions
- `400`: Cannot delete user with active shifts/patrols

---

## User Roles and Permissions

### Available Roles
- **guard**: Basic patrol and checkpoint access
- **supervisor**: Manage patrols, view reports, manage guards
- **manager**: Manage sites, users, advanced analytics
- **admin**: Full system access

### Role Permissions Matrix
| Permission | Guard | Supervisor | Manager | Admin |
|------------|-------|------------|---------|-------|
| `patrols:view` | ✓ | ✓ | ✓ | ✓ |
| `patrols:manage` | - | ✓ | ✓ | ✓ |
| `checkpoints:visit` | ✓ | ✓ | ✓ | ✓ |
| `users:view` | - | ✓ | ✓ | ✓ |
| `users:manage` | - | - | ✓ | ✓ |
| `sites:view` | ✓ | ✓ | ✓ | ✓ |
| `sites:manage` | - | - | ✓ | ✓ |
| `analytics:view` | - | ✓ | ✓ | ✓ |
| `analytics:advanced` | - | - | ✓ | ✓ |

---

## User Profile Settings

Users can customize their experience through profile settings:

```json
{
  "profile_settings": {
    "notifications_enabled": true,
    "gps_tracking": true,
    "mobile_access": true,
    "language": "en",
    "timezone": "UTC",
    "patrol_preferences": {
      "auto_start_patrol": false,
      "gps_accuracy_required": "high",
      "checkpoint_reminder_distance": 50
    },
    "notification_preferences": {
      "email_enabled": true,
      "push_enabled": true,
      "sms_enabled": false,
      "panic_alerts": true,
      "shift_reminders": true
    }
  }
}
```

---

## Bulk Operations

### Bulk User Creation
```json
POST /users/bulk
{
  "users": [
    {
      "username": "guard1",
      "email": "guard1@company.com",
      "full_name": "Guard One",
      "password": "temp_password",
      "role": "guard"
    },
    {
      "username": "guard2", 
      "email": "guard2@company.com",
      "full_name": "Guard Two",
      "password": "temp_password",
      "role": "guard"
    }
  ],
  "send_welcome_email": true
}
```

### Bulk Role Updates
```json
PUT /users/bulk/role
{
  "user_ids": [1, 2, 3],
  "new_role": "supervisor"
}
```

---

## Search and Filtering

### Advanced Search
```
GET /users/?search=john&role=guard&is_active=true&site_id=1
```

### Search Fields
- `full_name`: Partial name matching
- `username`: Exact or partial username
- `email`: Partial email matching

---

## Integration Examples

### Create User with Site Assignment
```javascript
const createUser = async (userData) => {
  const response = await fetch('/users/', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      ...userData,
      assigned_sites: [1, 2] // Assign to sites 1 and 2
    })
  });
  
  return response.json();
};
```

### Update User Profile Settings
```javascript
const updateProfileSettings = async (userId, settings) => {
  const response = await fetch(`/users/${userId}`, {
    method: 'PUT',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      profile_settings: settings
    })
  });
  
  return response.json();
};
```