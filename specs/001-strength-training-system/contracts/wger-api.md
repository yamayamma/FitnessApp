# API Contracts: wger Integration

**Feature**: 001-strength-training-system  
**Date**: 2026-02-11  
**API Version**: wger REST API v2

## Base URL

`{serverURL}/api/v2/` — configured per user in `AppConfig.serverURL`

## Authentication

### POST /token — Obtain JWT Token Pair

**Request**:
```json
{
  "username": "string",
  "password": "string"
}
```

**Response** (200):
```json
{
  "access": "eyJ...",
  "refresh": "eyJ..."
}
```

**Error** (401):
```json
{
  "detail": "No active account found with the given credentials"
}
```

### POST /token/refresh — Refresh Access Token

**Request**:
```json
{
  "refresh": "eyJ..."
}
```

**Response** (200):
```json
{
  "access": "eyJ..."
}
```

**Error** (401):
```json
{
  "detail": "Token is invalid or expired",
  "code": "token_not_valid"
}
```

---

## Workout Plans

### GET /routine/ — List User Routines

**Headers**: `Authorization: Bearer {access_token}`

**Response** (200):
```json
{
  "count": 3,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "name": "Push Pull Legs",
      "description": "3-day split",
      "created": "2026-01-01T00:00:00Z",
      "start": "2026-01-01",
      "end": "2026-03-31",
      "fit_in_week": true,
      "is_template": false,
      "is_public": false
    }
  ]
}
```

### GET /routine/{id}/structure/ — Full Routine Structure

**Headers**: `Authorization: Bearer {access_token}`

**Response** (200):
```json
{
  "id": 1,
  "name": "Push Pull Legs",
  "description": "3-day split",
  "created": "2026-01-01T00:00:00Z",
  "start": "2026-01-01",
  "end": "2026-03-31",
  "fit_in_week": true,
  "days": [
    {
      "id": 10,
      "routine": 1,
      "order": 1,
      "name": "Push Day",
      "description": "",
      "is_rest": false,
      "need_logs_to_advance": false,
      "slots": [
        {
          "id": 100,
          "day": 10,
          "order": 1,
          "comment": "",
          "entries": [
            {
              "id": 1000,
              "slot": 100,
              "exercise": 192,
              "order": 1,
              "comment": "",
              "repetition_unit": 1,
              "weight_unit": 1,
              "weight_rounding": "1.25",
              "set_nr_configs": [
                { "value": "4", "iteration": 1, "slot_entry": 1000 }
              ],
              "repetitions_configs": [
                { "value": "8", "iteration": 1, "slot_entry": 1000 }
              ],
              "weight_configs": [
                { "value": "80.00", "iteration": 1, "slot_entry": 1000 }
              ],
              "rest_configs": [
                { "value": "120", "iteration": 1, "slot_entry": 1000 }
              ],
              "rir_configs": [],
              "max_weight_configs": [],
              "max_repetitions_configs": [],
              "max_set_nr_configs": [],
              "max_rest_configs": [],
              "max_rir_configs": []
            }
          ]
        }
      ]
    }
  ]
}
```

**Mapping to internal `WorkoutPlan`**:
| wger field | Internal field |
|-----------|----------------|
| `routine.id` | `WorkoutPlan.planId` (as String) |
| `routine.name` | `WorkoutPlan.name` |
| `routine.description` | `WorkoutPlan.description` |
| `days[].id` | `WorkoutDay.dayId` (as String) |
| `days[].name` | `WorkoutDay.name` |
| `days[].order` | `WorkoutDay.order` |
| `days[].is_rest` | `WorkoutDay.isRest` |
| `entries[].exercise` | `PlannedExercise.exerciseId` (as String) |
| `entries[].order` | `PlannedExercise.order` |
| `entries[].set_nr_configs[0].value` | `PlannedExercise.sets` (as Int) |
| `entries[].repetitions_configs[0].value` | `PlannedExercise.reps` (as Int) |
| `entries[].weight_configs[0].value` | `PlannedExercise.weightKg` (as Double?) |
| `entries[].rest_configs[0].value` | `PlannedExercise.restSec` (as Int) |

