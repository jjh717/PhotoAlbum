# PhotoAlbum

iOS Photo Album with multi-select and drag selection support.

Built with both **UIKit** and **SwiftUI** implementations.

## Features

- Photo library browsing with grid layout
- Multi-select with tap
- Drag selection via long press + pan gesture
- Selection order badge display (1, 2, 3...)
- Camera integration for capturing new photos
- High-quality image resizing (UIKit / CoreImage / CoreGraphics / ImageIO / Accelerate)
- async/await based image loading

## Requirements

- iOS 17.0+
- Swift 5.9+
- Xcode 15.0+

## Project Structure

```
PhotoAlbum/
├── PhotoAlbum/                    # UIKit Version
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   ├── Controller/
│   │   └── PhotoAlbumViewController.swift
│   ├── View/
│   │   ├── PhotoAlbumCollectionView.swift
│   │   └── PhotoAlbumCell.swift
│   └── Extension/
│       └── UIImage+Resize.swift
│
└── PhotoAlbumSwiftUI/             # SwiftUI Version
    ├── App/
    │   └── PhotoAlbumApp.swift
    ├── Models/
    │   └── PhotoItem.swift
    ├── ViewModels/
    │   └── PhotoAlbumViewModel.swift
    └── Views/
        ├── PhotoAlbumView.swift
        ├── PhotoThumbnailView.swift
        └── CameraView.swift
```

## UIKit Version

- **Programmatic UI** - No Storyboard dependency
- **Compositional Layout** - Modern `UICollectionViewCompositionalLayout`
- **Diffable Data Source** - Type-safe `UICollectionViewDiffableDataSource`
- **Cell Registration** - `UICollectionView.CellRegistration` API
- **async/await** - Concurrent image loading with `TaskGroup`
- **PHCachingImageManager** - Optimized thumbnail caching

## SwiftUI Version

- **@Observable** macro (iOS 17+)
- **LazyVGrid** for performant photo grid
- **async/await** image loading with `.task` modifier
- **MVVM** architecture with `PhotoAlbumViewModel`
- **UIViewControllerRepresentable** camera integration

## Modernization Changes (from original 2020 version)

| Before (2020) | After (2026) |
|---|---|
| `protocol: class` | `protocol: AnyObject` |
| `@UIApplicationMain` | `@main` |
| `guard let \`self\` = self` | `guard let self` |
| `requestImageData(for:)` | `requestImageDataAndOrientation(for:)` |
| `PHPhotoLibrary.requestAuthorization(_:)` | `PHPhotoLibrary.requestAuthorization(for: .readWrite)` |
| `UIGraphicsBeginImageContext` | `UIGraphicsImageRenderer` |
| Storyboard + IBOutlet | Programmatic UI |
| GCD DispatchQueue | async/await + TaskGroup |
| UICollectionViewFlowLayout | CompositionalLayout + DiffableDataSource |
| No SceneDelegate | SceneDelegate lifecycle |

## Privacy

The app requires the following permissions:

- **Camera** (`NSCameraUsageDescription`)
- **Photo Library** (`NSPhotoLibraryUsageDescription`)

## License

MIT
