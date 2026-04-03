//
//  PhotoAlbumCollectionView.swift
//  PhotoAlbum
//
//  Created by jjh717
//

import UIKit
import Photos

// MARK: - Delegate Protocol

protocol PhotoAlbumCollectionViewDelegate: AnyObject {
    func photoAlbumCollectionViewDidRequestCamera(_ view: PhotoAlbumCollectionView)
    func photoAlbumCollectionView(_ view: PhotoAlbumCollectionView, didChangeSelectionCount count: Int)
    func photoAlbumCollectionView(_ view: PhotoAlbumCollectionView, didSelect images: [UIImage])
}

// MARK: - Section & Item

private enum Section: Hashable {
    case main
}

private enum Item: Hashable {
    case camera
    case photo(String) // PHAsset localIdentifier
}

// MARK: - PhotoAlbumCollectionView

final class PhotoAlbumCollectionView: UIView {

    // MARK: - Properties

    weak var photoAlbumDelegate: PhotoAlbumCollectionViewDelegate?

    private var fetchResult: PHFetchResult<PHAsset>?
    private var selectedAssetIdentifiers: [String] = []
    private var isDragSelecting = false
    private var lastDragSelectedIndexPath: IndexPath?

    private let imageManager = PHCachingImageManager()

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        cv.backgroundColor = .systemBackground
        cv.allowsMultipleSelection = true
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        return cv
    }()

    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupGestures()
        configureDataSource()
        requestPhotoLibraryAccess()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupGestures()
        configureDataSource()
        requestPhotoLibraryAccess()
    }

    // MARK: - Layout

    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0 / 3.0),
            heightDimension: .fractionalWidth(1.0 / 3.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 1, leading: 1, bottom: 1, trailing: 1)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalWidth(1.0 / 3.0)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        return UICollectionViewCompositionalLayout(section: section)
    }

    // MARK: - Setup

    private func setupView() {
        addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func setupGestures() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.15
        longPress.delegate = self
        collectionView.addGestureRecognizer(longPress)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        collectionView.addGestureRecognizer(pan)
    }

    // MARK: - Data Source

    private func configureDataSource() {
        let cameraCellRegistration = UICollectionView.CellRegistration<PhotoAlbumCell, Item> { cell, _, _ in
            cell.configure(with: UIImage(systemName: "camera.fill"), isCamera: true)
        }

        let photoCellRegistration = UICollectionView.CellRegistration<PhotoAlbumCell, Item> { [weak self] cell, indexPath, item in
            guard let self,
                  case let .photo(identifier) = item,
                  let asset = self.asset(for: identifier) else { return }

            let targetSize = CGSize(
                width: cell.bounds.width * UIScreen.main.scale,
                height: cell.bounds.height * UIScreen.main.scale
            )

            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .opportunistic

            self.imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                cell.configure(with: image, isCamera: false)
            }

            // Selection state
            let selectionIndex = self.selectedAssetIdentifiers.firstIndex(of: identifier)
            cell.updateSelection(index: selectionIndex)
        }

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .camera:
                return collectionView.dequeueConfiguredReusableCell(using: cameraCellRegistration, for: indexPath, item: item)
            case .photo:
                return collectionView.dequeueConfiguredReusableCell(using: photoCellRegistration, for: indexPath, item: item)
            }
        }
    }

    // MARK: - Photo Library Access

    private func requestPhotoLibraryAccess() {
        Task {
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            await MainActor.run {
                switch status {
                case .authorized, .limited:
                    fetchPhotos()
                case .denied, .restricted:
                    print("Photo library access denied")
                default:
                    print("Photo library access not determined")
                }
            }
        }
    }

    // MARK: - Fetch Photos

    private func fetchPhotos() {
        selectedAssetIdentifiers.removeAll()

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        applySnapshot()
    }

    private func applySnapshot(animating: Bool = false) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])

        var items: [Item] = [.camera]
        if let fetchResult {
            fetchResult.enumerateObjects { asset, _, _ in
                items.append(.photo(asset.localIdentifier))
            }
        }
        snapshot.appendItems(items, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: animating)
    }

    // MARK: - Public Methods

    func reloadPhotos() {
        fetchPhotos()
    }

    func loadSelectedImages() async -> [UIImage] {
        await withTaskGroup(of: (Int, UIImage?).self, returning: [UIImage].self) { group in
            for (index, identifier) in selectedAssetIdentifiers.enumerated() {
                guard let asset = asset(for: identifier) else { continue }
                group.addTask {
                    let image = await self.loadFullSizeImage(for: asset)
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

    // MARK: - Image Loading

    private func loadFullSizeImage(for asset: PHAsset) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true

            imageManager.requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                guard let data,
                      let image = UIImage(data: data) else {
                    continuation.resume(returning: nil)
                    return
                }

                let dimension: CGFloat = 2048
                let resized = image.resizeWithScaleAspectFitMode(to: dimension) ?? image
                continuation.resume(returning: resized)
            }
        }
    }

    // MARK: - Selection Management

    private func toggleSelection(at indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath),
              case let .photo(identifier) = item else { return }

        if let existingIndex = selectedAssetIdentifiers.firstIndex(of: identifier) {
            selectedAssetIdentifiers.remove(at: existingIndex)
        } else {
            selectedAssetIdentifiers.append(identifier)
        }

        refreshVisibleCells()
        photoAlbumDelegate?.photoAlbumCollectionView(self, didChangeSelectionCount: selectedAssetIdentifiers.count)
    }

    private func refreshVisibleCells() {
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard let item = dataSource.itemIdentifier(for: indexPath),
                  case let .photo(identifier) = item,
                  let cell = collectionView.cellForItem(at: indexPath) as? PhotoAlbumCell else { continue }

            let selectionIndex = selectedAssetIdentifiers.firstIndex(of: identifier)
            cell.updateSelection(index: selectionIndex)
        }
    }

    // MARK: - Helpers

    private func asset(for identifier: String) -> PHAsset? {
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        return result.firstObject
    }

    // MARK: - Gestures

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            isDragSelecting = true
            let point = gesture.location(in: collectionView)
            if let indexPath = collectionView.indexPathForItem(at: point) {
                toggleSelection(at: indexPath)
                lastDragSelectedIndexPath = indexPath
            }
        case .ended, .cancelled:
            isDragSelecting = false
            lastDragSelectedIndexPath = nil
        default:
            break
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard isDragSelecting else { return }

        switch gesture.state {
        case .began:
            collectionView.isScrollEnabled = false
        case .changed:
            let point = gesture.location(in: collectionView)
            if let indexPath = collectionView.indexPathForItem(at: point),
               indexPath != lastDragSelectedIndexPath {
                toggleSelection(at: indexPath)
                lastDragSelectedIndexPath = indexPath
            }
        case .ended, .cancelled:
            collectionView.isScrollEnabled = true
            isDragSelecting = false
            lastDragSelectedIndexPath = nil
        default:
            break
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension PhotoAlbumCollectionView: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

// MARK: - UICollectionViewDelegate

extension PhotoAlbumCollectionView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)

        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }

        switch item {
        case .camera:
            photoAlbumDelegate?.photoAlbumCollectionViewDidRequestCamera(self)
        case .photo:
            toggleSelection(at: indexPath)
        }
    }
}
