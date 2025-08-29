# PatrolShield First-Class Patrol System Documentation

## Overview

PatrolShield now provides first-class `PatrolTemplate` and `PatrolRun` entities with dedicated endpoints, mobile sync semantics, and comprehensive documentation for common workflows.

## Benefits

- **Clearer Contracts**: Dedicated patrol entities provide clear separation from generic tasks
- **Simpler Analytics**: Direct patrol-specific data models enable easier reporting
- **Mobile Optimization**: Purpose-built mobile endpoints with sync support
- **Better Scalability**: First-class entities support advanced patrol features

## Core Entities

### PatrolTemplate
Defines reusable patrol routes and procedures.

**Key Features:**
- Checkpoint definitions with GPS coordinates
- Geofence validation rules
- Time windows and requirements
- QR/NFC tag support
- Recurring schedule patterns

### PatrolRun
Actual execution of a patrol based on a template.

**Key Features:**
- Real-time status tracking
- GPS location recording
- Checkpoint visit validation
- Photo evidence support
- Offline sync capabilities

### PatrolCheckpoint
Individual checkpoints within a patrol template.

**Key Features:**
- GPS coordinates with tolerance settings
- QR code and NFC tag identification
- Time window constraints
- Photo and note requirements

### PatrolCheckpointVisit
Records when checkpoints are visited during patrol runs.

**Key Features:**
- GPS validation against checkpoint location
- Multiple scan methods (QR, NFC, GPS, manual)
- Photo and evidence attachment
- Client-side duplicate detection

## API Endpoints

### Patrol Templates (`/patrol-templates`)

#### Create Template
```http
POST /patrol-templates
Content-Type: application/json

{
  "name": "Main Building Patrol",
  "description": "Standard patrol of main building perimeter",
  "site_id": 1,
  "estimated_duration": 60,
  "priority": "medium",
  "instructions": "Check all doors and windows",
  "checkpoint_tolerance_meters": 25.0,
  "require_photos": true,
  "checkpoints": [
    {
      "name": "Main Entrance",
      "latitude": 40.7128,
      "longitude": -74.0060,
      "order_index": 1,
      "is_required": true,
      "qr_code": "QR001",
      "require_photo": true
    }
  ]
}
```

#### List Templates
```http
GET /patrol-templates?site_id=1&active_only=true&page=1&per_page=20
```

#### Get Template Details
```http
GET /patrol-templates/1
```

#### Update Template
```http
PUT /patrol-templates/1
Content-Type: application/json

{
  "name": "Updated Main Building Patrol",
  "estimated_duration": 75
}
```

### Patrol Runs (`/patrol-runs`)

#### Start Patrol Run
```http
POST /patrol-runs/start
Content-Type: application/json

{
  "template_id": 1,
  "start_latitude": 40.7128,
  "start_longitude": -74.0060,
  "start_notes": "Starting patrol at main entrance",
  "sync_token": "abc123-def456-ghi789"
}
```

**Response:**
```json
{
  "id": 123,
  "template_id": 1,
  "guard_id": 456,
  "status": "in_progress",
  "total_checkpoints": 5,
  "completed_checkpoints": 0,
  "sync_token": "abc123-def456-ghi789",
  "actual_start": "2024-01-15T09:00:00Z"
}
```

#### Record Checkpoint Visit
```http
POST /patrol-runs/123/checkpoints/visit
Content-Type: multipart/form-data

checkpoint_id: 1
latitude: 40.7128
longitude: -74.0060
scan_method: qr
scan_data: QR001
notes: "All clear, door secured"
photos: [file1.jpg, file2.jpg]
```

#### End Patrol Run
```http
POST /patrol-runs/123/end
Content-Type: application/json

{
  "end_latitude": 40.7128,
  "end_longitude": -74.0060,
  "end_notes": "Patrol completed successfully",
  "summary": "All checkpoints visited, no issues found"
}
```

## Mobile API v2 Endpoints

