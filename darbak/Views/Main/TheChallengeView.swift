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
    
    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    if let onBack = onBack {
                        onBack()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                Text("التحدي")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Invisible button for symmetry
                Button(action: {}) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .opacity(0)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            Spacer()
            
            // Steps counter
            VStack(spacing: 5) {
                Text("خطواتك للحين")
                    .font(.title3)
                    .foregroundColor(.gray)
                
                if healthKitManager.isAuthorized {
                    Text(numberFormatter.string(from: NSNumber(value: healthKitManager.currentSteps)) ?? "\(healthKitManager.currentSteps)")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundColor(.black)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.8), value: healthKitManager.currentSteps)
                } else {
                    VStack(spacing: 8) {
                        Text("--")
                            .font(.system(size: 80, weight: .bold))
                            .foregroundColor(.gray)
                        
                        Text("يرجى السماح للتطبيق بالوصول للبيانات الصحية")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
            }
            .padding(.top, 40)
            
            Spacer()
            
            // Progress bar
            VStack(alignment: .trailing, spacing: 8) {
                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 8)
                        .frame(height: 20)
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black, lineWidth: 2)
                        )
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 6)
                        .frame(width: max(0, (UIScreen.main.bounds.width - 80) * progressValue - 4), height: 16)
                        .foregroundColor(Color(hex: "1B5299"))
                        .offset(x: 2)
                        .animation(.easeInOut(duration: 0.5), value: progressValue)
                }
                
                Text("\(dailyGoal)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 40)
            
#if DEBUG
            // Testing override button (DEBUG only) to bypass step gating
            Button(action: {
                if challengeProgress.isMaxPhotosReached { return }
                if !challengeProgress.isChallengeInProgress {
                    challengeProgress.startChallenge()
                }
                if currentChallenge.hasAI {
                    requestCameraPermissionAndShowCamera()
                } else {
                    openStandardCamera()
                }
            }) {
                Text("تجاوز للاختبار")
                    .font(.footnote)
                    .foregroundColor(.orange)
                    .padding(.top, 8)
            }
#endif
            
            // Challenge description
            VStack(spacing: 5) {
                                        Text(currentChallenge.fullTitle)
                    .font(.body)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                
                if !currentChallenge.hasAI {
                    Text("استخدم كاميرا الهاتف العادية لهذا التحدي")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            
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
                    let thresholdText = numberFormatter.string(from: NSNumber(value: threshold)) ?? "\(threshold)"
                    stepGateMessage = "تقدر تلتقط الصورة القادمة اذا وصلت  \(thresholdText) خطوة."
                    showStepGateAlert = true
                    return
                }
                
                // Start challenge if not already started
                if !challengeProgress.isChallengeInProgress {
                    challengeProgress.startChallenge()
                }
                
                if currentChallenge.hasAI {
                    requestCameraPermissionAndShowCamera()
                } else {
                    openStandardCamera()
                }
            }) {
                VStack(spacing: 12) {
                    Image(systemName: currentChallenge.hasAI ? "camera.viewfinder" : "camera")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundColor(challengeProgress.isMaxPhotosReached ? .gray : .black)
                    
                    Text(challengeProgress.isMaxPhotosReached ? "تم إكمال التحدي" : (currentChallenge.hasAI ? "خذ صورة" : "افتح الكاميرا"))
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(challengeProgress.isMaxPhotosReached ? .gray : .black)
                    
                   
                }
                .frame(width: 300, height: 150)
                .background(challengeProgress.isMaxPhotosReached ? Color.gray.opacity(0.1) : (currentChallenge.hasAI ? Color.white : Color.gray.opacity(0.1)))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(challengeProgress.isMaxPhotosReached ? Color.gray : (currentChallenge.hasAI ? Color.black : Color.gray), lineWidth: 2.5)
                )
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Progress indicator
            Text("\(challengeProgress.completedPhotos)/\(currentChallenge.totalPhotos)")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.black)
                .padding(.bottom, 40)
            
            Spacer()
        }
        .background(Color.white)
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
    
    private func handleDetectionComplete() {
        challengeProgress.incrementProgress()
        
        // Check if challenge is completed
        if challengeProgress.isMaxPhotosReached {
            challengeProgress.completeChallenge()
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
