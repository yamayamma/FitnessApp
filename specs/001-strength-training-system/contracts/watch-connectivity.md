# WatchConnectivity Contract

**Version**: 1.0.0  
**Date**: 2026-02-15

## Overview

iPhone ↔ Apple Watch 間の WatchConnectivity 通信プロトコル定義。

## Channels

### 1. Menu Sync (iPhone → Watch)

**Method**: `WCSession.default.updateApplicationContext(_:)`  
**Direction**: iPhone → Watch (単方向)  
**Trigger**: メニュー作成・更新・削除時  
**Delivery**: 最新スナップショットのみ配信（中間状態は上書き）

#### Request Format

```swift
// Application Context Dictionary
[String: Any]
```

| Key | Type | Description |
|-----|------|-------------|
| `menus` | Data | `[MenuTransfer]` の JSONEncoder 出力 |
| `timestamp` | TimeInterval | `Date().timeIntervalSince1970` |

#### MenuTransfer Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "array",
  "items": {
    "type": "object",
    "required": ["menuId", "name", "exercises"],
    "properties": {
      "menuId": { "type": "string", "format": "uuid" },
      "name": { "type": "string", "minLength": 1 },
      "exercises": {
        "type": "array",
        "items": {
          "type": "object",
          "required": ["exerciseId", "name", "defaultSets", "defaultWeight", "defaultReps", "sortOrder"],
          "properties": {
            "exerciseId": { "type": "string", "format": "uuid" },
            "name": { "type": "string" },
            "defaultSets": { "type": "integer", "minimum": 1 },
            "defaultWeight": { "type": "number", "minimum": 0 },
            "defaultReps": { "type": "integer", "minimum": 1 },
            "sortOrder": { "type": "integer", "minimum": 0 }
          }
        }
      }
    }
  }
}
```

#### Error Handling

- Watch 側で JSON デコード失敗時: ログ出力、既存メニューを保持
- `WCSession.isReachable == false`: Context はキューイングされ、次回接続時に自動配信

---

### 2. Workout Result (Watch → iPhone)

**Method**: `WCSession.default.transferUserInfo(_:)`  
**Direction**: Watch → iPhone (単方向)  
**Trigger**: ワークアウト完了時（status == completed）  
**Delivery**: 順序保証あり、オフライン時はキューイング

#### Request Format

```swift
// UserInfo Dictionary
[String: Any]
```

| Key | Type | Description |
|-----|------|-------------|
| `type` | String | 固定値: `"workoutResult"` |
| `sessionId` | String | UUID 文字列 |
| `data` | Data | `WorkoutResultTransfer` の JSONEncoder 出力 |

#### WorkoutResultTransfer Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["sessionId", "startDate", "endDate", "totalDuration", "status", "exercises"],
  "properties": {
    "sessionId": { "type": "string", "format": "uuid" },
    "startDate": { "type": "string", "format": "date-time" },
    "endDate": { "type": "string", "format": "date-time" },
    "menuId": { "type": "string", "format": "uuid", "nullable": true },
    "menuName": { "type": "string", "nullable": true },
    "totalDuration": { "type": "number", "minimum": 0 },
    "status": { "type": "string", "enum": ["completed"] },
    "exercises": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["exerciseId", "exerciseName", "sets"],
        "properties": {
          "exerciseId": { "type": "string", "format": "uuid" },
          "exerciseName": { "type": "string" },
          "sets": {
            "type": "array",
            "items": {
              "type": "object",
              "required": ["setNumber", "weight", "reps", "completedAt"],
              "properties": {
                "setNumber": { "type": "integer", "minimum": 1 },
                "weight": { "type": "number", "minimum": 0 },
                "reps": { "type": "integer", "minimum": 0 },
                "completedAt": { "type": "string", "format": "date-time" }
              }
            }
          }
        }
      }
    }
  }
}
```

#### Error Handling

- iPhone 側で受信時にデコード失敗: ログ出力、再送不要（transferUserInfo は到達保証あり）
- 重複チェック: `sessionId` で重複受信を検出、既存レコードがあればスキップ

---

### 3. Incremental Set Save (Watch Internal)

**Method**: ローカル SwiftData `modelContext.save()`  
**Trigger**: セット完了ごと（FR-017）  

Watch 側の SwiftData に即時保存。WatchConnectivity では送信しない。
ワークアウト完了後にまとめて `transferUserInfo` で送信。

---

## Connection Lifecycle

```
┌─────────────────────────────────────────────────────────────┐
│                    WCSession Lifecycle                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. App Launch                                              │
│     └─ WCSession.default.activate()                         │
│                                                             │
│  2. Session Activated                                       │
│     ├─ Check session.isWatchAppInstalled (iPhone)           │
│     └─ Check session.isCompanionAppInstalled (Watch)        │
│                                                             │
│  3. Ongoing                                                 │
│     ├─ iPhone: updateApplicationContext on menu change      │
│     └─ Watch: transferUserInfo on workout complete          │
│                                                             │
│  4. Background                                              │
│     ├─ transferUserInfo queued until delivery               │
│     └─ applicationContext replaced on next update           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```
