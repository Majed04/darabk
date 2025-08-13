//
//  PolaroidModels.swift
//  darbak
//
//  Created by AI Assistant for Polaroid Photo Gallery feature
//

import Foundation
import CoreGraphics

// MARK: - Challenge Type Enum
enum ChallengeType: String, Codable, CaseIterable {
    case object = "object"
    case color = "color"
    
    var displayName: String {
        switch self {
        case .object: return "كشف الأجسام"
        case .color: return "كشف الألوان"
        }
    }
}

// MARK: - Detection Data Model
struct DetectionData: Codable, Equatable {
    let challengeName: String
    let objectType: String?      // For object detection (e.g., "car", "cat")
    let confidence: Float?       // Detection confidence score
    let targetColor: String?     // For color detection (e.g., "red", "blue")
    let colorMatch: Float?       // Color match percentage
    let boundingBox: CGRect?     // Bounding box for object detection
    
    // Convenience initializers
    init(objectDetection challengeName: String, objectType: String, confidence: Float, boundingBox: CGRect) {
        self.challengeName = challengeName
        self.objectType = objectType
        self.confidence = confidence
        self.targetColor = nil
        self.colorMatch = nil
        self.boundingBox = boundingBox
    }
    
    init(colorDetection challengeName: String, targetColor: String, colorMatch: Float) {
        self.challengeName = challengeName
        self.objectType = nil
        self.confidence = nil
        self.targetColor = targetColor
        self.colorMatch = colorMatch
        self.boundingBox = nil
    }
}

// MARK: - Photo Position Model
struct PhotoPosition: Codable, Equatable {
    let center: CGPoint
    let rotation: Double  // Rotation angle in degrees
    let zIndex: Double    // Z-order for layering
    
    init(center: CGPoint, rotation: Double = 0.0, zIndex: Double = 0.0) {
        self.center = center
        self.rotation = rotation
        self.zIndex = zIndex
    }
    
    // Generate random position for new photos
    static func randomPosition(in bounds: CGSize, withZIndex zIndex: Double) -> PhotoPosition {
        let padding: CGFloat = 120 // Keep photos away from edges
        let centerX = CGFloat.random(in: padding...(bounds.width - padding))
        let centerY = CGFloat.random(in: padding...(bounds.height - padding))
        let rotation = Double.random(in: -12...12) // Random rotation between -12° and +12°
        
        return PhotoPosition(
            center: CGPoint(x: centerX, y: centerY),
            rotation: rotation,
            zIndex: zIndex
        )
    }
}

// MARK: - Polaroid Photo Model
struct PolaroidPhoto: Identifiable, Codable, Equatable {
    let id: String
    let originalImagePath: String    // Path to original camera capture
    let polaroidImagePath: String    // Path to generated polaroid image
    let thumbnailImagePath: String   // Path to compressed thumbnail
    let challengeType: ChallengeType
    let detectionData: DetectionData
    let caption: String              // Arabic caption text
    let timestamp: Date
    var userPosition: PhotoPosition? // Custom user-arranged position
    
    // Computed properties
    var displayName: String {
        switch challengeType {
        case .object:
            return detectionData.objectType ?? "جسم"
        case .color:
            return detectionData.targetColor ?? "لون"
        }
    }
    
    var confidenceText: String {
        if let confidence = detectionData.confidence {
            return "\(Int(confidence * 100))%"
        } else if let colorMatch = detectionData.colorMatch {
            return "\(Int(colorMatch))%"
        }
        return ""
    }
    
    var arabicTimestamp: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    // Default position when no user position is set
    var effectivePosition: PhotoPosition {
        return userPosition ?? PhotoPosition.randomPosition(
            in: CGSize(width: 800, height: 1200),
            withZIndex: timestamp.timeIntervalSince1970
        )
    }
    
    // Generate unique ID
    static func generateID() -> String {
        return UUID().uuidString
    }
    
    // Generate filename based on type and timestamp
    static func generateFilename(for type: ChallengeType, objectType: String?, colorType: String?) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        
        let identifier: String
        switch type {
        case .object:
            identifier = objectType?.lowercased().replacingOccurrences(of: " ", with: "_") ?? "object"
        case .color:
            identifier = colorType?.lowercased() ?? "color"
        }
        
