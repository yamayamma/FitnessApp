# Speckit コマンド別プロンプト一覧

> 要件定義 v1.0 を Speckit ワークフローで整理するためのプロンプト集  
> 実行順: constitution → specify → clarify → plan → checklist → tasks → analyze → implement

---

## 1. `/speckit.constitution` — プロジェクト原則の確立

```text
筋力トレーニング記録管理プラットフォーム「FitnessApp」のConstitutionを策定する。

■ プロジェクト名
FitnessApp

■ 原則（5つ）

1. Privacy-First（プライバシー最優先）
   - ユーザーデータはすべてローカル保存（HealthKit + ローカルDB）
   - 外部API依存なし（MVP）
   - Apple審査基準を常に準拠
   - クラウド同期はオプトイン方式のみ（将来Phase）

2. Minimal Friction Recording（記録の摩擦最小化）
   - Apple Watchでのワークアウト記録を最小タップで完了可能にする
   - 操作ステップを最適化し、トレーニング中の中断を最小にする
   - オフライン完全動作を保証する

3. Extensible Architecture（拡張可能なアーキテクチャ）
   - sessionId(UUID)でHealthKitとローカルDBを紐付け
   - JSON変換可能なデータ構造を維持
   - 将来のMCP・外部AI・wger連携に対応可能な境界設計
   - Phase分離: MVP → 管理強化 → MCP公開 → 生活統合

4. Platform-Native Design（プラットフォームネイティブ設計）
   - SwiftUI + HealthKit + WatchConnectivity を標準APIとして使用
   - Apple Watch / iPhone の各デバイス特性に最適化したUI
   - watchOS / iOS のHIG準拠

5. Incremental Delivery（段階的デリバリー）
   - Phase 1(MVP)で最小機能をリリース可能に保つ
   - 各Phaseは独立してテスト・デプロイ可能
   - MVPでやらないこと（wger連携, MCP, クラウド同期, AI, 自動スケジューリング, 高度分析）を明確に除外

■ 追加制約セクション
- 技術スタック: Swift 5.9+, SwiftUI, watchOS 10+, iOS 17+
- ストレージ: HealthKit (HKWorkout), SwiftData or CoreData (ローカルDB)
- テスト: XCTest
- OSSライセンス準拠

■ 開発ワークフロー
- speckit駆動の仕様優先開発
- 機能ブランチベース（###-feature-name形式）
- PRベースのレビュー

■ ガバナンス
- Constitutionは全設計判断の最上位基準
- 変更はセマンティックバージョニングで管理
- Ratification Date: 2026-02-15
```

---

## 2. `/speckit.specify` — ベースライン仕様の作成

```text
筋力トレーニング記録システム（MVP / Phase 1）の機能仕様を作成する。

■ 機能概要
Apple Watchでワークアウトを実行・記録し、iPhoneで履歴管理とメニュー管理を行う
筋力トレーニング記録アプリ。MVP目標は「記録の摩擦を最小化する」こと。

■ ユーザーストーリー（優先度順）

US1 (P1): ワークアウト実行（Apple Watch）
- ワークアウトを開始し、セット進行しながら経過時間・心拍を確認し、完了時にHealthKitへ保存する
- 受け入れ条件:
  - Watch上でワークアウト開始/終了が可能
  - 経過時間がリアルタイム表示される
  - 心拍数が表示される
  - セット進行（次セットへの遷移）が最低限動作する
  - 完了時にHKWorkoutとしてHealthKitに保存される
  - sessionId(UUID)がHKWorkout.metadataに含まれる

US2 (P2): 履歴管理（iPhone）
- 当日のワークアウトおよび過去履歴を一覧表示し、詳細を確認できる
- 受け入れ条件:
  - 当日のワークアウトが表示される
  - 過去の履歴一覧が表示される
  - 各ワークアウトの詳細（種目、セット数、時間）が確認可能
  - 合計時間などの基本統計が表示される

US3 (P3): メニュー管理（iPhone）
- iPhoneでトレーニングメニューを作成し、種目とセット数を登録する
- 受け入れ条件:
  - 新しいメニューを作成できる
  - メニューに種目を登録できる
  - 各種目にセット数を指定できる
  - 作成したメニューをWatch側で利用可能（WatchConnectivity経由）

US4 (P2): データ保存・連携
- ワークアウトデータがHealthKitとローカルDBに二重保存され、sessionIdで紐付けられる
- 受け入れ条件:
  - HKWorkoutがHealthKitに保存される
  - 詳細データ（種目、レップ数、重量等）がローカルDBに保存される
  - sessionId(UUID)で両者が紐付けられる
  - JSON変換可能な構造を持つ

■ 非機能要件
- オフラインで完全動作可能
- 外部API依存なし
- Apple審査基準準拠
- ユーザーデータはローカル保存のみ

■ MVPスコープ外（明示的除外）
- wger連携, MCP公開, Googleカレンダー連携
- クラウド同期, AI生成, 自動スケジューリング, 高度分析

■ キーエンティティ
- WorkoutSession: sessionId, startDate, endDate, menuId, totalDuration
- ExerciseResult: exerciseId, setResults[], exerciseName
- SetResult: weight, reps, setNumber
- TrainingMenu: menuId, name, exercises[]
- Exercise: exerciseId, name, defaultSets
```