---

## Exercise Information

### GET /exerciseinfo/{id}/ — Full Exercise Details

**Headers**: `Authorization: Bearer {access_token}`

**Response** (200):
```json
{
  "id": 192,
  "uuid": "bc2e08e8-4b3e-4ee5-ad4d-abc7df1e3285",
  "category": {
    "id": 11,
    "name": "Chest"
  },
  "muscles": [
    { "id": 4, "name": "Pectoralis major", "name_en": "Chest", "is_front": true }
  ],
  "muscles_secondary": [
    { "id": 5, "name": "Triceps brachii", "name_en": "Triceps", "is_front": false }
  ],
  "equipment": [
    { "id": 1, "name": "Barbell" }
  ],
  "translations": [
    {
      "id": 718,
      "name": "Bench Press",
      "description": "<p>Lie on bench...</p>",
      "language": 2
    }
  ],
  "images": [
    { "id": 1, "image": "https://...", "is_main": true }
  ]
}
```

**Usage**: Called once per unique `exerciseId` in a routine. Exercise name is cached in `PlannedExercise.exerciseName` using the user's preferred language from `translations[]`.

---

## Workout Logging (Result Sync to wger)

### POST /workoutsession/ — Create Workout Session

**Headers**: `Authorization: Bearer {access_token}`

**Request**:
```json
{
  "routine": 1,
  "date": "2026-02-11",
  "notes": "",
  "impression": "3",
  "time_start": "09:00:00",
  "time_end": "10:15:00"
}
```

**Response** (201):
```json
{
  "id": 42,
  "routine": 1,
  "date": "2026-02-11",
  "notes": "",
  "impression": "3",
  "time_start": "09:00:00",
  "time_end": "10:15:00"
}
```

### POST /workoutlog/ — Create Workout Log Entry (per set)

**Headers**: `Authorization: Bearer {access_token}`

**Request**:
```json
{
  "session": 42,
  "routine": 1,
  "exercise": 192,
  "repetitions": "8.00",
  "weight": "80.00",
  "repetition_unit": 1,
  "weight_unit": 1,
  "rir": "2.0",
  "rest": 120,
  "iteration": 1
}
```

**Response** (201):
```json
{
  "id": 100,
  "date": "2026-02-11T09:30:00Z",
  "session": 42,
  "routine": 1,
  "exercise": 192,
  "repetitions": "8.00",
  "weight": "80.00",
  "repetition_unit": 1,
  "weight_unit": 1,
  "rir": "2.0",
  "rest": 120,
  "iteration": 1
}
```

**Mapping from internal `WorkoutSessionResult`**:
| Internal field | wger field |
|---------------|-----------|
| `sessionResult.planId` | `workoutsession.routine` (as Int) |
| `sessionResult.performedAt` → date | `workoutsession.date` |
| `sessionResult.performedAt` → time | `workoutsession.time_start` |
| `sessionResult.completedAt` → time | `workoutsession.time_end` |
| `exerciseResult.exerciseId` | `workoutlog.exercise` (as Int) |
| `setResult.reps` | `workoutlog.repetitions` (as Decimal String) |
| `setResult.weightKg` | `workoutlog.weight` (as Decimal String) |

---

## Error Handling

All endpoints may return:

| Status | Meaning | Action |
|--------|---------|--------|
| 401 | Token expired | Attempt token refresh, retry once |
| 403 | Forbidden | Show auth error, prompt re-login |
| 404 | Not found | Remove local reference on next sync |
| 429 | Rate limited | Exponential backoff, retry after `Retry-After` header |
| 500 | Server error | Show generic error, preserve local data |

---

## Pagination Contract

All list endpoints follow:

```json
{
  "count": 100,
  "next": "https://{server}/api/v2/{resource}/?limit=20&offset=20",
  "previous": null,
  "results": [...]
}
```

Client MUST follow `next` links until `next` is `null` to fetch all records.
