//
//  LiveDetectionCameraView.swift
//  darbak
//
//  Created by AI Assistant for live traffic light detection
//

import SwiftUI
import AVFoundation
import CoreML
import Vision
import AudioToolbox

struct LiveDetectionCameraView: View {
    @Binding var isPresented: Bool
    @ObservedObject var challengeProgress: ChallengeProgress
    let onDetectionComplete: () -> Void
    
    @StateObject private var cameraManager = LiveDetectionCameraManager()
    @State private var currentZoomFactor: CGFloat = 1.0
    @State private var showingDetectionFeedback = false
    @State private var lastZoomFactor: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Clean camera preview with pinch gesture
            CameraPreviewView(cameraManager: cameraManager)
                .ignoresSafeArea()
                .scaleEffect(1.0)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let newZoom = max(1.0, min(10.0, lastZoomFactor * value))
                            cameraManager.setZoomFactor(newZoom)
                            currentZoomFactor = newZoom
                        }
                        .onEnded { _ in
                            lastZoomFactor = currentZoomFactor
                        }
                )
            
            // Modern UI overlay with app design system
            VStack(spacing: 0) {
                // Top section with challenge title and controls
                VStack(spacing: DesignSystem.Spacing.md) {
                    // Challenge title header
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Text("التحدي الحالي")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(challengeProgress.challengeTitle)
                            .font(DesignSystem.Typography.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                    }
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.7),
                                Color.black.opacity(0.5)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Top controls row
                    HStack {
                        // Cancel button
                        Button(action: {
                            isPresented = false
                        }) {
                            HStack(spacing: DesignSystem.Spacing.sm) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("إلغاء")
                                    .font(DesignSystem.Typography.headline)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                            .padding(.vertical, DesignSystem.Spacing.md)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                        }
                        
                        Spacer()
                        
                        // Camera switch button
                        Button(action: {
                            cameraManager.switchCamera()
                        }) {
                            Image(systemName: "camera.rotate")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(DesignSystem.CornerRadius.medium)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                }
                
                Spacer()
                
                // Bottom section with detection status
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Detection status card
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        // Status icon
                        Image(systemName: getStatusIcon())
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(getStatusColor())
                            .opacity(0.9)
                        
                        // Status text
                        Text(cameraManager.detectionStatus)
                            .font(DesignSystem.Typography.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                            .fill(Color.black.opacity(0.7))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                                    .stroke(getStatusColor().opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Instructions card
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Text("تعليمات")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(getInstructionsText())
                            .font(DesignSystem.Typography.footnote)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .fill(Color.black.opacity(0.5))
                    )
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                }
                .padding(.bottom, DesignSystem.Spacing.xl)
            }
            
            // Final detection success overlay
            if showingDetectionFeedback {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Success icon with animation
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.success)
                            .frame(width: 100, height: 100)
                            .scaleEffect(showingDetectionFeedback ? 1.0 : 0.5)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingDetectionFeedback)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Text("تم الاكتشاف!")
                            .font(DesignSystem.Typography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(getSuccessText())
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.9),
                            Color.black.opacity(0.8)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea()
            }
        }
        .onAppear {
            lastZoomFactor = 1.0
            currentZoomFactor = 1.0
            cameraManager.loadMLModel(modelName: challengeProgress.currentModelName)
            cameraManager.setChallengePrompt(challengeProgress.challengeTitle)
            cameraManager.startSession()
            cameraManager.onDetectionSuccess = {
                handleDetectionSuccess()
            }
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .onChange(of: challengeProgress.selectedChallengeIndex) {
            // Update challenge prompt for YOLO filtering
            cameraManager.setChallengePrompt(challengeProgress.challengeTitle)
            // Reset detection state for new challenge
            cameraManager.resetDetectionState()
        }
    }
    
    // MARK: - Helper Functions
    private func getStatusIcon() -> String {
        if cameraManager.hasDetectedInThisSession {
            return "checkmark.circle.fill"
        } else if let confidence = cameraManager.lastDetectionConfidence, confidence > 0.5 {
            return "eye.fill"
        } else {
            return "viewfinder"
        }
    }
    
    private func getStatusColor() -> Color {
        if cameraManager.hasDetectedInThisSession {
            return DesignSystem.Colors.success
        } else if let confidence = cameraManager.lastDetectionConfidence {
            if confidence >= 0.8 { return DesignSystem.Colors.success }
            if confidence >= 0.6 { return DesignSystem.Colors.warning }
            return DesignSystem.Colors.error
        } else {
            return .white
        }
    }
    
    private func getInstructionsText() -> String {
        let challenges = ChallengesData.shared.challenges
        let currentChallenge = challenges[challengeProgress.selectedChallengeIndex]
        let prompt = currentChallenge.prompt
        
        if prompt.contains("علامات مرورية") {
            return "وجه الكاميرا نحو اللافتات المرورية واضغط للتكبير إذا لزم الأمر"
        } else if prompt.contains("سيارات") {
            return "وجه الكاميرا نحو السيارات في الشارع أو موقف السيارات"
        } else if prompt.contains("باصات") {
            return "وجه الكاميرا نحو الباصات أو محطات النقل العام"
        } else if prompt.contains("قطط") {
            return "ابحث عن القطط في الشوارع أو الحدائق أو المنازل"
        } else if prompt.contains("طيور") {
            return "وجه الكاميرا نحو الطيور في السماء أو على الأشجار"
        } else if prompt.contains("سياكل") {
            return "ابحث عن الدراجات الهوائية في الشوارع أو مسارات الدراجات"
        } else if prompt.contains("اشارات مرور") {
            return "وجه الكاميرا نحو إشارات المرور في الشوارع"
        } else {
            return "وجه الكاميرا نحو العنصر المطلوب واضغط للتكبير إذا لزم الأمر"
        }
    }
    
    private func handleDetectionSuccess() {
        // Gentle haptic feedback - just once
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        
        // Show brief success animation
        showingDetectionFeedback = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showingDetectionFeedback = false
            onDetectionComplete()
            isPresented = false
        }
    }
    
    private func getSuccessText() -> String {
        let challenges = ChallengesData.shared.challenges
        let currentChallenge = challenges[challengeProgress.selectedChallengeIndex]
        
        // Extract the object type from the challenge prompt
        let prompt = currentChallenge.prompt
        
        if prompt.contains("علامات مرورية") {
            return "تم اكتشاف اللافتة المرورية!"
        } else if prompt.contains("سيارات") {
            return "تم اكتشاف السيارة!"
        } else if prompt.contains("باصات") {
            return "تم اكتشاف الباص!"
        } else if prompt.contains("قطط") {
            return "تم اكتشاف القطة!"
        } else if prompt.contains("طيور") {
            return "تم اكتشاف الطائر!"
        } else if prompt.contains("سياكل") {
            return "تم اكتشاف الدراجة!"
        }
        else if prompt.contains("اشارة مرور") {
            return "تم اكتشاف الاشارة!"
        }
        else {
            return "تم اكتشاف العنصر!"
        }
    }
    
    private func confidenceColor(for confidence: Float) -> Color {
        if confidence >= 0.8 { return .green }
        if confidence >= 0.6 { return .orange }
        return .red
    }
}

