//
//  PhotoAlbumView.swift
//  PhotoAlbumSwiftUI
//
//  Created by jjh717
//

import SwiftUI
import Photos

struct PhotoAlbumView: View {

    @State private var viewModel = PhotoAlbumViewModel()
    @State private var showCamera = false
    @State private var showImagePicker = false
    @State private var selectedImages: [UIImage] = []
    @State private var showResult = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    var body: some View {
        VStack(spacing: 0) {
            photoGrid
            bottomBar
        }
        .navigationTitle("Photo Album")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.requestAuthorization()
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { image in
                Task {
                    if await viewModel.savePhotoToLibrary(image) {
                        viewModel.fetchPhotos()
                    }
                }
            }
        }
        .sheet(isPresented: $showResult) {
            SelectedImagesView(images: selectedImages)
        }
    }

    // MARK: - Photo Grid

    private var photoGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                // Camera button
                cameraButton

                // Photo thumbnails
                ForEach(viewModel.photos) { item in
                    PhotoThumbnailView(
                        asset: item.asset,
                        isSelected: viewModel.isSelected(item),
                        selectionIndex: viewModel.selectionIndex(for: item),
                        viewModel: viewModel
                    )
                    .aspectRatio(1, contentMode: .fill)
                    .clipped()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            viewModel.toggleSelection(item)
                        }
                    }
                    .onLongPressGesture(minimumDuration: 0.15) {
                        viewModel.isDragSelecting = true
                        viewModel.toggleSelection(item)
                    }
                }
            }
        }
    }

    // MARK: - Camera Button

    private var cameraButton: some View {
        Button {
            showCamera = true
        } label: {
            ZStack {
                Color(.secondarySystemBackground)
                Image(systemName: "camera.fill")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
            .aspectRatio(1, contentMode: .fill)
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            Text("\(viewModel.selectedCount) selected")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Spacer()

            Button("OK") {
                Task {
                    selectedImages = await viewModel.loadSelectedImages()
                    showResult = true
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(viewModel.selectedCount == 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }
}

// MARK: - Selected Images Result View

struct SelectedImagesView: View {
    let images: [UIImage]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("\(images.count) Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PhotoAlbumView()
    }
}
