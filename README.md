# FitnessApp

Apple Watch での筋力トレーニング記録アプリ。ワークアウトを Watch で実行・記録し、iPhone で履歴管理とメニュー管理を行う iOS/watchOS アプリ。

**プリンシプル**: Privacy-First（すべてのデータはローカル完結）・Minimal Friction（記録操作は最少タップ）

---

## 📋 Overview

### 特徴

- **Watch でのワークアウト実行**: ワンタップで重量・レップ記録、リアルタイム心拍数表示
- **HealthKit 統合**: セッション情報は HealthKit に自動保存
- **iPhone での履歴管理**: ワークアウト履歴を日付別に表示、統計情報を表示
- **メニュー管理**: iPhone で筋トレメニューを作成・編集し、Watch に同期
- **オフライン動作**: 外部 API 依存なし、完全ローカル動作
- **クラッシュリカバリ**: セット完了時にインクリメンタル保存、アプリクラッシュ時も安全

### ユースケース

1. **Watch でワークアウト実行** (US1)
   - メニュー選択 → ワークアウト開始
   - セット進行: 重量調整 → セット完了記録 → 次セット
   - ワークアウト終了時に HealthKit に自動保存

2. **iPhone で履歴確認** (US2)
   - 本日のワークアウト / 過去のセッション表示
   - セッション詳細: 種目別に完了セット数・重量・レップ確認

3. **メニュー管理** (US3)
   - iPhone でメニュー・種目を作成・編集
   - デフォルト重量・レップ数を設定
   - 変更は Watch に自動同期

4. **データ同期** (US4)
   - Watch → iPhone: ワークアウト結果を WatchConnectivity 経由で転送
   - iPhone → Watch: メニュー情報をアプリコンテキスト同期

---

## 🏗️ Architecture

### MVVM + Service Layer

```
Views (SwiftUI)
    ↓
ViewModels (@Observable)
    ↓
Services (HealthKit, WatchConnectivity, SwiftData)
    ↓
Models (@Model entities + Codable Transfer structs)
```

### データモデル

**iOS + watchOS 共有**:
- `WorkoutSession`: ワークアウトセッション（sessionId で HealthKit と紐付け）
- `ExerciseResult`: セッション内の種目実行結果
- `SetResult`: 各セットの重量・レップ・時刻
- `WorkoutStatus`: enum (active / paused / completed / cancelled)

**iOS のみ**:
- `TrainingMenu`: 筋トレメニュー
- `Exercise`: メニュー内の種目

**watchOS のみ**:
- `HealthKitRetryItem`: HealthKit 保存失敗時のリトライキュー（最大 10 回、指数バックオフ）

**Codable Transfer** (WatchConnectivity 用):
- `MenuTransfer`: メニュー同期（iPhone → Watch、updateApplicationContext）
- `WorkoutResultTransfer`: ワークアウト結果転送（Watch → iPhone、transferUserInfo）

### HealthKit 統合

- **フレームワーク**: HKWorkoutSession + HKLiveWorkoutBuilder + HKLiveWorkoutDataSource
- **Activity Type**: traditionalStrengthTraining
- **カスタムメタデータ**: 
  - `com.fitnessapp.sessionId`: クロスシステム識別子
  - `com.fitnessapp.menuId`: メニュー ID（オプション）
  - `com.fitnessapp.menuName`: メニュー名（表示用、非正規化）
- **保存失敗時**: 自動リトライキュー（5 秒 → 30 秒 → 5 分内で再試行、最大 10 回）

### WatchConnectivity 同期

**メニュー同期** (iPhone → Watch):
```swift
updateApplicationContext([String: Data])
// Key: "menus", Value: [MenuTransfer] の JSON Data
```

**結果転送** (Watch → iPhone):
```swift
transferUserInfo([String: Any])
// Key: "type" = "workoutResult"
// Key: "sessionId", "workoutData" (JSON Data)
```

---

## 📁 Project Structure

