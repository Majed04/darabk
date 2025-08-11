//
//  ColorDetectionCameraView.swift
//  darbak
//
//  Created by AI Assistant for color detection challenges
//

import SwiftUI
import AVFoundation
import CoreImage
import Combine

struct ColorDetectionCameraView: View {
    @Binding var isPresented: Bool
    @ObservedObject var challengeProgress: ChallengeProgress
    let onDetectionComplete: () -> Void
    let targetColor: String // "green", "red", "blue", etc.
    
    @StateObject private var cameraModel = ColorDetectionCameraModel()
    @State private var showingDetectionFeedback = false
    @State private var currentZoomFactor: CGFloat = 1.0
    @State private var lastZoomFactor: CGFloat = 1.0
    @State private var detectionTimer: Timer?
    @State private var colorMatchPercentage: Float = 0.0
    
    var body: some View {
        ZStack {
            // Camera preview with pinch gesture
            ColorCameraPreview(session: cameraModel.session)
                .ignoresSafeArea()
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let newZoom = max(1.0, min(10.0, lastZoomFactor * value))
                            cameraModel.setZoomFactor(newZoom)
                            currentZoomFactor = newZoom
                        }
                        .onEnded { _ in
                            lastZoomFactor = currentZoomFactor
                        }
                )
            
            // UI overlay
            VStack(spacing: 0) {
                // Top section with challenge title and controls
                VStack(spacing: DesignSystem.Spacing.md) {
                    // Challenge title header
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Text("تحدي الألوان")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("صور أشياء \(getColorNameInArabic(targetColor))")
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
                            cameraModel.switchCamera()
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
                
                VStack(spacing: DesignSystem.Spacing.md) {
                    // Color detection display
                    if let dominantColor = cameraModel.dominantColor {
                        HStack(spacing: DesignSystem.Spacing.lg) {
                            // Color preview
                            Color(dominantColor)
                                .frame(width: 80, height: 80)
                                .cornerRadius(DesignSystem.CornerRadius.large)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                                        .stroke(Color.white, lineWidth: 3)
                                )
                                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                            
                            // Color match percentage
                            VStack(spacing: DesignSystem.Spacing.xs) {
                                Text("نسبة التطابق")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text("\(Int(colorMatchPercentage))%")
                                    .font(DesignSystem.Typography.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(getMatchColor())
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, DesignSystem.Spacing.xl)
                        .padding(.vertical, DesignSystem.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                                .fill(Color.black.opacity(0.8))
                        )
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                    }
                    
                    // Instructions card at the bottom
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Text("تعليمات")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("وجه الكاميرا نحو أشياء \(getColorNameInArabic(targetColor)) لتحقيق نسبة تطابق عالية")
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
                    .padding(.bottom, DesignSystem.Spacing.xl)
                }
            }
            
            // Success overlay
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
                        Text("تم اكتشاف اللون!")
                            .font(DesignSystem.Typography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("تم العثور على \(getColorNameInArabic(targetColor)) بنجاح!")
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
            cameraModel.startSession()
            cameraModel.targetColor = targetColor
            startDetectionTimer()
        }
        .onDisappear {
            cameraModel.stopSession()
            detectionTimer?.invalidate()
        }
        .onChange(of: cameraModel.dominantColor) { _ in
            updateColorMatch()
        }
    }
    
    // MARK: - Helper Functions
    private func getColorNameInArabic(_ color: String) -> String {
        switch color.lowercased() {
        case "green": return "خضراء"
        case "red": return "حمراء"
        case "blue": return "زرقاء"
        case "yellow": return "صفراء"
        case "orange": return "برتقالية"
        case "purple": return "بنفسجية"
        case "pink": return "زهرية"
        case "brown": return "بنية"
        case "black": return "سوداء"
        case "white": return "بيضاء"
        default: return "ملونة"
        }
    }
    
    private func getMatchColor() -> Color {
        if colorMatchPercentage >= 80 { return .green }
        if colorMatchPercentage >= 60 { return .orange }
        return .red
    }
    
    private func updateColorMatch() {
        guard let dominantColor = cameraModel.dominantColor else {
            colorMatchPercentage = 0
            return
        }
        
        colorMatchPercentage = calculateColorMatch(dominantColor: dominantColor, target: targetColor)
    }
    
    private func calculateColorMatch(dominantColor: UIColor, target: String) -> Float {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        dominantColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let targetColor = getTargetColorRGB(target)
        
        // Calculate similarity using RGB distance
        let distance = sqrt(
            pow(red - targetColor.r, 2) +
            pow(green - targetColor.g, 2) +
            pow(blue - targetColor.b, 2)
        )
        
        // Convert distance to similarity percentage (0-100)
        let maxDistance: CGFloat = sqrt(3) // Maximum possible RGB distance
        let similarity = max(0, (1 - distance / maxDistance)) * 100
        
        return Float(similarity)
    }
    
    private func getTargetColorRGB(_ color: String) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
        switch color.lowercased() {
        case "green": return (0.0, 0.8, 0.0)
        case "red": return (0.8, 0.0, 0.0)
        case "blue": return (0.0, 0.0, 0.8)
        case "yellow": return (1.0, 1.0, 0.0)
        case "orange": return (1.0, 0.5, 0.0)
        case "purple": return (0.5, 0.0, 0.5)
        case "pink": return (1.0, 0.4, 0.7)
        case "brown": return (0.6, 0.3, 0.1)
        case "black": return (0.0, 0.0, 0.0)
        case "white": return (1.0, 1.0, 1.0)
        default: return (0.5, 0.5, 0.5)
        }
    }
    
