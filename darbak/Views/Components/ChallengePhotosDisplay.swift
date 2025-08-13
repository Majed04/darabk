//
//  ChallengePhotosDisplay.swift
//  darbak
//
//  Created by AI Assistant for displaying polaroid photos in place of challenge images
//

import SwiftUI

struct ChallengePhotosDisplay: View {
    @ObservedObject var galleryManager = PolaroidGalleryManager.shared
    
    private let maxVisiblePhotos = 6
    private let photoSize = CGSize(width: 100, height: 130) // Smaller size for horizontal layout
    
    var body: some View {
        if !galleryManager.photos.isEmpty {
            // Only show content when there are photos
            VStack(spacing: 0) {
                // Photos row
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(Array(galleryManager.photos.prefix(maxVisiblePhotos).enumerated()), id: \.element.id) { index, photo in
                            AsyncImageLoader(photo: photo) { image in
                                HorizontalPolaroidCard(
                                    image: image,
                                    photo: photo,
                                    index: index
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20) // Add vertical padding for rotated cards
                }
                .frame(height: 170) // Fixed height that accommodates rotated cards
            }
        } else {
            // Empty space when no photos - no challenge image
            Rectangle()
                .fill(Color.clear)
                .frame(height: 20)
        }
    }
}

// MARK: - Horizontal Polaroid Card
struct HorizontalPolaroidCard: View {
    let image: UIImage?
    let photo: PolaroidPhoto
    let index: Int
    
    @State private var hasAppeared = false
    
    private let cardSize = CGSize(width: 100, height: 130)
    
    var body: some View {
        VStack(spacing: 0) {
            // Photo area (4:3 ratio)
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
                                .font(.caption)
                                .foregroundColor(.gray)
                        )
                }
            }
            .frame(width: 99, height: 115) // Maximum photo area - almost entire card
            .cornerRadius(1)
            .clipped()
            .padding(.horizontal, 0.5) // Near-zero border
            .padding(.top, 0.5) // Near-zero top border
            
            // Caption area
            VStack(spacing: 3) {
                Text(photo.caption)
                    .font(.custom("Kalam-Regular", size: 8))
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                
                HStack(spacing: 2) {
                    Text(photo.confidenceText)
                        .font(.system(size: 6, weight: .bold))
                        .foregroundColor(.green)
                    
                    Text("•")
                        .font(.system(size: 4))
                        .foregroundColor(.gray)
                    
                    Text(formatTime(photo.timestamp))
                        .font(.system(size: 5))
                        .foregroundColor(.gray)
                }
            }
            .frame(height: 14) // Minimal caption area for maximum photo space
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 0.5) // Match photo near-zero padding
            .padding(.bottom, 0.5) // Near-zero bottom border
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .background(Color.white)
        .cornerRadius(6)
        .shadow(
            color: Color.black.opacity(0.12),
            radius: 3,
            x: 1,
            y: 2
        )
        .rotationEffect(.degrees(randomRotation))
        .scaleEffect(hasAppeared ? 1.0 : 0.1)
        .opacity(hasAppeared ? 1.0 : 0.0)
        .animation(
            .spring(response: 0.6, dampingFraction: 0.8)
            .delay(Double(index) * 0.2), // Staggered animation based on order
            value: hasAppeared
        )
        .onAppear {
            hasAppeared = true
        }
    }
    
    private var randomRotation: Double {
        // Consistent random rotation based on photo ID
        let hash = photo.id.hashValue
        return Double((hash % 13) - 6) // Range: -6 to +6 degrees (smaller rotation to prevent cropping)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Preview
struct ChallengePhotosDisplay_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ChallengePhotosDisplay()
                .padding()
            
            Spacer()
        }
        .background(Color.gray.opacity(0.1))
    }
}
