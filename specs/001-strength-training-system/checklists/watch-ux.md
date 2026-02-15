# Watch UX Checklist: 筋力トレーニング記録システム

**Purpose**: Apple Watch UI/UX に関する要件の完全性・明確性・一貫性を検証する
**Created**: 2026-02-15
**Evaluated**: 2026-02-15 (Re-evaluated)
**Feature**: [spec.md](../spec.md) | [quickstart.md](../quickstart.md)
**Result**: 16/27 PASS (59.3%) ← 前回 0/27 (0%)

## Requirement Completeness — Screen Flow

- [x] CHK001 — Watch 側の画面遷移フロー（メニュー選択 → ワークアウト実行 → サマリー）の全パスが仕様で網羅されているか？ [Completeness, Gap]
  > ✅ spec.md FR-021 に「メニュー一覧 → ワークアウト実行 → サマリー」の画面遷移フロー定義、FR-018/FR-019/FR-020 で分岐パスも定義。
- [ ] CHK002 — メニュー選択画面の要件は定義されているか？（メニュー一覧の表示形式、メニューなしでの開始オプション等） [Gap]
  > ❌ FR-025 にメニューなし開始オプションあるが、一覧の表示形式（List? Grid?）、各行の情報量、ソート順は未定義。
- [x] CHK003 — ワークアウト完了後のサマリー画面の要件は定義されているか？（表示項目、操作可能なアクション） [Gap]
  > ✅ FR-021 に「サマリー画面には合計時間・種目数・総セット数を表示し、「閉じる」ボタンでメニュー一覧に戻る」と定義。
- [x] CHK004 — ワークアウト中の Always On Display (AOD) 表示要件は定義されているか？ [Gap, Coverage]
  > ✅ Out of Scope に「Always On Display (AOD) カスタマイズ」として明示的に除外。
- [ ] CHK005 — 「メニューなし」でワークアウトを開始する場合のフローは定義されているか？（種目をどのように追加するか） [Gap, Edge Case]
  > ❌ FR-025 にメニューなし開始オプションの提供は記載あるが、その場合の種目追加 UI フローの詳細は未定義。

## Requirement Clarity — Set Progression UI

- [ ] CHK006 — FR-004 の「上部にセット数・重量等の可変値をワンタップで記録・変更できるエリア」のレイアウト要件は具体的なサイズ・配置で定義されているか？ [Clarity, Spec §FR-004]
  > ❌ FR-004 で上下 2 エリアの配置と操作仕様は改善されたが、具体的サイズ比率・マージン等のレイアウト制約は未定義。
- [ ] CHK007 — 重量値の変更 UI の要件は明確か？ [Clarity, Spec §US1 Scenario 3]
  > ❌ FR-004 に増減幅（±2.5kg）は追加されたが、UI 種別（Picker? ステッパー? ボタン?）は未定義。
- [x] CHK008 — レップ数の入力/変更方法の要件は定義されているか？ [Gap, Spec §FR-004]
  > ✅ FR-004 に「レップ数変更は ±1 刻みの増減操作で行う」と追加。
- [ ] CHK009 — 「次セット」ボタンの「フルワイド」のサイズ要件は具体的な寸法またはレイアウト制約で定義されているか？ [Clarity, Spec §FR-004]
  > ❌ FR-004 の「フルワイド」に具体的寸法・高さ・パディング等の記載なし。
- [ ] CHK010 — セット間の遷移時のフィードバック要件（触覚フィードバック、視覚的な遷移アニメーション等）は定義されているか？ [Gap]
  > ❌ 全ドキュメントに記載なし。
- [x] CHK011 — 最終セット完了時の「次セット」ボタンの挙動要件は定義されているか？ [Gap, Edge Case]
  > ✅ FR-019 に「最終セット完了時に自動で次種目に遷移」「最終種目の最終セット完了時はワークアウト完了確認画面に遷移」と定義。
- [x] CHK011a — ★ 種目間の遷移操作の要件は定義されているか？ [**Critical Gap → RESOLVED**, Spec §FR-019]
  > ✅ FR-019 に「メニューの種目順序 sortOrder に従い自動遷移。スワイプ操作で任意の種目にスキップ/戻り可」と定義。Critical Gap 解消。

