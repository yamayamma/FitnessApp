# Feature Specification: 筋力トレーニング記録システム

**Feature Branch**: `001-strength-training-system`  
**Created**: 2026-02-15  
**Status**: Draft  
**Input**: 筋力トレーニング記録システム（MVP / Phase 1）の機能仕様

## Overview

Apple Watch でワークアウトを実行・記録し、iPhone で履歴管理とメニュー管理を行う
筋力トレーニング記録アプリ。MVP 目標は「記録の摩擦を最小化する」こと。

## Clarifications

### Session 2026-02-15

- Q: ワークアウトセッションが取り得る状態（ライフサイクル）は？ → A: 4状態: `active` → `paused` → `completed` / `cancelled`（一時停止・キャンセルあり）
- Q: HealthKit 保存失敗時のリカバリ戦略は？ → A: ローカル DB には即座に保存し、HealthKit へは自動リトライキューで後から再試行する
- Q: Watch 上でのセット完了操作のインタラクション方式は？ → A: 大きなボタンタップ方式。画面上部にセット数・重量等の可変値をワンタップで記録できる UI、画面下部にフルワイド「次セット」ボタン
- Q: ローカル DB の技術選択は？ → A: SwiftData（`@Model` マクロ、`@Query` による SwiftUI 統合、iOS 17+ / watchOS 10+ ネイティブ）
- Q: WatchConnectivity によるメニュー同期方式は？ → A: `updateApplicationContext` — 最新状態のスナップショット同期（上書き方式、Watch 未起動でも次回起動時に反映）

## User Scenarios & Testing *(mandatory)*

### User Story 1 - ワークアウト実行（Apple Watch） (Priority: P1)

ユーザーは Apple Watch 上でワークアウトを開始し、セットを進行しながら
経過時間・心拍数をリアルタイムで確認し、完了時に HealthKit へ保存する。

**Why this priority**: ワークアウト記録はアプリの中核価値であり、
これなしには他のすべての機能が意味を持たない。

**Independent Test**: Apple Watch 単体でワークアウトを開始→セット進行→完了し、
HealthKit にデータが保存されることを確認できる。

**Acceptance Scenarios**:

1. **Given** Watch アプリが起動している, **When** ユーザーがワークアウト開始をタップする, **Then** ワークアウトセッションが開始され経過時間のリアルタイム表示が始まる
2. **Given** ワークアウトが進行中, **When** ユーザーが画面を確認する, **Then** 現在の心拍数が表示されている
3. **Given** ワークアウトが進行中, **When** ユーザーが画面上部の重量表示をタップする, **Then** 重量値をワンタップで変更できる（プリセット値から選択または増減）
4. **Given** ワークアウトが進行中, **When** ユーザーが画面下部の「次セット」ボタンをタップする, **Then** 現在のセットが記録されセット番号が進行し次のセット情報が表示される
5. **Given** ワークアウトが進行中, **When** ユーザーが一時停止をタップする, **Then** セッション状態が `paused` に遷移しタイマーが停止する
6. **Given** セッションが一時停止中, **When** ユーザーが再開をタップする, **Then** セッション状態が `active` に戻りタイマーが再開する
7. **Given** ワークアウトが進行中または一時停止中, **When** ユーザーがキャンセルをタップする, **Then** セッション状態が `cancelled` に遷移しデータは HealthKit に保存されない
8. **Given** ワークアウトが進行中, **When** ユーザーがワークアウト完了をタップする, **Then** セッション状態が `completed` になり HKWorkout として HealthKit に保存され、metadata に sessionId（UUID）が含まれる

---

### User Story 2 - 履歴管理（iPhone） (Priority: P2)

ユーザーは iPhone 上で当日のワークアウトおよび過去の履歴を一覧表示し、
各ワークアウトの詳細を確認できる。

**Why this priority**: 記録したデータを振り返れることで、ユーザーの
トレーニング継続モチベーションを支える。

**Independent Test**: iPhone アプリ単体で過去のワークアウト履歴一覧が
表示され、任意の記録の詳細画面に遷移できることを確認する。

**Acceptance Scenarios**:

1. **Given** 過去にワークアウトが記録されている, **When** ユーザーが履歴画面を開く, **Then** 当日のワークアウトが上部に表示され、過去の履歴が日付順に一覧表示される
2. **Given** 履歴一覧が表示されている, **When** ユーザーが特定のワークアウトをタップする, **Then** そのワークアウトの詳細（種目、セット数、時間）が表示される
3. **Given** 履歴画面が表示されている, **When** ユーザーが画面を確認する, **Then** 合計時間などの基本統計が表示される

---

### User Story 3 - メニュー管理（iPhone） (Priority: P3)

ユーザーは iPhone 上でトレーニングメニューを作成し、種目とセット数を登録する。
作成したメニューは WatchConnectivity 経由で Apple Watch 側で利用可能となる。

**Why this priority**: メニューのプリセットにより Watch 側での操作ステップを
さらに削減し、記録の摩擦を低減する。

**Independent Test**: iPhone でメニューを作成し、Watch 側でそのメニューが
表示・選択可能であることを確認する。

**Acceptance Scenarios**:

1. **Given** iPhone アプリのメニュー管理画面, **When** ユーザーが新しいメニューを作成する, **Then** メニュー名を入力してメニューが作成される
2. **Given** メニューが存在する, **When** ユーザーが種目を追加する, **Then** 種目名とセット数を指定して登録できる
3. **Given** メニューが iPhone で作成済み, **When** Watch アプリがメニュー一覧を表示する, **Then** `updateApplicationContext` 経由で同期された最新のメニュー一覧が表示される（Watch 未起動時も次回起動時に自動反映）