// MARK: - Camera Preview View
struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: LiveDetectionCameraManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        DispatchQueue.main.async {
            let previewLayer = cameraManager.previewLayer
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            cameraManager.previewLayer.frame = uiView.bounds
        }
    }
}

// MARK: - Camera Manager
class LiveDetectionCameraManager: NSObject, ObservableObject {
    private let captureSession = AVCaptureSession()
    private var videoDataOutput = AVCaptureVideoDataOutput()
    private var currentDevice: AVCaptureDevice?
    private let videoDataOutputQueue = DispatchQueue(label: "videoDataOutput", qos: .userInitiated)
    
    lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        return layer
    }()
    
    // MARK: - Published Properties
    @Published var lastDetectionConfidence: Float?
    @Published var recentDetections: [(identifier: String, confidence: Float, boundingBox: CGRect)] = []
    @Published var hasDetectedInThisSession = false
    @Published var currentlyActiveModel: String = ""
    @Published var detectionCount: Int = 0
    @Published var detectionStatus: String = "جاري البحث..."
    
    var onDetectionSuccess: (() -> Void)?
    
    // MARK: - Model Management
    private var mlModel: MLModel?
    private var visionModel: VNCoreMLModel?
    private var currentModelName: String = ""
    private var currentChallengePrompt: String = ""  // Track current challenge for YOLO filtering
    
    // MARK: - YOLO Detection Parameters (Optimized for Real-world Usage)
    private let confidenceThreshold: Float = 0.75  // Optimized for YOLO v3
    private let minimumDetectionSize: Float = 0.015  // Slightly smaller for distant objects
    private let cooldownDuration: TimeInterval = 1.5  // Faster response
    private let maxDetectionsPerSecond: Int = 5  // Increased for better responsiveness
    private let requiredConsistentFrames: Int = 3  // Reduced for faster detection
    
    // MARK: - Debug Mode (Disabled for Clean UI)
    private let isDebugMode: Bool = false  // Disabled for production
    @Published var debugDetections: [String] = []  // Not shown in UI
    
    // MARK: - Detection State Management
    private var lastDetectionTime: Date = Date.distantPast
    private var lastSuccessfulDetectionTime: Date = Date.distantPast
    private var detectionHistory: [(confidence: Float, timestamp: Date, boundingBox: CGRect)] = []
    private let detectionHistoryWindow: TimeInterval = 3.0
    private var frameCount: Int = 0
    private var lastProcessedTime: Date = Date()
    
    // MARK: - Performance Optimization (Apple's Recommendations)
    private let frameSkipInterval: Int = 3  // Process every 3rd frame for performance
    private var isProcessingFrame: Bool = false
    private var pendingRequests: Int = 0  // Track pending Vision requests
    private let maxPendingRequests: Int = 1  // Apple recommends queue size of 1
    private var bufferSize = CGSize.zero  // Track buffer dimensions for coordinate conversion
    
    override init() {
        super.init()
        setupCaptureSession()
    }
    
    // MARK: - YOLO Model Loading with Memory Management
    func loadMLModel(modelName: String) {
        // Always use YOLOv3TinyInt8LUT for all challenges
        let actualModelName = "YOLOv3TinyInt8LUT"
        
        // Prevent loading the same model twice
        guard actualModelName != currentModelName || visionModel == nil else {
            print("🔄 Model \(actualModelName) already loaded")
            return
        }
        
        // Clear previous model from memory
        unloadCurrentModel()
        
        print("🤖 Loading YOLO model: \(actualModelName)")
        currentModelName = actualModelName
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                // Load YOLOv3 model
                guard let modelURL = Bundle.main.url(forResource: "YOLOv3TinyInt8LUT", withExtension: "mlmodelc") ??
                                    Bundle.main.url(forResource: "YOLOv3TinyInt8LUT", withExtension: "mlmodel") else {
                    print("❌ YOLOv3TinyInt8LUT model file not found in bundle")
                    DispatchQueue.main.async {
                        self?.detectionStatus = "نموذج YOLOv3TinyInt8LUT غير موجود"
                    }
                    return
                }
                
                let model = try MLModel(contentsOf: modelURL, configuration: self?.createOptimizedMLConfiguration() ?? MLModelConfiguration())
                let visionModel = try VNCoreMLModel(for: model)
                
                DispatchQueue.main.async {
                    self?.mlModel = model
                    self?.visionModel = visionModel
                    self?.currentlyActiveModel = actualModelName
                    self?.detectionStatus = "نموذج YOLO جاهز"
                    
                    print("✅ Successfully loaded YOLOv3 object detection model")
                    print("📋 Model input: \(model.modelDescription.inputDescriptionsByName)")
                    print("📋 Model output: \(model.modelDescription.outputDescriptionsByName)")
                }
            } catch {
                DispatchQueue.main.async {
                    self?.detectionStatus = "خطأ في تحميل نموذج YOLO"
                }
                print("❌ Failed to load YOLOv3TinyInt8LUT model: \(error)")
            }
        }
    }
    
    private func createOptimizedMLConfiguration() -> MLModelConfiguration {
        let config = MLModelConfiguration()
        config.computeUnits = .all  // Use all available compute units (CPU, GPU, Neural Engine)
        config.allowLowPrecisionAccumulationOnGPU = true
        return config
    }
    
    private func unloadCurrentModel() {
        mlModel = nil
        visionModel = nil
        currentlyActiveModel = ""
        print("🗑️ Previous model unloaded from memory")
    }
    
    private func setupCaptureSession() {
        // Configure session based on Apple's recommendations
        captureSession.beginConfiguration()
        
        // Choose resolution based on model requirements - prefer VGA for better performance
        // Apple recommends not selecting highest resolution unless required
        captureSession.sessionPreset = .vga640x480  // Apple's recommended preset for Vision
        
        // Discovery session to find the best wide angle camera
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .back
        )
        
        guard let videoDevice = deviceDiscoverySession.devices.first else {
            print("Could not get video device")
            captureSession.commitConfiguration()
            return
        }
        
        currentDevice = videoDevice
        
        // Configure camera for optimal detection
        configureCameraForDetection(device: videoDevice)
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            guard captureSession.canAddInput(deviceInput) else {
                print("Could not add video device input to the session")
                captureSession.commitConfiguration()
                return
            }
            captureSession.addInput(deviceInput)
            
            if captureSession.canAddOutput(videoDataOutput) {
                captureSession.addOutput(videoDataOutput)
                
                // Configure video output according to Apple's best practices
                videoDataOutput.alwaysDiscardsLateVideoFrames = true
                
                // Use Apple's recommended pixel format for Vision
                videoDataOutput.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
                ]
                
                // Configure connection for optimal detection
                if let captureConnection = videoDataOutput.connection(with: .video) {
                    // Always process frames as recommended
                    captureConnection.isEnabled = true
                    
                    // Enable video stabilization for steadier detection
                    if captureConnection.isVideoStabilizationSupported {
                        captureConnection.preferredVideoStabilizationMode = .auto
                        print("✅ Video stabilization enabled")
                    }
                    
                    // Get buffer dimensions as Apple recommends
                    do {
                        try videoDevice.lockForConfiguration()
                        let dimensions = CMVideoFormatDescriptionGetDimensions(videoDevice.activeFormat.formatDescription)
                        bufferSize.width = CGFloat(dimensions.width)
                        bufferSize.height = CGFloat(dimensions.height)
                        videoDevice.unlockForConfiguration()
                        print("✅ Buffer size configured: \(bufferSize)")
                    } catch {
                        print("❌ Could not get buffer dimensions: \(error)")
                    }
                }
                
                videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
            } else {
                print("Could not add video data output to the session")
                captureSession.commitConfiguration()
                return
            }
            
        } catch {
            print("Could not create video device input: \(error)")
            captureSession.commitConfiguration()
            return
        }
        
        // Commit configuration changes
        captureSession.commitConfiguration()
        print("✅ Capture session configured with VGA resolution for optimal Vision performance")
    }
    
    private func configureCameraForDetection(device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            
            // Configure autofocus for optimal object detection
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
                print("✅ Continuous autofocus enabled")
            }
            
            // Configure exposure with lock capability
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            
            // Enable auto white balance for consistent detection
            if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                device.whiteBalanceMode = .continuousAutoWhiteBalance
            }
            
            // Set 30fps frame rate as specified
            let targetFrameRate: Int32 = 30
            let supportedFormats = device.formats
            
            for format in supportedFormats {
                let ranges = format.videoSupportedFrameRateRanges
                for range in ranges {
                    if range.minFrameRate <= Double(targetFrameRate) && Double(targetFrameRate) <= range.maxFrameRate {
                        device.activeFormat = format
                        device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: targetFrameRate)
                        device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: targetFrameRate)
                        print("✅ Frame rate set to \(targetFrameRate)fps")
                        break
                    }
                }
            }
            
            // Configure low light boost if available
            if device.isLowLightBoostSupported {
                device.automaticallyEnablesLowLightBoostWhenAvailable = true
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Could not configure camera: \(error)")
        }
    }
    
    func startSession() {
        // Reset all detection state
        resetDetectionState()
        detectionStatus = "جاري البحث..."
        
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
                DispatchQueue.main.async {
                    self.detectionStatus = "جاهز للاكتشاف"
                }
            }
        }
    }
    
    func stopSession() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    func setZoomFactor(_ factor: CGFloat) {
        guard let device = currentDevice else { return }
        
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = max(1.0, min(factor, device.activeFormat.videoMaxZoomFactor))
            device.unlockForConfiguration()
        } catch {
            print("Could not set zoom factor: \(error)")
        }
    }
    
    func switchCamera() {
        guard let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput else { return }
        
        let newPosition: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back
        
        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else {
            return
        }
        
        do {
            let newInput = try AVCaptureDeviceInput(device: newDevice)
            
            captureSession.beginConfiguration()
            captureSession.removeInput(currentInput)
            
            if captureSession.canAddInput(newInput) {
                captureSession.addInput(newInput)
                currentDevice = newDevice
            } else {
                captureSession.addInput(currentInput)
            }
            
            captureSession.commitConfiguration()
        } catch {
            print("Could not switch camera: \(error)")
        }
    }
    
    func resetDetectionState() {
        hasDetectedInThisSession = false
        lastDetectionTime = Date.distantPast
        lastSuccessfulDetectionTime = Date.distantPast
        lastDetectionConfidence = nil
        recentDetections.removeAll()
        detectionHistory.removeAll()
        detectionCount = 0
        frameCount = 0
        isProcessingFrame = false
        pendingRequests = 0  // Reset pending requests counter
        lastProcessedTime = Date()
        print("🔄 Detection state reset")
    }
    
    // MARK: - Challenge Configuration
    func setChallengePrompt(_ prompt: String) {
        currentChallengePrompt = prompt
        print("🎯 Challenge set to: \(prompt)")
    }
    
    // MARK: - Device Orientation Handling (Apple's Recommended Approach)
    private func getCurrentCameraOrientation() -> CGImagePropertyOrientation {
        let curDeviceOrientation = UIDevice.current.orientation
        let exifOrientation: CGImagePropertyOrientation
        
        // Get the current camera position to determine proper orientation mapping
        let isUsingFrontCamera = currentDevice?.position == .front
        
        switch curDeviceOrientation {
        case UIDeviceOrientation.portraitUpsideDown:  // Device oriented vertically, home button on the top
            exifOrientation = isUsingFrontCamera ? .rightMirrored : .left
        case UIDeviceOrientation.landscapeLeft:       // Device oriented horizontally, home button on the right
            exifOrientation = isUsingFrontCamera ? .downMirrored : .up
        case UIDeviceOrientation.landscapeRight:      // Device oriented horizontally, home button on the left
            exifOrientation = isUsingFrontCamera ? .upMirrored : .down
        case UIDeviceOrientation.portrait:            // Device oriented vertically, home button on the bottom
            exifOrientation = isUsingFrontCamera ? .leftMirrored : .right
        default:
            // For unknown orientations, use the interface orientation as fallback
            let interfaceOrientation = getInterfaceOrientation()
            switch interfaceOrientation {
            case .portrait:
                exifOrientation = isUsingFrontCamera ? .leftMirrored : .right
            case .portraitUpsideDown:
                exifOrientation = isUsingFrontCamera ? .rightMirrored : .left
            case .landscapeLeft:
                exifOrientation = isUsingFrontCamera ? .downMirrored : .up
            case .landscapeRight:
                exifOrientation = isUsingFrontCamera ? .upMirrored : .down
            default:
                exifOrientation = isUsingFrontCamera ? .leftMirrored : .right
            }
        }
        
        // Debug logging to verify orientation mapping is working
        print("📱 Device orientation: \(curDeviceOrientation.rawValue), Camera: \(isUsingFrontCamera ? "Front" : "Back"), EXIF: \(exifOrientation.rawValue)")
        
        return exifOrientation
    }
    
    // Helper function to get interface orientation as fallback
    private func getInterfaceOrientation() -> UIInterfaceOrientation {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.interfaceOrientation
        }
        return .portrait
    }
    

}