## Requirement Completeness — Workout Controls

- [ ] CHK012 — 一時停止/再開/キャンセル/完了のコントロール UI の配置・操作方法の要件は定義されているか？ [Gap, Spec §FR-001]
  > ❌ FR-020/FR-022 でキャンセル確認・一時停止表示は追加されたが、ボタン配置（常時表示/スワイプ表示等）の具体的要件は未定義。
- [x] CHK013 — キャンセル操作の確認ダイアログの要件は定義されているか？ [Gap, Edge Case]
  > ✅ FR-020 に「確認ダイアログ（「ワークアウトをキャンセルしますか？」/「キャンセル」「続行」ボタン）を表示」と定義。
- [ ] CHK014 — ワークアウト中の通知ハンドリング要件は定義されているか？ [Gap]
  > ❌ 全ドキュメントに記載なし。
- [x] CHK015 — ★ 種目間遷移の UI フローが要件として定義されているか？ [**Critical Gap → RESOLVED**, Spec §FR-019]
  > ✅ FR-019 で種目間の自動遷移・スワイプ操作によるナビゲーションが定義され Critical Gap 解消。

## Requirement Completeness — State Display

- [x] CHK016 — 経過時間表示のフォーマット要件は定義されているか？ [Clarity, Spec §FR-024]
  > ✅ FR-024 に「経過時間は MM:SS、1 時間以上は H:MM:SS」と明確に定義。
- [ ] CHK017 — 心拍数表示の更新頻度・表示位置の要件は定義されているか？ [Clarity, Spec §FR-003]
  > ❌ FR-003 に「bpm」は追加されたが、更新頻度（リアルタイム? 5秒間隔?）、画面内の表示位置は依然として未定義。
- [x] CHK018 — paused 状態の視覚的フィードバック要件は定義されているか？ [Gap, Spec §FR-022]
  > ✅ FR-022 に「経過時間表示の一時停止、背景色またはアイコンの変化」により視覚的フィードバックを定義。

## Scenario Coverage — Error & Empty States

- [x] CHK019 — メニュー未同期時（Watch にメニューが 0 件）の空状態 UI 要件は定義されているか？ [Gap, Edge Case]
  > ✅ FR-025 + Edge Cases に空状態 UI（ガイダンスメッセージ）とメニューなし開始オプションを定義。
- [x] CHK020 — HealthKit 許可未取得時の Watch 側 UI ガイダンス要件は定義されているか？ [Gap, Edge Case]
  > ✅ healthkit.md Authorization Flow step 2 + spec.md Edge Cases に HealthKit 拒否時の UI ガイダンスを定義。
- [x] CHK021 — FR-018 のクラッシュリカバリダイアログの Watch 側 UI 要件は具体的に定義されているか？ [Clarity, Spec §FR-018]
  > ✅ FR-018 に「Watch アプリ起動直後（メニュー一覧表示前）に表示」「ボタンテキストは『続行』『破棄』」「破棄時は cancelled に遷移しメニュー一覧へ戻る」と具体化。
- [ ] CHK022 — ローディング状態（HealthKit 初期化中、メニュー読み込み中）の UI 要件は定義されているか？ [Gap]
  > ❌ 全ドキュメントに記載なし。

## watchOS HIG Compliance

- [ ] CHK023 — watchOS Human Interface Guidelines への準拠が要件として具体的に記載されているか？ [Clarity, Constitution §IV]
  > ❌ Constitution §IV に一般記述あるが、具体的なガイドライン項目が未特定。
- [x] CHK024 — Apple Watch の画面サイズバリエーションへの対応要件は定義されているか？ [Gap, Coverage]
  > ✅ Out of Scope に「Apple Watch 画面サイズ別の個別レイアウト最適化（SwiftUI アダプティブレイアウトに依存）」として明示的に除外。
- [x] CHK025 — Digital Crown の役割要件は定義されているか？ [Gap]
  > ✅ Out of Scope に「Digital Crown による値入力操作」として明示的に除外。
- [ ] CHK026 — ワークアウト中の手首下げ動作（画面消灯）時の表示復帰要件は定義されているか？ [Gap, Edge Case]
  > ❌ spec.md / Out of Scope いずれにも未記載。