---

### User Story 4 - データ保存・連携 (Priority: P2)

ワークアウトデータが HealthKit とローカル DB に二重保存され、
sessionId（UUID）で紐付けられる。

**Why this priority**: データの永続性と将来の拡張性を担保する
基盤レイヤーとして、US1 と同時に実装が必要。

**Independent Test**: ワークアウト完了後に HealthKit と ローカル DB の
両方にデータが存在し、sessionId で突合できることを確認する。

**Acceptance Scenarios**:

1. **Given** ワークアウトが完了した, **When** データ保存処理が実行される, **Then** 詳細データ（種目、レップ数、重量等）がまずローカル DB に即座に保存される
2. **Given** ローカル DB 保存が成功した, **When** HealthKit への保存処理が実行される, **Then** HKWorkout が HealthKit に保存される
3. **Given** HealthKit への保存が失敗した, **When** エラーが検出される, **Then** 自動リトライキューに登録され、後からバックグラウンドで再試行される
4. **Given** HealthKit と ローカル DB にデータが保存されている, **When** sessionId で検索する, **Then** 両方のデータが同一セッションとして紐付けられる
5. **Given** ローカル DB のデータ, **When** JSON 変換を実行する, **Then** エラーなく JSON 形式に変換できる

---

### Edge Cases

- ワークアウト中に Watch アプリがクラッシュした場合、進行中のデータはどうなるか？
- HealthKit への保存が失敗した場合: ローカル DB には即座に保存済みのため、自動リトライキューで HealthKit への再試行を行う。リトライ回数上限到達後の挙動は要検討。
- iPhone と Watch 間の WatchConnectivity が切断されている場合: `updateApplicationContext` は次回接続時に最新コンテキストが自動配信されるため、特別なリトライ処理は不要。Watch 側はローカルキャッシュで前回のメニューを表示する。
- ワークアウト中にバッテリーが低下した場合の動作は？
- 同時に複数のワークアウトセッションが開始された場合の挙動は？
- セッションが `paused` 状態のまま長時間放置された場合の扱いは？
- `cancelled` されたセッションのローカル DB データを保持するか破棄するか？

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Watch アプリでワークアウトセッションの開始・一時停止・再開・完了・キャンセルができなければならない（状態遷移: `active` → `paused` → `completed` / `cancelled`）
- **FR-002**: ワークアウト中に経過時間がリアルタイム表示されなければならない
- **FR-003**: ワークアウト中に心拍数が表示されなければならない
- **FR-004**: Watch のワークアウト画面は上部にセット数・重量等の可変値をワンタップで記録・変更できるエリア、下部にフルワイドの「次セット」ボタンを配置しなければならない
- **FR-005**: ワークアウト完了時に HKWorkout として HealthKit に保存されなければならない
- **FR-006**: HKWorkout の metadata に sessionId（UUID）が含まれなければならない
- **FR-007**: ワークアウト詳細データ（種目、レップ数、重量）がローカル DB に即座に保存されなければならない（HealthKit 保存より先行）
- **FR-015**: HealthKit への保存が失敗した場合、自動リトライキューに登録しバックグラウンドで再試行しなければならない
- **FR-008**: iPhone アプリで当日および過去のワークアウト履歴が一覧表示されなければならない
- **FR-009**: 各ワークアウトの詳細（種目、セット数、時間）が確認可能でなければならない
- **FR-010**: 合計時間などの基本統計が表示されなければならない
- **FR-011**: iPhone でトレーニングメニューを作成・編集できなければならない
- **FR-012**: メニューに種目とセット数を登録できなければならない
- **FR-013**: 作成したメニューが `WCSession.updateApplicationContext` 経由で Watch 側に同期されなければならない（最新スナップショットの上書き方式）
- **FR-014**: ローカル DB のデータは JSON 変換可能な構造を持たなければならない

### Non-Functional Requirements

- **NFR-001**: オフライン環境下で完全に動作可能でなければならない
- **NFR-002**: 外部 API への依存を持ってはならない（MVP）
- **NFR-003**: Apple App Store 審査基準に準拠しなければならない
- **NFR-004**: ユーザーデータはローカル保存のみとする
- **NFR-005**: ローカル DB には SwiftData（`@Model` マクロ）を使用しなければならない

### Key Entities

全エンティティは SwiftData `@Model` で定義する。iPhone と Watch で同一のモデルコードを共有フレームワーク経由で利用する。

- **WorkoutSession**: ワークアウトセッションを表す。sessionId（UUID）, startDate, endDate, menuId, totalDuration, status（`active` / `paused` / `completed` / `cancelled`）を持つ。
- **ExerciseResult**: セッション内の各種目の結果。exerciseId, setResults 配列, exerciseName を持つ。
- **SetResult**: 各セットの結果。weight, reps, setNumber を持つ。
- **TrainingMenu**: トレーニングメニューのプリセット。menuId, name, exercises 配列を持つ。
- **Exercise**: 種目の定義。exerciseId, name, defaultSets を持つ。

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Apple Watch でワークアウトの開始から完了までを 5 タップ以内で完了できる
- **SC-002**: ワークアウト完了後、HealthKit とローカル DB の両方にデータが保存される（成功率 100%）
- **SC-003**: iPhone で過去のワークアウト履歴が 1 秒以内に一覧表示される
- **SC-004**: iPhone で作成したメニューが Watch に正常に同期される

## Out of Scope (MVP)

以下の機能は MVP（Phase 1）では明確に除外する:

- wger API 連携
- MCP サーバー公開
- Google カレンダー連携
- クラウド同期
- AI によるメニュー生成
- 自動スケジューリング
- 高度な分析・レポート機能
