//
//  PolaroidGenerator.swift
//  darbak
//
//  Created by AI Assistant for Polaroid Photo Gallery feature
//

import UIKit
import CoreImage
import AVFoundation

class PolaroidGenerator {
    
    // MARK: - Constants
    private struct Constants {
        static let polaroidSize = CGSize(width: 300, height: 390)  // File size (display: 200x260)
        static let borderWidth: CGFloat = 18
        static let photoAspectRatio: CGFloat = 4.0/3.0
        static let captionHeight: CGFloat = 90
        static let cornerRadius: CGFloat = 8
        
        // Typography
        static let captionFontSize: CGFloat = 20
        static let timestampFontSize: CGFloat = 14
        static let lineSpacing: CGFloat = 4
        
        // Colors
        static let backgroundColor = UIColor.white
        static let textColor = UIColor.black
        static let shadowColor = UIColor.black.withAlphaComponent(0.15)
        static let shadowOffset = CGSize(width: 0, height: 2)
        static let shadowRadius: CGFloat = 4
    }
    
    private let context = CIContext()
    
    // MARK: - Main Generation Method
    func generatePolaroid(
        from pixelBuffer: CVPixelBuffer,
        detectionData: DetectionData,
        challengeType: ChallengeType
    ) async throws -> UIImage {
        
        // Convert pixel buffer to UIImage
        let capturedImage = try await convertPixelBufferToUIImage(pixelBuffer)
        
        // Generate caption
        let caption = ArabicCaptionGenerator.generateCaption(
            for: detectionData,
            challengeType: challengeType
        )
        
        // Create polaroid layout
        return try await createPolaroidLayout(
            photo: capturedImage,
            caption: caption,
            timestamp: Date(),
            detectionData: detectionData
        )
    }
    
    // MARK: - Pixel Buffer Conversion
    private func convertPixelBufferToUIImage(_ pixelBuffer: CVPixelBuffer) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                
                // Apply orientation correction for portrait mode
                // Camera captures in landscape, we want portrait polaroids
                let orientedImage = ciImage.oriented(.right)
                
                guard let cgImage = self.context.createCGImage(orientedImage, from: orientedImage.extent) else {
                    continuation.resume(throwing: PolaroidError.imageProcessingFailed)
                    return
                }
                
