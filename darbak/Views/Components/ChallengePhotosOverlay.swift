//
//  ChallengePhotosOverlay.swift
//  darbak
//
//  Created by AI Assistant for in-challenge polaroid display
//

import SwiftUI

struct ChallengePhotosOverlay: View {
    @ObservedObject var galleryManager = PolaroidGalleryManager.shared
    
    private let maxVisiblePhotos = 3
    private let photoSize = CGSize(width: 80, height: 104) // Smaller display size
    
    var body: some View {
        if !galleryManager.currentChallengePhotos.isEmpty {
            VStack {
                HStack {
                    Spacer()
                    
                    // Photos stack
                    photosStack
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.top, DesignSystem.Spacing.md)
                
                Spacer()
            }
            .ignoresSafeArea(.all, edges: .top)
        }
    }
    
    private var photosStack: some View {
        ZStack {
            ForEach(Array(galleryManager.currentChallengePhotos.prefix(maxVisiblePhotos).enumerated()), id: \.element.id) { index, photo in
                
                AsyncImageLoader(photo: photo) { image in
                    PolaroidMiniCard(
                        image: image,
                        photo: photo,
                        stackIndex: index
                    )
                }
            }
        }
    }
}

// MARK: - Polaroid Mini Card
struct PolaroidMiniCard: View {
    let image: UIImage?
    let photo: PolaroidPhoto
    let stackIndex: Int
    
    @State private var hasAppeared = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Photo area
            ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        )
                }
            }
            .frame(width: 60, height: 45) // Mini photo area
            .cornerRadius(3)
            .clipped()
            .padding(.horizontal, 6)
            .padding(.top, 6)
            
            // Mini caption area
            VStack(spacing: 2) {
                Text(photo.caption)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                
                Text(photo.confidenceText)
                    .font(.system(size: 6, weight: .bold))
                    .foregroundColor(.green)
            }
            .frame(height: 25)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 6)
            .padding(.bottom, 6)
        }
        .frame(width: 72, height: 76) // Mini polaroid size
        .background(Color.white)
        .cornerRadius(4)
        .shadow(
            color: Color.black.opacity(0.2),
            radius: 3,
            x: 1,
            y: 2
        )
        .rotationEffect(.degrees(Double.random(in: -8...8)))
        .offset(
            x: CGFloat(stackIndex) * 8,
            y: CGFloat(stackIndex) * 6
        )
        .scaleEffect(hasAppeared ? 1.0 : 0.5)
        .opacity(hasAppeared ? 1.0 : 0.0)
        .animation(
            .spring(response: 0.6, dampingFraction: 0.8)
            .delay(Double(stackIndex) * 0.1),
            value: hasAppeared
        )
        .onAppear {
            hasAppeared = true
        }
    }
}

// MARK: - Async Image Loader
struct AsyncImageLoader<Content: View>: View {
    let photo: PolaroidPhoto
    let content: (UIImage?) -> Content
    
    @State private var loadedImage: UIImage?
    
    init(photo: PolaroidPhoto, @ViewBuilder content: @escaping (UIImage?) -> Content) {
        self.photo = photo
        self.content = content
    }
    
    var body: some View {
        content(loadedImage)
            .onAppear {
                loadImage()
            }
    }
    
    private func loadImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            let image = PolaroidGalleryManager.shared.loadThumbnailImage(for: photo)
            
            DispatchQueue.main.async {
                loadedImage = image
            }
        }
    }
}

// MARK: - Preview
struct ChallengePhotosOverlay_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ChallengePhotosOverlay()
        }
    }
}
