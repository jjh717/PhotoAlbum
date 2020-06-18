//
//  PhotoAlbum.swift
//  JDM
//
//  Created by Jang Dong Min on 2020/06/16.
//  Copyright © 2020 Infovine. All rights reserved.
//

import UIKit
import Photos

protocol PhotoAlbumDelegate {
    func getImages(images: [UIImage])
    func openCamera()
}

class PhotoAlbum: UICollectionView {
    var arrSelectedIndex = [IndexPath]()
    var results: PHFetchResult<PHAsset>?
    var photoAlbumDelegate: PhotoAlbumDelegate?
      
    var selectMode = false
    var lastSelectedCell = IndexPath()
    
    override func awakeFromNib() {
        setupCollectionView()
        auth()
    }
    
    func auth() {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                DispatchQueue.main.async { [weak self] in
                    self?.setDelegate()
                }
            case .denied, .restricted:
                print("Not allowed")
            case .notDetermined:
                print("Not determined yet")
            @unknown default:
                print("Not determined yet")
            }
        }
    }
    
    func setDelegate() {
        self.delegate = self
        self.dataSource = self
        
        self.getAllPhotos()
    }
    
    func setupCollectionView() {
        self.canCancelContentTouches = false
        self.allowsMultipleSelection = true

        let longpressGesture = UILongPressGestureRecognizer(target: self, action: #selector(didLongpress))
        longpressGesture.minimumPressDuration = 0.15
        longpressGesture.delaysTouchesBegan = true
        longpressGesture.delegate = self
        self.addGestureRecognizer(longpressGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan(toSelectCells:)))
        panGesture.cancelsTouchesInView = false
        panGesture.delegate = self
        panGesture.delaysTouchesBegan = true
        self.addGestureRecognizer(panGesture)
    }

    @objc func didPan(toSelectCells panGesture: UIPanGestureRecognizer) {
        if !selectMode {
            self.isScrollEnabled = true
            return
        } else {
            if panGesture.state == .began {
                self.isUserInteractionEnabled = false
                self.isScrollEnabled = false
            } else if panGesture.state == .changed {
                let location: CGPoint = panGesture.location(in: self)
                if let indexPath: IndexPath = self.indexPathForItem(at: location) {
                    if indexPath != lastSelectedCell {
                        self.selectCell(indexPath, selected: true)
                        lastSelectedCell = indexPath
                    }
                }
            } else if panGesture.state == .ended {
                self.isScrollEnabled = true
                self.isUserInteractionEnabled = true
                selectMode = false
            }
        }
    }

    @objc func didLongpress() {
        selectMode = true
    }
 
    func getAllPhotos() {
        arrSelectedIndex.removeAll()
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .fastFormat
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        self.results = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        self.reloadData()
    }
    
    func getImageFromAsset(dimension: CGFloat = 2048) {
        print("Image Process loading")
    
        let photoAlbumQueue = DispatchQueue(label: "PhotoAlbum")
        photoAlbumQueue.async {
            var imageArr = [UIImage]()
            for i in 0..<self.arrSelectedIndex.count {
                guard let asset = self.results?.object(at: self.arrSelectedIndex[i].row - 1) else { continue }
                let options = PHImageRequestOptions()
                options.isSynchronous = true
                 
                PHImageManager.default().requestImageData(for: asset, options: options) { (data, string, orientation, info) in
                    if let imgData = data {
                        let image = UIImage(data: imgData)
                        if let img = image {
                            print("img.size.width = ", img.size.width)
                            self.printInfo(of: img, title: "original image |")
                            
                            let dimension: CGFloat = 2048
                            let framework: UIImage.ResizeFramework = .uikit
                            let startTime = Date()
                             
                            if let img = image?.resizeWithScaleAspectFitMode(to: dimension, resizeFramework: framework) {
                                self.printInfo(of: img, title: "resized image |", with: framework, startedTime: startTime)
                                imageArr.append(img)
                            }
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                print("Image Process Complete")
                self.photoAlbumDelegate?.getImages(images: imageArr)
            }
        }
    }
     
    private func printInfo(of image: UIImage, title: String, with resizeFramework: UIImage.ResizeFramework? = nil, startedTime: Date? = nil) {
        var description = "\(title) \(image.size)"
        if let startedTime = startedTime { description += ", execution time: \(Date().timeIntervalSince(startedTime))" }
        if let fileSize = image.getFileSizeInfo(compressionQuality: 0.9) { description += ", size: \(fileSize)" }
        if let resizeFramework = resizeFramework { description += ", framework: \(resizeFramework)" }
        print(description)
    }
    
    
//    func listAlbums() {
//        let fetchOptions = PHFetchOptions()
//        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: fetchOptions)
//        let topLevelUserCollections = PHCollectionList.fetchTopLevelUserCollections(with: fetchOptions)
//        let allAlbums = [topLevelUserCollections, smartAlbums]
//
//        smartAlbums.enumerateObjects {(assetCollection, index, stop) in
//            if assetCollection is PHAssetCollection {
//                let collection: PHAssetCollection = assetCollection as! PHAssetCollection
//
//                let result = PHAsset.fetchAssets(in: collection, options: nil)
//                let fetchOptions = PHFetchOptions()
//                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
//                fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
//
//                let newAlbum = AlbumModel(name: collection.localizedTitle!, count: collection.estimatedAssetCount, collection: collection, assetArr: assetArr)
//
//                self.album.append(newAlbum)
//            }
//        }
//
//        for item in album {
//            print(item.name)
//        }
//    }
}

extension PhotoAlbum: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension PhotoAlbum {
    func selectCell(_ indexPath: IndexPath, selected: Bool) {
        if indexPath.row == 0 {
            return
        }
        
        if let cell = self.cellForItem(at: indexPath) {
            if cell.isSelected {
                self.deselectItem(at: indexPath, animated: false)
                deSelectCell(indexPath)
            } else {
                self.selectItem(at: indexPath, animated: false, scrollPosition: [])
                selectCell(indexPath)
            }
            
            print("\(arrSelectedIndex) items selected")
        }
    }
    
    func deSelectCell(_ indexPath: IndexPath) {
        if indexPath.row == 0 {
            return
        }
        
        arrSelectedIndex = arrSelectedIndex.filter { $0 != indexPath}
        cellCheck(indexPath, false)
    }
    
    func selectCell(_ indexPath: IndexPath) {
        if indexPath.row == 0 {
            return
        }
        
        arrSelectedIndex.append(indexPath)
        selectArrAllCheck(true)
    }
    
    func selectArrAllCheck(_ check: Bool) {
        for i in 0..<arrSelectedIndex.count {
            if let cell = self.cellForItem(at: arrSelectedIndex[i]) as? PhotoAlbumCell {
                cellCheck(cell, arrSelectedIndex[i], check)
            }
        }
    }
    
    func cellCheck(_ indexPath: IndexPath, _ check: Bool) {
        if indexPath.row == 0 {
            return
        }
        
        if let cell = self.cellForItem(at: indexPath) as? PhotoAlbumCell {
            cellCheck(cell, indexPath, check)
        }
        
        selectArrAllCheck(true)
    }
    
    func cellCheck(_ cell: PhotoAlbumCell, _ indexPath: IndexPath, _ check: Bool) {
        if indexPath.row == 0 {
            return
        }
        
        if check {
            cell.selectView.isHidden = false
            if let count = arrSelectedIndex.firstIndex(of: indexPath) {
                cell.selectNumberLabel.text = "\(count + 1)"
            }
        } else {
            cell.selectView.isHidden = true
        }
    }
}

extension PhotoAlbum: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            photoAlbumDelegate?.openCamera()
            return
        }
    
        if arrSelectedIndex.contains(indexPath) {
            deSelectCell(indexPath)
        } else {
            selectCell(indexPath)
        }
        
        print("didSelectItemAt = ", arrSelectedIndex)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            return
        }
        
        if arrSelectedIndex.contains(indexPath) {
            deSelectCell(indexPath)
            print("didDeselectItemAt = ", indexPath)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let results = self.results {
            return results.count + 1
        }
        
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize{
        return CGSize(width: self.frame.size.width / 3 - 2, height: self.frame.size.width / 3 - 2 )
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: PhotoAlbumCell.self), for: indexPath) as? PhotoAlbumCell {
            if indexPath.row == 0 {
                if #available(iOS 13.0, *) {
                    cell.contentImageView.image = UIImage(systemName: "camera")
                } else {
                    cell.contentImageView.image = UIImage(named: "camera")
                }
            } else {
                guard let asset = results?.object(at: indexPath.row - 1) else { return UICollectionViewCell() }
                cell.contentImageView.fetchImage(asset: asset, contentMode: .aspectFill, targetSize: cell.contentImageView.frame.size)
            }
             
            cellCheck(cell, indexPath, cell.isSelected)

            return cell
        }
        return UICollectionViewCell()
    }
}

extension UIImageView {
    func fetchImage(asset: PHAsset, contentMode: PHImageContentMode, targetSize: CGSize) {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: options) { image, _ in
            guard let image = image else { return }
            switch contentMode {
            case .aspectFill:
                self.contentMode = .scaleAspectFill
            case .aspectFit:
                self.contentMode = .scaleAspectFit
            @unknown default:
                self.contentMode = .scaleAspectFill
            }
            self.image = image
        }
    }
}

extension UIImage {
    func getFileSizeInfo(allowedUnits: ByteCountFormatter.Units = .useMB,
                         countStyle: ByteCountFormatter.CountStyle = .memory,
                         compressionQuality: CGFloat = 1.0) -> String? {
        // https://developer.apple.com/documentation/foundation/bytecountformatter
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = allowedUnits
        formatter.countStyle = countStyle
        return getSizeInfo(formatter: formatter, compressionQuality: compressionQuality)
    }

    func getSizeInfo(formatter: ByteCountFormatter, compressionQuality: CGFloat = 1.0) -> String? {
        guard let imageData = self.jpegData(compressionQuality: compressionQuality) else { return nil }
        return formatter.string(fromByteCount: Int64(imageData.count))
    }
}
 