                let uiImage = UIImage(cgImage: cgImage)
                continuation.resume(returning: uiImage)
            }
        }
    }
    
    // MARK: - Polaroid Layout Creation
    private func createPolaroidLayout(
        photo: UIImage,
        caption: String,
        timestamp: Date,
        detectionData: DetectionData
    ) async throws -> UIImage {
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                
                // Calculate layout dimensions
                let totalSize = Constants.polaroidSize
                let photoAreaWidth = totalSize.width - (Constants.borderWidth * 2)
                let photoAreaHeight = photoAreaWidth / Constants.photoAspectRatio
                let photoAreaY = Constants.borderWidth
                
                let captionAreaY = photoAreaY + photoAreaHeight
                let captionAreaHeight = totalSize.height - captionAreaY - Constants.borderWidth
                
                // Create the polaroid canvas
                let renderer = UIGraphicsImageRenderer(
                    size: totalSize,
                    format: UIGraphicsImageRendererFormat()
                )
                
                let polaroidImage = renderer.image { context in
                    let cgContext = context.cgContext
                    
                    // Draw white background with rounded corners and shadow
                    self.drawPolaroidBackground(in: cgContext, size: totalSize)
                    
                    // Draw the photo
                    self.drawPhoto(
                        photo,
                        in: cgContext,
                        frame: CGRect(
                            x: Constants.borderWidth,
                            y: photoAreaY,
                            width: photoAreaWidth,
                            height: photoAreaHeight
                        )
                    )
                    
                    // Draw caption area
                    self.drawCaption(
                        caption,
                        timestamp: timestamp,
                        detectionData: detectionData,
                        in: cgContext,
                        frame: CGRect(
                            x: Constants.borderWidth,
                            y: captionAreaY,
                            width: photoAreaWidth,
                            height: captionAreaHeight
                        )
                    )
                }
                
                continuation.resume(returning: polaroidImage)
            }
        }
    }
    
    // MARK: - Drawing Methods
    private func drawPolaroidBackground(in context: CGContext, size: CGSize) {
        // Draw drop shadow
        context.saveGState()
        context.setShadow(
            offset: Constants.shadowOffset,
            blur: Constants.shadowRadius,
            color: Constants.shadowColor.cgColor
        )
        
        // Draw rounded rectangle background
        let backgroundRect = CGRect(origin: .zero, size: size)
        let backgroundPath = UIBezierPath(
            roundedRect: backgroundRect,
            cornerRadius: Constants.cornerRadius
        )
        
        context.setFillColor(Constants.backgroundColor.cgColor)
        context.addPath(backgroundPath.cgPath)
        context.fillPath()
        
        context.restoreGState()
    }
    
    private func drawPhoto(_ photo: UIImage, in context: CGContext, frame: CGRect) {
        // Calculate aspect-fit scaling
        let photoSize = photo.size
        let photoAspect = photoSize.width / photoSize.height
        let frameAspect = frame.width / frame.height
        
        var drawRect = frame
        
        if photoAspect > frameAspect {
            // Photo is wider than frame
            let scaledHeight = frame.width / photoAspect
            drawRect = CGRect(
                x: frame.minX,
                y: frame.minY + (frame.height - scaledHeight) / 2,
                width: frame.width,
                height: scaledHeight
            )
        } else {
            // Photo is taller than frame
            let scaledWidth = frame.height * photoAspect
            drawRect = CGRect(
                x: frame.minX + (frame.width - scaledWidth) / 2,
                y: frame.minY,
                width: scaledWidth,
                height: frame.height
            )
        }
        
        // Clip to rounded corners (subtle rounding for photo area)
        let photoPath = UIBezierPath(
            roundedRect: frame,
            cornerRadius: 4
        )
        context.addPath(photoPath.cgPath)
        context.clip()
        
        // Draw the photo
        photo.draw(in: drawRect)
    }
    
    private func drawCaption(
        _ caption: String,
        timestamp: Date,
        detectionData: DetectionData,
        in context: CGContext,
        frame: CGRect
    ) {
        // Prepare text attributes for caption
        let captionFont = UIFont(name: "Kalam-Regular", size: Constants.captionFontSize) ??
                         UIFont.systemFont(ofSize: Constants.captionFontSize, weight: .medium)
        
        let captionAttributes: [NSAttributedString.Key: Any] = [
            .font: captionFont,
            .foregroundColor: Constants.textColor,
            .paragraphStyle: createParagraphStyle(alignment: .center, lineSpacing: Constants.lineSpacing)
        ]
        
        // Prepare text attributes for timestamp
        let timestampFont = UIFont.systemFont(ofSize: Constants.timestampFontSize, weight: .regular)
        let timestampAttributes: [NSAttributedString.Key: Any] = [
            .font: timestampFont,
            .foregroundColor: Constants.textColor.withAlphaComponent(0.7),
            .paragraphStyle: createParagraphStyle(alignment: .center)
        ]
        
        // Format timestamp in Arabic
        let timestampText = formatTimestampInArabic(timestamp)
        
        // Calculate text layout
        let captionSize = caption.boundingRect(
            with: CGSize(width: frame.width - 16, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: captionAttributes,
            context: nil
        ).size
        
        let timestampSize = timestampText.boundingRect(
            with: CGSize(width: frame.width - 16, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: timestampAttributes,
            context: nil
        ).size
        
        // Calculate vertical centering
        let totalTextHeight = captionSize.height + 8 + timestampSize.height
        let startY = frame.minY + (frame.height - totalTextHeight) / 2
        
        // Draw caption
        let captionRect = CGRect(
            x: frame.minX + 8,
            y: startY,
            width: frame.width - 16,
            height: captionSize.height
        )
        caption.draw(in: captionRect, withAttributes: captionAttributes)
        
        // Draw timestamp
        let timestampRect = CGRect(
            x: frame.minX + 8,
            y: startY + captionSize.height + 8,
            width: frame.width - 16,
            height: timestampSize.height
        )
        timestampText.draw(in: timestampRect, withAttributes: timestampAttributes)
        
        // Optionally draw confidence/match indicator
        if let confidence = detectionData.confidence {
            drawConfidenceIndicator(confidence, in: context, frame: frame)
        } else if let colorMatch = detectionData.colorMatch {
            drawColorMatchIndicator(colorMatch, in: context, frame: frame)
        }
    }
    
    private func drawConfidenceIndicator(_ confidence: Float, in context: CGContext, frame: CGRect) {
        // Draw a small confidence indicator in the corner
        let indicatorSize: CGFloat = 6
        let indicatorRect = CGRect(
            x: frame.maxX - indicatorSize - 8,
            y: frame.minY + 8,
            width: indicatorSize,
            height: indicatorSize
        )
        
        let indicatorColor: UIColor
        if confidence >= 0.8 {
            indicatorColor = UIColor.systemGreen
        } else if confidence >= 0.6 {
            indicatorColor = UIColor.systemOrange
        } else {
            indicatorColor = UIColor.systemRed
        }
        
        context.setFillColor(indicatorColor.cgColor)
        context.fillEllipse(in: indicatorRect)
    }
    
    private func drawColorMatchIndicator(_ colorMatch: Float, in context: CGContext, frame: CGRect) {
        // Similar to confidence indicator but for color matching
        let indicatorSize: CGFloat = 6
        let indicatorRect = CGRect(
            x: frame.maxX - indicatorSize - 8,
            y: frame.minY + 8,
            width: indicatorSize,
            height: indicatorSize
        )
        
        let indicatorColor: UIColor
        if colorMatch >= 80 {
            indicatorColor = UIColor.systemGreen
        } else if colorMatch >= 60 {
            indicatorColor = UIColor.systemOrange
        } else {
            indicatorColor = UIColor.systemRed
        }
        
        context.setFillColor(indicatorColor.cgColor)
        context.fillEllipse(in: indicatorRect)
    }
    
    // MARK: - Helper Methods
    private func createParagraphStyle(alignment: NSTextAlignment, lineSpacing: CGFloat = 0) -> NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineSpacing = lineSpacing
        return paragraphStyle
    }
    
    private func formatTimestampInArabic(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar")
        
        // Use a simple format showing time
        formatter.dateFormat = "HH:mm"
        let timeString = formatter.string(from: date)
        
        // Get day of week in Arabic
        formatter.dateFormat = "EEEE"
        let dayString = formatter.string(from: date)
        
        return "\(dayString) \(timeString)"
    }
}

// MARK: - Error Types
enum PolaroidError: LocalizedError {
    case imageProcessingFailed
    case invalidPixelBuffer
    case renderingFailed
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "فشل في معالجة الصورة"
        case .invalidPixelBuffer:
            return "بيانات الصورة غير صالحة"
        case .renderingFailed:
            return "فشل في إنشاء الصورة"
        }
    }
}

// MARK: - Thumbnail Generator Extension
extension PolaroidGenerator {
    
    // Generate compressed thumbnail
    func generateThumbnail(from polaroidImage: UIImage, size: CGSize = CGSize(width: 100, height: 130)) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            polaroidImage.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    // Generate optimized display image
    func generateDisplayImage(from polaroidImage: UIImage, size: CGSize = CGSize(width: 200, height: 260)) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            polaroidImage.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
