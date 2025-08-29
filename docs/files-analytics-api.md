# Files & Analytics API Documentation

## Overview
The Files & Analytics API provides file management capabilities and comprehensive analytics for the PatrolShield system, including reports, dashboards, and performance metrics.

**Base URL**: `https://api.millio.space`  
**Authentication**: JWT Bearer Token required  
**Headers**: `Authorization: Bearer <token>`, `Content-Type: application/json`

---

## Files API

### File Storage Types
- `local`: Local server storage
- `s3`: Amazon S3 storage
- `gcs`: Google Cloud Storage

### File Types
- `image`: Photos and images (jpg, png, gif)
- `document`: Documents (pdf, doc, txt)
- `video`: Video files (mp4, avi, mov)
- `audio`: Audio files (mp3, wav)
- `archive`: Compressed files (zip, tar)

---

### GET /files/
**Description**: List files with filtering  
**Permission**: `files:view`

**Query Parameters**:
- `file_type` (string, optional): Filter by file type
- `uploaded_by` (integer, optional): Filter by user who uploaded
- `tags` (string, optional): Comma-separated tags to filter
- `is_public` (boolean, optional): Filter by public access
- `skip` (integer, optional): Records to skip (default: 0)
- `limit` (integer, optional): Max records (default: 50, max: 200)

**Response (200)**:
```json
{
  "files": [
    {
      "id": "file_123",
      "filename": "checkpoint_evidence.jpg",
      "original_filename": "IMG_20240121_143000.jpg",
      "file_type": "image",
      "file_size": 245760,
      "mime_type": "image/jpeg",
      "uploaded_by": {
        "user_id": 1,
        "username": "john_guard",
        "full_name": "John Doe"
      },
      "uploaded_at": "2024-01-21T14:30:00Z",
      "is_public": false,
      "tags": ["checkpoint", "evidence", "patrol"],
      "metadata": {
        "width": 1920,
        "height": 1080,
        "gps_location": {
          "latitude": 40.7128,
          "longitude": -74.0060
        }
      },
      "download_url": "/files/file_123/download"
    }
  ],
  "total": 1,
  "skip": 0,
  "limit": 50
}
```

---

### POST /files/upload
**Description**: Upload single file  
**Permission**: `files:upload`  
**Content-Type**: `multipart/form-data`

**Form Data**:
- `file`: File binary data
- `tags` (optional): Comma-separated tags
- `is_public` (optional): Make file publicly accessible
- `description` (optional): File description

**Response (201)**:
```json
{
  "file_id": "file_124",
  "filename": "incident_report.pdf",
  "file_type": "document",
  "file_size": 524288,
  "uploaded_at": "2024-01-21T15:00:00Z",
  "download_url": "/files/file_124/download",
  "public_url": null,
  "processing_status": "completed"
}
```

---

### POST /files/batch-upload
**Description**: Upload multiple files in batch  
**Permission**: `files:upload`  
**Content-Type**: `multipart/form-data`

**Form Data**:
- `files[]`: Multiple file binary data
- `tags` (optional): Tags for all files
- `metadata` (optional): JSON metadata for files

**Response (201)**:
```json
{
  "uploaded_files": [
    {
      "file_id": "file_125",
      "filename": "photo1.jpg",
      "status": "success"
    },
    {
      "file_id": "file_126", 
      "filename": "photo2.jpg",
      "status": "success"
    }
  ],
  "successful_uploads": 2,
  "failed_uploads": 0,
  "total_size": 1048576
}
```

---

### GET /files/{file_id}
**Description**: Get file metadata  
**Permission**: `files:view` or file owner

