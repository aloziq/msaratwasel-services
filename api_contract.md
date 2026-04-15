# API Role Contracts (Complete Reference)

This document provides the full technical schemas for each role, including request and response payloads.

---

## 1. Teacher Role (`/api/teacher`)

### [GET] Get Classes
**URI**: `/classes`
- **Response**: `Array<ClassMetadata>`
```json
[
  {
    "id": "1",
    "name_ar": "فصل 1/أ",
    "grade": "الابتدائي",
    "student_count": 25,
    "teacher_id": "10"
  }
]
```

### [GET] Get Students in Class
**URI**: `/classes/{class_id}/students`
- **Response**: `Array<StudentMetadata>`
```json
[
  {
    "id": "101",
    "name_ar": "خالد أحمد",
    "parent_name": "أحمد محمد",
    "image_url": "...",
    "status": "present"
  }
]
```

### [PUT] Mark Attendance
**URI**: `/students/{student_id}/attendance`
- **Request**:
```json
{ "status": "present" } // present, absent, late, excused
```

### [GET] Class Attendance History
**URI**: `/classes/{class_id}/attendance-history`
- **Request Parameters**: `?year=2024&month=4`
- **Response**:
```json
{
  "class_id": "1",
  "class_name": "فصل 1/أ",
  "daily_records": [
    {
      "date": "2024-04-15",
      "total_students": 25,
      "present_count": 23,
      "absent_count": 2,
      "attended_students": [
        {
          "id": "101",
          "name_ar": "خالد أحمد",
          "status": "present"
        }
      ]
    }
  ]
}
```

---

## 2. Field Supervisor Role (`/api/field`)

### [POST] Submit Inspection
**URI**: `/inspections`
- **Request (Multipart/Form-Data)**:
```json
{
  "bus_id": 1,
  "overall_status": "pass",
  "notes": "الحافلة ممتازة",
  "results": [
    { "item_id": 1, "is_passed": true, "notes": "الفرامل" }
  ],
  "photos[]": [ "BinaryFile1", "BinaryFile2" ]
}
```

### [POST] Report Incident
**URI**: `/incidents`
- **Request**:
```json
{
  "bus_id": 1,
  "type": "accident", // sos, accident, breakdown, health
  "severity": "high", // low, medium, high, critical
  "description": "تصادم بسيط",
  "location_lat": 24.5,
  "location_lng": 46.5,
  "photos[]": [ "BinaryFile" ]
}
```

---

## 3. Driver / Assistant Role (`/api/bus`)

### [GET] Passenger List
**URI**: `/{bus}/passengers`
- **Response**:
```json
{
  "bus": { "id": 1, "bus_number": "B01", "trip_status": "on_route" },
  "passengers": [
    {
      "id": "101",
      "student_code": "S101",
      "name_ar": "خالد أحمد",
      "status": "atHome",
      "is_on_bus": false,
      "parent_name": "أحمد محمد",
      "parent_phone": "050...",
      "image_url": "..."
    }
  ],
  "on_bus_count": 5,
  "total_count": 20
}
```

### [POST] Start Trip
**URI**: `/{bus}/start-trip`
- **Request**:
```json
{ "direction": "to_school" } // optional, defaults by time
```
- **Response**:
```json
{
  "message": "تم بدء الرحلة بنجاح.",
  "trip_status": "to_school",
  "trip": { "id": 5, "bus_id": 1, "status": "in_progress" }
}
```

### [POST] Board Student
**URI**: `/{bus}/board`
- **Request**:
```json
{ "student_id": "101", "direction": "to_school" }
```

---

## 4. Auth & Profile (Common)

### [POST] Update Profile
**URI**: `/api/auth/profile/update`
- **Request**:
```json
{
  "address": "الرياض، حي السليمانية",
  "latitude": 24.123,
  "longitude": 46.123
}
```
