//
//  PhotoAlbumViewModel.swift
//  PhotoAlbumSwiftUI
//
//  Created by jjh717
//

import SwiftUI
import Photos

@Observable
final class PhotoAlbumViewModel {

    // MARK: - Published State

    var photos: [PhotoItem] = []
    var selectedIdentifiers: [String] = []
    var authorizationStatus: PHAuthorizationStatus = .notDetermined
    var isLoadingFullImages = false
    var isDragSelecting = false

    // MARK: - Private

    private let imageManager = PHCachingImageManager()

    var selectedCount: Int { selectedIdentifiers.count }

    // MARK: - Authorization

    func requestAuthorization() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await MainActor.run {
            authorizationStatus = status
            if status == .authorized || status == .limited {
                fetchPhotos()
            }
        }
    }

    // MARK: - Fetch

    func fetchPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        var items: [PhotoItem] = []
        result.enumerateObjects { asset, _, _ in
            items.append(PhotoItem(id: asset.localIdentifier, asset: asset))
        }

        photos = items
        selectedIdentifiers.removeAll()
    }

    // MARK: - Selection

    func toggleSelection(_ item: PhotoItem) {
        if let index = selectedIdentifiers.firstIndex(of: item.id) {
            selectedIdentifiers.remove(at: index)
        } else {
            selectedIdentifiers.append(item.id)
        }
    }

    func selectionIndex(for item: PhotoItem) -> Int? {
        selectedIdentifiers.firstIndex(of: item.id)
    }

    func isSelected(_ item: PhotoItem) -> Bool {
        selectedIdentifiers.contains(item.id)
    }

    func clearSelection() {
        selectedIdentifiers.removeAll()
    }

    // MARK: - Thumbnail Loading

    func loadThumbnail(for asset: PHAsset, targetSize: CGSize) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .opportunistic

            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                // Only return final (non-degraded) or single result
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !isDegraded {
                    continuation.resume(returning: image)
                }
            }
        }
    }

    // MARK: - Full Size Image Loading

    func loadSelectedImages() async -> [UIImage] {
        isLoadingFullImages = true
        defer { isLoadingFullImages = false }

        return await withTaskGroup(of: (Int, UIImage?).self, returning: [UIImage].self) { group in
            for (index, identifier) in selectedIdentifiers.enumerated() {
                guard let item = photos.first(where: { $0.id == identifier }) else { continue }
                group.addTask {
                    let image = await self.loadFullSizeImage(for: item.asset)
                    return (index, image)
                }
            }

            var indexedImages: [(Int, UIImage)] = []
            for await (index, image) in group {
                if let image { indexedImages.append((index, image)) }
            }
            return indexedImages.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }

    private func loadFullSizeImage(for asset: PHAsset) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true

            imageManager.requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                guard let data, let image = UIImage(data: data) else {
                    continuation.resume(returning: nil)
                    return
                }
                let resized = image.resizeWithScaleAspectFitMode(to: 2048) ?? image
                continuation.resume(returning: resized)
            }
        }
    }

    // MARK: - Camera (Save Photo)

    func savePhotoToLibrary(_ image: UIImage) async -> Bool {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}
