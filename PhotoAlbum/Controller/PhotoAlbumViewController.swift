//
//  PhotoAlbumViewController.swift
//  PhotoAlbum
//
//  Created by jjh717
//

import UIKit
import Photos
import PhotosUI

// MARK: - Delegate Protocol

protocol PhotoAlbumViewControllerDelegate: AnyObject {
    func photoAlbumViewController(_ controller: PhotoAlbumViewController, didSelect images: [UIImage])
}

// MARK: - PhotoAlbumViewController

final class PhotoAlbumViewController: UIViewController {

    // MARK: - Properties

    weak var delegate: PhotoAlbumViewControllerDelegate?

    private lazy var photoAlbumView: PhotoAlbumCollectionView = {
        let view = PhotoAlbumCollectionView()
        view.photoAlbumDelegate = self
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var okButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "OK"
        config.baseBackgroundColor = .systemBlue
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 24, bottom: 8, trailing: 24)
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(okButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var selectionCountLabel: UILabel = {
        let label = UILabel()
        label.text = "0 selected"
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - UI Setup

    private func setupUI() {
        title = "Photo Album"
        view.backgroundColor = .systemBackground

        // Navigation bar
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Back",
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )

        // Bottom toolbar
        let bottomBar = UIView()
        bottomBar.backgroundColor = .systemBackground
        bottomBar.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(photoAlbumView)
        view.addSubview(bottomBar)
        bottomBar.addSubview(selectionCountLabel)
        bottomBar.addSubview(okButton)

        NSLayoutConstraint.activate([
            photoAlbumView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            photoAlbumView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            photoAlbumView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            photoAlbumView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 56),

            selectionCountLabel.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 16),
            selectionCountLabel.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),

            okButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -16),
            okButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
        ])
    }

    // MARK: - Actions

    @objc private func okButtonTapped() {
        Task {
            let images = await photoAlbumView.loadSelectedImages()
            delegate?.photoAlbumViewController(self, didSelect: images)
            navigationController?.popViewController(animated: true)
        }
    }

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    private func updateSelectionCount(_ count: Int) {
        selectionCountLabel.text = "\(count) selected"
        okButton.isEnabled = count > 0
    }
}

// MARK: - PhotoAlbumCollectionViewDelegate

extension PhotoAlbumViewController: PhotoAlbumCollectionViewDelegate {

    func photoAlbumCollectionViewDidRequestCamera(_ view: PhotoAlbumCollectionView) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showAlert(title: "Camera Unavailable", message: "This device does not have a camera.")
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }

    func photoAlbumCollectionView(_ view: PhotoAlbumCollectionView, didChangeSelectionCount count: Int) {
        updateSelectionCount(count)
    }

    func photoAlbumCollectionView(_ view: PhotoAlbumCollectionView, didSelect images: [UIImage]) {
        delegate?.photoAlbumViewController(self, didSelect: images)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension PhotoAlbumViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        let editedImage = info[.editedImage] as? UIImage
        let originalImage = info[.originalImage] as? UIImage
        guard let selectedImage = editedImage ?? originalImage else { return }

        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: selectedImage)
        } completionHandler: { [weak self] success, error in
            Task { @MainActor in
                if success {
                    self?.photoAlbumView.reloadPhotos()
                } else if let error {
                    self?.showAlert(title: "Save Error", message: error.localizedDescription)
                }
            }
        }

        picker.dismiss(animated: true)
    }
}

// MARK: - Alert Helper

extension PhotoAlbumViewController {
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
