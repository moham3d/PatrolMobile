# Sites & Zones API Documentation

## Overview
The Sites & Zones API manages physical locations, their hierarchical zones, and user assignments within the PatrolShield system.

**Base URL**: `https://api.millio.space`  
**Authentication**: JWT Bearer Token required  
**Headers**: `Authorization: Bearer <token>`, `Content-Type: application/json`

---

## Sites API

### GET /sites/
**Description**: List all sites with optional filtering  
**Permission**: `sites:view`

**Query Parameters**:
- `skip` (integer, optional): Number of records to skip (default: 0)
- `limit` (integer, optional): Maximum records to return (default: 100)
- `search` (string, optional): Search sites by name or address
- `is_active` (boolean, optional): Filter by active status
- `include_zones` (boolean, optional): Include zone information (default: false)

**Response (200)**:
```json
{
  "sites": [
    {
      "id": 1,
      "name": "Downtown Office Complex",
      "address": "123 Business Ave, City, State 12345",
      "description": "Main corporate headquarters",
      "coordinates": {
        "latitude": 40.7128,
        "longitude": -74.0060
      },
      "is_active": true,
      "created_at": "2024-01-15T10:30:00Z",
      "zone_count": 8,
      "assigned_users_count": 12,
      "settings": {
        "gps_accuracy_required": "high",
        "geofence_radius": 100,
        "patrol_frequency": "4_hours"
      }
    }
  ],
  "total": 1,
  "skip": 0,
  "limit": 100
}
```

---

### POST /sites/
**Description**: Create a new site  
**Permission**: `sites:manage`

**Request Body**:
```json
{
  "name": "Warehouse Complex",
  "address": "456 Industrial Blvd, City, State 54321",
  "description": "Storage and distribution facility",
  "coordinates": {
    "latitude": 40.7589,
    "longitude": -73.9851
  },
  "is_active": true,
  "settings": {
    "gps_accuracy_required": "medium",
    "geofence_radius": 200,
    "patrol_frequency": "2_hours",
    "security_level": "high"
  }
}
```

**Response (201)**:
```json
{
  "id": 2,
  "name": "Warehouse Complex",
  "address": "456 Industrial Blvd, City, State 54321",
  "description": "Storage and distribution facility",
  "coordinates": {
    "latitude": 40.7589,
    "longitude": -73.9851
  },
  "is_active": true,
  "created_at": "2024-01-21T14:20:00Z",
  "settings": {
    "gps_accuracy_required": "medium",
    "geofence_radius": 200,
    "patrol_frequency": "2_hours",
    "security_level": "high"
  }
}
```

---

### GET /sites/{site_id}
**Description**: Get specific site details  
**Permission**: `sites:view`

**Response (200)**:
```json
{
  "id": 1,
  "name": "Downtown Office Complex",
  "address": "123 Business Ave, City, State 12345",
  "description": "Main corporate headquarters",
  "coordinates": {
    "latitude": 40.7128,
    "longitude": -74.0060
  },
  "is_active": true,
  "created_at": "2024-01-15T10:30:00Z",
  "zones": [
    {
      "id": 1,
      "name": "Main Entrance",
      "zone_type": "entrance",
      "security_level": "high"
    }
  ],
  "assigned_users": [
    {
      "user_id": 1,
      "username": "john_guard",
      "full_name": "John Doe",
      "access_level": "full",
      "assigned_at": "2024-01-15T10:30:00Z"
    }
  ],
  "statistics": {
    "total_patrols": 156,
    "checkpoints_count": 24,
    "active_alerts": 0,
    "last_patrol": "2024-01-21T08:30:00Z"
  }
}
```

---

### PUT /sites/{site_id}
**Description**: Update existing site  
**Permission**: `sites:manage`

**Request Body**:
```json
{
  "name": "Downtown Office Complex - Updated",
  "description": "Main corporate headquarters with new security measures",
  "settings": {
    "gps_accuracy_required": "high",
    "geofence_radius": 150,
    "patrol_frequency": "3_hours"
  }
}
```

---

### DELETE /sites/{site_id}
**Description**: Delete site (soft delete)  
**Permission**: `sites:manage`

**Response (204)**: No content

---

## Site User Assignment

### GET /sites/{site_id}/users
**Description**: Get users assigned to site  
**Permission**: `sites:view`

**Response (200)**:
```json
{
  "assigned_users": [
    {
      "user_id": 1,
      "username": "john_guard",
      "full_name": "John Doe",
      "role": "guard",
      "access_level": "full",
      "assigned_at": "2024-01-15T10:30:00Z",
      "assigned_by": "admin",
      "permissions": ["patrols:view", "checkpoints:visit"]
    }
  ],
  "total": 1
}
```

---

### POST /sites/{site_id}/users/{user_id}
**Description**: Assign user to site  
**Permission**: `sites:manage`

**Query Parameters**:
- `access_level` (string): "full", "limited", "read_only" (default: "full")

**Response (201)**:
```json
{
  "user_id": 1,
  "site_id": 1,
  "access_level": "full",
  "assigned_at": "2024-01-21T15:30:00Z",
  "assigned_by": "manager_user"
}
```

---

### DELETE /sites/{site_id}/users/{user_id}
**Description**: Remove user from site  
**Permission**: `sites:manage`

