# HealthKit & Privacy Checklist: 筋力トレーニング記録システム

**Purpose**: HealthKit 統合とプライバシーに関する要件の完全性・明確性・一貫性を検証する
**Created**: 2026-02-15
**Feature**: [spec.md](../spec.md) | [contracts/healthkit.md](../contracts/healthkit.md)

## Requirement Completeness — HealthKit Authorization

- [ ] CHK001 — HealthKit 許可リクエストのタイミング要件は明確に定義されているか？（「初回起動時」のみか、ワークアウト開始前にも再確認するかが不明瞭） [Clarity, Contract §Authorization Flow]
- [ ] CHK002 — HealthKit 許可対象のデータ型（Share/Read）は網羅的に列挙されているか？ [Completeness, Contract §Required Permissions]
- [ ] CHK003 — `.heartRate` と `.activeEnergyBurned` の Read 権限が「将来」とされているが、FR-003（心拍数表示）は MVP 要件として存在する。矛盾はないか？ [Conflict, Spec §FR-003 vs Contract §Required Permissions]
- [ ] CHK004 — ユーザーが HealthKit 許可を拒否した場合の UI フィードバック要件は定義されているか？（「ローカル DB のみに保存」の技術動作は定義済みだが、ユーザーへの通知/説明が未定義） [Gap]
- [ ] CHK005 — HealthKit 許可を後から設定アプリで変更した場合のアプリ側の挙動要件は定義されているか？ [Gap, Edge Case]

## Requirement Completeness — Privacy Description

- [ ] CHK006 — Info.plist に設定すべき `NSHealthShareUsageDescription`（Read）のテキスト要件は仕様に含まれているか？ [Gap]
- [ ] CHK007 — Info.plist に設定すべき `NSHealthUpdateUsageDescription`（Write）のテキスト要件は仕様に含まれているか？ [Gap]
- [ ] CHK008 — Privacy Description のテキストがユーザーに対してデータ利用目的を十分に説明する内容として定義されているか？ [Gap, Apple Guidelines]

## Requirement Clarity — HealthKit Data Storage

- [ ] CHK009 — `HKWorkoutActivityType.traditionalStrengthTraining` の選択根拠と、他の Activity Type（`.functionalStrengthTraining` 等）を除外した理由は要件として記載されているか？ [Clarity, Contract §Activity Type]
- [ ] CHK010 — `HKWorkoutSessionLocationType.indoor` 固定の要件は定義されているが、屋外トレーニングのユースケースが将来あり得るかの検討は記載されているか？ [Coverage, Contract §Location Type]
- [ ] CHK011 — カスタム metadata キー（`com.fitnessapp.sessionId` 等）の命名規則が reverse-domain 形式であることの根拠は記載されているか？ [Clarity, Contract §Custom Metadata Keys]
- [ ] CHK012 — `menuId` が空文字列（メニューなし開始時）として metadata に保存される設計だが、`nil` ではなく空文字列を選択した理由の要件は明確か？ [Clarity, Contract §End Workout]

## Requirement Completeness — Auto-Retry Queue

- [ ] CHK013 — リトライ回数の上限値は具体的な数値で定義されているか？（5+ 以降の「App 次回起動時」のみで、最大リトライ回数が不明確） [Clarity, Contract §Retry Strategy]
- [ ] CHK014 — `abandoned` ステータス（最大リトライ超過）に到達した場合のユーザー通知・UI 表示の要件は定義されているか？ [Gap, Contract §Retry Queue Model]
- [ ] CHK015 — リトライキュー自体の永続化方式（SwiftData? UserDefaults?）の要件は定義されているか？ [Gap, Contract §Retry Queue Model]
- [ ] CHK016 — バックグラウンドリトライの実行トリガー要件は明確か？（BGTaskScheduler 使用？ App foreground 復帰時のみ？） [Clarity, Contract §保存フロー]

## Apple App Store Guidelines Compliance

- [ ] CHK017 — HealthKit データの使用目的が Apple Review Guidelines §5.1.3（Health and Health Research）に準拠することが要件として確認されているか？ [Coverage, Spec §NFR-003]
- [ ] CHK018 — HealthKit で取得したデータを広告やデータマイニングに使用しないことが要件として明記されているか？（Apple Guidelines 要求事項） [Gap, Apple Guidelines]
- [ ] CHK019 — HealthKit のデータが iCloud バックアップの対象外であることの認識が要件に含まれているか？ [Gap, Apple Guidelines]
- [ ] CHK020 — Constitution §I Privacy-First の「外部 API 依存なし」がすべてのデータフロー（HealthKit → ローカル DB → WatchConnectivity）で遵守されているか？ [Consistency, Constitution §I]

## Scenario Coverage — Error & Edge Cases

- [ ] CHK021 — HealthKit が利用不可能なデバイス（HealthKit 非対応の iPad 等）での動作要件は定義されているか？ [Gap, Edge Case]
- [ ] CHK022 — HealthKit データベースのストレージ容量不足時の要件は定義されているか？ [Gap, Edge Case]
- [ ] CHK023 — HealthKit の `HKError` の全エラーコードに対するハンドリング要件は定義されているか？（Contract に 5 種のみ記載、他のエラーコードの扱いが未定義） [Completeness, Contract §Error Handling]

## Notes

- Check items off as completed: `[x]`
- Add comments or findings inline
- Link to relevant resources or documentation
- Items are numbered sequentially for easy reference