Mobile-optimized endpoints with simplified responses and batch sync support.

### Mobile Templates
```http
GET /mobile/v2/patrols/templates?site_id=1&limit=20
```

### Mobile Patrol Start
```http
POST /mobile/v2/patrols/start
Content-Type: application/json

{
  "template_id": 1,
  "start_latitude": 40.7128,
  "start_longitude": -74.0060,
  "client_id": "mobile_patrol_123",
  "sync_token": "unique_token_456"
}
```

### Mobile Checkpoint Visit
```http
POST /mobile/v2/patrols/123/checkpoints/visit
Content-Type: multipart/form-data

checkpoint_id: 1
latitude: 40.7128
longitude: -74.0060
scan_method: qr
notes: "Checkpoint verified"
client_visit_id: "visit_123"
photos: [photo.jpg]
```

## Mobile Sync Semantics and Idempotency

### Idempotency Keys

The system supports idempotency through multiple mechanisms:

1. **Sync Tokens**: Patrol runs include a `sync_token` to prevent duplicate creation
2. **Client IDs**: Mobile clients can provide `client_id` for patrol runs and `client_visit_id` for checkpoint visits
3. **Timestamp Handling**: Server-side reconciliation based on timestamps

### Batch Synchronization

Mobile clients can sync data in batches for offline scenarios:

```http
POST /mobile/v2/patrols/sync
Content-Type: application/json

{
  "patrol_run_id": 123,
  "sync_token": "batch_sync_abc123",
  "visits": [
    {
      "checkpoint_id": 1,
      "latitude": 40.7128,
      "longitude": -74.0060,
      "scan_method": "qr",
      "scan_data": "QR001",
      "notes": "All clear",
      "client_visit_id": "visit_1",
      "photos": ["/local/photo1.jpg"]
    },
    {
      "checkpoint_id": 2,
      "latitude": 40.7130,
      "longitude": -74.0062,
      "scan_method": "nfc",
      "notes": "Minor issue noted",
      "client_visit_id": "visit_2"
    }
  ],
  "run_updates": {
    "completion_percentage": 50,
    "distance_traveled": 250.5
  },
  "client_timestamp": "2024-01-15T10:30:00Z"
}
```

### Duplicate Detection

The system detects and handles duplicates through:

- **Client Visit IDs**: Prevent duplicate checkpoint visits
- **Sync Tokens**: Prevent duplicate patrol run creation
- **Timestamp Reconciliation**: Server timestamp takes precedence for conflicts

### Partial Failures

Sync operations handle partial failures gracefully:

```json
{
  "success": true,
  "patrol_run_id": 123,
  "processed_visits": 2,
  "conflicts": [],
  "errors": [
    "Visit visit_3 failed: Invalid checkpoint ID"
  ],
  "server_timestamp": "2024-01-15T10:35:00Z"
}
```

## Recurring Patrol Scheduling

### Using Existing Shift Scheduler

Patrol templates can be integrated with the existing shift scheduler by setting the `recurrence_pattern` field:

```json
{
  "name": "Daily Security Patrol",
  "recurrence_pattern": "0 */4 * * *",
  "site_id": 1,
  "estimated_duration": 60
}
```

**Creating Scheduled PatrolRuns from Templates:**

1. Query templates with recurrence patterns:
```http
GET /patrol-templates?site_id=1&has_recurrence=true
```

2. Create patrol runs based on shift schedules:
```http
POST /patrol-runs/start
{
  "template_id": 1,
  "scheduled_start": "2024-01-15T14:00:00Z"
}
```

### Alternative: Dedicated Patrol Scheduler

If implementing a separate scheduler:

```http
POST /patrol-templates/1/schedule
Content-Type: application/json

{
  "recurrence_rule": "FREQ=DAILY;INTERVAL=1;BYHOUR=6,14,22",
  "start_date": "2024-01-15",
  "end_date": "2024-02-15",
  "assigned_guards": [456, 789],
  "auto_assign": true
}
```

