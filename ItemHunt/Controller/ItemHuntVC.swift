//
//  ItemHuntVC.swift
//  ItemHunt
//
//  Created by Igor Eydman on 3/30/18.
//  Copyright © 2018 Igor Eydman. All rights reserved.
//

import UIKit

class ItemHuntVC: UIViewController {
    
    @IBOutlet weak var cameraImage: UIImageView!
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
    }
    
    @IBAction func CameraTapped(_ sender: Any) {
        
        imagePicker.sourceType = .camera
        imagePicker.cameraCaptureMode = .photo
        self.present(imagePicker, animated: true, completion: nil)
    }
}

extension ItemHuntVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        SetImage(image: chosenImage)
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func SetImage(image: UIImage) {
        cameraImage.image = image
    }
}