**Response (204)**: No content

---

## Zones API

### GET /zones/
**Description**: List all zones with filtering  
**Permission**: `zones:view`

**Query Parameters**:
- `site_id` (integer, optional): Filter by site
- `zone_type` (string, optional): Filter by type (entrance, perimeter, building, parking, etc.)
- `security_level` (string, optional): Filter by security level (low, medium, high, critical)
- `search` (string, optional): Search by zone name
- `is_active` (boolean, optional): Filter by active status

**Response (200)**:
```json
{
  "zones": [
    {
      "id": 1,
      "site_id": 1,
      "name": "Main Entrance",
      "description": "Primary building entrance with card access",
      "zone_type": "entrance",
      "security_level": "high",
      "coordinates": {
        "latitude": 40.7128,
        "longitude": -74.0060
      },
      "geofence_radius": 25,
      "is_active": true,
      "checkpoint_count": 3,
      "patrol_frequency": "1_hour"
    }
  ],
  "total": 1
}
```

---

### GET /sites/{site_id}/zones/
**Description**: Get zones for specific site  
**Permission**: `zones:view`

**Response (200)**:
```json
{
  "zones": [
    {
      "id": 1,
      "name": "Main Entrance",
      "zone_type": "entrance",
      "security_level": "high",
      "checkpoints": [
        {
          "id": 1,
          "name": "Front Door Scanner",
          "scan_method": "qr"
        }
      ]
    },
    {
      "id": 2,
      "name": "Parking Garage Level 1",
      "zone_type": "parking",
      "security_level": "medium"
    }
  ]
}
```

---

### POST /sites/{site_id}/zones/
**Description**: Create zone within site  
**Permission**: `zones:manage`

**Request Body**:
```json
{
  "name": "Emergency Exit - North",
  "description": "North side emergency exit with alarm system",
  "zone_type": "exit",
  "security_level": "high",
  "coordinates": {
    "latitude": 40.7135,
    "longitude": -74.0055
  },
  "geofence_radius": 15,
  "is_active": true,
  "patrol_settings": {
    "frequency": "2_hours",
    "required_checkpoints": 2,
    "gps_verification_required": true
  }
}
```

**Response (201)**:
```json
{
  "id": 3,
  "site_id": 1,
  "name": "Emergency Exit - North",
  "description": "North side emergency exit with alarm system",
  "zone_type": "exit",
  "security_level": "high",
  "coordinates": {
    "latitude": 40.7135,
    "longitude": -74.0055
  },
  "geofence_radius": 15,
  "is_active": true,
  "created_at": "2024-01-21T16:00:00Z"
}
```

---

### PUT /zones/{zone_id}
**Description**: Update existing zone  
**Permission**: `zones:manage`

**Request Body**:
```json
{
  "security_level": "critical",
  "patrol_settings": {
    "frequency": "30_minutes",
    "required_checkpoints": 3
  }
}
```

---

### DELETE /zones/{zone_id}
**Description**: Delete zone  
**Permission**: `zones:manage`

**Response (204)**: No content

---

### GET /zones/statistics
**Description**: Get zone usage statistics  
**Permission**: `zones:view`

**Query Parameters**:
- `site_id` (integer, optional): Filter by site

**Response (200)**:
```json
{
  "total_zones": 25,
  "zones_by_type": {
    "entrance": 4,
    "perimeter": 8,
    "building": 6,
    "parking": 4,
    "exit": 3
  },
  "zones_by_security_level": {
    "low": 5,
    "medium": 12,
    "high": 6,
    "critical": 2
  },
  "patrol_coverage": {
    "fully_covered": 20,
    "partially_covered": 3,
    "not_covered": 2
  }
}
```

---

## Zone Types and Security Levels

### Available Zone Types
- `entrance`: Main and secondary entrances
- `exit`: Emergency and regular exits  
- `perimeter`: Boundary and fence areas
- `building`: Interior building areas
- `parking`: Parking lots and garages
- `storage`: Warehouse and storage areas
- `office`: Office and workspace areas
- `common`: Common areas like lobbies
- `restricted`: High-security restricted areas

### Security Levels
- `low`: Basic monitoring, infrequent patrols
- `medium`: Regular patrols, standard checkpoints
- `high`: Frequent patrols, multiple checkpoints, GPS verification
- `critical`: Constant monitoring, mandatory checkpoints, immediate alerts

---

## Integration Examples

### Create Site with Zones
```javascript
const createSiteWithZones = async (siteData) => {
  // Create site first
  const siteResponse = await fetch('/sites/', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(siteData)
  });
  
  const site = await siteResponse.json();
  
  // Create zones for the site
  const zones = [
    {
      name: "Main Entrance",
      zone_type: "entrance",
      security_level: "high"
    },
    {
      name: "Parking Area",
      zone_type: "parking", 
      security_level: "medium"
    }
  ];
  
  for (const zoneData of zones) {
    await fetch(`/sites/${site.id}/zones/`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(zoneData)
    });
  }
  
  return site;
};
```

### Assign Multiple Users to Site
```javascript
const assignUsersToSite = async (siteId, userIds) => {
  const promises = userIds.map(userId => 
    fetch(`/sites/${siteId}/users/${userId}?access_level=full`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`
      }
    })
  );
  
  return Promise.all(promises);
};
```