// MARK: - Video Data Output Delegate
extension LiveDetectionCameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Apple's Performance Recommendations:
        // 1. Don't hold on to more than one Vision request at a time
        guard pendingRequests < maxPendingRequests else {
            // Skip frame if too many requests pending (buffer overflow prevention)
            return
        }
        
        // 2. Skip frames for performance (process every nth frame)
        frameCount += 1
        guard frameCount % frameSkipInterval == 0 else { return }
        
        // 3. Ensure we have a loaded model
        guard let visionModel = visionModel,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // Skip if already detected in this session
        guard !hasDetectedInThisSession else { return }
        
        // 4. Rate limiting: Limit detections per second
        let now = Date()
        guard now.timeIntervalSince(lastProcessedTime) >= 1.0 / Double(maxDetectionsPerSecond) else {
            return
        }
        
        // Increment pending requests counter
        pendingRequests += 1
        lastProcessedTime = now
        
        let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
            defer {
                DispatchQueue.main.async {
                    // Decrement pending requests counter
                    self?.pendingRequests = max(0, (self?.pendingRequests ?? 1) - 1)
                    self?.isProcessingFrame = false
                }
            }
            
            if let error = error {
                print("Vision request error: \(error)")
                return
            }
            
            // Process results on main queue for UI updates as Apple recommends
            DispatchQueue.main.async {
                self?.processDetectionResults(request.results, timestamp: now)
            }
        }
        
        // Optimize request configuration for object detection
        request.imageCropAndScaleOption = .scaleFit
        
        // Use all available compute units for best performance
        if #available(iOS 17.0, *) {
            // Use default processing in iOS 17+
        } else {
            request.usesCPUOnly = false
        }
        
        // Configure image orientation based on device orientation - Apple's recommended approach
        let exifOrientation = getCurrentCameraOrientation()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: [:])
        
        // Perform detection on background queue
        DispatchQueue.global(qos: .userInitiated).async {
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform vision request: \(error)")
                DispatchQueue.main.async {
                    self.isProcessingFrame = false
                }
            }
        }
    }
    
    private func processDetectionResults(_ results: [VNObservation]?, timestamp: Date) {
        guard let results = results else {
            DispatchQueue.main.async {
                self.detectionStatus = "لا يوجد نتائج"
            }
            return
        }
        
        // Skip if already detected in this session
        guard !hasDetectedInThisSession else { return }
        
        // Apply cooldown period
        guard timestamp.timeIntervalSince(lastSuccessfulDetectionTime) >= cooldownDuration else {
            return
        }
        
        var allDetections: [(identifier: String, confidence: Float, boundingBox: CGRect)] = []
        var bestConfidence: Float = 0.0
        
        // Process object detection results following Apple's recommendations
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }
            
            let objectBounds = objectObservation.boundingBox
            
            // Select only the label with the highest confidence as Apple recommends
            let topLabelObservation = objectObservation.labels[0]
            
            let detection = (
                identifier: topLabelObservation.identifier,
                confidence: topLabelObservation.confidence,
                boundingBox: objectBounds
            )
            allDetections.append(detection)
            bestConfidence = max(bestConfidence, topLabelObservation.confidence)
            
            // Debug logging - show what the model detects
            if isDebugMode && topLabelObservation.confidence > 0.3 {
                let debugInfo = "\(topLabelObservation.identifier): \(Int(topLabelObservation.confidence * 100))%"
                print("🔍 DEBUG: Model sees - \(debugInfo)")
            }
        }
        
        // Filter detections by current model target
        let validDetections = filterDetectionsByModel(allDetections)
        
        // Apply non-maximum suppression to remove overlapping detections
        let filteredDetections = applyNonMaximumSuppression(validDetections)
        
        // Apply STRICT confidence threshold and size filtering
        let confidentDetections = filteredDetections.filter { detection in
            let area = Float(detection.boundingBox.width * detection.boundingBox.height)
            return detection.confidence >= confidenceThreshold && area >= minimumDetectionSize
        }
        
        DispatchQueue.main.async {
            self.lastDetectionConfidence = bestConfidence > 0.1 ? bestConfidence : nil
            self.recentDetections = Array(filteredDetections.sorted { $0.confidence > $1.confidence }.prefix(5))
            
            // Debug mode - show what model actually detects
            if self.isDebugMode {
                let topDetections = allDetections.sorted { $0.confidence > $1.confidence }.prefix(3)
                self.debugDetections = topDetections.map { "\($0.identifier): \(Int($0.confidence * 100))%" }
            }
            
            // Update detection status
            if confidentDetections.isEmpty {
                if bestConfidence > 0.5 {
                    self.detectionStatus = String(format: "مشكوك فيه %.0f%% - اقترب وثبت موقعك", bestConfidence * 100)
                } else {
                    self.detectionStatus = "جاري البحث..."
                }
            } else {
                // Valid detection found - check for successful detection
                let isValidDetection = self.validateDetection(confidentDetections, timestamp: timestamp)
                
                if isValidDetection {
                    self.handleSuccessfulDetection(confidentDetections.first!, timestamp: timestamp)
                } else {
                    let requiredFrames = self.requiredConsistentFrames
                    let currentFrames = self.detectionHistory.filter { $0.confidence >= 0.85 }.count
                    self.detectionStatus = String(format: "موجود %.0f%% - يحتاج %d إطارات (%d/%d)", confidentDetections.first!.confidence * 100, requiredFrames, currentFrames, requiredFrames)
                }
            }
        }
    }
    
    // MARK: - YOLO Challenge-Specific Detection Filtering
    private func filterDetectionsByModel(_ detections: [(identifier: String, confidence: Float, boundingBox: CGRect)]) -> [(identifier: String, confidence: Float, boundingBox: CGRect)] {
        return detections.filter { detection in
            let identifier = detection.identifier.lowercased()
            
            // Filter based on current challenge prompt using YOLO classes
            if currentChallengePrompt.contains("علامات مرورية") {
                // Traffic signs challenge - YOLO classes: stop sign, traffic light
                let isTrafficSign = identifier == "stop sign" ||
                                   identifier == "traffic light" ||
                                   identifier.contains("sign") ||
                                   identifier.contains("traffic")
                return isTrafficSign && detection.confidence >= 0.75
                
            } else if currentChallengePrompt.contains("سيارات") {
                // Cars challenge - YOLO classes: car, truck, van
                let isCar = identifier == "car" ||
                           identifier == "truck" ||
                           identifier == "van" ||
                           identifier == "automobile" ||
                           identifier == "vehicle"
                return isCar && detection.confidence >= 0.75
                
            } else if currentChallengePrompt.contains("باصات") {
                // Bus challenge - YOLO classes: bus, truck
                let isBus = identifier == "bus" ||
                           identifier == "truck" ||
                           identifier.contains("bus")
                return isBus && detection.confidence >= 0.75
                
            } else if currentChallengePrompt.contains("قطط") {
                // Cat challenge - YOLO classes: cat
                let isCat = identifier == "cat" ||
                           identifier.contains("cat")
                return isCat && detection.confidence >= 0.75
                
            } else if currentChallengePrompt.contains("طيور") {
                // Birds challenge - YOLO classes: bird
                let isBird = identifier == "bird" ||
                            identifier.contains("bird")
                return isBird && detection.confidence >= 0.75
                
            } else if currentChallengePrompt.contains("سياكل") {
                // Bicycle challenge - YOLO classes: bicycle, bike
                let isBike = identifier == "bicycle" ||
                            identifier == "bike" ||
                            identifier.contains("bicycle") ||
                            identifier.contains("bike")
                return isBike && detection.confidence >= 0.75
                
            } else {
                // Default: accept any detection with high confidence
                return detection.confidence >= 0.80
            }
        }
    }
    
    // MARK: - Non-Maximum Suppression
    private func applyNonMaximumSuppression(_ detections: [(identifier: String, confidence: Float, boundingBox: CGRect)]) -> [(identifier: String, confidence: Float, boundingBox: CGRect)] {
        guard detections.count > 1 else { return detections }
        
        // Sort by confidence (highest first)
        let sortedDetections = detections.sorted { $0.confidence > $1.confidence }
        var suppressedDetections: [(identifier: String, confidence: Float, boundingBox: CGRect)] = []
        
        for detection in sortedDetections {
            var shouldSuppress = false
            
            for existingDetection in suppressedDetections {
                let iou = calculateIoU(detection.boundingBox, existingDetection.boundingBox)
                if iou > 0.5 { // IoU threshold for suppression
                    shouldSuppress = true
                                break
                            }
                        }
            
            if !shouldSuppress {
                suppressedDetections.append(detection)
            }
        }
        
        return suppressedDetections
    }
    
    // Calculate Intersection over Union (IoU) for bounding boxes
    private func calculateIoU(_ box1: CGRect, _ box2: CGRect) -> Float {
        let intersection = box1.intersection(box2)
        guard !intersection.isNull else { return 0.0 }
        
        let intersectionArea = intersection.width * intersection.height
        let unionArea = box1.width * box1.height + box2.width * box2.height - intersectionArea
        
        return Float(intersectionArea / unionArea)
    }
    
    // MARK: - Advanced Detection Validation
    private func validateDetection(_ detections: [(identifier: String, confidence: Float, boundingBox: CGRect)], timestamp: Date) -> Bool {
        guard let bestDetection = detections.first else { return false }
        
        // Add to detection history
        let historyEntry = (confidence: bestDetection.confidence, timestamp: timestamp, boundingBox: bestDetection.boundingBox)
        detectionHistory.append(historyEntry)
        
        // Clean up old detections (keep only recent ones within the window)
        detectionHistory = detectionHistory.filter { timestamp.timeIntervalSince($0.timestamp) <= detectionHistoryWindow }
        
        // STRICT Validation criteria to prevent false positives:
        
        // 1. Check minimum object size (prevent tiny false detections)
        let detectionArea = Float(bestDetection.boundingBox.width * bestDetection.boundingBox.height)
        if detectionArea < minimumDetectionSize {
            print("❌ Detection too small: \(detectionArea) < \(minimumDetectionSize)")
            return false
        }
        
        // 2. YOLO Optimized: High confidence (>= 0.85) for quicker validation
        if bestDetection.confidence >= 0.85 {
            // Require fewer consistent detections for faster response
            let recentHighConfidence = detectionHistory.filter { $0.confidence >= 0.80 && timestamp.timeIntervalSince($0.timestamp) <= 1.0 }
            if recentHighConfidence.count >= 2 {
                print("🎯 High confidence YOLO detection: \(bestDetection.confidence)")
                return true
            }
        }
        
        // 3. Require consistent high confidence over multiple frames (>= 0.80 for 3+ frames)
        let highConfidenceDetections = detectionHistory.filter { $0.confidence >= 0.80 }
        if highConfidenceDetections.count >= requiredConsistentFrames {
            // Check that detections are recent (within last 1.5 seconds)
            let recentDetections = highConfidenceDetections.filter { timestamp.timeIntervalSince($0.timestamp) <= 1.5 }
            if recentDetections.count >= requiredConsistentFrames {
                print("🎯 Consistent YOLO detection: \(recentDetections.count) frames")
                return true
            }
        }
        
        // 4. Stable bounding box with good confidence
        if detectionHistory.count >= requiredConsistentFrames {
            let recent = detectionHistory.suffix(requiredConsistentFrames)
            let boundingBoxStability = calculateBoundingBoxStability(Array(recent))
            let averageConfidence = recent.map { $0.confidence }.reduce(0, +) / Float(recent.count)
            
            if averageConfidence >= 0.82 && boundingBoxStability > 0.7 && bestDetection.confidence >= 0.83 {
                print("🎯 Stable YOLO detection: avg=\(averageConfidence), stability=\(boundingBoxStability)")
                return true
            }
        }
        
        return false
    }
    
    // Calculate how stable the bounding box is (less movement = more stable)
    private func calculateBoundingBoxStability(_ detections: [(confidence: Float, timestamp: Date, boundingBox: CGRect)]) -> Float {
        guard detections.count >= 2 else { return 0.0 }
        
        var totalStability: Float = 0.0
        
        for i in 1..<detections.count {
            let currentBox = detections[i].boundingBox
            let previousBox = detections[i-1].boundingBox
            
            // Calculate center point movement
            let currentCenter = CGPoint(x: currentBox.midX, y: currentBox.midY)
            let previousCenter = CGPoint(x: previousBox.midX, y: previousBox.midY)
            
            let distance = sqrt(pow(currentCenter.x - previousCenter.x, 2) + pow(currentCenter.y - previousCenter.y, 2))
            let stability = max(0.0, 1.0 - Float(distance * 10)) // Scale distance to stability
            
            totalStability += stability
        }
        
        return totalStability / Float(detections.count - 1)
    }
    
    // MARK: - Successful Detection Handling with Final Validation
    private func handleSuccessfulDetection(_ detection: (identifier: String, confidence: Float, boundingBox: CGRect), timestamp: Date) {
        // FINAL VALIDATION: Double-check the detection before confirming
        guard finalValidationCheck(detection) else {
            print("❌ Final validation failed for \(detection.identifier)")
            return
        }
        
        hasDetectedInThisSession = true
        lastSuccessfulDetectionTime = timestamp
        detectionCount += 1
        detectionStatus = String(format: "تم الاكتشاف! %.0f%% ثقة", detection.confidence * 100)
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        
        // Play system sound for success
        AudioServicesPlaySystemSound(1519) // System sound for success
        
        print("🎉 SUCCESSFUL DETECTION: \(detection.identifier) with \(detection.confidence) confidence")
        
        // Trigger success callback
        onDetectionSuccess?()
    }
    
    // MARK: - Final Validation Check for YOLO
    private func finalValidationCheck(_ detection: (identifier: String, confidence: Float, boundingBox: CGRect)) -> Bool {
        let identifier = detection.identifier.lowercased()
        
        // Final validation based on current challenge using YOLO classes
        if currentChallengePrompt.contains("علامات مرورية") {
            let validTerms = ["stop sign", "traffic light", "sign", "traffic"]
            let isValid = validTerms.contains(identifier) ||
                         identifier.contains("sign") ||
                         identifier.contains("traffic")
            return isValid && detection.confidence >= 0.80
            
        } else if currentChallengePrompt.contains("سيارات") {
            let validTerms = ["car", "truck", "van", "automobile", "vehicle"]
            return validTerms.contains(identifier) && detection.confidence >= 0.80
            
        } else if currentChallengePrompt.contains("باصات") {
            let validTerms = ["bus", "truck"]
            let isValid = validTerms.contains(identifier) || identifier.contains("bus")
            return isValid && detection.confidence >= 0.80
            
        } else if currentChallengePrompt.contains("قطط") {
            let validTerms = ["cat"]
            let isValid = validTerms.contains(identifier) || identifier.contains("cat")
            return isValid && detection.confidence >= 0.80
            
        } else if currentChallengePrompt.contains("طيور") {
            let validTerms = ["bird"]
            let isValid = validTerms.contains(identifier) || identifier.contains("bird")
            return isValid && detection.confidence >= 0.80
            
        } else if currentChallengePrompt.contains("سياكل") {
            let validTerms = ["bicycle", "bike"]
            let isValid = validTerms.contains(identifier) ||
                         identifier.contains("bicycle") ||
                         identifier.contains("bike")
            return isValid && detection.confidence >= 0.80
            
        }
        else if currentChallengePrompt.contains("اشارات مرور") {
            let validTerms = ["traffic light"]
            let isValid = validTerms.contains(identifier) ||
                         identifier.contains("traffic light")
            return isValid && detection.confidence >= 0.80
            
        }else {
            // Default validation
            return detection.confidence >= 0.85
        }
    }
}

