import Foundation
import UserNotifications
import SwiftUI

/// 通知管理マネージャー
@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isNotificationEnabled = false
    @Published var notificationTime = Date()
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private let center = UNUserNotificationCenter.current()
    private let notificationIdentifier = "mood_daily_reminder"
    
    private init() {
        loadSettings()
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    /// 通知許可をリクエスト
    func requestAuthorization() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.authorizationStatus = granted ? .authorized : .denied
                self.isNotificationEnabled = granted
                if granted {
                    scheduleNotification()
                }
                saveSettings()
            }
        } catch {
            #if DEBUG
            print("通知許可リクエストエラー: \(error)")
            #endif
        }
    }
    
    /// 認可状態をチェック
    private func checkAuthorizationStatus() {
        Task {
            let settings = await center.notificationSettings()
            await MainActor.run {
                self.authorizationStatus = settings.authorizationStatus
                self.isNotificationEnabled = (settings.authorizationStatus == .authorized)
            }
        }
    }
    
    // MARK: - Notification Scheduling
    
    /// 通知をスケジュール
    func scheduleNotification() {
        guard authorizationStatus == .authorized else { return }
        
        // 既存の通知をキャンセル
        center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
        
        guard isNotificationEnabled else { return }
        
        // 通知内容を作成
        let content = UNMutableNotificationContent()
        content.title = "きょうの気分を残しませんか？"
        content.body = "今日の気分をスタンプで記録しましょう 😊"
        content.sound = .default
        content.categoryIdentifier = "MOOD_REMINDER"
        
        // 時刻をコンポーネントに分解
        let components = Calendar.current.dateComponents([.hour, .minute], from: notificationTime)
        
        // 毎日の指定時刻にトリガー
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        // リクエストを作成
        let request = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: content,
            trigger: trigger
        )
        
        // 通知をスケジュール
        center.add(request) { error in
            if let error = error {
                #if DEBUG
                print("通知スケジュールエラー: \(error)")
                #endif
            } else {
                #if DEBUG
                print("通知がスケジュールされました: \(components.hour!):\(String(format: "%02d", components.minute!))")
                #endif
            }
        }
    }
    
    /// 通知をキャンセル
    func cancelNotification() {
        center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
        #if DEBUG
        print("通知がキャンセルされました")
        #endif
    }
    
    // MARK: - Settings Management
    
    /// 通知設定を更新
    func updateNotificationSettings(isEnabled: Bool, time: Date) {
        self.isNotificationEnabled = isEnabled
        self.notificationTime = time
        
        if isEnabled && authorizationStatus == .authorized {
            scheduleNotification()
        } else if !isEnabled {
            cancelNotification()
        }
        
        saveSettings()
    }
    
    /// 設定を保存
    private func saveSettings() {
        UserDefaults.standard.set(isNotificationEnabled, forKey: "notification_enabled")
        UserDefaults.standard.set(notificationTime, forKey: "notification_time")
    }
    
    /// 設定を読み込み
    private func loadSettings() {
        isNotificationEnabled = UserDefaults.standard.bool(forKey: "notification_enabled")
        
        if let savedTime = UserDefaults.standard.object(forKey: "notification_time") as? Date {
            notificationTime = savedTime
        } else {
            // デフォルト時刻: 20:00
            let calendar = Calendar.current
            notificationTime = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
        }
    }
    
    // MARK: - Notification Actions
    
    /// 通知アクションを設定
    func setupNotificationActions() {
        // 記録画面を開くアクション
        let recordAction = UNNotificationAction(
            identifier: "RECORD_MOOD",
            title: "記録する",
            options: [.foreground]
        )
        
        // 後で通知アクション
        let laterAction = UNNotificationAction(
            identifier: "REMIND_LATER",
            title: "後で",
            options: []
        )
        
        // カテゴリーを作成
        let category = UNNotificationCategory(
            identifier: "MOOD_REMINDER",
            actions: [recordAction, laterAction],
            intentIdentifiers: [],
            options: []
        )
        
        // カテゴリーを設定
        center.setNotificationCategories([category])
    }
    
    // MARK: - Debug
    
    /// pending通知を確認（デバッグ用）
    func checkPendingNotifications() {
        #if DEBUG
        center.getPendingNotificationRequests { requests in
            print("Pending notifications: \(requests.count)")
            for request in requests {
                print("- \(request.identifier): \(request.content.title)")
                if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                    print("  Time: \(trigger.dateComponents)")
                }
            }
        }
        #endif
    }
}