//
//  PhotoThumbnailView.swift
//  PhotoAlbumSwiftUI
//
//  Created by jjh717
//

import SwiftUI
import Photos

struct PhotoThumbnailView: View {

    let asset: PHAsset
    let isSelected: Bool
    let selectionIndex: Int?
    let viewModel: PhotoAlbumViewModel

    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Thumbnail image
            Group {
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color(.systemGray5)
                        .overlay {
                            ProgressView()
                                .tint(.secondary)
                        }
                }
            }

            // Selection overlay
            if isSelected {
                Color.blue.opacity(0.3)

                // Selection badge
                if let selectionIndex {
                    Text("\(selectionIndex + 1)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(.blue))
                        .padding(4)
                }
            }
        }
        .task(id: asset.localIdentifier) {
            let size = CGSize(width: 200, height: 200)
            thumbnail = await viewModel.loadThumbnail(for: asset, targetSize: size)
        }
    }
}
