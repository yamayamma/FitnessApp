# Watch UX Checklist: 筋力トレーニング記録システム

**Purpose**: Apple Watch UI/UX に関する要件の完全性・明確性・一貫性を検証する
**Created**: 2026-02-15
**Feature**: [spec.md](../spec.md) | [quickstart.md](../quickstart.md)

## Requirement Completeness — Screen Flow

- [ ] CHK001 — Watch 側の画面遷移フロー（メニュー選択 → ワークアウト実行 → サマリー）の全パスが仕様で網羅されているか？ [Completeness, Gap]
- [ ] CHK002 — メニュー選択画面の要件は定義されているか？（メニュー一覧の表示形式、メニューなしでの開始オプション等） [Gap]
- [ ] CHK003 — ワークアウト完了後のサマリー画面の要件は定義されているか？（表示項目、操作可能なアクション） [Gap]
- [ ] CHK004 — ワークアウト中の Always On Display (AOD) 表示要件は定義されているか？（watchOS 10+ のワークアウトアプリは AOD 対応が推奨される） [Gap, Coverage]
- [ ] CHK005 — 「メニューなし」でワークアウトを開始する場合のフローは定義されているか？（種目をどのように追加するか） [Gap, Edge Case]

## Requirement Clarity — Set Progression UI

- [ ] CHK006 — FR-004 の「上部にセット数・重量等の可変値をワンタップで記録・変更できるエリア」のレイアウト要件は具体的なサイズ・配置で定義されているか？ [Clarity, Spec §FR-004]
- [ ] CHK007 — 重量値の変更 UI の要件は明確か？（「プリセット値から選択または増減」と記載されているが、プリセットの定義/増減幅が未定義） [Clarity, Spec §US1 Scenario 3]
- [ ] CHK008 — レップ数の入力/変更方法の要件は定義されているか？（重量変更は記載されているがレップ数の変更方法が未記載） [Gap, Spec §FR-004]
- [ ] CHK009 — 「次セット」ボタンの「フルワイド」のサイズ要件は具体的な寸法またはレイアウト制約で定義されているか？ [Clarity, Spec §FR-004]
- [ ] CHK010 — セット間の遷移時のフィードバック要件（触覚フィードバック、視覚的な遷移アニメーション等）は定義されているか？ [Gap]
- [ ] CHK011 — 最終セット完了時の「次セット」ボタンの挙動要件は定義されているか？（自動的に次の種目に遷移？ワークアウト完了に遷移？ユーザーが選択？） [Gap, Edge Case]
- [ ] CHK011a — ★ 種目間の遷移操作の要件は定義されているか？（FR-004 はセット進行のみで、種目 A → 種目 B への遷移フローが完全に未定義。MVP の中核操作にギャップあり） [**Critical Gap**, Spec §FR-004]

## Requirement Completeness — Workout Controls

- [ ] CHK012 — 一時停止/再開/キャンセル/完了のコントロール UI の配置・操作方法の要件は定義されているか？（完了時の確認 UI、キャンセル時の誤タップ防止確認を含む） [Gap, Spec §FR-001]
- [ ] CHK013 — キャンセル操作の確認ダイアログの要件は定義されているか？（誤タップでデータ損失のリスクがあるため重要） [Gap, Edge Case]
- [ ] CHK014 — ワークアウト中の通知ハンドリング要件は定義されているか？（HKWorkoutSession は通知を抑制するが、その挙動の要件化が必要） [Gap]
- [ ] CHK015 — ★ 種目間遮移の UI フローが要件として定義されているか？（FR-004 はセット進行のみ。複数種目を含むメニューでの種目切り替え操作が未定義） [**Critical Gap**, Spec §FR-004]

## Requirement Completeness — State Display

- [ ] CHK016 — 経過時間表示のフォーマット要件は定義されているか？（MM:SS? HH:MM:SS?） [Clarity, Spec §FR-002]
- [ ] CHK017 — 心拍数表示の更新頻度・表示位置の要件は定義されているか？ [Clarity, Spec §FR-003]
- [ ] CHK018 — paused 状態の視覚的フィードバック要件は定義されているか？（タイマー停止の表示方法、背景色変更等） [Gap, Spec §FR-001]

## Scenario Coverage — Error & Empty States

- [ ] CHK019 — メニュー未同期時（Watch にメニューが 0 件）の空状態 UI 要件は定義されているか？ [Gap, Edge Case]
- [ ] CHK020 — HealthKit 許可未取得時の Watch 側 UI ガイダンス要件は定義されているか？ [Gap, Edge Case]
- [ ] CHK021 — FR-018 のクラッシュリカバリダイアログの Watch 側 UI 要件は具体的に定義されているか？（ボタンテキスト、ダイアログの表示タイミング等） [Clarity, Spec §FR-018]
- [ ] CHK022 — ローディング状態（HealthKit 初期化中、メニュー読み込み中）の UI 要件は定義されているか？ [Gap]

## watchOS HIG Compliance

- [ ] CHK023 — watchOS Human Interface Guidelines への準拠が要件として具体的に記載されているか？（NFR として「HIG 準拠」の記述はあるが、具体的なガイドライン項目が未特定） [Clarity, Constitution §IV]
- [ ] CHK024 — Apple Watch の画面サイズバリエーション（40mm/41mm/44mm/45mm/49mm）への対応要件は定義されているか？ [Gap, Coverage]
- [ ] CHK025 — Digital Crown の役割要件は定義されているか？（スクロール以外の用途、例: 重量値の増減） [Gap]
- [ ] CHK026 — ワークアウト中の手首下げ動作（画面消灯）時の表示復帰要件は定義されているか？（ワークアウト画面が即座に復帰するか、ロック画面か） [Gap, Edge Case]

## Notes

- Check items off as completed: `[x]`
- Add comments or findings inline
- Link to relevant resources or documentation
- Items are numbered sequentially for easy reference
