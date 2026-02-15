import WatchConnectivity
import SwiftUI
import Combine

/// Watch側のWCSessionデリゲート・メニューキャッシュ管理
@Observable
final class WatchSessionManager: NSObject, WCSessionDelegate {
    /// 受信したメニューのキャッシュ
    var cachedMenus: [MenuTransfer] = []
    
    /// 受信したワークアウト名（レガシー互換）
    var receivedWorkout: String = "No Workout"
    
    /// 接続状態
    var isConnected: Bool = false

    override init() {
        super.init()
        activate()
    }

    private func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    // MARK: - WCSessionDelegate

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        DispatchQueue.main.async {
            self.isConnected = (activationState == .activated)
        }
        
        // アクティベーション完了後に既存のapplicationContextを処理
        if activationState == .activated {
            processApplicationContext(session.receivedApplicationContext)
        }
    }

    /// iPhoneからsendMessageで受信（レガシー互換）
    func session(
        _ session: WCSession,
        didReceiveMessage message: [String : Any]
    ) {
        DispatchQueue.main.async {
            if let workout = message["workout"] as? String {
                self.receivedWorkout = workout
            }
        }
    }
    
    /// iPhoneからupdateApplicationContextで受信（メニュー同期 FR-013）
    func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String : Any]
    ) {
        processApplicationContext(applicationContext)
    }
    
    // MARK: - Menu Processing
    
    /// applicationContextからメニューデータをデコード
    private func processApplicationContext(_ context: [String: Any]) {
        guard let menusData = context["menus"] as? Data else { return }
        
        do {
            let menus = try JSONDecoder.fitnessApp.decode([MenuTransfer].self, from: menusData)
            DispatchQueue.main.async {
                self.cachedMenus = menus
            }
        } catch {
            print("Failed to decode menus from applicationContext: \(error)")
            // デコード失敗時は既存メニューを保持
        }
    }
    
    // MARK: - Workout Result Transfer (T024)
    
    /// ワークアウト完了結果をiPhoneへ転送（FR-014, FR-016）
    /// completedセッションのみ送信。cancelledは送信しない。
    func sendWorkoutResult(session: WorkoutSession) {
        guard session.status == .completed else {
            print("Skipping transfer: session status is \(session.statusRawValue)")
            return
        }
        
        guard let endDate = session.endDate else {
            print("Skipping transfer: session has no endDate")
            return
        }
        
        // WorkoutResultTransferに変換
        let exerciseTransfers = session.exerciseResults
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { exercise in
                ExerciseResultTransfer(
                    exerciseId: exercise.exerciseId,
                    exerciseName: exercise.exerciseName,
                    sortOrder: exercise.sortOrder,
                    sets: exercise.setResults
                        .sorted { $0.setNumber < $1.setNumber }
                        .map { set in
                            SetResultTransfer(
                                setNumber: set.setNumber,
                                weight: set.weight,
                                reps: set.reps,
                                completedAt: set.completedAt
                            )
                        }
                )
            }
        
        let resultTransfer = WorkoutResultTransfer(
            sessionId: session.sessionId,
            startDate: session.startDate,
            endDate: endDate,
            menuId: session.menuId,
            menuName: session.menuName,
            totalDuration: session.totalDuration,
            status: session.statusRawValue,
            exercises: exerciseTransfers
        )
        
        // JSONエンコードしてtransferUserInfoで送信
        do {
            let data = try JSONEncoder.fitnessApp.encode(resultTransfer)
            let userInfo: [String: Any] = [
                "type": "workoutResult",
                "sessionId": session.sessionId.uuidString,
                "data": data
            ]
            WCSession.default.transferUserInfo(userInfo)
            print("Workout result transferred: \(session.sessionId)")
        } catch {
            print("Failed to encode workout result: \(error)")
        }
    }
}