        return "\(identifier)_\(timestamp)"
    }
}

// MARK: - Arabic Caption Generator
struct ArabicCaptionGenerator {
    
    // Object names mapping (English to Arabic)
    static let objectNames: [String: String] = [
        "car": "سيارة",
        "cat": "قطة",
        "bird": "طائر",
        "bus": "باص",
        "stop sign": "إشارة قف",
        "traffic light": "إشارة مرور",
        "bicycle": "دراجة",
        "bike": "دراجة",
        "truck": "شاحنة",
        "van": "فان",
        "person": "شخص",
        "dog": "كلب",
        "horse": "حصان",
        "sheep": "خروف",
        "cow": "بقرة",
        "elephant": "فيل",
        "bear": "دب",
        "zebra": "حمار وحشي",
        "giraffe": "زرافة",
        "backpack": "حقيبة ظهر",
        "umbrella": "مظلة",
        "handbag": "حقيبة يد",
        "tie": "ربطة عنق",
        "suitcase": "حقيبة سفر",
        "frisbee": "قرص طائر",
        "skis": "زلاجات",
        "snowboard": "لوح التزلج",
        "sports ball": "كرة رياضية",
        "kite": "طائرة ورقية",
        "baseball bat": "مضرب بيسبول",
        "baseball glove": "قفاز بيسبول",
        "skateboard": "لوح التزلج",
        "surfboard": "لوح ركوب الأمواج",
        "tennis racket": "مضرب تنس"
    ]
    
    // Color names mapping (English to Arabic)
    static let colorNames: [String: String] = [
        "red": "أحمر",
        "green": "أخضر",
        "blue": "أزرق",
        "yellow": "أصفر",
        "orange": "برتقالي",
        "purple": "بنفسجي",
        "pink": "زهري",
        "brown": "بني",
        "black": "أسود",
        "white": "أبيض",
        "gray": "رمادي",
        "grey": "رمادي"
    ]
    
    // Generate Arabic caption for object detection
    static func generateObjectCaption(objectType: String) -> String {
        let arabicName = objectNames[objectType.lowercased()] ?? objectType
        return "لقيت \(arabicName)"
    }
    
    // Generate Arabic caption for color detection
    static func generateColorCaption(colorType: String) -> String {
        let arabicName = colorNames[colorType.lowercased()] ?? colorType
        return "لقيت لون \(arabicName)"
    }
    
    // Generate caption based on detection data
    static func generateCaption(for detectionData: DetectionData, challengeType: ChallengeType) -> String {
        switch challengeType {
        case .object:
            return generateObjectCaption(objectType: detectionData.objectType ?? "جسم")
        case .color:
            return generateColorCaption(colorType: detectionData.targetColor ?? "لون")
        }
    }
}

// MARK: - Gallery Statistics
struct GalleryStatistics: Codable {
    let totalPhotos: Int
    let objectPhotos: Int
    let colorPhotos: Int
    let favoriteDetectionType: String?
    let firstPhotoDate: Date?
    let lastPhotoDate: Date?
    
    init(photos: [PolaroidPhoto]) {
        self.totalPhotos = photos.count
        self.objectPhotos = photos.filter { $0.challengeType == .object }.count
        self.colorPhotos = photos.filter { $0.challengeType == .color }.count
        
        // Find most frequent detection type
        let detectionCounts = photos.reduce(into: [String: Int]()) { counts, photo in
            let key = photo.detectionData.objectType ?? photo.detectionData.targetColor ?? "unknown"
            counts[key, default: 0] += 1
        }
        self.favoriteDetectionType = detectionCounts.max(by: { $0.value < $1.value })?.key
        
        // Find date range
        let sortedPhotos = photos.sorted { $0.timestamp < $1.timestamp }
        self.firstPhotoDate = sortedPhotos.first?.timestamp
        self.lastPhotoDate = sortedPhotos.last?.timestamp
    }
}
