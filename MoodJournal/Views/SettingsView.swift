import SwiftUI
import UserNotifications

/// 設定画面
struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var proManager = ProManager.shared
    @State private var showingTimePicker = false
    @State private var showProUpgrade = false
    
    var body: some View {
        NavigationView {
            List {
                // Pro版セクション  
                proVersionSection
                
#if DEBUG
                // デバッグセクション
                Section {
                    // Pro版切り替え
                    HStack {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .foregroundColor(.purple)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(LocalizedStringKey("debug.pro_status"))
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                            
                            Text(LocalizedStringKey("debug.pro_toggle"))
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
                    
                    // 日本語サンプルデータ追加
                    Button(action: {
                        DataController.shared.addJapaneseSampleData()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(LocalizedStringKey("debug.japanese_sample"))
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text(LocalizedStringKey("debug.japanese_description"))
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    // 英語サンプルデータ追加
                    Button(action: {
                        DataController.shared.addEnglishSampleData()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(LocalizedStringKey("debug.english_sample"))
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text(LocalizedStringKey("debug.english_description"))
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                } header: {
                    Text(LocalizedStringKey("debug.section"))
                } footer: {
                    Text(LocalizedStringKey("debug.footer"))
                }
#endif
                
                // 通知設定セクション
                notificationSection
                
                // アプリ情報セクション
                aboutSection
                
            }
            .navigationTitle(LocalizedStringKey("settings.title"))
            .navigationBarTitleDisplayMode(.large)
            .background(Theme.gradientBackground(for: colorScheme).ignoresSafeArea())
            .onAppear {
                notificationManager.setupNotificationActions()
            }
            .sheet(isPresented: $showingTimePicker) {
                timePickerSheet
            }
        }
    }
    
  private var proVersionSection: some View {
        Section {
            if proManager.isPro {
                // 購入済みの場合
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStringKey("settings.pro_active"))
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                        
                        Text(LocalizedStringKey("settings.pro_features"))
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
                            Text(LocalizedStringKey("settings.pro_upgrade"))
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text(LocalizedStringKey("settings.pro_price"))
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
            Text(LocalizedStringKey(proManager.isPro ? "settings.pro_section" : "settings.pro_section"))
        } footer: {
            if !proManager.isPro {
                Text(LocalizedStringKey("settings.pro_features"))
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
                    Text(LocalizedStringKey("settings.daily_reminder"))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                    
                    Text(LocalizedStringKey("settings.reminder_description"))
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
                        Text(LocalizedStringKey("settings.notification_time"))
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                        
                        Text(formatTime(notificationManager.notificationTime))
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Button(LocalizedStringKey("settings.change")) {
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
                        Text(LocalizedStringKey("settings.notification_disabled"))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.red)
                        
                        Text(LocalizedStringKey("settings.open_settings"))
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(LocalizedStringKey("settings.open_settings")) {
                        openAppSettings()
                    }
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.blue)
                }
            }
        } header: {
            Text(LocalizedStringKey("settings.notifications"))
        } footer: {
            Text(LocalizedStringKey("settings.reminder_description"))
        }
    }
    
    
    private var aboutSection: some View {
        Section {
            // アプリ名・バージョン
            Button(action: {
                openWebsite("https://nekomura0728.github.io/mood_note/")
            }) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.pink)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("きぶん日記")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text(LocalizedStringKey("settings.version"))
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
            
            // プライバシーポリシー
            Button(action: {
                openWebsite("https://nekomura0728.github.io/mood_note/privacy.html")
            }) {
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStringKey("settings.privacy_policy"))
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text(LocalizedStringKey("settings.data_protection"))
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
            
        } header: {
            Text(LocalizedStringKey("settings.app_info"))
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func openWebsite(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Time Picker Sheet

extension SettingsView {
    private var timePickerSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(LocalizedStringKey("time_picker.title"))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .padding(.top)
                
                DatePicker(
                    LocalizedStringKey("time_picker.title"),
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
                    Button(LocalizedStringKey("time_picker.done")) {
                        showingTimePicker = false
                    }
                }
            }
        }
    }
}

/// Pro版機能の項目
struct ProFeatureRow: View {
    @Environment(\.colorScheme) private var colorScheme
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