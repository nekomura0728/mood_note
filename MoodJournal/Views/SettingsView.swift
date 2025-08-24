import SwiftUI
import UserNotifications

/// 設定画面
struct SettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var proManager = ProManager.shared
    @State private var showingTimePicker = false
    @State private var showProUpgrade = false
    
    var body: some View {
        NavigationView {
            List {
                // Pro版セクション  
                proVersionSection
                
                // デバッグセクション
                Section {
                    // Pro版切り替え
                    HStack {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .foregroundColor(.purple)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pro版ステータス")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                            
                            Text("シミュレーター用デバッグ機能")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { proManager.isPro },
                            set: { isEnabled in
                                if isEnabled {
                                    proManager.unlockProFeatures()
                                } else {
                                    proManager.resetProStatus()
                                }
                            }
                        ))
                    }
                    
                    // サンプルデータ追加
                    Button(action: {
                        DataController.shared.addDebugSampleData()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("サンプルデータ追加")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text("過去2週間のテストデータを生成")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                } header: {
                    Text("🛠️ デバッグ機能")
                } footer: {
                    Text("Pro機能をテストするためのデバッグ機能です。")
                }
                
                // 通知設定セクション
                notificationSection
                
                // アプリ情報セクション
                aboutSection
                
                // 簡易デバッグセクション  
                Section {
                    Button("Pro版を有効にする（デバッグ用）") {
                        UserDefaults.standard.set(true, forKey: "is_pro_user")
                        UserDefaults.standard.set(Date(), forKey: "pro_purchase_date")
                        // アプリを再起動して確認
                    }
                    .foregroundColor(.orange)
                    
                    Button("サンプルデータを追加（デバッグ用）") {
                        // 簡易サンプルデータ追加
                        let dataController = DataController.shared
                        let calendar = Calendar.current
                        let now = Date()
                        
                        // 過去7日間のサンプルデータ
                        for i in 0..<7 {
                            guard let date = calendar.date(byAdding: .day, value: -i, to: now) else { continue }
                            let moods: [Mood] = [.happy, .normal, .tired, .angry, .sleepy]
                            let randomMood = moods.randomElement() ?? .normal
                            let texts = ["今日は良い日", "普通の日", "疲れた", "イライラ", "眠い"]
                            
                            dataController.createEntry(mood: randomMood, text: texts.randomElement())
                        }
                    }
                    .foregroundColor(.blue)
                    
                } header: {
                    Text("デバッグ機能")
                } footer: {
                    Text("Pro機能をテストするためのデバッグ機能です。")
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
            .background(Theme.gradientBackground.ignoresSafeArea())
            .onAppear {
                notificationManager.setupNotificationActions()
            }
            .sheet(isPresented: $showingTimePicker) {
                timePickerSheet
            }
        }
    }
    
    // MARK: - Views
    
    private var proVersionSection: some View {
        Section {
            if proManager.isPro {
                // 購入済みの場合
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pro版 利用中")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                        
                        Text("パーソナルコーチング、詳細レポート")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("✓")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.green)
                }
            } else {
                // 未購入の場合
                NavigationLink(destination: ProVersionView()) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pro版にアップグレード")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("¥300買い切り - パーソナルコーチング、詳細レポート")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        } header: {
            Text(proManager.isPro ? "Pro版" : "アップグレード")
        } footer: {
            if !proManager.isPro {
                Text("Pro版ではパーソナルコーチング、詳細レポートをご利用いただけます。")
            }
        }
    }
    
    private var notificationSection: some View {
        Section {
            // 通知ON/OFF
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("毎日のリマインダー")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                    
                    Text("気分記録を忘れないようにお知らせします")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { notificationManager.isNotificationEnabled },
                    set: { isEnabled in
                        if isEnabled && notificationManager.authorizationStatus != .authorized {
                            Task {
                                await notificationManager.requestAuthorization()
                            }
                        } else {
                            notificationManager.updateNotificationSettings(
                                isEnabled: isEnabled,
                                time: notificationManager.notificationTime
                            )
                        }
                    }
                ))
            }
            
            // 通知時刻設定
            if notificationManager.isNotificationEnabled {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("通知時刻")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                        
                        Text(formatTime(notificationManager.notificationTime))
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Button("変更") {
                        showingTimePicker = true
                    }
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                }
            }
            
            // 認可状態の表示
            if notificationManager.authorizationStatus == .denied {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("通知が無効になっています")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.red)
                        
                        Text("設定アプリで通知を有効にしてください")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("設定を開く") {
                        openAppSettings()
                    }
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.blue)
                }
            }
        } header: {
            Text("通知")
        } footer: {
            Text("毎日指定した時刻に気分記録のリマインダーが届きます")
        }
    }
    
    
    private var aboutSection: some View {
        Section {
            // アプリ名・バージョン
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("きぶん日記")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                    
                    Text("Version 1.0.0")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // プライバシー
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.green)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("プライバシー重視")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                    
                    Text("データは端末内にのみ保存されます")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
        } header: {
            Text("アプリについて")
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Time Picker Sheet

extension SettingsView {
    private var timePickerSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("通知時刻を設定")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .padding(.top)
                
                DatePicker(
                    "時刻",
                    selection: Binding(
                        get: { notificationManager.notificationTime },
                        set: { newTime in
                            notificationManager.updateNotificationSettings(
                                isEnabled: notificationManager.isNotificationEnabled,
                                time: newTime
                            )
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        showingTimePicker = false
                    }
                }
            }
        }
    }
}

/// Pro版機能の項目
struct ProFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.orange)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

#Preview {
    SettingsView()
}