```
FitnessApp/
├── Models/
│   ├── WorkoutStatus.swift
│   ├── WorkoutSession.swift
│   ├── ExerciseResult.swift
│   ├── SetResult.swift
│   ├── TrainingMenu.swift          # iOS only
│   ├── Exercise.swift              # iOS only
│   ├── HealthKitRetryItem.swift    # watchOS only
│   └── TransferModels.swift        # Codable for WC
├── Services/
│   ├── WorkoutDataService.swift    # Watch → iPhone 結果受信・永続化
│   └── WatchConnectivityManager.swift
├── ViewModels/
│   ├── HistoryViewModel.swift      # 履歴表示
│   └── MenuViewModel.swift         # メニュー管理
├── Views/
│   ├── HomeView.swift              # ホーム（ナビゲーション）
│   ├── HistoryListView.swift
│   ├── WorkoutDetailView.swift
│   └── MenuManagementView.swift
├── FitnessAppApp.swift
├── WatchConnectivityManager.swift
└── Info.plist

FitnessAppWatch Watch App/
├── Models/
│   ├── WorkoutStatus.swift
│   ├── WorkoutSession.swift
│   ├── ExerciseResult.swift
│   ├── SetResult.swift
│   ├── HealthKitRetryItem.swift
│   └── TransferModels.swift
├── Services/
│   └── WatchHealthKitManager.swift # HKWorkoutSession 管理
├── ViewModels/
│   └── WorkoutViewModel.swift      # ワークアウト状態管理
├── Views/
│   ├── MenuSelectionView.swift     # メニュー選択
│   ├── ActiveWorkoutView.swift     # ワークアウト実行画面
│   └── WorkoutSummaryView.swift    # 完了画面
├── FitnessAppWatchApp.swift
├── WatchSessionManager.swift
└── WatchConnectivityManager.swift (TBD)
```

---

## 🚀 Setup

### 前提条件

- Xcode 15.0+
- iOS 17.0+ / watchOS 10.0+
- Apple Watch（実機テスト時）
- Apple Developer Account

### 1. リポジトリのクローン

```bash
git clone <repository-url>
cd FitnessApp
```

### 2. Xcode でプロジェクトを開く

```bash
open FitnessApp.xcodeproj
```

### 3. Target Membership 設定（重要）

Xcode の File Inspector で各ファイルの Target Membership を設定:

| ファイル | iOS | watchOS |
|---------|-----|---------|
| WorkoutStatus.swift | ✓ | ✓ |
| WorkoutSession.swift | ✓ | ✓ |
| ExerciseResult.swift | ✓ | ✓ |
| SetResult.swift | ✓ | ✓ |
| TrainingMenu.swift | ✓ | ✗ |
| Exercise.swift | ✓ | ✗ |
| HealthKitRetryItem.swift | ✗ | ✓ |
| TransferModels.swift | ✓ | ✓ |

### 4. Capabilities 確認

**iOS ターゲット**:
- Signing & Capabilities タブを開く
- "+ Capability" → "HealthKit" を追加（既設定の場合は確認）
- HealthKit にチェック: Read + Write

**watchOS ターゲット**:
- 同様に HealthKit を追加
- Background Modes > Workout Processing を有効化

### 5. ビルド & 実行

```bash
# iOS シミュレータ
xcodebuild clean build -scheme FitnessApp -destination 'platform=iOS Simulator,name=iPhone 15'

# watchOS シミュレータ
xcodebuild clean build -scheme 'FitnessAppWatch Watch App' -destination 'platform=watchOS Simulator,name=Apple Watch Series 8'
```

---

## 💡 Usage

### Apple Watch でワークアウト

1. **Watch アプリを開く** → "ワークアウト" 画面
2. メニューを選択（または "フリーワークアウト"）
3. **ワークアウト実行画面**:
   - 上部: 種目名、体重・レップ数、心拍数、経過時間
   - 下部: "次セット" ボタン
4. 重量・レップは上部をタップで調整（±2.5kg、±1 reps）
5. セット完了 → "次セット" をタップ
6. すべてのセット完了 → "終了" をタップ
7. **完了画面**: 統計情報（時間、種目数、総セット数）
8. HealthKit に自動保存

### iPhone でメニュー管理

1. ホーム → "メニュー管理"
2. メニュー追加 → 種目追加
3. デフォルト重量・レップ数を設定
4. "保存" → Watch に自動同期

### iPhone で履歴確認

1. ホーム → "ワークアウト履歴"
2. 本日 / 過去のセッションを表示
3. セッションをタップ → 種目別の詳細表示

