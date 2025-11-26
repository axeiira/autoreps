#  API Documentation

Complete API reference for the AutoReps Backend.

## Base URL

```
http://localhost:3000
```

## Authentication

Protected endpoints require a JWT token in the Authorization header:

```
Authorization: Bearer <your_jwt_token>
```

Tokens are valid for 7 days and obtained through the `/auth/login` endpoint.

---

##  Authentication Endpoints

### Register User

Create a new user account.

**Endpoint:** `POST /auth/register`

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "securepassword123"
}
```

**Response (201):**
```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "password": "$2b$10$...", // hashed
  "createdAt": "2024-01-01T00:00:00.000Z"
}
```

**Error Response (400):**
```json
{
  "error": "Email already used"
}
```

---

### Login User

Authenticate and receive a JWT token.

**Endpoint:** `POST /auth/login`

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "securepassword123"
}
```

**Response (200):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "password": "$2b$10$...",
    "createdAt": "2024-01-01T00:00:00.000Z"
  }
}
```

**Error Responses:**

```json
// User not found (400)
{
  "error": "User not found"
}

// Wrong password (400)
{
  "error": "Wrong password"
}
```

---

##  User Endpoints

### Get User Profile

Get the current user's profile information.

**Endpoint:** `GET /user/profile`

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "id": 1,
  "userId": 1,
  "age": 25,
  "weight": 70.5,
  "primaryGoal": "Build Muscle",
  "experienceLevel": "Intermediate",
  "updatedAt": "2024-01-01T00:00:00.000Z"
}
```

**Response (200) - No profile:**
```json
null
```

---

### Create/Update User Profile

Create or update user profile information.

**Endpoint:** `POST /user/profile`

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "age": 25,
  "weight": 70.5,
  "primaryGoal": "Build Muscle",
  "experienceLevel": "Intermediate"
}
```

**Response (200):**
```json
{
  "id": 1,
  "userId": 1,
  "age": 25,
  "weight": 70.5,
  "primaryGoal": "Build Muscle",
  "experienceLevel": "Intermediate",
  "updatedAt": "2024-01-01T00:00:00.000Z"
}
```

---

## Training Plan Endpoints

### Get Training Plan

Get the current user's training plan.

**Endpoint:** `GET /plan`

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "id": 1,
  "userId": 1,
  "planName": "Push-Up Challenge",
  "reps": 20,
  "sets": 3,
  "formStatus": "Good",
  "updatedAt": "2024-01-01T00:00:00.000Z"
}
```

**Response (200) - No plan:**
```json
null
```

---

### Create/Update Training Plan

Create or update the user's training plan.

**Endpoint:** `POST /plan`

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "planName": "Push-Up Challenge",
  "reps": 20,
  "sets": 3,
  "formStatus": "Good"
}
```

**Form Status Options:**
- `"Good"`
- `"Average"`
- `"Bad"`

**Response (200):**
```json
{
  "id": 1,
  "userId": 1,
  "planName": "Push-Up Challenge",
  "reps": 20,
  "sets": 3,
  "formStatus": "Good",
  "updatedAt": "2024-01-01T00:00:00.000Z"
}
```

---

## 💪 Workout Session Endpoints

### Get Workout History

Get all workout sessions for the current user.

**Endpoint:** `GET /workout`

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
[
  {
    "id": 1,
    "userId": 1,
    "reps": 25,
    "validReps": 20,
    "invalidReps": 5,
    "durationSec": 120,
    "date": "2024-01-01T10:00:00.000Z"
  },
  {
    "id": 2,
    "userId": 1,
    "reps": 30,
    "validReps": 28,
    "invalidReps": 2,
    "durationSec": 150,
    "date": "2024-01-02T10:00:00.000Z"
  }
]
```

Sessions are ordered by date (most recent first).

---

### Log Workout Session

Record a new workout session.

**Endpoint:** `POST /workout`

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "reps": 25,
  "validReps": 20,
  "invalidReps": 5,
  "durationSec": 120
}
```

**Field Descriptions:**
- `reps`: Total repetitions attempted
- `validReps`: Repetitions with correct form
- `invalidReps`: Repetitions with incorrect form
- `durationSec`: Duration of workout in seconds

**Response (200):**
```json
{
  "id": 1,
  "userId": 1,
  "reps": 25,
  "validReps": 20,
  "invalidReps": 5,
  "durationSec": 120,
  "date": "2024-01-01T10:00:00.000Z"
}
```

---

##  Analytics Endpoints

### Get Workout Summary

Get total statistics for the user's workouts.

**Endpoint:** `GET /analytics/summary`

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "total_reps": 150,
  "total_sessions": 6
}
```

---

### Get Weekly Analytics

Get workout data for the last 7 days.

**Endpoint:** `GET /analytics/weekly`

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
[
  {
    "day": "2024-01-01",
    "reps": 25
  },
  {
    "day": "2024-01-02",
    "reps": 30
  },
  {
    "day": "2024-01-03",
    "reps": 28
  }
]
```

Data is ordered by day (ascending).

---

##  Health Check

### Check API Status

Verify the API is running.

**Endpoint:** `GET /health`

**Response (200):**
```json
{
  "status": "ok",
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

---

##  Error Responses

### 401 Unauthorized

Missing or invalid token.

```json
{
  "error": "No token provided"
}
```

```json
{
  "error": "Invalid token"
}
```

### 400 Bad Request

Invalid request data.

```json
{
  "error": "Email already used"
}
```

```json
{
  "error": "User not found"
}
```

```json
{
  "error": "Wrong password"
}
```

---

##  Example Usage

### Complete User Flow

```bash
# 1. Register
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "password123"
  }'

# 2. Login
TOKEN=$(curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "password123"
  }' | jq -r '.token')

# 3. Create Profile
curl -X POST http://localhost:3000/user/profile \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "age": 25,
    "weight": 70.5,
    "primaryGoal": "Build Muscle",
    "experienceLevel": "Intermediate"
  }'

# 4. Create Training Plan
curl -X POST http://localhost:3000/plan \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "planName": "Push-Up Challenge",
    "reps": 20,
    "sets": 3,
    "formStatus": "Good"
  }'

# 5. Log Workout
curl -X POST http://localhost:3000/workout \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "reps": 25,
    "validReps": 20,
    "invalidReps": 5,
    "durationSec": 120
  }'

# 6. Get Analytics
curl http://localhost:3000/analytics/summary \
  -H "Authorization: Bearer $TOKEN"
```

---

##  Testing with Postman

1. Import the API endpoints into Postman
2. Create an environment variable `token`
3. After login, set the token:
   ```javascript
   pm.environment.set("token", pm.response.json().token);
   ```
4. Use `{{token}}` in Authorization headers

---

##  Additional Resources

- [README.md](README.md) - Full documentation
- [QUICKSTART.md](QUICKSTART.md) - Quick setup guide
- [Prisma Schema](prisma/schema.prisma) - Database schema

---

**Last Updated:** 2024-01-01
