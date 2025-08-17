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
    @EnvironmentObject var user: User
    @State private var showingCamera = false
    @State private var showingColorCamera = false
    @State private var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    @State private var showGiveUpAlert = false
    @State private var showingPostChallenge = false
    
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
    
//    let disablePhotoButton = remainingStepsForNextPhoto() <= 0 || challengeProgress.completedPhotos < currentChallenge.totalPhotos
    
    var body: some View {
        ZStack {
            // Background
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        showGiveUpAlert = true;
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
                
                
                
                
                // Progress bar card
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.md) {
                    HStack {
                        Text("الهدف اليومي")
                            .font(DesignSystem.Typography.headline)
                            .primaryText()
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Text(healthKitManager.currentSteps.englishFormatted)
                                .font(DesignSystem.Typography.title3)
                                .accentText()
                                .contentTransition(.numericText())
                                .animation(.easeInOut(duration: 0.8), value: healthKitManager.currentSteps)
                            
                            Text("/")
                                .font(DesignSystem.Typography.title3)
                            
                            Text(dailyGoal.englishFormatted)
                                .font(DesignSystem.Typography.title3)
                                .accentText()
                           
                        }
                   
                       
                    }
                    
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                            .frame(height: 12)
                            .foregroundColor(DesignSystem.Colors.secondaryBackground)
                        
                        ZStack(alignment: .trailing){
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                .frame(width: max(0, (UIScreen.main.bounds.width - 80) * progressValue), height: 12)
                                .foregroundColor(DesignSystem.Colors.primary)
                                .animation(.easeInOut(duration: 0.5), value: progressValue)
                            Image("Star").resizable().frame(width: 50,height: 50).padding(.trailing, -15)
                        }
                    }
                }
                .padding(DesignSystem.Spacing.xl)
                .cardStyle()
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .padding(.top, DesignSystem.Spacing.xl)
                
                Spacer()
                
                // Large challenge image display
                challengeImageView
                
                
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
                Spacer()
                
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
                
                
                // Camera button
                Button(action: {
                    // Check if max photos reached
                    if challengeProgress.isMaxPhotosReached {
                        return // Do nothing if limit reached
                    }
                    
                    guard remainingStepsForNextPhoto() <= 0 else { return }
                    
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
                        
                        if challengeProgress.isMaxPhotosReached {
                            Text("تم إكمال التحدي")
                                .font(DesignSystem.Typography.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                        } else if remainingStepsForNextPhoto() > 0 {
                            Text("تبقى \(remainingStepsForNextPhoto().englishFormatted) خطوة")
                                .font(DesignSystem.Typography.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                        } else {
                            Text(getCameraButtonText())
                                .font(DesignSystem.Typography.title2)
                                .fontWeight(.medium)
                                .foregroundColor(DesignSystem.Colors.text)
                        }
                        
                        
                        Text("\(challengeProgress.completedPhotos.englishFormatted)/\(currentChallenge.totalPhotos.englishFormatted)")
                            .font(DesignSystem.Typography.title2)
                            .fontWeight(.medium)
                            .accentText()
                    }
                    .frame(width: 300, height: 150)
                    .background(
                        (challengeProgress.isMaxPhotosReached || remainingStepsForNextPhoto() > 0)
                            ? Color.gray.opacity(0.1)
                            : DesignSystem.Colors.cardBackground
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                            .stroke(
                                (challengeProgress.isMaxPhotosReached || remainingStepsForNextPhoto() > 0)
                                    ? Color.gray
                                    : DesignSystem.Colors.border,
                                lineWidth: 2.5
                            )
                    )
                    .cornerRadius(DesignSystem.CornerRadius.large)
                    .shadow(color: DesignSystem.Shadows.medium, radius: 4, x: 0, y: 2)
                }
                .disabled(challengeProgress.isMaxPhotosReached || remainingStepsForNextPhoto() > 0)
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .padding(.top, DesignSystem.Spacing.xxl)
                
//                Spacer()
                
                
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            checkCameraPermission()
            // Reset progress if challenge has changed
            if let selectedIndex = selectedChallengeIndex,
               selectedIndex != challengeProgress.selectedChallengeIndex {
                challengeProgress.selectChallenge(index: selectedIndex)
                // Clear photos when challenge changes
                PolaroidGalleryManager.shared.startChallengeSession()
            }
        }
        .onDisappear {
            // Clear photos when challenge ends/exits
            PolaroidGalleryManager.shared.endChallengeSession()
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
        .fullScreenCover(isPresented: $showingPostChallenge) {
            PostChallengeView(onBackToHome: {
                // Reset challenge progress completely to force navigation to home
                challengeProgress.resetProgress()
                
                // Dismiss the full screen cover
                showingPostChallenge = false
            })
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
        }
        .alert(isPresented: $showGiveUpAlert) {
            Alert(
                title: Text("توك بدري"),
                message: Text("خلاص ما عاد أقدر"),
                primaryButton: .default(Text("متأكد"), action: {
                    if let onBack = onBack {
                        onBack()
                    }
                }),
                secondaryButton: .default(Text("لا"))
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
            // Mark photos as preserved when challenge is completed
            PolaroidGalleryManager.shared.completeChallengeSession()
            challengeProgress.completeChallenge()
            
            // Navigate to post challenge view
            showingPostChallenge = true
        }
    }
    
    private func updateCompetitionProgress() {
        // Competition progress tracking removed
    }
    
    // MARK: - Challenge Image Display View
    private var challengeImageView: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(height: 320)
            .overlay(
                Image(currentChallenge.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(15)
            )
            .cornerRadius(15)
            .padding(.horizontal, 20)
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
        .environmentObject(User())
}
