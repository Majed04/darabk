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
            // Camera preview with pinch gesture
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
            
            // Detection status overlay for live feedback with ultra-precise thresholds
            if let confidence = cameraManager.lastDetectionConfidence, confidence > 0.5 && !cameraManager.hasDetectedInThisSession {
                VStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            confidence > 0.85 ? Color.green : 
                            confidence > 0.75 ? Color.blue :
                            confidence > 0.65 ? Color.orange : Color.yellow, 
                            lineWidth: confidence > 0.8 ? 5 : confidence > 0.7 ? 4 : 3
                        )
                        .fill(Color.clear)
                        .padding(20)
                        .animation(.easeInOut(duration: 0.3), value: confidence)
                    
                    // Show confidence percentage
                    VStack {
                        Text("\(Int(confidence * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(
                                confidence > 0.85 ? .green : 
                                confidence > 0.75 ? .blue :
                                confidence > 0.65 ? .orange : .yellow
                            )
                        
                        Text("ثقة الاكتشاف")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
                    .animation(.easeInOut(duration: 0.3), value: confidence)
                }
            }
            
            // Detection overlay
            VStack {
                // Top section with title and controls
                VStack(spacing: 12) {
                    // Challenge title
                    Text(challengeProgress.challengeTitle)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                    
                    // Controls
                    HStack {
                        Button("إلغاء") {
                            isPresented = false
                        }
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding()
                        
                        Spacer()
                        
                        // Lens switching button
                        Button(action: {
                            cameraManager.switchCamera()
                        }) {
                            Image(systemName: "camera.rotate")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        .padding()
                    }
                }
                .padding(.top, 10)
                
                Spacer()
                
                // Detection status
                VStack(spacing: 8) {
                    if cameraManager.hasDetectedInThisSession {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                            
                            Text(getSuccessText())
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(8)
                    } else {
                        
                    }
                }
                
                Spacer()
                
                // Bottom section
                VStack(spacing: 12) {
                    // Progress indicator
                    Text("\(challengeProgress.completedPhotos)/\(challengeProgress.totalPhotos)")
                        .font(.title)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(10)
                    
                    if !cameraManager.hasDetectedInThisSession {
                        // Show zoom indicator and test button during detection
                        HStack {
                            // Zoom indicator
                            Text("\(currentZoomFactor, specifier: "%.1f")x")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(6)
                            
                            Spacer()
                            
                            // Debug: Manual trigger button
                            Button(action: {
                                handleDetectionSuccess()
                            }) {
                                Text("TEST")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 30)
                                    .background(Color.red.opacity(0.8))
                                    .cornerRadius(6)
                            }
                        }
                        .padding(.horizontal, 20)
                    } else {
                        // Show completion message
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.green)
                            
                            Text("سيتم إغلاق الكاميرا تلقائياً")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.bottom, 50)
            }
            
            // Detection feedback overlay
            if showingDetectionFeedback {
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text(getSuccessText())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.8))
                .ignoresSafeArea()
            }
        }
        .onAppear {
            lastZoomFactor = 1.0
            currentZoomFactor = 1.0
            cameraManager.loadMLModel(modelName: challengeProgress.currentModelName)
            cameraManager.startSession()
            cameraManager.onDetectionSuccess = {
                handleDetectionSuccess()
            }
        }
        .onDisappear {
            cameraManager.stopSession()
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
    
    private func getSearchText() -> String {
        switch challengeProgress.currentModelName {
        case "BikesModel":
            return "ابحث عن سياكل"
        default:
            return "ابحث عن لافتة مرورية"
        }
    }
    
    private func getSuccessText() -> String {
        switch challengeProgress.currentModelName {
        case "BikesModel":
            return "تم اكتشاف العنصر!"
        default:
            return "تم اكتشاف اللافتة المرورية!"
        }
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
    
    @Published var lastDetectionConfidence: Float?
    @Published var recentDetections: [(identifier: String, confidence: Float)] = []
    @Published var hasDetectedInThisSession = false
    var onDetectionSuccess: (() -> Void)?
    
    private var mlModel: MLModel?
    private var visionModel: VNCoreMLModel?
    private var lastDetectionTime: Date = Date.distantPast
    private var currentModelName: String = "TrafficSigns"
    
    // Detection averaging for improved accuracy
    private var detectionHistory: [(confidence: Float, timestamp: Date)] = []
    private var consecutiveDetections = 0
    private let requiredConsecutiveDetections = 5
    private let detectionHistoryWindow: TimeInterval = 3.0
    
    // Ultra-precise detection validation
    private var stableDetectionCount = 0
    private var lastConfidenceValues: [Float] = []
    private let maxConfidenceVariance: Float = 0.15
    
    override init() {
        super.init()
        setupCaptureSession()
    }
    
    func loadMLModel(modelName: String) {
        currentModelName = modelName
        print("🤖 Loading model: \(modelName)")
        
        do {
            if modelName == "BikesModel" {
                let bikesModel = try BikesModel(configuration: MLModelConfiguration())
                mlModel = bikesModel.model
            } else {
                let trafficSignsModel = try TrafficSigns(configuration: MLModelConfiguration())
                mlModel = trafficSignsModel.model
            }
            
            visionModel = try VNCoreMLModel(for: mlModel!)
            
            // Print model information
            print("✅ Successfully loaded \(modelName) object detection model")
            print("Model description: \(mlModel!.modelDescription)")
            
            // This is an object detection model, not a classifier
            let metadata = mlModel!.modelDescription.metadata
            print("📋 Model metadata: \(metadata)")
        } catch {
            print("❌ Failed to load \(modelName) model: \(error)")
        }
    }
    
    private func setupCaptureSession() {
        // Use high quality preset for better detection
        captureSession.sessionPreset = .photo
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Could not get video device")
            return
        }
        
        currentDevice = videoDevice
        
        // Configure camera for optimal detection
        configureCameraForDetection(device: videoDevice)
        
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
            }
            
            if captureSession.canAddOutput(videoDataOutput) {
                captureSession.addOutput(videoDataOutput)
                
                // Optimize video output settings for ML
                videoDataOutput.alwaysDiscardsLateVideoFrames = true
                videoDataOutput.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                ]
                
                // Enable video stabilization for steadier detection
                if let connection = videoDataOutput.connection(with: .video) {
                    if connection.isVideoStabilizationSupported {
                        connection.preferredVideoStabilizationMode = .auto
                        print("✅ Video stabilization enabled")
                    }
                }
                
                videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
            }
        } catch {
            print("Could not create video device input: \(error)")
        }
    }
    
    private func configureCameraForDetection(device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            
            // Enable auto focus for sharp images
            if device.isFocusModeSupported(.autoFocus) {
                device.focusMode = .autoFocus
            }
            
            // Optimize exposure for detection
            if device.isExposureModeSupported(.autoExpose) {
                device.exposureMode = .autoExpose
            }
            
            // Enable image stabilization if available
            if device.activeFormat.isVideoStabilizationModeSupported(.auto) {
                // Will be set on connection later
            }
            
            // Set frame rate for smooth detection
            let frameRate = CMTimeMake(value: 1, timescale: 30) // 30 FPS
            device.activeVideoMinFrameDuration = frameRate
            device.activeVideoMaxFrameDuration = frameRate
            
            device.unlockForConfiguration()
            
            print("✅ Camera configured for optimal detection")
        } catch {
            print("❌ Could not configure camera: \(error)")
        }
    }
    
    func startSession() {
        // Reset detection state for new session
        hasDetectedInThisSession = false
        lastDetectionTime = Date.distantPast
        lastDetectionConfidence = nil
        recentDetections.removeAll()
        
        // Reset detection averaging variables
        detectionHistory.removeAll()
        consecutiveDetections = 0
        
        // Reset ultra-precise validation variables
        stableDetectionCount = 0
        lastConfidenceValues.removeAll()
        
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
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
}

