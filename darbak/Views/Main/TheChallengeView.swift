//
//  TheChallengeView.swift
//  darbak
//
//  Created by Ali Alsuwaiyel on 10/02/1447 AH.
//

import SwiftUI
import AVFoundation

struct TheChallengeView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    @EnvironmentObject var challengeProgress: ChallengeProgress
    @ObservedObject var user: User = User()
    @State private var showingCamera = false
    @State private var showingColorCamera = false
    @State private var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    @State private var showStepGateAlert = false
    @State private var stepGateMessage: String = ""
    
    private var dailyGoal: Int {
        user.goalSteps > 0 ? user.goalSteps : 10000
    }
    
    let selectedChallengeIndex: Int?
    var onBack: (() -> Void)? = nil
    
    init(selectedChallengeIndex: Int? = nil, onBack: (() -> Void)? = nil) {
        self.selectedChallengeIndex = selectedChallengeIndex
        self.onBack = onBack
    }
    
    // Use centralized challenges data
    private let allChallenges = ChallengesData.shared.challenges
    
    private var currentChallenge: Challenge {
        let index = selectedChallengeIndex ?? challengeProgress.selectedChallengeIndex
        let safeIndex = min(index, allChallenges.count - 1)
        return allChallenges[safeIndex]
    }
    
    private var stepsPerPhoto: Int {
        let total = max(1, currentChallenge.totalPhotos)
        return Int(ceil(Double(dailyGoal) / Double(total)))
    }
    
    private func remainingStepsForNextPhoto() -> Int {
        // First photo allowed immediately at challenge start
        // Subsequent photos require stepsPerPhoto more steps each
        let requiredSteps = stepsPerPhoto * challengeProgress.completedPhotos
        return max(0, requiredSteps - healthKitManager.currentSteps)
    }
    
    var progressValue: Double {
        min(1.0, Double(healthKitManager.currentSteps) / Double(dailyGoal))
    }
    
    var body: some View {
        ZStack {
            // Background
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        if let onBack = onBack {
                            onBack()
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(DesignSystem.Typography.title2)
                            .foregroundColor(DesignSystem.Colors.text)
                    }
                    
                    Spacer()
                    
                    Text("التحدي")
                        .font(DesignSystem.Typography.title)
                        .fontWeight(.semibold)
                        .primaryText()
                    
                    Spacer()
                    
                    // Invisible button for symmetry
                    Button(action: {}) {
                        Image(systemName: "chevron.right")
                            .font(DesignSystem.Typography.title2)
                            .opacity(0)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .padding(.top, DesignSystem.Spacing.sm)
                
                Spacer()
                
                // Steps counter card
                VStack(spacing: DesignSystem.Spacing.lg) {
                    Text("خطواتك للحين")
                        .font(DesignSystem.Typography.title3)
                        .secondaryText()
                    
                    if healthKitManager.isAuthorized {
                        Text(healthKitManager.currentSteps.englishFormatted)
                            .font(DesignSystem.Typography.largeTitle)
                            .accentText()
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.8), value: healthKitManager.currentSteps)
                    } else {
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            Text("--")
                                .font(DesignSystem.Typography.largeTitle)
                                .foregroundColor(.gray)
                            
                            Text("يرجى السماح للتطبيق بالوصول للبيانات الصحية")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.warning)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, DesignSystem.Spacing.xxxl)
                            
                            Button("تحديث الحالة") {
                                healthKitManager.refreshAuthorizationStatus()
                            }
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.accent)
                            .padding(.top, DesignSystem.Spacing.xs)
                        }
                    }
                }
                .padding(DesignSystem.Spacing.xl)
                .cardStyle()
                .padding(.horizontal, DesignSystem.Spacing.xl)
                
                Spacer()
                
                // Progress bar card
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.sm) {
                    HStack {
                        Text("الهدف اليومي")
                            .font(DesignSystem.Typography.headline)
                            .primaryText()
                        
                        Spacer()
                        
                        Text(dailyGoal.englishFormatted)
                            .font(DesignSystem.Typography.title3)
                            .accentText()
                    }
                    
                    // Progress bar
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                            .frame(height: 12)
                            .foregroundColor(DesignSystem.Colors.secondaryBackground)
                        
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                            .frame(width: max(0, (UIScreen.main.bounds.width - 80) * progressValue), height: 12)
                            .foregroundColor(DesignSystem.Colors.primary)
                            .animation(.easeInOut(duration: 0.5), value: progressValue)
                    }
                }
                .padding(DesignSystem.Spacing.xl)
                .cardStyle()
                .padding(.horizontal, DesignSystem.Spacing.xl)
                
