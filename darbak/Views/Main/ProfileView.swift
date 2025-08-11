//
//  ProfileView.swift
//  darbak
//
//  Created by Assistant on ${DATE}
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var user: User
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var achievementManager: AchievementManager
    @EnvironmentObject var notificationManager: NotificationManager
    
    @State private var showingSettings = false
    @State private var showingAchievements = false
    @State private var showingDataInsights = false
    @State private var showingEditProfile = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header
                HStack {
                    Text("الملف الشخصي")
                        .font(DesignSystem.Typography.largeTitle)
                        .primaryText()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(DesignSystem.Typography.title2)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Profile Header
                VStack(spacing: 15) {
                    // Profile Image
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.primaryLight)
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(DesignSystem.Colors.primary)
                        
                        // Edit button
                        Button(action: {
                            showingEditProfile = true
                        }) {
                            Image(systemName: "pencil.circle.fill")
                                .font(DesignSystem.Typography.title2)
                                .foregroundColor(DesignSystem.Colors.primary)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                        .offset(x: 35, y: 35)
                    }
                    .onTapGesture {
                        showingEditProfile = true
                    }
                    
                    // User Name
                    VStack(spacing: 5) {
                        Text(user.name.isEmpty ? "اضغط لإضافة اسمك" : user.name)
                            .font(DesignSystem.Typography.title2)
                            .foregroundColor(user.name.isEmpty ? DesignSystem.Colors.secondaryText : DesignSystem.Colors.text)
                        
                        if !user.name.isEmpty {
                            Text("عضو منذ \(memberSinceDate)")
                                .font(DesignSystem.Typography.caption)
                                .secondaryText()
                        }
                    }
                    .onTapGesture {
                        showingEditProfile = true
                    }
                }
                .padding(.horizontal, 20)
                
                // Stats Cards
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 2), spacing: 15) {
                    StatsCard(
                        title: "خطواتك اليوم",
                        value: healthKitManager.currentSteps.englishFormatted,
                        icon: "figure.walk",
                        color: DesignSystem.Colors.primary
                    )
                    
                    StatsCard(
                        title: "هدفك اليومي",
                        value: (user.goalSteps > 0 ? user.goalSteps : 10000).englishFormatted,
                        icon: "target",
                        color: DesignSystem.Colors.success
                    )
                    
                    StatsCard(
                        title: "الإنجازات",
                        value: achievementManager.getUnlockedAchievements().count.englishFormatted,
                        icon: "trophy.fill",
                        color: DesignSystem.Colors.accent
                    )
                    
                    StatsCard(
                        title: "التحديات المكتملة",
                        value: achievementManager.getCompletedChallengesCount().englishFormatted,
                        icon: "checkmark.circle.fill",
                        color: Color.purple
                    )
                }
                .padding(.horizontal, 20)
                
                // Menu Items
                VStack(spacing: 12) {
                    ProfileMenuItem(
                        icon: "trophy.fill",
                        title: "الإنجازات والشارات",
                        subtitle: "\(achievementManager.getUnlockedAchievements().count) إنجاز مفتوح",
                        action: { showingAchievements = true }
                    )
                    
                    ProfileMenuItem(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "تحليل البيانات",
                        subtitle: "اطلع على إحصائياتك المفصلة",
                        action: { showingDataInsights = true }
                    )
                    
                    ProfileMenuItem(
                        icon: "person.crop.circle",
                        title: "تعديل الملف الشخصي",
                        subtitle: "اضبط معلوماتك الشخصية",
                        action: { showingEditProfile = true }
                    )
                    
                    ProfileMenuItem(
                        icon: "heart.fill",
                        title: "الصحة والأذونات",
                        subtitle: healthKitManager.isAuthorized ? "متصل بـ HealthKit" : "غير متصل",
                        action: { requestHealthKitPermission() }
                    )
                    
                    ProfileMenuItem(
                        icon: "bell.fill",
                        title: "الإشعارات",
                        subtitle: notificationManager.isAuthorized ? "مفعل" : "غير مفعل",
                        action: { showingSettings = true }
                    )
                    
                    ProfileMenuItem(
                        icon: "gamecontroller.fill",
                        title: "Game Center",
                        subtitle: GameCenterManager.shared.isAuthenticated ? "متصل" : "غير متصل",
                        action: { requestGameCenterLogin() }
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 100)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(notificationManager)
                .environmentObject(user)
        }
        .sheet(isPresented: $showingAchievements) {
            AchievementsView()
                .environmentObject(achievementManager)
        }
        .sheet(isPresented: $showingDataInsights) {
            DataInsightsView()
                .environmentObject(user)
                .environmentObject(healthKitManager)
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
                .environmentObject(user)
        }
    }
    
    private func requestHealthKitPermission() {
        print("🏥 Health permission button tapped")
        
        if healthKitManager.isAuthorized {
            // Already authorized, show alert with options to refresh or go to settings
            let alert = UIAlertController(
                title: "إذن الصحة",
                message: "تم منح الإذن بالفعل للوصول إلى بيانات الصحة. يمكنك إدارة الأذونات من تطبيق الصحة في الإعدادات.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "تحديث الحالة", style: .default) { _ in
                self.healthKitManager.refreshAuthorizationStatus()
            })
            
            alert.addAction(UIAlertAction(title: "فتح الإعدادات", style: .default) { _ in
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            })
            
            alert.addAction(UIAlertAction(title: "حسناً", style: .cancel))
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(alert, animated: true)
            }
        } else {
            // Not authorized, show options to try again or refresh status
            let alert = UIAlertController(
                title: "إذن الصحة",
                message: "يحتاج التطبيق للوصول إلى بيانات الخطوات لتتبع نشاطك اليومي. إذا منحت الإذن بالفعل، جرب تحديث الحالة.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "طلب الإذن", style: .default) { _ in
                self.healthKitManager.retryAuthorization()
            })
            
            alert.addAction(UIAlertAction(title: "تحديث الحالة", style: .default) { _ in
                self.healthKitManager.refreshAuthorizationStatus()
            })
            
            alert.addAction(UIAlertAction(title: "فتح الإعدادات", style: .default) { _ in
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            })
            
            alert.addAction(UIAlertAction(title: "إلغاء", style: .cancel))
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(alert, animated: true)
            }
        }
    }
    
    private func requestGameCenterLogin() {
        print("🎮 Game Center login button tapped")
        
        if GameCenterManager.shared.isAuthenticated {
            // Already authenticated, show alert with status
            let alert = UIAlertController(
                title: "Game Center",
                message: "أنت متصل بالفعل بـ Game Center. يمكنك الوصول إلى المتصدرين والإنجازات.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "حسناً", style: .default))
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(alert, animated: true)
            }
        } else {
            // Not authenticated, try to authenticate
            GameCenterManager.shared.presentGameCenterLogin()
        }
    }
    
    private var memberSinceDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "ar")
        return formatter.string(from: Date())
    }
    

}