**Response (200)**:
```json
{
  "id": "file_123",
  "filename": "checkpoint_evidence.jpg",
  "original_filename": "IMG_20240121_143000.jpg",
  "file_type": "image",
  "file_size": 245760,
  "mime_type": "image/jpeg",
  "uploaded_by": {
    "user_id": 1,
    "username": "john_guard",
    "full_name": "John Doe"
  },
  "uploaded_at": "2024-01-21T14:30:00Z",
  "last_accessed": "2024-01-21T16:00:00Z",
  "access_count": 5,
  "is_public": false,
  "tags": ["checkpoint", "evidence", "patrol"],
  "metadata": {
    "width": 1920,
    "height": 1080,
    "camera_model": "iPhone 13",
    "gps_location": {
      "latitude": 40.7128,
      "longitude": -74.0060
    },
    "taken_at": "2024-01-21T14:29:30Z"
  },
  "related_entities": [
    {
      "type": "checkpoint_visit",
      "id": 15,
      "name": "Main Entrance Visit"
    },
    {
      "type": "patrol_run",
      "id": 8,
      "name": "Morning Perimeter Check"
    }
  ]
}
```

---

### GET /files/{file_id}/download
**Description**: Download file  
**Permission**: `files:view` or file owner or public file

**Response (200)**: File binary data with appropriate Content-Type header

---

### GET /files/public/{file_id}/download
**Description**: Get public download URL  
**Permission**: None (for public files)

**Response (200)**:
```json
{
  "download_url": "https://storage.example.com/public/file_123.jpg",
  "expires_at": "2024-01-22T14:30:00Z",
  "direct_access": true
}
```

---

### PUT /files/{file_id}
**Description**: Update file metadata  
**Permission**: `files:manage` or file owner

**Request Body**:
```json
{
  "tags": ["checkpoint", "evidence", "patrol", "reviewed"],
  "is_public": true,
  "description": "Evidence photo from main entrance checkpoint",
  "custom_metadata": {
    "review_status": "approved",
    "reviewed_by": "supervisor_jane",
    "reviewed_at": "2024-01-21T16:30:00Z"
  }
}
```

**Response (200)**:
```json
{
  "file_id": "file_123",
  "updated_at": "2024-01-21T16:30:00Z",
  "changes_applied": [
    "tags_updated",
    "public_access_enabled",
    "metadata_updated"
  ]
}
```

---

### DELETE /files/{file_id}
**Description**: Delete file (soft delete)  
**Permission**: `files:manage` or file owner

**Response (204)**: No content

---

### GET /files/stats/overview
**Description**: Get file usage statistics  
**Permission**: `files:view`

**Response (200)**:
```json
{
  "storage_summary": {
    "total_files": 1250,
    "total_size": 5368709120,
    "total_size_formatted": "5.0 GB",
    "files_by_type": {
      "image": 800,
      "document": 300,
      "video": 100,
      "audio": 50
    }
  },
  "upload_statistics": {
    "uploads_today": 45,
    "uploads_this_week": 320,
    "uploads_this_month": 1200,
    "top_uploaders": [
      {
        "user_id": 1,
        "username": "john_guard",
        "upload_count": 85
      }
    ]
  },
  "storage_usage": {
    "used_space": 5368709120,
    "available_space": 10737418240,
    "usage_percentage": 50.0,
    "quota_limit": 16106127360
  }
}
```

---

## Admin Operations

### POST /files/admin/cleanup
**Description**: Cleanup expired and orphaned files  
**Permission**: Admin only

**Request Body**:
```json
{
  "cleanup_options": {
    "delete_orphaned": true,
    "delete_expired": true,
    "older_than_days": 30,
    "exclude_types": ["document"]
  }
}
```

**Response (200)**:
```json
{
  "cleanup_summary": {
    "files_processed": 500,
    "files_deleted": 25,
    "space_freed": 134217728,
    "orphaned_files_removed": 10,
    "expired_files_removed": 15
  }
}
```

---

### GET /files/admin/orphaned
**Description**: Find files not linked to any entity  
**Permission**: Admin only

**Response (200)**:
```json
{
  "orphaned_files": [
    {
      "file_id": "file_999",
      "filename": "unused_photo.jpg",
      "uploaded_at": "2024-01-10T10:00:00Z",
      "file_size": 1024000,
      "last_accessed": null
    }
  ],
  "total_orphaned": 1,
  "total_size": 1024000
}
```

---

## Analytics API

### GET /analytics/
**Description**: Analytics overview dashboard  
**Permission**: `analytics:view`