// MARK: - Video Data Output Delegate
extension LiveDetectionCameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let visionModel = visionModel,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
            if let error = error {
                print("Vision request error: \(error)")
                return
            }
            
            self?.processDetectionResults(request.results)
        }
        
        // Optimize request for better accuracy
        request.imageCropAndScaleOption = .centerCrop
        request.usesCPUOnly = false // Use GPU when available for faster processing
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform vision request: \(error)")
        }
    }
    
    private func processDetectionResults(_ results: [VNObservation]?) {
        guard let results = results else { 
            print("No detection results")
            return 
        }
        
        // Skip if already detected in this session
        guard !hasDetectedInThisSession else {
            return
        }
        
        // Ultra-fast response for continuous detection analysis
        let now = Date()
        guard now.timeIntervalSince(lastDetectionTime) > 0.1 else {
            return
        }
        
        var bestConfidence: Float = 0.0
        var detectedTrafficSign = false
        var newDetections: [(identifier: String, confidence: Float)] = []
        
        print("=== Object Detection Results ===")
        
        for result in results {
            if let coreMLResult = result as? VNCoreMLFeatureValueObservation {
                // Handle object detection output
                if let multiArray = coreMLResult.featureValue.multiArrayValue {
                    print("Detected CoreML output: \(coreMLResult.featureName)")
                    if coreMLResult.featureName == "confidence" {
                        // Parse confidence scores for detected objects
                        let confidenceArray = multiArray
                        print("Confidence array shape: \(confidenceArray.shape)")
                        print("Confidence array count: \(confidenceArray.count)")
                        
                        // Get raw confidence values with improved thresholds
                        for i in 0..<min(20, confidenceArray.count) { // Check more detections
                            let confidence = confidenceArray[i].floatValue
                            if confidence > 0.05 { // Lower threshold for detection consideration
                                print("Detection \(i): confidence = \(confidence)")
                                bestConfidence = max(bestConfidence, confidence)
                                let objectType = self.currentModelName == "BikesModel" ? "bike" : "traffic_sign"
                                newDetections.append((identifier: "\(objectType)_\(i)", confidence: confidence))
                                
                                // Higher confidence threshold with ultra-precise validation
                                if confidence > 0.5 && !detectedTrafficSign {
                                    detectedTrafficSign = self.evaluateUltraPreciseDetection(confidence: confidence, now: now)
                                    if detectedTrafficSign {
                                        print("🎯 ULTRA-PRECISE HIGH CONFIDENCE DETECTION: \(confidence) for \(self.currentModelName)")
                                        break
                                    }
                                }
                            }
                        }
                    }
                }
            } else if let recognizedObject = result as? VNRecognizedObjectObservation {
                // Handle object detection with recognized objects
                print("Recognized object: \(recognizedObject.labels)")
                for label in recognizedObject.labels {
                    print("Label: \(label.identifier), Confidence: \(label.confidence)")
                    newDetections.append((identifier: label.identifier, confidence: label.confidence))
                    
                    // Check if it matches the current challenge type
                    let identifier = label.identifier.lowercased()
                    var isTargetObject = false
                    
                    if self.currentModelName == "BikesModel" {
                        // Look for bike-related detections
                        if identifier.contains("bike") || identifier.contains("bicycle") || 
                           identifier.contains("cycle") || identifier.contains("سياكل") {
                            isTargetObject = true
                        }
                    } else {
                        // Look for traffic sign detections
                        if identifier.contains("traffic") || identifier.contains("sign") || 
                           identifier.contains("stop") || identifier.contains("light") {
                            isTargetObject = true
                        }
                    }
                    
                    if isTargetObject {
                        bestConfidence = max(bestConfidence, label.confidence)
                        // Ultra-precise threshold with enhanced validation
                        if label.confidence > 0.75 && !detectedTrafficSign {
                            detectedTrafficSign = self.evaluateUltraPreciseDetection(confidence: label.confidence, now: now)
                            if detectedTrafficSign {
                                print("🎯 \(self.currentModelName.uppercased()) ULTRA-PRECISELY DETECTED: \(label.identifier) - \(label.confidence)")
                                break
                            }
                        }
                    }
                }
            }
        }
        
        print("=== End Object Detection Results ===")
        
        DispatchQueue.main.async {
            self.lastDetectionConfidence = bestConfidence > 0.1 ? bestConfidence : nil
            
            // Update recent detections for UI (keep top 5)
            self.recentDetections = Array(newDetections.sorted { $0.confidence > $1.confidence }.prefix(5))
            
            if detectedTrafficSign {
                let objectType = self.currentModelName == "BikesModel" ? "BIKE" : "TRAFFIC SIGN"
                print("🎯 \(objectType) DETECTION SUCCESS!")
                self.hasDetectedInThisSession = true
                self.lastDetectionTime = now
                self.onDetectionSuccess?()
            }
        }
    }
    
    // MARK: - Ultra-Precise Detection System
    private func evaluateUltraPreciseDetection(confidence: Float, now: Date) -> Bool {
        // Add current detection to history
        detectionHistory.append((confidence: confidence, timestamp: now))
        lastConfidenceValues.append(confidence)
        
        // Keep only recent confidence values (last 10 detections)
        if lastConfidenceValues.count > 10 {
            lastConfidenceValues.removeFirst()
        }
        
        // Clean up old detections outside the time window
        detectionHistory = detectionHistory.filter { now.timeIntervalSince($0.timestamp) <= detectionHistoryWindow }
        
        // Check for high-confidence detections
        let recentHighConfidenceDetections = detectionHistory.filter { $0.confidence > 0.5 }
        
        // Calculate statistics
        let averageConfidence = recentHighConfidenceDetections.reduce(0) { $0 + $1.confidence } / Float(max(recentHighConfidenceDetections.count, 1))
        let confidenceVariance = calculateConfidenceVariance()
        
        print("📊 Ultra-precise detection: \(recentHighConfidenceDetections.count) recent detections, avg: \(averageConfidence), variance: \(confidenceVariance)")
        
        // ULTRA-STRICT CRITERIA:
        // 1. Extremely high single detection (>0.85) with low variance OR
        // 2. Multiple excellent detections (>=5) with high average (>0.65) and stable confidence OR
        // 3. Many sustained detections (>=12) with good average (>0.55) and very stable confidence
        
        if confidence > 0.85 && confidenceVariance < 0.1 {
            print("✅ ULTRA-HIGH confidence single detection: \(confidence), variance: \(confidenceVariance)")
            return true
        } else if recentHighConfidenceDetections.count >= 5 && averageConfidence > 0.65 && confidenceVariance < maxConfidenceVariance {
            print("✅ EXCELLENT sustained detections: \(recentHighConfidenceDetections.count) detections, avg: \(averageConfidence), variance: \(confidenceVariance)")
            return true
        } else if recentHighConfidenceDetections.count >= 12 && averageConfidence > 0.55 && confidenceVariance < 0.1 {
            print("✅ ULTRA-SUSTAINED stable detections: \(recentHighConfidenceDetections.count) detections, avg: \(averageConfidence), variance: \(confidenceVariance)")
            return true
        }
        
        return false
    }
    
    private func calculateConfidenceVariance() -> Float {
        guard lastConfidenceValues.count > 1 else { return 0.0 }
        
        let mean = lastConfidenceValues.reduce(0, +) / Float(lastConfidenceValues.count)
        let squaredDifferences = lastConfidenceValues.map { pow($0 - mean, 2) }
        let variance = squaredDifferences.reduce(0, +) / Float(lastConfidenceValues.count - 1)
        
        return sqrt(variance) // Return standard deviation for easier interpretation
    }
}