    private func startDetectionTimer() {
        detectionTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            checkForSuccessfulDetection()
        }
    }
    
    private func checkForSuccessfulDetection() {
        if colorMatchPercentage >= 75 {
            handleDetectionSuccess()
        }
    }
    
    private func handleDetectionSuccess() {
        detectionTimer?.invalidate()
        
        // Gentle haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        
        // Show success animation
        showingDetectionFeedback = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showingDetectionFeedback = false
            onDetectionComplete()
            isPresented = false
        }
    }
}

// MARK: - Color Detection Camera Model
class ColorDetectionCameraModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var dominantColor: UIColor?
    let session = AVCaptureSession()
    private let context = CIContext()
    private var currentDevice: AVCaptureDevice?
    var targetColor: String = "green"
    
    func startSession() {
        session.beginConfiguration()
        session.sessionPreset = .medium
        
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        currentDevice = device
        
        if session.canAddInput(input) { session.addInput(input) }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "colorVideoQueue"))
        if session.canAddOutput(output) { session.addOutput(output) }
        
        session.commitConfiguration()
        
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
        }
    }
    
    func stopSession() {
        session.stopRunning()
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
        guard let currentInput = session.inputs.first as? AVCaptureDeviceInput else { return }
        
        let newPosition: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back
        
        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else {
            return
        }
        
        do {
            let newInput = try AVCaptureDeviceInput(device: newDevice)
            
            session.beginConfiguration()
            session.removeInput(currentInput)
            
            if session.canAddInput(newInput) {
                session.addInput(newInput)
                currentDevice = newDevice
            } else {
                session.addInput(currentInput)
            }
            
            session.commitConfiguration()
        } catch {
            print("Could not switch camera: \(error)")
        }
    }
    
    // MARK: - Frame Processing
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        DispatchQueue.main.async {
            self.dominantColor = self.getDominantColor(from: ciImage)
        }
    }
    
    private func getDominantColor(from ciImage: CIImage) -> UIColor? {
        let extent = ciImage.extent
        let filter = CIFilter(name: "CIAreaAverage",
                              parameters: [kCIInputImageKey: ciImage,
                                           kCIInputExtentKey: CIVector(cgRect: extent)])
        guard let outputImage = filter?.outputImage else { return nil }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(outputImage,
                       toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: CGColorSpaceCreateDeviceRGB())
        
        return UIColor(red: CGFloat(bitmap[0]) / 255,
                       green: CGFloat(bitmap[1]) / 255,
                       blue: CGFloat(bitmap[2]) / 255,
                       alpha: CGFloat(bitmap[3]) / 255)
    }
}

// MARK: - Color Camera Preview View
struct ColorCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = UIScreen.main.bounds
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