// MARK: - Advanced Detection Overlay with Bounding Boxes
struct DetectionOverlayView: View {
    let detections: [(identifier: String, confidence: Float, boundingBox: CGRect)]
    let confidence: Float?
    let status: String
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Draw bounding boxes for detected objects
                ForEach(0..<min(detections.count, 3), id: \.self) { index in
                    let detection = detections[index]
                    
                    BoundingBoxView(
                        detection: detection,
                        frame: geometry.frame(in: .local)
                    )
                }
                
                // Main detection feedback
        VStack {
                    Spacer()
                    
                    // Detection guidance overlay
                    if let confidence = confidence, confidence > 0.1 {
                        VStack(spacing: 8) {
                            // Confidence indicator
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(confidenceColor(for: confidence))
                                    .frame(width: 12, height: 12)
                                
                Text("\(Int(confidence * 100))%")
                                    .font(.title2)
                    .fontWeight(.bold)
                                    .foregroundColor(confidenceColor(for: confidence))
                            }
                
                            // Status text
                            Text(status)
                                .font(.subheadline)
                    .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(12)
                    } else {
                        // Scanning indicator
                        VStack(spacing: 8) {
                            Image(systemName: "viewfinder")
                                .font(.title)
                                .foregroundColor(.white)
                                .opacity(0.8)
                            
                            Text(status)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                        .frame(height: 100)
                }
            }
        }
    }
    
    private func confidenceColor(for confidence: Float) -> Color {
        if confidence >= 0.8 { return .green }
        if confidence >= 0.6 { return .orange }
        return .red
    }
}

