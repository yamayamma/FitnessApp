<!--
  Sync Impact Report
  ==================
  Version change: 0.0.0 → 1.0.0 (MAJOR: initial ratification)
  Modified principles: N/A (initial creation)
  Added sections:
    - Core Principles (5 principles)
    - Additional Constraints
    - Development Workflow
    - Governance
  Removed sections: N/A
  Templates requiring updates:
    - .specify/templates/plan-template.md ✅ compatible (Constitution Check section exists)
    - .specify/templates/spec-template.md ✅ compatible (no constitution-specific constraints)
    - .specify/templates/tasks-template.md ✅ compatible (phase structure aligns with Incremental Delivery)
  Follow-up TODOs: None
-->

# FitnessApp Constitution

## Core Principles

### I. Privacy-First（プライバシー最優先）

- ユーザーの健康・トレーニングデータはすべてローカルに保存
  しなければならない（HealthKit + ローカルDB）。
- MVP では外部 API への依存を一切持ってはならない。
- Apple App Store 審査基準（App Review Guidelines）に
  常に準拠しなければならない。
- クラウド同期は将来 Phase でオプトイン方式のみ許可される。
  デフォルトでデータが外部送信されてはならない。

**根拠**: 健康データは最もセンシティブな個人情報の一つであり、
ユーザー信頼とプラットフォーム審査の両方を担保するために
ローカルファースト設計を非交渉の原則とする。

### II. Minimal Friction Recording（記録の摩擦最小化）

- Apple Watch でのワークアウト記録は最小タップ数で
  完了できなければならない。
- 操作ステップを最適化し、トレーニング中の UI 操作による
  中断を最小にしなければならない。
- オフライン環境下で完全に動作しなければならない。
  ネットワーク接続を記録の前提条件にしてはならない。

**根拠**: トレーニング中のユーザーは手が塞がっており、
集中を維持する必要がある。記録の摩擦が高いとアプリの
利用継続率が著しく低下する。

### III. Extensible Architecture（拡張可能なアーキテクチャ）

- `sessionId`（UUID）で HealthKit エントリとローカル DB
  レコードを紐付けなければならない。
- データ構造は JSON 変換可能な形式を維持しなければならない。
- 将来の MCP サーバー公開・外部 AI 連携・wger API 連携に
  対応可能な境界（Boundary）設計をしなければならない。
- Phase 分離を厳守する:
  MVP → 管理強化 → MCP 公開 → 生活統合。

**根拠**: 初期段階で拡張ポイントを設計に組み込むことで、
将来の機能追加時にアーキテクチャの根本的な変更を回避する。

### IV. Platform-Native Design（プラットフォームネイティブ設計）

- SwiftUI + HealthKit + WatchConnectivity を標準 API
  として使用しなければならない。
- Apple Watch と iPhone の各デバイス特性に最適化した
  UI を提供しなければならない。
- watchOS / iOS の Human Interface Guidelines（HIG）に
  準拠しなければならない。

**根拠**: プラットフォームネイティブな設計により、OS アップデート
への追従コストを最小化し、ユーザーに一貫した体験を提供する。

### V. Incremental Delivery（段階的デリバリー）

- Phase 1（MVP）で最小限の機能セットをリリース可能な
  状態に保たなければならない。
- 各 Phase は独立してテスト・デプロイ可能でなければならない。
- MVP で明確に除外する機能:
  wger 連携、MCP サーバー、クラウド同期、AI 機能、
  自動スケジューリング、高度な分析・レポート。
- 除外機能を MVP に混入させてはならない。

**根拠**: スコープクリープを防止し、早期にユーザー価値を
届けるために、各 Phase の境界を厳密に定義する。

## Additional Constraints

- **言語 / フレームワーク**: Swift 5.9 以上、SwiftUI
- **対象 OS**: watchOS 10 以上、iOS 17 以上
- **ストレージ**:
  - HealthKit（`HKWorkout` 等の標準ワークアウト型）
  - SwiftData または CoreData（ローカル DB）
- **テストフレームワーク**: XCTest
- **OSS ライセンス**: 使用するすべてのサードパーティ
  ライブラリは OSS ライセンス準拠を確認しなければならない。
- **依存関係**: MVP では外部ネットワーク依存のライブラリを
  導入してはならない（Principle I 準拠）。

## Development Workflow

- **仕様駆動開発**: speckit を用いた仕様優先の開発プロセスに
  従わなければならない。Constitution → Spec → Plan → Tasks
  の順序で成果物を作成する。
- **ブランチ戦略**: 機能ブランチは `###-feature-name` 形式
  （例: `001-strength-training-system`）で作成する。
- **コードレビュー**: すべての変更は PR ベースのレビューを
  経てマージしなければならない。
- **Constitution 準拠確認**: PR レビュー時に、変更が本
  Constitution の原則に違反していないことを確認する。

## Governance

- 本 Constitution はすべての設計判断・実装判断における
  最上位の基準文書である。Constitution に矛盾する設計は
  許可されない。
- Constitution の変更はセマンティックバージョニングで管理する:
  - **MAJOR**: 原則の削除・根本的な再定義（後方互換性なし）
  - **MINOR**: 新しい原則・セクションの追加、既存原則の
    実質的な拡張
  - **PATCH**: 文言修正、タイポ修正、意味を変えない明確化
- 変更時は Sync Impact Report を更新し、影響を受ける
  テンプレート・成果物を特定しなければならない。
- コンプライアンスレビュー: 各 Phase の完了時に、成果物が
  Constitution の全原則に準拠していることを確認する。

**Version**: 1.0.0 | **Ratified**: 2026-02-15 | **Last Amended**: 2026-02-15
