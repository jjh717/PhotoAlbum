//
//  PhotoAlbumViewController.swift
//  JDM
//
//  Created by Jang Dong Min on 2020/06/16.
//  Copyright © 2020 Infovine. All rights reserved.
//

import UIKit

protocol PhotoAlbumViewControllerDelegate {
    func getImage(images: [UIImage])
}

class PhotoAlbumViewController: UIViewController {
    @IBOutlet var photoAlbum: PhotoAlbum!
    var delegate: PhotoAlbumViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        photoAlbum.photoAlbumDelegate = self
    }
    
    @IBAction func okButtonClick(_ sender: Any) {
         self.photoAlbum.getImageFromAsset()
    }
    
    @IBAction func backButtonClick(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension PhotoAlbumViewController: PhotoAlbumDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func getImages(images: [UIImage]) {
        self.delegate?.getImage(images: images)
        self.navigationController?.popViewController(animated: true)
    }
    
    func openCamera() {
        if(UIImagePickerController .isSourceTypeAvailable(.camera)){
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.cameraCaptureMode = .photo
            picker.allowsEditing = true
            picker.delegate = self
            present(picker, animated: true, completion: nil)
        }
    }
     
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        //print("didFinishPickingMediaWithInfo,", info)
        
        let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
        guard let selectedImage = editedImage ?? originalImage else { return }
            
        UIImageWriteToSavedPhotosAlbum(selectedImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if error != nil {

        } else {
            self.photoAlbum.getAllPhotos()
        }
    }
}