**Response (200)**:
```json
{
  "overview": {
    "total_patrols": 156,
    "completed_patrols": 145,
    "total_checkpoints": 25,
    "checkpoint_visits": 1250,
    "active_guards": 8,
    "panic_alerts": 3
  },
  "recent_activity": {
    "patrols_today": 12,
    "checkpoints_visited_today": 85,
    "incidents_reported_today": 2,
    "average_patrol_time": "01:25:00"
  },
  "trends": {
    "patrol_completion_rate": 93.0,
    "checkpoint_compliance": 98.5,
    "incident_rate": 0.02,
    "response_time_average": "00:02:15"
  }
}
```

---

### GET /analytics/dashboard/overview
**Description**: Comprehensive dashboard data  
**Permission**: `analytics:view`

**Query Parameters**:
- `period` (string, optional): Time period (today, week, month, quarter)
- `site_id` (integer, optional): Filter by site

**Response (200)**:
```json
{
  "performance_metrics": {
    "patrol_efficiency": {
      "average_completion_time": "01:25:00",
      "on_time_completion_rate": 92.5,
      "checkpoint_compliance_rate": 98.2
    },
    "guard_performance": {
      "active_guards": 8,
      "guards_on_shift": 3,
      "average_patrols_per_guard": 18.5,
      "top_performer": {
        "guard_id": 1,
        "guard_name": "John Doe",
        "completion_rate": 100.0
      }
    }
  },
  "security_metrics": {
    "incidents_reported": 5,
    "panic_alerts": 3,
    "false_alarm_rate": 60.0,
    "resolution_time_average": "00:12:30"
  },
  "operational_data": {
    "total_sites": 3,
    "active_sites": 3,
    "checkpoints_per_site": 8.3,
    "patrols_per_site_per_day": 4.0
  },
  "charts_data": {
    "patrol_trends": [
      {"date": "2024-01-15", "completed": 12, "scheduled": 12},
      {"date": "2024-01-16", "completed": 11, "scheduled": 12},
      {"date": "2024-01-17", "completed": 12, "scheduled": 12}
    ],
    "incident_trends": [
      {"date": "2024-01-15", "incidents": 1},
      {"date": "2024-01-16", "incidents": 0},
      {"date": "2024-01-17", "incidents": 2}
    ]
  }
}
```

---

### GET /analytics/guard-performance/{guard_id}
**Description**: Individual guard performance metrics  
**Permission**: `analytics:view` or own performance

**Response (200)**:
```json
{
  "guard_info": {
    "guard_id": 1,
    "name": "John Doe",
    "role": "guard",
    "hire_date": "2023-06-15"
  },
  "performance_summary": {
    "total_patrols": 85,
    "completed_patrols": 82,
    "completion_rate": 96.5,
    "average_patrol_time": "01:22:00",
    "checkpoint_compliance": 99.2,
    "incidents_reported": 3,
    "panic_alerts_triggered": 1
  },
  "time_analysis": {
    "punctuality_score": 94.0,
    "early_completions": 15,
    "on_time_completions": 65,
    "late_completions": 2,
    "average_start_delay": "00:03:00"
  },
  "quality_metrics": {
    "photo_evidence_rate": 87.5,
    "detailed_notes_rate": 65.0,
    "issue_detection_rate": 12.5,
    "false_alarm_rate": 5.0
  },
  "recent_activity": [
    {
      "date": "2024-01-21",
      "patrol_id": 156,
      "completion_time": "01:18:00",
      "checkpoints": 8,
      "issues_found": 0
    }
  ]
}
```

---

### GET /analytics/patrol-efficiency
**Description**: Patrol efficiency analysis  
**Permission**: `analytics:view`

**Query Parameters**:
- `start_date` (date, optional): Analysis from date
- `end_date` (date, optional): Analysis to date
- `site_id` (integer, optional): Filter by site