---

## 3. `/speckit.clarify` (optional) — 曖昧領域の質問による明確化

> `/speckit.plan` の前に実行。仕様の曖昧な領域を特定し、構造化された質問で解消する。

```text
筋力トレーニング記録アプリ（MVP）の仕様について、以下の観点で曖昧な領域を特定し
最大5つの質問で明確化してほしい。

■ 特に確認してほしい領域
1. データモデル: SetResultに「重量」「レップ数」以外に必要なフィールドがあるか
   （例: RPE, 休息時間, メモ）
2. Watch-iPhone連携: メニュー同期のタイミングと方式
   （WatchConnectivity の transferUserInfo vs updateApplicationContext）
3. HealthKit保存: HKWorkout.metadata に保存する独自キーの設計
4. セット進行UI: Watch上でのセット完了操作の具体的なインタラクション
   （タップ、スワイプ、Digital Crown等）
5. ローカルDB: SwiftData vs CoreData の選択

■ 補足コンテキスト
- 既存コードは WatchConnectivity の基礎実装（sendWorkoutName）のみ
- ターゲット: watchOS 10+ / iOS 17+
- 開発者は個人利用が主目的、将来OSS化予定
```

---

## 4. `/speckit.plan` — 実装計画の作成

```text
筋力トレーニング記録アプリ（MVP）の実装計画を作成する。

■ 技術コンテキスト
- Language: Swift 5.9+
- UI: SwiftUI
- Platforms: iOS 17+, watchOS 10+
- Storage: HealthKit (HKWorkout), SwiftData (ローカルDB)
- Communication: WatchConnectivity
- Testing: XCTest
- Project Type: mobile (iOS + watchOS)
- IDE: Xcode
- Architecture: MVVM
- 制約: オフライン動作必須、外部API依存なし

■ 既存コード状況
- Xcode プロジェクト構成済み（FitnessApp + FitnessAppWatch Watch App）
- WatchConnectivityManager / WatchSessionManager の基礎実装あり
- ContentView（iPhone側）: 「Send to Watch」でワークアウト名送信
- ContentView（Watch側）: 受信したワークアウト名を表示
- HealthKit統合: 未実装
- データモデル: 未実装
- ワークアウト実行ロジック: 未実装

■ 計画で特に決定してほしいこと
1. SwiftData モデル設計（WorkoutSession, ExerciseResult, SetResult, TrainingMenu, Exercise）
2. HealthKit連携のデータフロー（HKWorkoutSession → HKWorkout保存）
3. Watch ↔ iPhone のデータ同期方式
4. MVVM構成でのファイル配置
5. 画面遷移設計（Watch側: メニュー選択→ワークアウト実行→完了 / iPhone側: 履歴一覧→詳細→メニュー管理）

■ アーキテクチャ境界
Watch → HealthKit → iPhone → LocalDB (SwiftData)
```

---

## 5. `/speckit.checklist` (optional) — 品質チェックリストの生成

> `/speckit.plan` の後に実行。要件の完全性・明確性・一貫性を検証する。

```text
筋力トレーニング記録アプリ（MVP）について、以下のドメインのチェックリストを生成してほしい。

■ チェックリスト1: healthkit-privacy.md
HealthKitとプライバシーに関する要件品質の検証
- HealthKit許可フローの要件は明確か
- 保存するデータ種別（HKWorkoutType等）の要件は網羅されているか
- Privacy Description（Info.plist）の定義は仕様に含まれているか
- Apple審査ガイドラインとの整合性は確認されているか

■ チェックリスト2: watch-ux.md
Apple Watch UIに関する要件品質の検証
- セット進行操作の要件は具体的に定義されているか
- 画面遷移フローの要件はすべてのパスを網羅しているか
- エラー状態・空状態・ローディング状態の要件は定義されているか
- watchOS HIGへの準拠要件は明記されているか

■ チェックリスト3: data-model.md
データモデルに関する要件品質の検証
- 全エンティティの属性とリレーションは明確に定義されているか
- sessionIdによるHealthKit-ローカルDB紐付けの要件は一意か
- JSON変換可能性の要件は具体的なスキーマで定義されているか
- 将来拡張（MCP入出力フォーマット）への対応が要件として記載されているか
```