## Common API Flow Examples

### 1. Start Patrol Run (Request + Response)

**Request:**
```http
POST /mobile/v2/patrols/start
Content-Type: application/json

{
  "template_id": 1,
  "start_latitude": 40.7128,
  "start_longitude": -74.0060,
  "start_notes": "Starting patrol at main entrance",
  "sync_token": "mobile_start_abc123"
}
```

**Response:**
```json
{
  "success": true,
  "patrol_run_id": 123,
  "status": "in_progress",
  "template_id": 1,
  "total_checkpoints": 5,
  "sync_token": "mobile_start_abc123",
  "started_at": "2024-01-15T09:00:00Z",
  "message": "Patrol started successfully"
}
```

### 2. Record Checkpoint Visit with Photos

**Request:**
```http
POST /mobile/v2/patrols/123/checkpoints/visit
Content-Type: multipart/form-data

checkpoint_id: 1
latitude: 40.7128
longitude: -74.0060
accuracy: 3.5
scan_method: qr
scan_data: QR001
notes: "Door secured, no issues"
client_visit_id: visit_mobile_001
photos: checkpoint_photo_1.jpg
```

**Response:**
```json
{
  "success": true,
  "visit_id": 456,
  "checkpoint_id": 1,
  "visited_at": "2024-01-15T09:15:00Z",
  "is_valid_location": true,
  "distance_from_checkpoint": 2.3,
  "photos_uploaded": 1,
  "message": "Checkpoint visit recorded successfully"
}
```

### 3. Offline Sync Example (Batch with 3 Visits)

**Request:**
```http
POST /mobile/v2/patrols/sync
Content-Type: application/json

{
  "patrol_run_id": 123,
  "sync_token": "offline_batch_xyz789",
  "visits": [
    {
      "checkpoint_id": 1,
      "latitude": 40.7128,
      "longitude": -74.0060,
      "scan_method": "qr",
      "scan_data": "QR001",
      "notes": "All clear",
      "client_visit_id": "offline_visit_1",
      "photos": ["/cache/photo1.jpg"]
    },
    {
      "checkpoint_id": 2,
      "latitude": 40.7130,
      "longitude": -74.0062,
      "scan_method": "nfc",
      "scan_data": "NFC002",
      "notes": "Minor maintenance needed",
      "client_visit_id": "offline_visit_2"
    },
    {
      "checkpoint_id": 3,
      "latitude": 40.7132,
      "longitude": -74.0064,
      "scan_method": "gps",
      "notes": "Area clear",
      "client_visit_id": "offline_visit_3"
    }
  ],
  "run_updates": {
    "completion_percentage": 60,
    "distance_traveled": 350.0
  },
  "client_timestamp": "2024-01-15T09:45:00Z"
}
```

**Response:**
```json
{
  "success": true,
  "patrol_run_id": 123,
  "processed_visits": 3,
  "conflicts": [],
  "errors": [],
  "server_timestamp": "2024-01-15T09:46:00Z"
}
```

### 4. End Run + Run Summary Response

**Request:**
```http
POST /mobile/v2/patrols/123/end
Content-Type: application/json

{
  "end_latitude": 40.7128,
  "end_longitude": -74.0060,
  "end_notes": "Patrol completed successfully",
  "summary": "All 5 checkpoints visited. Minor maintenance issue noted at checkpoint 2."
}
```

**Response:**
```json
{
  "success": true,
  "patrol_run_id": 123,
  "status": "completed",
  "completion_percentage": 100,
  "completed_checkpoints": 5,
  "total_checkpoints": 5,
  "missed_checkpoints": 0,
  "duration_minutes": 62,
  "ended_at": "2024-01-15T10:02:00Z",
  "message": "Patrol completed successfully"
}
```

## Geofence/Geo-Validation Rules

### Configuration

Geofence validation is configured at the template level:

