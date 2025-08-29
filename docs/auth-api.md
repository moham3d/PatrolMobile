# Authentication API Documentation

## Overview
The Authentication API provides secure login, token management, and user session handling for the PatrolShield system.

**Base URL**: `https://api.millio.space`  
**Authentication**: JWT Bearer Token (except for login endpoints)  
**Headers**: `Authorization: Bearer <token>`, `Content-Type: application/json`

---

## Endpoints

### POST /auth/login
**Description**: Authenticate user with username/password credentials  
**Authentication**: None required  
**Content-Type**: `application/x-www-form-urlencoded`

**Request Body**:
```json
{
  "username": "string",
  "password": "string"
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
    "email": "john@example.com",
    "full_name": "John Doe",
    "role": "guard",
    "permissions": ["patrols:view", "checkpoints:visit"]
  }
}
```

**Error Responses**:
- `400`: Invalid credentials
- `422`: Validation error

---

### POST /auth/refresh
**Description**: Refresh access token using existing valid token  
**Authentication**: Bearer Token required

**Request Body**: None

**Response (200)**:
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "token_type": "bearer",
  "expires_in": 3600
}
```

**Error Responses**:
- `401`: Invalid or expired token

---

### GET /auth/me
**Description**: Get current user profile information  
**Authentication**: Bearer Token required

**Response (200)**:
```json
{
  "id": 1,
  "username": "john_guard",
  "email": "john@example.com", 
  "full_name": "John Doe",
  "role": "guard",
  "permissions": ["patrols:view", "checkpoints:visit"],
  "created_at": "2024-01-15T10:30:00Z",
  "last_login": "2024-01-20T08:15:00Z",
  "is_active": true,
  "profile_settings": {
    "notifications_enabled": true,
    "gps_tracking": true
  }
}
```

**Error Responses**:
- `401`: Unauthorized

---

### POST /auth/logout
**Description**: Logout user and blacklist current token  
**Authentication**: Bearer Token required

**Request Body**: None

**Response (204)**: No content

**Error Responses**:
- `401`: Unauthorized

---

### GET /auth/debug
**Description**: Debug JWT configuration (development only)  
**Authentication**: Bearer Token required  
**Environment**: Development only

**Response (200)**:
```json
{
  "jwt_config": {
    "algorithm": "HS256",
    "expires_in": 3600,
    "issuer": "patrolshield-api"
  },
  "token_info": {
    "user_id": 1,
    "exp": 1674567890,
    "iat": 1674564290
  }
}
```

---

## Authentication Flow

### 1. Initial Login
```
POST /auth/login
Content-Type: application/x-www-form-urlencoded

username=john_guard&password=secure_password
```

### 2. Use Token for API Calls
```
GET /auth/me
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

### 3. Refresh Token Before Expiry
```
POST /auth/refresh
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

### 4. Logout
```
POST /auth/logout
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

---

## Error Handling

All authentication endpoints return standard error formats:

**Validation Error (422)**:
```json
{
  "error": "Request Validation Error",
  "message": "The request contains invalid or missing data",
  "details": [
    {
      "field": "username",
      "message": "Required field 'username' is missing",
      "type": "missing"
    }
  ]
}
```

**Authentication Error (401)**:
```json
{
  "detail": "Invalid credentials"
}
```

---

## Security Notes

- Tokens expire after 1 hour by default
- Use HTTPS in production environments
- Store tokens securely (not in localStorage for web apps)
- Implement proper logout to blacklist tokens
- Regular token refresh recommended before expiry

---

## Frontend Integration Example

```javascript
// Login
const loginResponse = await fetch('/auth/login', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/x-www-form-urlencoded',
  },
  body: new URLSearchParams({
    username: 'john_guard',
    password: 'secure_password'
  })
});

const { access_token } = await loginResponse.json();

// Use token for authenticated requests
const userResponse = await fetch('/auth/me', {
  headers: {
    'Authorization': `Bearer ${access_token}`,
    'Content-Type': 'application/json'
  }
});
```