---

## 6. `/speckit.tasks` — 実行可能なタスクの生成

```text
筋力トレーニング記録アプリ（MVP）の実装タスクを生成する。

■ 追加コンテキスト
- 既存のXcodeプロジェクト構成を活用する
- WatchConnectivityの基礎実装（WatchConnectivityManager, WatchSessionManager）は既に存在
- TDDアプローチは必須ではないが、主要ロジック（データモデル、HealthKit連携）にはユニットテストを含める
- タスク粒度: 各タスクが1つのファイルまたは1つの明確な機能変更に対応

■ 期待するフェーズ構成
Phase 1: セットアップ（SwiftDataモデル定義、HealthKit設定、プロジェクト構造整備）
Phase 2: 基盤（HealthKitマネージャー、データ永続化層、WatchConnectivity拡張）
Phase 3: [US1] ワークアウト実行（Watch側 - メニュー選択→実行→完了→保存）
Phase 4: [US4] データ保存連携（sessionIdベースのHealthKit-SwiftData紐付け）
Phase 5: [US2] 履歴管理（iPhone側 - 一覧→詳細→統計）
Phase 6: [US3] メニュー管理（iPhone側 - 作成→種目登録→セット数指定→Watch同期）
Phase 7: ポリッシュ（エラーハンドリング、UI調整、テスト追加）
```

---

## 7. `/speckit.analyze` (optional) — 成果物間の整合性チェック

> `/speckit.tasks` の後、`/speckit.implement` の前に実行。

```text
筋力トレーニング記録アプリ（MVP）のspec.md、plan.md、tasks.mdについて
整合性・一貫性の分析を実行する。

■ 特に確認してほしい観点
1. Constitution整合性: Privacy-First原則がすべてのデータフローに反映されているか
2. カバレッジ: 4つのユーザーストーリー(US1-US4)がすべてタスクに展開されているか
3. データモデル一貫性: spec上のエンティティ定義がplan/tasksで矛盾なく使用されているか
4. 非機能要件カバレッジ: オフライン動作・Apple審査準拠がタスクに反映されているか
5. 用語統一: WorkoutSession, ExerciseResult等の用語がファイル間で一致しているか
6. 依存関係: タスク間の依存順序に矛盾がないか（特にHealthKit設定→ワークアウト保存の順序）
7. スコープ外の混入: MVPスコープ外の機能（wger, MCP, クラウド同期等）がタスクに入り込んでいないか
```

---

## 8. `/speckit.implement` — 実装の実行

```text
筋力トレーニング記録アプリ（MVP）のtasks.mdに基づき実装を開始する。

■ 実装上の注意点
- 既存のXcodeプロジェクト構成（FitnessApp.xcodeproj）を維持する
- 既存ファイル（WatchConnectivityManager.swift, WatchSessionManager.swift）は拡張する形で進める
- 新規ファイルはMVVM構成に従い適切なディレクトリに配置する
  - Models/: SwiftDataモデル
  - ViewModels/: ビューモデル
  - Views/: SwiftUI View
  - Services/: HealthKitManager等のサービス層
- HealthKit entitlements の設定が必要
- Info.plist に Privacy Description の追加が必要
- WatchConnectivity のメッセージ形式を既存実装と互換性を保つ

■ フェーズ実行方針
- Phase 1（セットアップ）から順に実行
- 各フェーズ完了時にビルド確認可能な状態を維持
- 並列タスク[P]は同時実行可
- tasks.md の各タスクを完了時に [X] マーク
```

---

## 実行順序フロー

```
1. /speckit.constitution  ← プロジェクト原則確立
        ↓
2. /speckit.specify       ← MVP仕様書作成
        ↓
3. /speckit.clarify       ← (optional) 曖昧領域の解消
        ↓
4. /speckit.plan          ← 実装計画・技術設計
        ↓
5. /speckit.checklist     ← (optional) 要件品質チェックリスト
        ↓
6. /speckit.tasks         ← タスク分解
        ↓
7. /speckit.analyze       ← (optional) 整合性分析
        ↓
8. /speckit.implement     ← 実装実行
```
