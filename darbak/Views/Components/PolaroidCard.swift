//
//  PolaroidCard.swift
//  darbak
//
//  Created by AI Assistant for Polaroid Photo Gallery feature
//

import SwiftUI

struct PolaroidCard: View {
    let photo: PolaroidPhoto
    let image: UIImage?
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    @State private var dragOffset = CGSize.zero
    @State private var isPressed = false
    @GestureState private var isLongPressing = false
    
    // Animation properties
    @State private var cardRotation: Double = 0
    @State private var cardScale: CGFloat = 1.0
    @State private var shadowRadius: CGFloat = 8
    @State private var shadowOpacity: Double = 0.2
    
    private let baseSize = CGSize(width: 200, height: 260)
    
    var body: some View {
        VStack(spacing: 0) {
            // Photo area
            photoArea
            
            // Caption area
            captionArea
        }
        .frame(width: baseSize.width, height: baseSize.height)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(
            color: Color.black.opacity(shadowOpacity),
            radius: shadowRadius,
            x: 2,
            y: 4
        )
        .scaleEffect(cardScale)
        .rotationEffect(.degrees(cardRotation))
        .offset(dragOffset)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isSelected)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dragOffset)
        .gesture(cardGesture)
        .onAppear {
            setupInitialState()
        }
        .onChange(of: isSelected) { selected in
            updateSelectionState(selected)
        }
        .zIndex(isSelected ? 1000 : photo.effectivePosition.zIndex)
    }
    
    // MARK: - Photo Area
    private var photoArea: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // Placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundColor(.gray)
                            Text("جاري التحميل...")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    )
            }
        }
        .frame(height: 180) // Bigger image area - increased from 150 to 180
        .cornerRadius(4)
        .clipped()
        .padding(.horizontal, 12) // Reduced padding to give more space to image
        .padding(.top, 12) // Reduced padding to give more space to image
    }
    
    // MARK: - Caption Area
    private var captionArea: some View {
        VStack(spacing: 6) {
            // Main caption
            Text(photo.caption)
                .font(.custom("Kalam-Regular", size: 16))
                .fontWeight(.medium)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Timestamp
            Text(photo.arabicTimestamp)
                .font(.caption2)
                .foregroundColor(.black.opacity(0.6))
            
            // Confidence/match indicator
            if !photo.confidenceText.isEmpty {
                Text(photo.confidenceText)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(confidenceColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(confidenceColor.opacity(0.15))
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12) // Reduced padding to match image area
        .padding(.bottom, 12) // Reduced padding to match image area
        .frame(height: 80) // Reduced caption area to give more space to image
    }
    
    // MARK: - Computed Properties
    private var confidenceColor: Color {
        if let confidence = photo.detectionData.confidence {
            if confidence >= 0.8 { return .green }
            if confidence >= 0.6 { return .orange }
            return .red
        } else if let colorMatch = photo.detectionData.colorMatch {
            if colorMatch >= 80 { return .green }
            if colorMatch >= 60 { return .orange }
            return .red
        }
        return .gray
    }
    
    // MARK: - Gesture Handling
    private var cardGesture: some Gesture {
        let tapGesture = TapGesture()
            .onEnded { _ in
                onTap()
            }
        
        let longPressGesture = LongPressGesture(minimumDuration: 0.5)
            .updating($isLongPressing) { value, state, _ in
                state = value
            }
            .onEnded { _ in
                onLongPress()
            }
        
        let dragGesture = DragGesture()
            .onChanged { value in
                if isSelected {
                    dragOffset = value.translation
                }
            }
            .onEnded { value in
                if isSelected {
                    // Apply spring animation back to position
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        dragOffset = .zero
                    }
                }
            }
        
        return tapGesture
            .simultaneously(with: longPressGesture)
            .simultaneously(with: dragGesture)
    }
    
    // MARK: - Animation Methods
    private func setupInitialState() {
        // Set initial rotation from photo position
        cardRotation = photo.effectivePosition.rotation
        
        // Add slight entrance animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.9).delay(Double.random(in: 0...0.3))) {
            cardScale = 1.0
        }
    }
    
    private func updateSelectionState(_ selected: Bool) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            if selected {
                cardScale = 1.1
                shadowRadius = 15
                shadowOpacity = 0.4
                cardRotation = 0 // Straighten when selected
            } else {
                cardScale = 1.0
                shadowRadius = 8
                shadowOpacity = 0.2
                cardRotation = photo.effectivePosition.rotation // Return to original rotation
            }
        }
    }
    
    // MARK: - Press Animation
    private func updatePressState(_ pressed: Bool) {
        withAnimation(.easeInOut(duration: 0.1)) {
            isPressed = pressed
            cardScale = pressed ? 0.95 : (isSelected ? 1.1 : 1.0)
        }
    }
}