---

## 🛠️ Technical Stack

| 分野 | 技術 |
|------|------|
| **言語** | Swift 5.9+ |
| **UI** | SwiftUI |
| **データ永続化** | SwiftData (@Model) |
| **HealthKit** | HKWorkoutSession, HKLiveWorkoutBuilder |
| **デバイス間通信** | WatchConnectivity (updateApplicationContext, transferUserInfo) |
| **アーキテクチャ** | MVVM + Service Layer |
| **ターゲット** | iOS 17+, watchOS 10+ |
| **テスト** | XCTest (準備中) |

---

## 📝 Features & Status

### MVP (Phase 1 - 完成)

- [x] US1: Watch ワークアウト実行（メニュー選択、セット進行、HealthKit 保存）
- [x] US2: iPhone 履歴表示（セッション一覧、詳細表示）
- [x] US3: iPhone メニュー管理（CRUD、Watch 同期）
- [x] US4: データパイプライン（Watch → iPhone 結果転送、deduplication）

### Future (Phase 2+)

- [ ] 詳細統計（総重量、総時間、進捗グラフ）
- [ ] iCloud 同期
- [ ] ワークアウト分析（インターバル自動検出など）
- [ ] ウィジェット（iOS/watchOS）
- [ ] Apple Health との統合（カロリー表示など）

---

## 🧪 Testing

```bash
# iOS ユニットテスト
xcodebuild test -scheme FitnessApp

# watchOS ユニットテスト
xcodebuild test -scheme 'FitnessAppWatch Watch App'
```

テストファイル: `FitnessAppTests/`, `FitnessAppWatch Watch AppTests/`

---

## 📚 Documentation

詳細な仕様は `/specs/001-strength-training-system/` を参照:

- [spec.md](specs/001-strength-training-system/spec.md) - 機能仕様書
- [plan.md](specs/001-strength-training-system/plan.md) - 実装計画
- [data-model.md](specs/001-strength-training-system/data-model.md) - データモデル詳細
- [quickstart.md](specs/001-strength-training-system/quickstart.md) - クイックスタート
- [research.md](specs/001-strength-training-system/research.md) - HealthKit/WatchConnectivity 調査
- [contracts/](specs/001-strength-training-system/contracts/) - API コントラクト

---

## ⚙️ Configuration

### Privacy & HealthKit

`Info.plist` に以下の記述が必要:

```xml
<key>NSHealthShareUsageDescription</key>
<string>ワークアウトデータを HealthKit に保存して管理します</string>
<key>NSHealthUpdateUsageDescription</key>
<string>ワークアウトセッション情報を HealthKit に記録します</string>
```

### Entitlements

`FitnessApp.entitlements` / `FitnessAppWatch Watch App.entitlements`:

```xml
<key>com.apple.healthkit</key>
<true/>
```

---

## 🤝 Contributing

1. feature branch を切る: `git checkout -b feature/improve-x`
2. 変更をコミット: `git commit -am 'Add feature X'`
3. Push: `git push origin feature/improve-x`
4. Pull Request を作成

---

## 📄 License

TBD

---

## 👤 Author

yamayamma  
Created: 2026-02-15

---

## 🐛 Troubleshooting

### ビルドエラー: "WorkoutStatus" が見つからない

**原因**: Target Membership が正しく設定されていない  
**解決**: Xcode で各モデルファイルの File Inspector を確認し、「Target Membership」セクションで適切なターゲットにチェック

### Watch にメニューが表示されない

**原因**: iPhone でメニューを作成していない、または同期未完了  
**解決**:
1. iPhone アプリを開く
2. "メニュー管理" でメニューを作成
3. Watch アプリを再起動（スワイプアップで閉じて再開）

### HealthKit 保存でエラー

**原因**: HealthKit 認可が得られていない  
**解決**:
1. iPhone 設定 → ヘルスケア → データアクセス → FitnessApp を確認
2. 読み込み・書き込みを両方有効化

### WatchConnectivity が同期されない

**原因**: iPhone と Watch が非接続状態  
**解決**:
1. iPhone と Watch が Bluetooth で接続していることを確認
2. 両アプリを同じ Wi-Fi に接続（推奨）

---

**Happy Fitness Tracking! 💪**
