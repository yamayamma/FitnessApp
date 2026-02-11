# API Contracts: WatchConnectivity Protocol

**Feature**: 001-strength-training-system  
**Date**: 2026-02-11

## Overview

All iPhone ↔ Watch communication uses `WCSession` with Codable JSON payloads. The iPhone acts as the hub; the Watch never communicates directly with the backend.

---

## Message Types

Each message includes a `type` field for routing:

```json
{
  "type": "startWorkout | sessionResult | planListUpdate",
  "payload": { ... }
}
```

---

## iPhone → Watch

### Start Workout Session

**Method**: `WCSession.sendMessageData(_:replyHandler:errorHandler:)`  
**Trigger**: User taps "Start Workout" on iPhone  
**Requirement**: Watch must be reachable (`WCSession.isReachable`)

**Payload**:
```json
{
  "type": "startWorkout",
  "payload": {
    "sessionId": "550e8400-e29b-41d4-a716-446655440000",
    "plan": {
      "planId": "1",
      "name": "Push Pull Legs",
      "days": [
        {
          "dayId": "10",
          "name": "Push Day",
          "order": 1,
          "isRest": false,
          "exercises": [
            {
              "exerciseId": "192",
              "exerciseName": "Bench Press",
              "order": 1,
              "sets": 4,
              "reps": 8,
              "weightKg": 80.0,
              "restSec": 120
            }
          ]
        }
      ]
    },
    "selectedDayId": "10"
  }
}
```

**Reply** (from Watch):
```json
{
  "type": "startWorkoutAck",
  "payload": {
    "sessionId": "550e8400-e29b-41d4-a716-446655440000",
    "status": "ready"
  }
}
```

**Error Reply**:
```json
{
  "type": "startWorkoutAck",
  "payload": {
    "sessionId": "550e8400-e29b-41d4-a716-446655440000",
    "status": "error",
    "errorMessage": "HealthKit authorization required"
  }
}
```

### Plan List Update (Background)

**Method**: `WCSession.updateApplicationContext(_:)`  
**Trigger**: After successful wger sync on iPhone  

**Payload**:
```json
{
  "type": "planListUpdate",
  "payload": {
    "plans": [
      {
        "planId": "1",
        "name": "Push Pull Legs",
        "dayCount": 3,
        "lastSyncedAt": "2026-02-11T10:00:00Z"
      }
    ],
    "syncedAt": "2026-02-11T10:00:00Z"
  }
}
```

---

## Watch → iPhone

### Session Result

**Method**: `WCSession.transferUserInfo(_:)`  
**Trigger**: Workout session ends on Watch  
**Guarantee**: Queued for eventual delivery even if iPhone is unreachable

**Payload**:
```json
{
  "type": "sessionResult",
  "payload": {
    "sessionId": "550e8400-e29b-41d4-a716-446655440000",
    "planId": "1",
    "dayId": "10",
    "performedAt": "2026-02-11T09:00:00Z",
    "completedAt": "2026-02-11T10:15:00Z",
    "exercises": [
      {
        "exerciseId": "192",
        "exerciseName": "Bench Press",
        "sets": [
          { "setNumber": 1, "reps": 8, "weightKg": 80.0, "completed": true },
          { "setNumber": 2, "reps": 8, "weightKg": 80.0, "completed": true },
          { "setNumber": 3, "reps": 7, "weightKg": 80.0, "completed": true },
          { "setNumber": 4, "reps": 6, "weightKg": 80.0, "completed": false }
        ]
      }
    ],
    "isHealthKitSynced": true,
    "isWgerSynced": false,
    "schemaVersion": "1.0.0"
  }
}
```

---

## Error Handling

| Scenario | iPhone Action | Watch Action |
|----------|---------------|--------------|
| Watch not reachable | Show "Watch not connected" alert | N/A |
| `sendMessageData` timeout | Retry once, then show error | N/A |
| `transferUserInfo` pending | N/A | Save locally; OS queues delivery |
| Session mismatch (unknown sessionId) | Log warning, accept data | N/A |
| Decode error | Log error, discard message | Log error, discard message |

---

## Data Size Constraints

- `sendMessageData` payload: Expected < 5 KB per workout plan
- `transferUserInfo` payload: Expected < 3 KB per session result
- `updateApplicationContext` payload: Expected < 1 KB for plan list metadata
- All well within WCSession limits (65 KB for `sendMessage`, no hard limit for `transferUserInfo`)
