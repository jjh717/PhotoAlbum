//
//  PhotoAlbumCell.swift
//  JDM
//
//  Created by Jang Dong Min on 2020/06/16.
//  Copyright © 2020 Infovine. All rights reserved.
//

import UIKit

class PhotoAlbumCell: UICollectionViewCell {
    @IBOutlet var contentImageView: UIImageView!
    
    @IBOutlet var selectView: CustomView!
    @IBOutlet var selectNumberLabel: UILabel!

    override var isSelected: Bool {
        didSet {
            if self.isSelected {
            }
            else {
            }
        }
    }
}
