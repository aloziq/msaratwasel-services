# Wasel Backend API Contract

This document provides a comprehensive guide to building the API for the **Wasel** platform. It defines the required endpoints, payload structures, and response schemas based strictly on the flutter application's generated Domain Models and Repositories.

## Table of Contents
1. [Authentication](#1-authentication)
2. [Messages](#2-messages)
3. [Assistant API](#3-assistant-api)
4. [Driver API](#4-driver-api)
5. [Field Supervisor API](#5-field-supervisor-api)
6. [Teacher API](#6-teacher-api)

---

## 1. Authentication
*Based on `AuthRepository` & `UserModel`*

### `POST /api/auth/login`
Authenticates a user based on their ID, password, and their designated role.
**Request Body (`application/json`):**
```json
{
  "id": "12345678",
  "password": "hashed_password",
  "role": "driver" // Values: driver, assistant, fieldSupervisor, teacher
}
```
**Response (`200 OK`):**
```json
{
  "id": "12345678",
  "name": "عصام كمال",
  "role": "driver",
  "token": "eyJhbGciOiJIUzI1NiIsInR...",
  "avatar": "https://example.com/avatar.jpg"
}
```

### `POST /api/auth/reset-password`
Initiates a password reset for the given civil ID.
**Request Body (`application/json`):**
```json
{
  "id": "12345678"
}
```
**Response (`200 OK`)**: `{ "message": "Success" }`

---

## 2. Messages
*Based on `MessageModel` and `ConversationModel`*

### `GET /api/messages/conversations`
Gets a list of conversations for the currently logged-in user.
**Response (`200 OK`):**
```json
[
  {
    "id": "conv_1",
    "parentName": "أحمد محمد",
    "studentName": "يوسف أحمد",
    "lastMessage": "شكراً لكم",
    "lastMessageTime": "2024-05-18T14:30:00.000Z",
    "avatarUrl": "https://example.com/parent1.jpg"
  }
]
```

### `GET /api/messages/conversations/{conversationId}`
Retrieves messages for a specific conversation.
**Response (`200 OK`):**
```json
[
  {
    "id": "msg_1",
    "text": "مرحباً، متى ستصل الحافلة؟",
    "sender": "أحمد محمد",
    "time": "2024-05-18T14:30:00.000Z",
    "incoming": true,
    "mediaUrl": null
  }
]
```

---

## 3. Assistant API
*Based on `AssistantRepository`, `BusTripModel`, `BusStudentModel`, `BusPositionModel`*

### `GET /api/assistant/trip/active`
Retrieves the current active trip assigned to the assistant, including all students.
**Response (`200 OK`):**
```json
{
  "id": "trip-101",
  "busNumber": "B-45",
  "driverName": "عصام كمال",
  "assistantName": "مريم سعيد",
  "startTime": "2024-05-18T06:30:00.000Z",
  "endTime": null,
  "isCompleted": false,
  "students": [
    {
      "id": "s1",
      "name": "أحمد محمد",
      "schoolId": "SCH-001",
      "parentName": "محمد علي",
      "parentPhone": "99999999",
      "status": "atHome", // Values: atHome, onBus, atSchool, absent, unknown
    }
  ]
}
```

### `PUT /api/assistant/students/{studentId}/status`
Updates a student's status (e.g. from `atHome` to `onBus`).
**Request Body:**
```json
{
  "status": "onBus"
}
```
**Response (`200 OK`)**

### `POST /api/assistant/incident-reports`
Submits an incident report.
**Request Body:**
```json
{
  "studentId": "s1",
  "type": "behavioral", 
  "description": "Student was refusing to wear seatbelt"
}
```

### `POST /api/assistant/daily-checklist`
Submits the pre-trip/post-trip bus check.
**Request Body:**
```json
{
  "items": {
    "cleanliness": true,
    "safetyEquipment": true,
    "doorsFunctioning": true
  }
}
```

### `PUT /api/tracking/bus/{busId}`
Updates the live location and status of the bus.
**Request Body:**
```json
{
  "busId": "bus_123",
  "lat": 23.6000,
  "lng": 58.3500,
  "speedKmh": 45.5,
  "distanceKm": 12.0,
  "etaMinutes": 15,
  "studentsOnBoard": 12,
  "state": "enRoute", // Values: atStation, enRoute, arrived
  "updatedAt": "2024-05-18T06:45:00.000Z"
}
```

---

## 4. Driver API
*Based on `HomeRepository`, `RouteRepository`, `MaintenanceRepository`, `TripRepository`*

### `GET /api/driver/trip/status`
Gets the high-level summary of the driver's current trip.
**Response (`200 OK`):**
```json
{
  "id": "trip_123",
  "departureTime": "06:30 AM",
  "totalStudents": 22,
  "boardedCount": 5,
  "droppedOffCount": 0,
  "isStarted": true,
  "isCompleted": false
}
```

### `POST /api/driver/trip/{tripId}/start`
Starts the current trip.
**Response (`200 OK`)**

### `POST /api/driver/trip/{tripId}/end`
Ends the current trip.
**Response (`200 OK`)**

### `GET /api/driver/trip/stops`
Gets the navigation stops (students' locations) for the map overlay.
**Response (`200 OK`):**
```json
[
  {
    "id": "stop_1",
    "nameAr": "أحمد سعيد",
    "nameEn": "Ahmed Saeed",
    "parentAr": "سعيد العلوي",
    "parentEn": "Saeed Al-Alawi",
    "location": {
      "lat": 23.6000,
      "lng": 58.3500
    },
    "isAbsent": false,
    "isBoarded": false,
    "isDroppedOff": false
  }
]
```

### `POST /api/driver/maintenance/fuel`
Logs a fuel refill event.
**Request Body:**
```json
{
  "bill": "Bill_URL",
  "amount": 25.5,
  "odometer": 125000,
  "date": "2024-05-18T10:00:00.000Z"
}
```

### `POST /api/driver/maintenance/request`
Requests vehicle maintenance.
**Request Body:**
```json
{
  "description": "Brakes are squeaking",
  "bill": "Bill_URL",
  "date": "2024-05-18T10:00:00.000Z",
  "cost": 50.0 // Optional
}

### `POST /api/driver/students`
List of all students linked to the driver
**Response (`200 OK`):**
```json
[
  {
    "id": "std_1",
    "name": "أحمد محمد",
    "parentName": "محمد محمود",
    "parentPhone": "99999999",
  }
]
```

---

## 5. Field Supervisor API
*Based on `FleetRepository`, `FleetBusModel`*

### `GET /api/supervisor/fleet`
Fetches the status of all buses under the supervisor's purview.
**Response (`200 OK`):**
```json
[
  {
    "id": "B001",
    "name": "حافلة 1",
    "driverName": "محمد أحمد",
    "supervisorName": "فاطمة الحارثي",
    "schoolName": "مدرسة النور",
    "driverPhone": "96812345678",
    "route": "المعبيلة → المطار",
    "lat": 23.5880,
    "lng": 58.3829,
    "speedKmh": 45.0,
    "studentsOnBoard": 18,
    "status": "active", // Values: active, stopped, maintenance
    "updatedAt": "2024-05-18T06:50:00.000Z"
  }
]
```

---

## 6. Teacher API
*(Based on `StudentModel`, `AttendanceHistoryModel`, `ReportModel`, `ClassroomModel`)*

### `GET /api/teacher/classes`
Fetches classrooms assigned to the teacher.
**Response (`200 OK`):**
```json
[
  {
    "id": "C001",
    "name": "الصف الأول أ",
    "grade": "الصف الأول",
    "studentCount": 20,
    "teacherId": "T001"
  }
]
```

### `GET /api/teacher/classes/{classId}/students`
Fetches students in a specific classroom with their daily attendance status.
**Response (`200 OK`):**
```json
[
  {
    "id": "std_1",
    "name": "أحمد محمد",
    "parentName": "محمد محمود",
    "parentPhone": "99999999",
    "photoUrl": "https://...",
    "status": "present" // Values: present, absent, late, excused, unknown
  }
]
```

### `GET /api/teacher/classes/{classId}/attendance/history`
Gets historical attendance records for a classroom.
**Response (`200 OK`):**
```json
{
  "classId": "C001",
  "className": "الصف الأول أ",
  "dailyRecords": [
    {
      "date": "2024-05-17T00:00:00.000Z",
      "totalStudents": 20,
      "presentCount": 18,
      "absentCount": 2,
      "lateCount": 0,
      "attendedStudents": [ /* Array of StudentModel */ ]
    }
  ]
}
```

### `GET /api/teacher/reports/stats`
Gets attendance analytics for a teacher's students.
**Response (`200 OK`):**
```json
{
  "totalStudents": 150,
  "presentToday": 140,
  "absentToday": 10,
  "averageAttendance": 95.5,
  "weeklyTrend": [
    {
      "date": "2024-05-12T00:00:00.000Z",
      "attendancePercentage": 96.0
    }
  ],
  "studentReports": [
    {
      "name": "أحمد",
      "presentCount": 100,
      "absentCount": 5
    }
  ]
}
```