// MARK: - Bounding Box View
struct BoundingBoxView: View {
    let detection: (identifier: String, confidence: Float, boundingBox: CGRect)
    let frame: CGRect
    
    var body: some View {
        let boundingBox = detection.boundingBox
        let confidence = detection.confidence
        
        // Use Apple's recommended VNImageRectForNormalizedRect approach
        let objectBounds = VNImageRectForNormalizedRect(
            boundingBox,
            Int(frame.width),
            Int(frame.height)
        )
        
        // Convert to SwiftUI coordinates
        let x = objectBounds.minX
        let y = frame.height - objectBounds.maxY  // Flip Y coordinate for SwiftUI
        let width = objectBounds.width
        let height = objectBounds.height
        
        Rectangle()
            .stroke(borderColor(for: confidence), lineWidth: 3)
            .fill(Color.clear)
            .frame(width: width, height: height)
            .position(x: x + width/2, y: y + height/2)
            .overlay(
                // Label overlay
                VStack {
                    HStack {
                        Text("\(Int(confidence * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(borderColor(for: confidence))
                            .cornerRadius(4)
                        
                        Spacer()
                    }
                    Spacer()
                }
                .frame(width: width, height: height)
                .position(x: x + width/2, y: y + height/2)
            )
    }
    
    private func borderColor(for confidence: Float) -> Color {
        if confidence >= 0.8 { return .green }
        if confidence >= 0.6 { return .orange }
        return .red
    }
}


