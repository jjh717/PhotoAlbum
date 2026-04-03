//
//  PhotoItem.swift
//  PhotoAlbumSwiftUI
//
//  Created by jjh717
//

import UIKit
import Photos

struct PhotoItem: Identifiable, Hashable {
    let id: String  // PHAsset localIdentifier
    let asset: PHAsset

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: PhotoItem, rhs: PhotoItem) -> Bool {
        lhs.id == rhs.id
    }
}
