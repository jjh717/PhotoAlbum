//
//  PhotoAlbumCell.swift
//  PhotoAlbum
//
//  Created by jjh717
//

import UIKit

final class PhotoAlbumCell: UICollectionViewCell {

    // MARK: - UI Elements

    private let photoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.tintColor = .secondaryLabel
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let selectionOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let selectionBadge: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = .systemBlue
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.image = nil
        selectionOverlay.isHidden = true
        selectionBadge.isHidden = true
        selectionBadge.text = nil
    }

    // MARK: - Setup

    private func setupUI() {
        contentView.addSubview(photoImageView)
        contentView.addSubview(selectionOverlay)
        contentView.addSubview(selectionBadge)

        NSLayoutConstraint.activate([
            photoImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            photoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            photoImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            photoImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            selectionOverlay.topAnchor.constraint(equalTo: contentView.topAnchor),
            selectionOverlay.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            selectionOverlay.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            selectionOverlay.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            selectionBadge.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            selectionBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
            selectionBadge.widthAnchor.constraint(equalToConstant: 24),
            selectionBadge.heightAnchor.constraint(equalToConstant: 24),
        ])
    }

    // MARK: - Configuration

    func configure(with image: UIImage?, isCamera: Bool) {
        photoImageView.image = image
        photoImageView.contentMode = isCamera ? .scaleAspectFit : .scaleAspectFill
        contentView.backgroundColor = isCamera ? .secondarySystemBackground : .clear
    }

    func updateSelection(index: Int?) {
        if let index {
            selectionOverlay.isHidden = false
            selectionBadge.isHidden = false
            selectionBadge.text = "\(index + 1)"
        } else {
            selectionOverlay.isHidden = true
            selectionBadge.isHidden = true
        }
    }
}