**Response (200)**:
```json
{
  "efficiency_summary": {
    "total_patrols_analyzed": 500,
    "average_completion_time": "01:25:00",
    "fastest_patrol": "00:45:00",
    "slowest_patrol": "02:30:00",
    "standard_deviation": "00:15:30"
  },
  "route_optimization": {
    "optimized_routes": 12,
    "time_saved_per_patrol": "00:08:00",
    "total_time_saved": "40:00:00",
    "fuel_cost_savings": 125.50
  },
  "checkpoint_analysis": {
    "most_time_consuming": {
      "checkpoint_id": 5,
      "name": "Parking Garage Level B2",
      "average_time": "00:12:00"
    },
    "fastest_checkpoints": [
      {
        "checkpoint_id": 1,
        "name": "Main Entrance",
        "average_time": "00:03:00"
      }
    ],
    "problematic_checkpoints": [
      {
        "checkpoint_id": 8,
        "name": "Roof Access",
        "issue": "GPS signal poor",
        "failure_rate": 15.0
      }
    ]
  },
  "recommendations": [
    "Optimize route for Parking Garage checkpoint",
    "Install signal booster for Roof Access checkpoint",
    "Consider splitting long patrol routes"
  ]
}
```

---

### POST /analytics/reports/generate
**Description**: Generate custom analytics report  
**Permission**: `analytics:advanced`

**Request Body**:
```json
{
  "report_type": "security_summary",
  "parameters": {
    "start_date": "2024-01-01",
    "end_date": "2024-01-31",
    "site_ids": [1, 2],
    "include_charts": true,
    "include_recommendations": true
  },
  "format": "pdf",
  "delivery": {
    "email_recipients": ["manager@company.com"],
    "schedule": "monthly"
  }
}
```

**Response (202)**:
```json
{
  "report_id": "report_123",
  "status": "generating",
  "estimated_completion": "2024-01-21T17:00:00Z",
  "download_url": null,
  "webhook_url": "/analytics/reports/report_123/callback"
}
```

---

### POST /analytics/reports/export/csv
**Description**: Export analytics data as CSV  
**Permission**: `analytics:view`

**Request Body**:
```json
{
  "data_type": "patrol_performance",
  "filters": {
    "start_date": "2024-01-01",
    "end_date": "2024-01-31",
    "site_id": 1
  },
  "columns": [
    "patrol_id",
    "guard_name", 
    "start_time",
    "completion_time",
    "checkpoint_count",
    "issues_found"
  ]
}
```

**Response (200)**:
```csv
patrol_id,guard_name,start_time,completion_time,checkpoint_count,issues_found
156,John Doe,2024-01-21T10:00:00Z,01:18:00,8,0
155,Jane Smith,2024-01-21T08:00:00Z,01:25:00,8,1
```

---

## Integration Examples

### Upload Evidence Photos
```javascript
const uploadEvidencePhotos = async (photos, checkpointVisitId) => {
  const formData = new FormData();
  
  photos.forEach((photo, index) => {
    formData.append('files[]', photo.file, photo.filename);
  });
  
  formData.append('tags', 'evidence,checkpoint,patrol');
  formData.append('metadata', JSON.stringify({
    checkpoint_visit_id: checkpointVisitId,
    upload_source: 'mobile_app'
  }));
  
  const response = await fetch('/files/batch-upload', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`
    },
    body: formData
  });
  
  return response.json();
};
```

### Generate Performance Dashboard
```javascript
const generateDashboard = async (siteId, period = 'month') => {
  const [overview, guardPerformance, efficiency] = await Promise.all([
    fetch(`/analytics/dashboard/overview?site_id=${siteId}&period=${period}`, {
      headers: { 'Authorization': `Bearer ${token}` }
    }).then(r => r.json()),
    
    fetch(`/analytics/guard-performance/summary?site_id=${siteId}`, {
      headers: { 'Authorization': `Bearer ${token}` }
    }).then(r => r.json()),
    
    fetch(`/analytics/patrol-efficiency?site_id=${siteId}`, {
      headers: { 'Authorization': `Bearer ${token}` }
    }).then(r => r.json())
  ]);
  
  return {
    overview,
    guardPerformance,
    efficiency,
    generatedAt: new Date().toISOString()
  };
};
```