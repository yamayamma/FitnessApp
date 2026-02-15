# Research: 筋力トレーニング記録システム

**Date**: 2026-02-15  
**Status**: Complete

## R1: HKWorkoutSession + HKLiveWorkoutBuilder パターン

**Decision**: `HKWorkoutSession` + `HKLiveWorkoutBuilder` + `HKLiveWorkoutDataSource` の3クラス連携パターンを使用する。

**Rationale**: Apple 公式の標準パターン。watchOS 10+ / iOS 17+ で `HKWorkoutSession` が利用可能。`HKLiveWorkoutDataSource` を設定するだけで心拍数が自動収集される。

**Key findings**:
- ライフサイクル: `prepare()` → `startActivity(with:)` → `pause()` / `resume()` → `stopActivity(with:)` → `end()`
- `session.associatedWorkoutBuilder()` で builder を取得
- `builder.addMetadata(_:completion:)` でセッション開始後にカスタムメタデータ追加可能
- アクティビティタイプ: `.traditionalStrengthTraining`
- 認可タイプ: 書き込み `workoutType()`、読み取り `.heartRate` + `.activeEnergyBurned`
- Apple Watch は同時に1セッションのみ実行可能（同時複数セッション問題は自動解決）
- 心拍数は `builder.statistics(for: .heartRate)` で最新値を取得

**Alternatives rejected**:
- `HKWorkoutBuilder` 単体: watchOS ライブセッションには `HKLiveWorkoutBuilder` が必須
- iOS 側でセッション開始: 心拍数センサーなし

## R2: SwiftData on watchOS 10+

**Decision**: SwiftData `@Model` は watchOS 10+ で完全サポート。iOS / watchOS 間のデータベースファイル直接共有は不可のため、各デバイスが独立したストアを持つ設計とする。

**Rationale**: `ModelContainer`, `ModelConfiguration`, `@Model` マクロすべて watchOS 10.0+ で利用可能。同じモデルコードを共有するが、ストアは分離。

**Key findings**:
- インクリメンタル保存: `ModelContext.save()` をセット完了ごとに呼ぶ
- iOS ⇔ watchOS 間のデータ同期は WatchConnectivity で明示的に実行
- CloudKit 同期は MVP スコープ外（遅延が問題＋Privacy-First 原則に抵触）
- App Group コンテナは同一デバイス上のエクステンション間限定、iOS-watchOS 間は不可

**Design implication**: Watch 側でワークアウト結果を SwiftData に保存した後、`transferUserInfo` で iPhone に送信し、iPhone 側でも SwiftData に保存する二重保存パターン。

## R3: WatchConnectivity 使い分け

**Decision**: メニューデータ（iPhone → Watch）は `updateApplicationContext`、ワークアウト結果（Watch → iPhone）は `transferUserInfo` を使い分ける。

**Rationale**:
- `updateApplicationContext`: 最新状態のみ保持（上書き方式）→ メニュー一覧に最適
- `transferUserInfo`: キューに蓄積され順序通り配信 → ワークアウト結果の確実な配信に適切

**Key findings**:
- `updateApplicationContext` は相手が到達不可能でも呼び出し可能。`isReachable` チェック不要
- 値は plist 互換型のみ → `Codable` モデルを `JSONEncoder` で `Data` にエンコードして Dictionary に格納
- `transferUserInfo` はアプリ終了後も配信継続

**Alternatives rejected**:
- `sendMessage` のみ: 相手が到達不能の場合失敗する
- `updateApplicationContext` でワークアウト結果送信: 上書きされるため複数結果の配信に不適

## R4: HealthKit メタデータカスタムキー

**Decision**: 逆ドメイン記法でカスタムキーを定義。`builder.addMetadata` で追加。

**Rationale**: Apple は自先キー定義を明示的に推奨。衝突回避のため逆ドメインを使用。

**Key naming**:
```
"com.fitnessapp.sessionId"  → UUID 文字列
"com.fitnessapp.menuId"     → UUID 文字列（任意）
```

**Constraints**: 値の型は `NSString`, `NSNumber`, `NSDate` のみ。複雑なオブジェクトは格納不可。

## R5: watchOS workout-processing バックグラウンドモード

**Decision**: `workout-processing` バックグラウンドモードが必須かつ十分。既に Info.plist に設定済み。

**Rationale**: ワークアウト中のバックグラウンド実行、センサーデータ受信、手首上げ時の自動復帰を提供。

**Key findings**:
- ワークアウト完了後のデータ保存は `session.end()` 前に `builder.finishWorkout()` の completion handler 内で実行
- クラッシュリカバリ: `healthStore.recoverActiveWorkoutSession(completion:)` でセッション復元可能
- 追加モード不要（`audio` はセット間通知用ハプティクスが必要になったら追加）
- `transferUserInfo` はバックグラウンド転送のためモード追加不要

## R6: データフロー設計（研究に基づく決定）

研究結果を統合した設計:

```
[Watch] ワークアウト開始
  ├── HKWorkoutSession.startActivity()
  ├── HKLiveWorkoutBuilder.beginCollection()
  └── SwiftData: WorkoutSession(status: .active) を保存

[Watch] セット完了ごと
  ├── SwiftData: SetResult をインクリメンタル保存
  └── builder.statistics(for: .heartRate) で心拍数更新

[Watch] ワークアウト完了
  ├── session.stopActivity()
  ├── builder.addMetadata(["com.fitnessapp.sessionId": ...])
  ├── builder.endCollection()
  ├── builder.finishWorkout() → HKWorkout が HealthKit に保存
  ├── session.end()
  ├── SwiftData: WorkoutSession(status: .completed) を更新
  └── WCSession.transferUserInfo() で iPhone に結果送信

[iPhone] 結果受信
  ├── WCSessionDelegate.didReceiveUserInfo()
  ├── SwiftData: WorkoutSession + ExerciseResult + SetResult を保存
  └── HealthKit: HKWorkout は自動同期（iCloud 経由）

[iPhone] メニュー更新
  └── WCSession.updateApplicationContext() で Watch に送信

[Watch] メニュー受信
  ├── WCSessionDelegate.didReceiveApplicationContext()
  └── ローカルキャッシュ更新
```