// MARK: - Interactive Polaroid Card
struct InteractivePolaroidCard: View {
    let photo: PolaroidPhoto
    @ObservedObject var galleryManager: PolaroidGalleryManager
    @Binding var selectedPhotoId: String?
    @Binding var rearrangementMode: Bool
    
    @State private var loadedImage: UIImage?
    @State private var position: CGPoint
    @State private var isDragging = false
    
    init(
        photo: PolaroidPhoto,
        galleryManager: PolaroidGalleryManager,
        selectedPhotoId: Binding<String?>,
        rearrangementMode: Binding<Bool>
    ) {
        self.photo = photo
        self.galleryManager = galleryManager
        self._selectedPhotoId = selectedPhotoId
        self._rearrangementMode = rearrangementMode
        self._position = State(initialValue: photo.effectivePosition.center)
    }
    
    var body: some View {
        PolaroidCard(
            photo: photo,
            image: loadedImage,
            isSelected: selectedPhotoId == photo.id,
            onTap: {
                handleTap()
            },
            onLongPress: {
                handleLongPress()
            }
        )
        .position(position)
        .gesture(rearrangementMode ? rearrangementGesture : nil)
        .onAppear {
            loadImage()
        }
        .onChange(of: photo.effectivePosition.center) { newCenter in
            if !isDragging {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    position = newCenter
                }
            }
        }
    }
    
    private var rearrangementGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                isDragging = true
                position = value.location
            }
            .onEnded { value in
                isDragging = false
                
                // Update photo position
                let newPosition = PhotoPosition(
                    center: value.location,
                    rotation: photo.effectivePosition.rotation,
                    zIndex: photo.effectivePosition.zIndex
                )
                
                Task {
                    await galleryManager.updatePhotoPosition(photo, position: newPosition)
                }
            }
    }
    
    private func handleTap() {
        if rearrangementMode {
            // In rearrangement mode, tap to select/deselect
            selectedPhotoId = selectedPhotoId == photo.id ? nil : photo.id
        } else {
            // Normal mode: bring to front and show details
            selectedPhotoId = photo.id
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
    
    private func handleLongPress() {
        if !rearrangementMode {
            rearrangementMode = true
            selectedPhotoId = photo.id
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
    
    private func loadImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            let image = galleryManager.loadThumbnailImage(for: photo)
            
            DispatchQueue.main.async {
                loadedImage = image
            }
        }
    }
}

// MARK: - Preview
struct PolaroidCard_Previews: PreviewProvider {
    static var previews: some View {
        let samplePhoto = PolaroidPhoto(
            id: "sample",
            originalImagePath: "",
            polaroidImagePath: "",
            thumbnailImagePath: "",
            challengeType: .object,
            detectionData: DetectionData(
                objectDetection: "سيارات",
                objectType: "car",
                confidence: 0.87,
                boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.3)
            ),
            caption: "لقيت سيارة",
            timestamp: Date(),
            userPosition: PhotoPosition(
                center: CGPoint(x: 200, y: 300),
                rotation: 5.0,
                zIndex: 1.0
            )
        )
        
        PolaroidCard(
            photo: samplePhoto,
            image: nil,
            isSelected: false,
            onTap: {},
            onLongPress: {}
        )
        .padding()
        .background(Color.gray.opacity(0.1))
        .previewLayout(.sizeThatFits)
    }
}
