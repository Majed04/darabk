//
//  PolaroidGalleryManager.swift
//  darbak
//
//  Created by AI Assistant for Polaroid Photo Gallery feature
//

import Foundation
import UIKit
import AVFoundation
import Combine

@MainActor
class PolaroidGalleryManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = PolaroidGalleryManager()
    
    // MARK: - Published Properties
    @Published var photos: [PolaroidPhoto] = []
    @Published var currentChallengePhotos: [PolaroidPhoto] = [] // Photos for current challenge session
    @Published var isLoading = false
    @Published var statistics: GalleryStatistics?
    
    // MARK: - Private Properties
    private let polaroidGenerator = PolaroidGenerator()
    private let fileManager = FileManager.default
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Storage Paths
    private lazy var documentsDirectory: URL = {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }()
    
    private lazy var galleryDirectory: URL = {
        documentsDirectory.appendingPathComponent("DarbakGallery")
    }()
    
    private lazy var photosDirectory: URL = {
        galleryDirectory.appendingPathComponent("photos")
    }()
    
    private lazy var originalsDirectory: URL = {
        photosDirectory.appendingPathComponent("original")
    }()
    
    private lazy var polaroidsDirectory: URL = {
        photosDirectory.appendingPathComponent("polaroids")
    }()
    
    private lazy var thumbnailsDirectory: URL = {
        photosDirectory.appendingPathComponent("thumbnails")
    }()
    
    private lazy var metadataURL: URL = {
        galleryDirectory.appendingPathComponent("gallery_metadata.json")
    }()
    
    private lazy var positionsURL: URL = {
        galleryDirectory.appendingPathComponent("user_positions.json")
    }()
    
    // MARK: - Constants
    private struct Constants {
        static let maxPhotos = 200
        static let jpegCompressionQuality: CGFloat = 0.85
        static let thumbnailCompressionQuality: CGFloat = 0.7
    }
    
    // MARK: - Initialization
    private init() {
        setupDirectories()
        loadPhotosFromDisk()
        
        // Update statistics when photos change
        $photos
            .map { GalleryStatistics(photos: $0) }
            .assign(to: \.statistics, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Directory Setup
    private func setupDirectories() {
        let directories = [
            galleryDirectory,
            photosDirectory,
            originalsDirectory,
            polaroidsDirectory,
            thumbnailsDirectory
        ]
        
        for directory in directories {
            do {
                try fileManager.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                print("❌ Failed to create directory \(directory): \(error)")
            }
        }
    }
    
    // MARK: - Main Capture Method
    func captureDetectionAsPolaroid(
        pixelBuffer: CVPixelBuffer,
        challengeType: ChallengeType,
        detectionData: DetectionData
    ) async {
        
        guard photos.count < Constants.maxPhotos else {
            await cleanupOldestPhotos()
            return
        }
        
        isLoading = true
        
        do {
            // Generate filenames
            let baseFilename = PolaroidPhoto.generateFilename(
                for: challengeType,
                objectType: detectionData.objectType,
                colorType: detectionData.targetColor
            )
            
            // Create paths
            let originalPath = originalsDirectory.appendingPathComponent("\(baseFilename).jpg").path
            let polaroidPath = polaroidsDirectory.appendingPathComponent("\(baseFilename).jpg").path
            let thumbnailPath = thumbnailsDirectory.appendingPathComponent("\(baseFilename).jpg").path
            
            // Generate polaroid image
            let polaroidImage = try await polaroidGenerator.generatePolaroid(
                from: pixelBuffer,
                detectionData: detectionData,
                challengeType: challengeType
            )
            
            // Save original frame
            let originalImage = convertPixelBufferToUIImage(pixelBuffer)
            try await saveImage(originalImage, to: originalPath, quality: Constants.jpegCompressionQuality)
            
            // Save polaroid image
            try await saveImage(polaroidImage, to: polaroidPath, quality: Constants.jpegCompressionQuality)
            
            // Generate and save thumbnail
            if let thumbnail = polaroidGenerator.generateThumbnail(from: polaroidImage) {
                try await saveImage(thumbnail, to: thumbnailPath, quality: Constants.thumbnailCompressionQuality)
            }
            
            // Create photo model
            let photo = PolaroidPhoto(
                id: PolaroidPhoto.generateID(),
                originalImagePath: originalPath,
                polaroidImagePath: polaroidPath,
                thumbnailImagePath: thumbnailPath,
                challengeType: challengeType,
                detectionData: detectionData,
                caption: ArabicCaptionGenerator.generateCaption(for: detectionData, challengeType: challengeType),
                timestamp: Date(),
                userPosition: nil
            )
            
            // Add to main collection (newest first)
            photos.insert(photo, at: 0)
            
            // Save metadata
            await saveMetadata()
            
            print("✅ Polaroid photo captured and saved: \(photo.displayName)")
            
        } catch {
            print("❌ Failed to capture polaroid: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Image Utilities
    private func convertPixelBufferToUIImage(_ pixelBuffer: CVPixelBuffer) -> UIImage {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return UIImage() // Return empty image as fallback
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func saveImage(_ image: UIImage, to path: String, quality: CGFloat) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let data = image.jpegData(compressionQuality: quality) else {
                    continuation.resume(throwing: PolaroidGalleryError.imageCompressionFailed)
                    return
                }
                
                do {
                    try data.write(to: URL(fileURLWithPath: path))
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Photo Management
    func deletePhoto(_ photo: PolaroidPhoto) async {
        // Remove files
        let paths = [photo.originalImagePath, photo.polaroidImagePath, photo.thumbnailImagePath]
        for path in paths {
            try? fileManager.removeItem(atPath: path)
        }
        
        // Remove from collection
        photos.removeAll { $0.id == photo.id }
        
        // Save updated metadata
        await saveMetadata()
        
        print("🗑️ Deleted photo: \(photo.displayName)")
    }
    
    func updatePhotoPosition(_ photo: PolaroidPhoto, position: PhotoPosition) async {
        guard let index = photos.firstIndex(where: { $0.id == photo.id }) else { return }
        
        var updatedPhoto = photo
        updatedPhoto.userPosition = position
        photos[index] = updatedPhoto
        
        await saveUserPositions()
    }
    
    private func cleanupOldestPhotos() async {
        let photosToRemove = photos.suffix(photos.count - Constants.maxPhotos + 10) // Remove 10 oldest
        
        for photo in photosToRemove {
            await deletePhoto(photo)
        }
    }
    
    // MARK: - Data Persistence
    private func saveMetadata() async {
        let metadata = photos.map { photo in
            PhotoMetadata(
                id: photo.id,
                originalImagePath: photo.originalImagePath,
                polaroidImagePath: photo.polaroidImagePath,
                thumbnailImagePath: photo.thumbnailImagePath,
                challengeType: photo.challengeType,
                detectionData: photo.detectionData,
                caption: photo.caption,
                timestamp: photo.timestamp
            )
        }
        
        do {
            let data = try JSONEncoder().encode(metadata)
            try data.write(to: metadataURL)
        } catch {
            print("❌ Failed to save metadata: \(error)")
        }
    }
    
    private func saveUserPositions() async {
        let positions = photos.compactMap { photo -> (String, PhotoPosition)? in
            guard let position = photo.userPosition else { return nil }
            return (photo.id, position)
        }
        
        let positionsDict = Dictionary(positions, uniquingKeysWith: { _, new in new })
        
        do {
            let data = try JSONEncoder().encode(positionsDict)
            try data.write(to: positionsURL)
        } catch {
            print("❌ Failed to save user positions: \(error)")
        }
    }
    
    private func loadPhotosFromDisk() {
        do {
            // Load metadata
            let metadataData = try Data(contentsOf: metadataURL)
            let metadata = try JSONDecoder().decode([PhotoMetadata].self, from: metadataData)
            
            // Load user positions
            var userPositions: [String: PhotoPosition] = [:]
            if fileManager.fileExists(atPath: positionsURL.path) {
                let positionsData = try Data(contentsOf: positionsURL)
                userPositions = try JSONDecoder().decode([String: PhotoPosition].self, from: positionsData)
            }
            
            // Convert to PolaroidPhoto objects
            photos = metadata.compactMap { meta in
                // Verify files exist
                guard fileManager.fileExists(atPath: meta.polaroidImagePath) else {
                    print("⚠️ Polaroid image missing: \(meta.polaroidImagePath)")
                    return nil
                }
                
                return PolaroidPhoto(
                    id: meta.id,
                    originalImagePath: meta.originalImagePath,
                    polaroidImagePath: meta.polaroidImagePath,
                    thumbnailImagePath: meta.thumbnailImagePath,
                    challengeType: meta.challengeType,
                    detectionData: meta.detectionData,
                    caption: meta.caption,
                    timestamp: meta.timestamp,
                    userPosition: userPositions[meta.id]
                )
            }
            
            // Sort by timestamp (newest first)
            photos.sort { $0.timestamp > $1.timestamp }
            
            print("✅ Loaded \(photos.count) photos from disk")
            
        } catch {
            print("📁 No existing photos found or failed to load: \(error)")
            photos = []
        }
    }
    
    // MARK: - Photo Loading
    func loadPolaroidImage(for photo: PolaroidPhoto) -> UIImage? {
        guard fileManager.fileExists(atPath: photo.polaroidImagePath) else {
            print("⚠️ Polaroid image not found: \(photo.polaroidImagePath)")
            return nil
        }
        
        return UIImage(contentsOfFile: photo.polaroidImagePath)
    }
    
    func loadThumbnailImage(for photo: PolaroidPhoto) -> UIImage? {
        guard fileManager.fileExists(atPath: photo.thumbnailImagePath) else {
            // Fallback to polaroid image if thumbnail missing
            return loadPolaroidImage(for: photo)
        }
        
        return UIImage(contentsOfFile: photo.thumbnailImagePath)
    }
    
    // MARK: - Challenge Session Management
    private var challengeCompleted = false
    
    func startChallengeSession() {
        // Clear all photos when starting a new challenge
        challengeCompleted = false
        Task {
            await clearAllPhotos()
        }
        print("🎯 Started new challenge session - photos cleared")
    }
    
    func completeChallengeSession() {
        // Mark challenge as completed - photos should be preserved
        challengeCompleted = true
        print("✅ Challenge completed - photos preserved")
    }
    
    func endChallengeSession() {
        // Only clear photos if challenge was not completed
        if !challengeCompleted {
            Task {
                await clearAllPhotos()
            }
            print("🏁 Ended challenge session - photos cleared (challenge not completed)")
        } else {
            print("🏁 Ended challenge session - photos preserved (challenge completed)")
        }
        // Reset the flag for next challenge
        challengeCompleted = false
    }
    
    // MARK: - Gallery Operations
    func clearAllPhotos() async {
        for photo in photos {
            await deletePhoto(photo)
        }
        
        photos.removeAll()
        await saveMetadata()
        
        print("🗑️ Cleared all photos from gallery")
    }
    
    func exportPhoto(_ photo: PolaroidPhoto) -> UIImage? {
        return loadPolaroidImage(for: photo)
    }
    
    // MARK: - Storage Info
    func getStorageInfo() -> (photosCount: Int, estimatedSize: String) {
        let count = photos.count
        let averageFileSize: Int64 = 150_000 // Approximate 150KB per photo
        let totalSize = Int64(count) * averageFileSize
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        
        return (count, formatter.string(fromByteCount: totalSize))
    }
}

// MARK: - Supporting Models
private struct PhotoMetadata: Codable {
    let id: String
    let originalImagePath: String
    let polaroidImagePath: String
    let thumbnailImagePath: String
    let challengeType: ChallengeType
    let detectionData: DetectionData
    let caption: String
    let timestamp: Date
}

// MARK: - Error Types
enum PolaroidGalleryError: LocalizedError {
    case imageCompressionFailed
    case fileWriteFailed
    case metadataSaveFailed
    
    var errorDescription: String? {
        switch self {
        case .imageCompressionFailed:
            return "فشل في ضغط الصورة"
        case .fileWriteFailed:
            return "فشل في حفظ الملف"
        case .metadataSaveFailed:
            return "فشل في حفظ بيانات الصور"
        }
    }
}
