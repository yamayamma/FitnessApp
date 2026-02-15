import WatchConnectivity
import SwiftData

/// iPhone側のWCSessionデリゲート
/// メニュー同期（iPhone→Watch）とワークアウト結果受信（Watch→iPhone）を管理
final class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    
    /// SwiftData ModelContextの参照（ワークアウト結果の永続化用）
    var modelContext: ModelContext?

    override private init() {
        super.init()
        activate()
    }

    private func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    // MARK: - WCSessionDelegate (必須)
    
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    func sessionDidBecomeInactive(_ session: WCSession) {}
    
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    // MARK: - Receive Workout Results (T026)
    
    /// Watchからのワークアウト結果をtransferUserInfo経由で受信
    func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String : Any] = [:]
    ) {
        // type == "workoutResult" のチェック
        guard let type = userInfo["type"] as? String,
              type == "workoutResult",
              let data = userInfo["data"] as? Data else {
            return
        }
        
        // WorkoutDataServiceに委譲して永続化
        if let context = modelContext {
            DispatchQueue.main.async {
                WorkoutDataService.receiveAndPersist(
                    transferData: data,
                    modelContext: context
                )
            }
        } else {
            print("ModelContext not available for workout result persistence")
        }
    }
    
    // MARK: - Send Menu Sync (T034で本格実装、ここは基盤)
    
    /// メニューデータをWatchに同期（updateApplicationContext）
    func syncMenus(_ menus: [MenuTransfer]) {
        guard WCSession.default.activationState == .activated else { return }
        
        #if os(iOS)
        guard WCSession.default.isWatchAppInstalled else {
            print("Watch app is not installed")
            return
        }
        #endif
        
        do {
            let data = try JSONEncoder.fitnessApp.encode(menus)
            let context: [String: Any] = [
                "menus": data,
                "timestamp": Date().timeIntervalSince1970
            ]
            try WCSession.default.updateApplicationContext(context)
            print("Menu sync sent: \(menus.count) menus")
        } catch {
            print("Failed to sync menus: \(error)")
        }
    }

    // MARK: - Legacy (互換性維持)
    
    func sendWorkoutName(_ name: String) {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(
            ["workout": name],
            replyHandler: nil
        )
    }
}