#if DEBUG
                // Testing override button (DEBUG only) to bypass step gating
                Button(action: {
                    if challengeProgress.isMaxPhotosReached { return }
                    if !challengeProgress.isChallengeInProgress {
                        challengeProgress.startChallenge()
                    }
                    if currentChallenge.isColorChallenge {
                        requestCameraPermissionAndShowColorCamera()
                    } else if currentChallenge.hasAI {
                        requestCameraPermissionAndShowCamera()
                    } else {
                        openStandardCamera()
                    }
                }) {
                    Text("تجاوز للاختبار")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundColor(DesignSystem.Colors.warning)
                        .padding(.top, DesignSystem.Spacing.sm)
                }
#endif
                
                // Challenge description card
                VStack(spacing: DesignSystem.Spacing.md) {
                    Text(currentChallenge.fullTitle)
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.medium)
                        .primaryText()
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if currentChallenge.isColorChallenge {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "paintpalette.fill")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.accent)
                            
                            Text("تحدي الألوان - وجه الكاميرا للأشياء الملونة")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.accent)
                        }
                    } else if !currentChallenge.hasAI {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "info.circle.fill")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.warning)
                            
                            Text("استخدم كاميرا الهاتف العادية لهذا التحدي")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.warning)
                        }
                    }
                }
                .padding(DesignSystem.Spacing.xl)
                .cardStyle()
                .padding(.horizontal, DesignSystem.Spacing.xl)
                
                Spacer()
                
                // Camera button
                Button(action: {
                    // Check if max photos reached
                    if challengeProgress.isMaxPhotosReached {
                        return // Do nothing if limit reached
                    }
                    
                    // Step-based gating: split daily goal over number of photos
                    let remaining = remainingStepsForNextPhoto()
                    if remaining > 0 {
                        let threshold = stepsPerPhoto * challengeProgress.completedPhotos
                        let thresholdText = threshold.englishFormatted
                        stepGateMessage = "تقدر تلتقط الصورة القادمة اذا وصلت  \(thresholdText) خطوة."
                        showStepGateAlert = true
                        return
                    }
                    
                    // Start challenge if not already started
                    if !challengeProgress.isChallengeInProgress {
                        challengeProgress.startChallenge()
                    }
                    
                    if currentChallenge.isColorChallenge {
                        requestCameraPermissionAndShowColorCamera()
                    } else if currentChallenge.hasAI {
                        requestCameraPermissionAndShowCamera()
                    } else {
                        openStandardCamera()
                    }
                }) {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: getCameraIcon())
                            .font(.system(size: 50, weight: .medium))
                            .foregroundColor(challengeProgress.isMaxPhotosReached ? .gray : DesignSystem.Colors.text)
                        
                        Text(getCameraButtonText())
                            .font(DesignSystem.Typography.title2)
                            .fontWeight(.medium)
                            .foregroundColor(challengeProgress.isMaxPhotosReached ? .gray : DesignSystem.Colors.text)
                    }
                    .frame(width: 300, height: 150)
                    .background(challengeProgress.isMaxPhotosReached ? Color.gray.opacity(0.1) : DesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                            .stroke(challengeProgress.isMaxPhotosReached ? Color.gray : DesignSystem.Colors.border, lineWidth: 2.5)
                    )
                    .cornerRadius(DesignSystem.CornerRadius.large)
                    .shadow(color: DesignSystem.Shadows.medium, radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal, DesignSystem.Spacing.xl)
                
                Spacer()
                
                // Progress indicator card
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Text("التقدم")
                        .font(DesignSystem.Typography.headline)
                        .secondaryText()
                    
                    Text("\(challengeProgress.completedPhotos.englishFormatted)/\(currentChallenge.totalPhotos.englishFormatted)")
                        .font(DesignSystem.Typography.title2)
                        .fontWeight(.medium)
                        .accentText()
                }
                .padding(DesignSystem.Spacing.lg)
                .cardStyle()
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .padding(.bottom, DesignSystem.Spacing.xl)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            checkCameraPermission()
            // Reset progress if challenge has changed
            if let selectedIndex = selectedChallengeIndex,
               selectedIndex != challengeProgress.selectedChallengeIndex {
                challengeProgress.selectChallenge(index: selectedIndex)
            }
        }
        .sheet(isPresented: $showingCamera) {
            if currentChallenge.hasAI {
                LiveDetectionCameraView(
                    isPresented: $showingCamera,
                    challengeProgress: challengeProgress,
                    onDetectionComplete: {
                        handleDetectionComplete()
                    }
                )
            }
        }
        .sheet(isPresented: $showingColorCamera) {
            if currentChallenge.isColorChallenge, let targetColor = currentChallenge.targetColor {
                ColorDetectionCameraView(
                    isPresented: $showingColorCamera,
                    challengeProgress: challengeProgress,
                    onDetectionComplete: {
                        handleDetectionComplete()
                    },
                    targetColor: targetColor
                )
            }
        }
        .alert(isPresented: $showStepGateAlert) {
            Alert(
                title: Text("توك بدري"),
                message: Text(stepGateMessage),
                dismissButton: .default(Text("طيب"))
            )
        }
    }
    
    // MARK: - Camera Methods
    private func checkCameraPermission() {
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    private func requestCameraPermissionAndShowCamera() {
        switch cameraPermissionStatus {
        case .authorized:
            showingCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.cameraPermissionStatus = granted ? .authorized : .denied
                    if granted {
                        self.showingCamera = true
                    }
                }
            }
        case .denied, .restricted:
            // Show alert to go to settings
            break
        @unknown default:
            break
        }
    }
    
    private func requestCameraPermissionAndShowColorCamera() {
        switch cameraPermissionStatus {
        case .authorized:
            showingColorCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.cameraPermissionStatus = granted ? .authorized : .denied
                    if granted {
                        self.showingColorCamera = true
                    }
                }
            }
        case .denied, .restricted:
            // Show alert to go to settings
            break
        @unknown default:
            break
        }
    }
    
    private func getCameraIcon() -> String {
        if challengeProgress.isMaxPhotosReached {
            return "checkmark.circle"
        } else if currentChallenge.isColorChallenge {
            return "camera.filters"
        } else if currentChallenge.hasAI {
            return "camera.viewfinder"
        } else {
            return "camera"
        }
    }
    
    private func getCameraButtonText() -> String {
        if challengeProgress.isMaxPhotosReached {
            return "تم إكمال التحدي"
        } else if currentChallenge.isColorChallenge {
            return "اكتشف اللون"
        } else if currentChallenge.hasAI {
            return "خذ صورة"
        } else {
            return "افتح الكاميرا"
        }
    }
    
    private func handleDetectionComplete() {
        challengeProgress.incrementProgress()
        
        // Update competition progress
        updateCompetitionProgress()
        
        // Check if challenge is completed
        if challengeProgress.isMaxPhotosReached {
            challengeProgress.completeChallenge()
        }
    }
    
    private func updateCompetitionProgress() {
        let competitionManager = CompetitionManager.shared
        let gameCenterManager = GameCenterManager.shared
        
        guard let currentPlayer = gameCenterManager.currentPlayer else { return }
        
        // Check if player is in active race
        if let activeRace = competitionManager.getActiveRace(for: currentPlayer.gamePlayerID) {
            competitionManager.updateRaceProgress(
                raceId: activeRace.id.uuidString,
                playerId: currentPlayer.gamePlayerID,
                completedPhotos: challengeProgress.completedPhotos,
                dailyGoalProgress: healthKitManager.currentSteps
            )
        }
    }
    
    private func openStandardCamera() {
        // For non-AI challenges (cats, birds), open standard camera
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("Camera not available")
            return
        }
        
        // For now, just show an alert since we can't implement full image picker in this scope
        // In a real implementation, you would present UIImagePickerController
        print("Opening standard camera for \(currentChallenge.fullTitle)")
        
        // Simulate photo taken for demo purposes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            handleDetectionComplete()
        }
    }
}

#Preview {
    TheChallengeView()
        .environmentObject(ChallengeProgress())
}
