# Driver API Contract

This document defines the REST API endpoints required for the **Driver** role in the Wasel application.

## Base URL

`https://srv1428362.hstgr.cloud/api`

## Trip Management

### 3. Get Active Trip

- **Endpoint**: `GET /driver/trips/active`
- **Description**: Returns details of the current assigned trip.
- **Response (200 OK)**:
  ```json
  {
    "id": "trip_789",
    "departureTime": "07:30 AM",
    "totalStudents": 15,
    "status": "pending"
  }
  ```

### 4. Start Trip

- **Endpoint**: `POST /driver/trips/{tripId}/start`
- **Description**: Marks the beginning of a trip.
- **Request Body**:
  ```json
  {
    "start_time": "07:30",
    "start_location": { "lat": 23.6, "lng": 58.35 }
  }
  ```

- **Response (200 OK)**:
  ```json
  { "message": "Trip started successfully" }
  ```

### 5. Get Trip Stops

- **Endpoint**: `GET /driver/trips/{tripId}/stops`
- **Description**: Returns the list of student stops/home locations for the trip.
- **Response (200 OK)**:

  ```json
  [
    {
      "id": "stop_1",
      "studentNameAr": "أحمد سعيد",
      "studentNameEn": "Ahmed Saeed",
      "parentNameAr": "سعيد العلوي",
      "location": { "lat": 23.6, "lng": 58.35 },
      "isAbsent": false,
      "photoUrl": "..."
    }
  ]
  ```

  ###اذا هي موجودة جيبهاواذا ما قد طبقتوها خلاص بتتأخر يوم يومين, لما تجهزوها

### 6. Get Route Path

- **Endpoint**: `GET /driver/trips/{tripId}/route`
- **Description**: Returns the coordinates for the optimized route polyline.
- **Response (200 OK)**:
  ```json
  {
    "points": [
      { "lat": 23.6264, "lng": 58.2618 },
      { "lat": 23.6245, "lng": 58.2625 }
    ]
  }
  ```

### 7. End Trip

- **Endpoint**: `POST /driver/trips/{tripId}/end`
- **Description**: Finalizes the trip.
- **Response (200 OK)**:
  ```json
  { "message": "Trip ended successfully" }
  ```

---

## Student Tracking

### 8. Update Student Status

- **Endpoint**: `PATCH /driver/trips/{tripId}/students/{studentId}`
- **Description**: Updates whether a student is absent, boarded, or dropped off.
- **Request Body**:
  ```json
  {
    "isAbsent": true,
    "isBoarded": false,
    "isDroppedOff": false
  }
  ```
- **Response (200 OK)**:
  ```json
  { "status": "updated" }
  ```

---

## Maintenance & Operations

### 9. Submit Fuel Refill

- **Endpoint**: `POST /driver/maintenance/fuel`
- **Description**: Logs a fuel refill event.
- **Request (Multipart/form-data)**:
  - `amount`: double
  - `odometer`: int
  - [date]
  - `photo`: File (optional)
- **Response (201 Created)**:
  ```json
  { "id": "fuel_log_123" }
  ```

### 10. Submit Maintenance Request

- **Endpoint**: `POST /driver/maintenance/request`
- **Description**: Submits a technical issue or service request.
- **Request (Multipart/form-data)**:
  - `description`: string
  - `cost`: double (optional)
  - [date]
  - `photo`: File (optional)
- **Response (201 Created)**:
  ```json
  { "id": "req_456" }
  ```

### 11. Report Incident (SOS)

- **Endpoint**: `POST /driver/incidents`
- **Description**: Reports an emergency or incident during the trip.
- **Request Body**:
  ```json
  {
    "type": "accident|breakdown|other",
    "description": "...",
    "location": { "lat": 23.6, "lng": 58.35 }
  }
  ```
- **Response (201 Created)**:
  ```json
  { "id": "inc_789" }
  ```