struct StatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.title2)
                .foregroundColor(color)
            
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(value)
                    .font(DesignSystem.Typography.title2)
                    .primaryText()
                
                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .secondaryText()
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xl)
        .cardStyle(backgroundColor: DesignSystem.Colors.secondaryBackground)
    }
}

struct ProfileMenuItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.lg) {
                Image(systemName: icon)
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(DesignSystem.Colors.primary)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(title)
                        .font(DesignSystem.Typography.headline)
                        .primaryText()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(subtitle)
                        .font(DesignSystem.Typography.caption)
                        .secondaryText()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Image(systemName: "chevron.left")
                    .font(DesignSystem.Typography.caption)
                    .secondaryText()
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .cardStyle()
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var user: User
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("الإشعارات") {
                    Toggle("التذكير اليومي", isOn: .init(
                        get: { notificationManager.dailyReminderEnabled },
                        set: { notificationManager.toggleDailyReminder($0) }
                    ))
                    
                    Toggle("إنجاز الهدف", isOn: .init(
                        get: { notificationManager.goalAchievementEnabled },
                        set: { notificationManager.toggleGoalAchievement($0) }
                    ))
                    
                    Toggle("تذكير السلسلة", isOn: .init(
                        get: { notificationManager.streakReminderEnabled },
                        set: { notificationManager.toggleStreakReminder($0) }
                    ))
                    
                    Toggle("إشعارات التحديات", isOn: .init(
                        get: { notificationManager.challengeNotificationsEnabled },
                        set: { notificationManager.toggleChallengeNotifications($0) }
                    ))
                }
                
                Section("معلومات التطبيق") {
                    HStack {
                        Text("الإصدار")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("الإعدادات")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("تم") { dismiss() })
        }
    }
}

struct EditProfileView: View {
    @EnvironmentObject var user: User
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var goalSteps: Int = 10000
    @State private var age: Int = 0
    @State private var weight: Int = 0
    @State private var height: Int = 0
    @State private var sleepingHours: Int = 8
    
    var body: some View {
        NavigationView {
            Form {
                Section("المعلومات الأساسية") {
                    TextField("الاسم", text: $name)
                    
                    Stepper("العمر: \(age)", value: $age, in: 1...120)
                    
                    Stepper("الوزن: \(weight) كغ", value: $weight, in: 30...200)
                    
                    Stepper("الطول: \(height) سم", value: $height, in: 100...250)
                    
                    Stepper("ساعات النوم: \(sleepingHours)", value: $sleepingHours, in: 4...12)
                }
                
                Section("الأهداف") {
                    Stepper("الهدف اليومي: \(goalSteps) خطوة", value: $goalSteps, in: 1000...50000, step: 500)
                }
            }
            .navigationTitle("تعديل الملف الشخصي")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("إلغاء") { dismiss() },
                trailing: Button("حفظ") { saveProfile() }
            )
            .onAppear {
                loadCurrentValues()
            }
        }
    }
    
    private func loadCurrentValues() {
        name = user.name
        goalSteps = user.goalSteps
        age = user.age
        weight = user.weight
        height = user.height
        sleepingHours = user.sleepingHours
    }
    
    private func saveProfile() {
        user.name = name
        user.goalSteps = goalSteps
        user.age = age
        user.weight = weight
        user.height = height
        user.sleepingHours = sleepingHours
        user.saveToDefaults()
        dismiss()
    }
}

#Preview {
    ProfileView()
        .environmentObject(User())
        .environmentObject(HealthKitManager())
        .environmentObject(AchievementManager())
        .environmentObject(NotificationManager())
}
