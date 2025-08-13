//
//  PolaroidGalleryView.swift
//  darbak
//
//  Created by AI Assistant for Polaroid Photo Gallery feature
//

import SwiftUI

struct PolaroidGalleryView: View {
    @StateObject private var galleryManager = PolaroidGalleryManager.shared
    @State private var selectedPhotoId: String?
    @State private var rearrangementMode = false
    @State private var showingPhotoDetail = false
    @State private var zoomScale: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero
    @State private var showingMenu = false
    @State private var showingDeleteAlert = false
    @GestureState private var magnification: CGFloat = 1.0
    @GestureState private var panGesture: CGSize = .zero
    
    // Canvas size for scattered layout
    private let canvasSize = CGSize(width: 1440, height: 2160) // 1.8x screen dimensions
    private let minZoom: CGFloat = 0.5
    private let maxZoom: CGFloat = 3.0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark textured background
                backgroundView
                
                if galleryManager.photos.isEmpty {
                    // Empty state
                    emptyStateView
                } else {
                    // Gallery canvas
                    galleryCanvasView
                        .scaleEffect(zoomScale * magnification)
                        .offset(
                            x: panOffset.width + panGesture.width,
                            y: panOffset.height + panGesture.height
                        )
                        .gesture(galleryGestures)
                        .clipped()
                }
                