```json
{
  "checkpoint_tolerance_meters": 25.0,
  "geofence_validation": {
    "enabled": true,
    "tolerance_meters": 25.0,
    "strict_mode": false,
    "spoof_detection": true
  }
}
```

### Validation Rules

1. **Radius-based Checks**: Checkpoints must be within the configured tolerance radius
2. **Threshold for "Missed" vs "Arrived"**:
   - ≤ tolerance_meters: Valid visit
   - > tolerance_meters && < (tolerance_meters * 2): Warning (still recorded)
   - > (tolerance_meters * 2): Invalid/missed

3. **Spoof Detection Heuristics**:
   - GPS accuracy validation
   - Speed/distance calculations between visits
   - Timestamp consistency checks
   - Pattern analysis for unrealistic movements

### Example Validation Response

```json
{
  "is_valid_location": true,
  "distance_from_checkpoint": 12.5,
  "validation_details": {
    "gps_accuracy": 3.5,
    "within_tolerance": true,
    "warning_flags": [],
    "confidence_score": 0.95
  }
}
```

## Webhooks & Events

### Available Patrol Events

The system emits webhook events for key patrol activities:

- `patrol_started`: When a patrol run begins
- `patrol_completed`: When a patrol run is completed
- `patrol_cancelled`: When a patrol run is cancelled
- `checkpoint_visited`: When a checkpoint is visited
- `checkpoint_missed`: When a required checkpoint is missed
- `patrol_overdue`: When a scheduled patrol is overdue
- `geofence_violation`: When location validation fails

### Webhook Registration

```http
POST /integrations/webhooks/register
Content-Type: application/json

{
  "url": "https://your-system.com/patrol-webhooks",
  "events": [
    "patrol_completed",
    "checkpoint_missed",
    "geofence_violation"
  ],
  "secret": "your_webhook_secret",
  "enabled": true
}
```

### Event Payload Examples

#### Patrol Completed Event
```json
{
  "event": "patrol_completed",
  "timestamp": "2024-01-15T10:02:00Z",
  "data": {
    "patrol_run_id": 123,
    "template_id": 1,
    "template_name": "Main Building Patrol",
    "guard_id": 456,
    "guard_name": "John Smith",
    "site_id": 1,
    "completion_percentage": 100,
    "duration_minutes": 62,
    "checkpoints_completed": 5,
    "checkpoints_missed": 0,
    "started_at": "2024-01-15T09:00:00Z",
    "completed_at": "2024-01-15T10:02:00Z"
  }
}
```

#### Checkpoint Missed Event
```json
{
  "event": "checkpoint_missed",
  "timestamp": "2024-01-15T09:30:00Z",
  "data": {
    "patrol_run_id": 123,
    "checkpoint_id": 3,
    "checkpoint_name": "Emergency Exit B",
    "template_id": 1,
    "guard_id": 456,
    "expected_time_window": {
      "start": "2024-01-15T09:20:00Z",
      "end": "2024-01-15T09:25:00Z"
    },
    "severity": "high"
  }
}
```

### Webhook Security

All webhooks include HMAC-SHA256 signatures for verification:

```http
POST /your-webhook-url
X-Patrol-Signature: sha256=abc123def456...
Content-Type: application/json

{...event payload...}
```

## Database Schema Migration

To implement the first-class patrol entities, add the following tables:

