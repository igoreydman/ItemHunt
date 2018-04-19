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
    @IBOutlet weak var nextBtnLabel: UIButton!
    @IBOutlet weak var previewLabel: UILabel!
    @IBOutlet weak var randomBtnLabel: UIButton!
    @IBOutlet weak var findNextLabel: UILabel!
    @IBOutlet weak var findView: ShadowView!
    
    let imagePicker = UIImagePickerController()
    var itemEmojis = [Item]()
    
    var currentIndex = 0
    var nextIndex = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        generateItems()
        let firstString = itemEmojis[currentIndex].emoji
        findNextLabel.text = "Find a \(firstString)"
    }
    
    // Hide status bar
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @IBAction func findTapped(_ sender: Any) {
        findView.shake()
    }
    
    @IBAction func cameraTapped(_ sender: Any) {
        imagePicker.sourceType = .camera
        imagePicker.cameraCaptureMode = .photo
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func nextTapped(_ sender: Any) {
        guard currentIndex != itemEmojis.count - 1 else {
            currentIndex = 0
            updateItemLabels()
            return
        }
        
        currentIndex += 1
        updateItemLabels()
    }
    
    @IBAction func randomTapped(_ sender: Any) {
        
        currentIndex =  Int(arc4random_uniform(UInt32(itemEmojis.count)))
        updateItemLabels()
    }
}

// MARK - Item functions
extension ItemHuntVC {
    func generateItems() {
        let itemDict = [
            "apple":    "🍎",
            "hotdog":   "🌭",
            "orange":   "🍊",
            "pizza":    "🍕"
        ]
    
        for (itemName, emoji) in itemDict {
            let newItem = Item(name: itemName, emoji: emoji)
            itemEmojis.append(newItem)
            itemEmojis = itemEmojis.sorted(by: {$0.name < $1.name})
        }
    }
    
    func updateItemLabels() {

        if currentIndex >= itemEmojis.count - 1 {
                nextIndex = 0
        } else {
            nextIndex = currentIndex + 1
        }

        let currentText = itemEmojis[currentIndex].emoji
        let nextText = itemEmojis[nextIndex].emoji
        findNextLabel.text = "Find a \(currentText)!"
        previewLabel.text = "\(nextText)"
        
    }
    
    func checkModelResult(modelIdentifier: String) {
        // Search for item.name in model identifier
        var resultLowecased = modelIdentifier.lowercased()
        
        // TODO - Fine tune model to identify apples
        if resultLowecased.range(of: "granny smith") != nil {
            resultLowecased = "apple"
        }
        
        if resultLowecased.range(of: itemEmojis[currentIndex].name) != nil {
            DispatchQueue.main.async { [weak self] in
                let emojiName = self?.itemEmojis[(self?.currentIndex)!].name.capitalized
                self?.classificationLabel.text = "\(String(describing: emojiName!)) FOUND"
                self?.updateItemLabels()
            }
        } else {
            classificationLabel.text = "Object not detected, please try again."
        }
    }
}

// MARK - CoreML
extension ItemHuntVC {
    func classifyImage(image: CIImage) {
        classificationLabel.text = "Detecting object..."
        
        // Load the ML model through generated class
        guard let model = try? VNCoreMLModel(for: Inceptionv3().model) else {
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
                self?.classificationLabel.text = "\(topResult.identifier) detected"
                NSLog("\(Int(topResult.confidence * 100))% \(topResult.identifier) detected")
                
                // Check if item is a match
                self!.checkModelResult(modelIdentifier: topResult.identifier)
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

// MARK - Camera
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