                // UI Overlays
                VStack {
                    // Top controls
                    if !galleryManager.photos.isEmpty {
                        topControlsView
                    }
                    
                    Spacer()
                    
                    // Bottom controls
                    if rearrangementMode {
                        rearrangementControlsView
                    }
                }
                .ignoresSafeArea(.all, edges: .top)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingPhotoDetail) {
                photoDetailView
            }
            .actionSheet(isPresented: $showingMenu) {
                galleryMenuActionSheet
            }
            .alert("حذف الصورة", isPresented: $showingDeleteAlert) {
                Button("حذف", role: .destructive) {
                    deleteSelectedPhoto()
                }
                Button("إلغاء", role: .cancel) {}
            } message: {
                Text("هل تريد حذف هذه الصورة نهائياً؟")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Background View
    private var backgroundView: some View {
        ZStack {
            // Base dark background
            Color.black
                .ignoresSafeArea()
            
            // Textured overlay
            Rectangle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.black.opacity(0.8),
                            Color.black.opacity(0.95)
                        ],
                        center: .center,
                        startRadius: 200,
                        endRadius: 800
                    )
                )
                .ignoresSafeArea()
            
            // Subtle grain texture
            Rectangle()
                .fill(Color.white.opacity(0.02))
                .blendMode(.overlay)
                .ignoresSafeArea()
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Icon
            Image("Star")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(.white.opacity(0.3))
            
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("لا توجد ذكريات بعد")
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("ابدأ التحديات لالتقاط صور تذكارية\nستظهر هنا كبطاقات بولارويد")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
    
    // MARK: - Gallery Canvas View
    private var galleryCanvasView: some View {
        ZStack {
            // Canvas background (transparent)
            Rectangle()
                .fill(Color.clear)
                .frame(width: canvasSize.width, height: canvasSize.height)
            
            // Photo cards
            ForEach(galleryManager.photos) { photo in
                InteractivePolaroidCard(
                    photo: photo,
                    galleryManager: galleryManager,
                    selectedPhotoId: $selectedPhotoId,
                    rearrangementMode: $rearrangementMode
                )
                .onTapGesture(count: 2) {
                    // Double tap to open detail view
                    selectedPhotoId = photo.id
                    showingPhotoDetail = true
                }
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
    }
    
    // MARK: - Top Controls View
    private var topControlsView: some View {
        HStack {
            // Back button (if in navigation)
            Button(action: {
                // Handle back action
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(DesignSystem.CornerRadius.medium)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("الذكريات")
                    .font(DesignSystem.Typography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if let stats = galleryManager.statistics {
                    Text("\(stats.totalPhotos) صورة")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            // Menu button
            Button(action: {
                showingMenu = true
            }) {
                Image(systemName: "ellipsis")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(DesignSystem.CornerRadius.medium)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.top, DesignSystem.Spacing.md)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.8),
                    Color.black.opacity(0.4),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            .clipped()
        )
    }
    
    // MARK: - Rearrangement Controls View
    private var rearrangementControlsView: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            // Done button
            Button("تم") {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    rearrangementMode = false
                    selectedPhotoId = nil
                }
            }
            .font(DesignSystem.Typography.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.primary)
            .cornerRadius(DesignSystem.CornerRadius.medium)
            
            Spacer()
            
            // Delete button (if photo selected)
            if selectedPhotoId != nil {
                Button("حذف") {
                    showingDeleteAlert = true
                }
                .font(DesignSystem.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(Color.red)
                .cornerRadius(DesignSystem.CornerRadius.medium)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.bottom, DesignSystem.Spacing.xl)
        .background(
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.4),
                    Color.black.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            .clipped()
        )
    }
    
    // MARK: - Gallery Gestures
    private var galleryGestures: some Gesture {
        let magnificationGesture = MagnificationGesture()
            .updating($magnification) { value, state, _ in
                state = value
            }
            .onEnded { value in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    zoomScale = max(minZoom, min(maxZoom, zoomScale * value))
                }
            }
        
        let panGestureRecognizer = DragGesture()
            .updating($panGesture) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    panOffset = CGSize(
                        width: panOffset.width + value.translation.width,
                        height: panOffset.height + value.translation.height
                    )
                    
                    // Constrain panning within reasonable bounds
                    let maxOffset: CGFloat = 500
                    panOffset = CGSize(
                        width: max(-maxOffset, min(maxOffset, panOffset.width)),
                        height: max(-maxOffset, min(maxOffset, panOffset.height))
                    )
                }
            }
        
        return magnificationGesture.simultaneously(with: panGestureRecognizer)
    }
    
    // MARK: - Photo Detail View
    private var photoDetailView: some View {
        Group {
            if let selectedId = selectedPhotoId,
               let photo = galleryManager.photos.first(where: { $0.id == selectedId }) {
                PhotoDetailView(photo: photo, galleryManager: galleryManager)
            } else {
                Text("الصورة غير موجودة")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Gallery Menu Action Sheet
    private var galleryMenuActionSheet: ActionSheet {
        ActionSheet(
            title: Text("خيارات المعرض"),
            buttons: [
                .default(Text("إعادة ترتيب الصور")) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        rearrangementMode = true
                    }
                },
                .default(Text("إعادة تعيين التكبير")) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        zoomScale = 1.0
                        panOffset = CGSize.zero
                    }
                },
                .default(Text("معلومات التخزين")) {
                    // Show storage info
                },
                .destructive(Text("مسح جميع الصور")) {
                    Task {
                        await galleryManager.clearAllPhotos()
                    }
                },
                .cancel(Text("إلغاء"))
            ]
        )
    }
    
    // MARK: - Helper Methods
    private func deleteSelectedPhoto() {
        guard let selectedId = selectedPhotoId,
              let photo = galleryManager.photos.first(where: { $0.id == selectedId }) else {
            return
        }
        
        Task {
            await galleryManager.deletePhoto(photo)
            selectedPhotoId = nil
            rearrangementMode = false
        }
    }
}

// MARK: - Photo Detail View
struct PhotoDetailView: View {
    let photo: PolaroidPhoto
    let galleryManager: PolaroidGalleryManager
    
    @Environment(\.dismiss) private var dismiss
    @State private var fullImage: UIImage?
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let image = fullImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("إغلاق") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let image = fullImage {
                    PolaroidShareSheet(items: [image])
                }
            }
        }
        .onAppear {
            loadFullImage()
        }
    }
    
    private func loadFullImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            let image = galleryManager.loadPolaroidImage(for: photo)
            
            DispatchQueue.main.async {
                fullImage = image
            }
        }
    }
}

// MARK: - Polaroid Share Sheet
struct PolaroidShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview
struct PolaroidGalleryView_Previews: PreviewProvider {
    static var previews: some View {
        PolaroidGalleryView()
            .preferredColorScheme(.dark)
    }
}
