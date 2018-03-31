//
//  ItemHuntVC.swift
//  ItemHunt
//
//  Created by Igor Eydman on 3/30/18.
//  Copyright © 2018 Igor Eydman. All rights reserved.
//

import UIKit
import CoreML
import Vision

class ItemHuntVC: UIViewController {
    
    @IBOutlet weak var cameraImage: UIImageView!
    @IBOutlet weak var classificationLabel: UILabel!
    
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
    
    func classifyImage(image: CIImage) {
        
        classificationLabel.text = "detecting object..."
        
        // Load the ML model through generated class
        guard let model = try? VNCoreMLModel(for: SqueezeNet().model) else {
            fatalError("can't load ML model")
        }
        
        // Vision request
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation],
                let topResult = results.first else {
                    fatalError("unexpected result type from VNCoreMLRequest")
            }
            
            // Update UI
            DispatchQueue.main.async { [weak self] in
                self?.classificationLabel.text = "\(Int(topResult.confidence * 100))% \(topResult.identifier) detected"
            }
        }
        
        // Running classifier on global dispatch que
        let handler = VNImageRequestHandler(ciImage: image)
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([request])
            } catch {
                print(error)
            }
        }
    }
    
}

extension ItemHuntVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("couldn't load image")
        }
        
        cameraImage.image = image
        
        guard let ciImage = CIImage(image: image) else {
            fatalError("couldn't convert UIImage to CIImage")
        }
        
        // Send to CoreML
        classifyImage(image: ciImage)
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