```sql
-- PatrolTemplate table
CREATE TABLE patrol_templates (
  id SERIAL PRIMARY KEY,
  name VARCHAR(200) NOT NULL,
  description TEXT,
  site_id INTEGER NOT NULL REFERENCES sites(id),
  estimated_duration INTEGER NOT NULL,
  priority VARCHAR(20) DEFAULT 'medium',
  instructions TEXT,
  is_active BOOLEAN DEFAULT true,
  recurrence_pattern VARCHAR(100),
  geofence_validation JSONB,
  checkpoint_tolerance_meters FLOAT DEFAULT 50.0,
  require_photos BOOLEAN DEFAULT false,
  created_by INTEGER NOT NULL REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- PatrolCheckpoint table
CREATE TABLE patrol_checkpoints (
  id SERIAL PRIMARY KEY,
  template_id INTEGER NOT NULL REFERENCES patrol_templates(id) ON DELETE CASCADE,
  name VARCHAR(200) NOT NULL,
  description TEXT,
  latitude FLOAT NOT NULL,
  longitude FLOAT NOT NULL,
  area_id INTEGER REFERENCES areas(id),
  qr_code VARCHAR(100) UNIQUE,
  nfc_tag VARCHAR(100) UNIQUE,
  is_required BOOLEAN DEFAULT true,
  order_index INTEGER DEFAULT 0,
  time_window_start INTEGER,
  time_window_end INTEGER,
  require_photo BOOLEAN DEFAULT false,
  require_notes BOOLEAN DEFAULT false,
  instructions TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- PatrolRun table
CREATE TABLE patrol_runs (
  id SERIAL PRIMARY KEY,
  template_id INTEGER NOT NULL REFERENCES patrol_templates(id),
  guard_id INTEGER NOT NULL REFERENCES users(id),
  scheduled_start TIMESTAMP,
  actual_start TIMESTAMP,
  actual_end TIMESTAMP,
  status VARCHAR(20) DEFAULT 'pending',
  completion_percentage INTEGER DEFAULT 0,
  start_latitude FLOAT,
  start_longitude FLOAT,
  end_latitude FLOAT,
  end_longitude FLOAT,
  start_notes TEXT,
  end_notes TEXT,
  summary TEXT,
  total_checkpoints INTEGER DEFAULT 0,
  completed_checkpoints INTEGER DEFAULT 0,
  missed_checkpoints INTEGER DEFAULT 0,
  distance_traveled FLOAT,
  client_id VARCHAR(100),
  sync_token VARCHAR(200),
  last_sync_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- PatrolCheckpointVisit table
CREATE TABLE patrol_checkpoint_visits (
  id SERIAL PRIMARY KEY,
  patrol_run_id INTEGER NOT NULL REFERENCES patrol_runs(id) ON DELETE CASCADE,
  checkpoint_id INTEGER NOT NULL REFERENCES patrol_checkpoints(id),
  visited_at TIMESTAMP DEFAULT NOW(),
  latitude FLOAT,
  longitude FLOAT,
  accuracy FLOAT,
  is_valid_location BOOLEAN DEFAULT true,
  distance_from_checkpoint FLOAT,
  scan_method VARCHAR(20) DEFAULT 'manual',
  scan_data VARCHAR(200),
  notes TEXT,
  photos JSONB,
  client_visit_id VARCHAR(100),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_patrol_templates_site_id ON patrol_templates(site_id);
CREATE INDEX idx_patrol_templates_active ON patrol_templates(is_active);
CREATE INDEX idx_patrol_checkpoints_template_id ON patrol_checkpoints(template_id);
CREATE INDEX idx_patrol_runs_guard_id ON patrol_runs(guard_id);
CREATE INDEX idx_patrol_runs_status ON patrol_runs(status);
CREATE INDEX idx_patrol_runs_template_id ON patrol_runs(template_id);
CREATE INDEX idx_patrol_checkpoint_visits_run_id ON patrol_checkpoint_visits(patrol_run_id);
CREATE INDEX idx_patrol_checkpoint_visits_checkpoint_id ON patrol_checkpoint_visits(checkpoint_id);
CREATE UNIQUE INDEX idx_patrol_runs_sync_token ON patrol_runs(sync_token) WHERE sync_token IS NOT NULL;
CREATE UNIQUE INDEX idx_patrol_checkpoint_visits_client_id ON patrol_checkpoint_visits(patrol_run_id, client_visit_id) WHERE client_visit_id IS NOT NULL;
```