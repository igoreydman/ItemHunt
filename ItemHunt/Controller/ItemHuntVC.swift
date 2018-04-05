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
    @IBOutlet weak var prevBtnLabel: UIButton!
    @IBOutlet weak var findNextLabel: UILabel!
    
    let imagePicker = UIImagePickerController()
    var itemEmojis = [Item]()
    
    var currentIndex = 0
    var nextItem = Int()
    var previousItem = Int()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        prevBtnLabel.isEnabled = false
        generateItems()
        let firstString = itemEmojis[currentIndex].emoji
        findNextLabel.text = "Find a \(firstString)"
        
    }
    
    @IBAction func cameraTapped(_ sender: Any) {
        imagePicker.sourceType = .camera
        imagePicker.cameraCaptureMode = .photo
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func nextTapped(_ sender: Any) {
        updateItemLabels()
    }
    
    @IBAction func prevTapped(_ sender: Any) {
        currentIndex = previousItem
        nextItem = Int(arc4random_uniform(UInt32(itemEmojis.count)))
        prevBtnLabel.isEnabled = false
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
            print(itemEmojis[0].name)
        }
    }
    
    func updateItemLabels() {
        if itemEmojis.isEmpty == false {
            DispatchQueue.main.async {
                self.previousItem = self.currentIndex
                print("Current index is: \(self.currentIndex)")
            // can this be condensed into if let?
                if self.currentIndex + 1 > self.itemEmojis.count {
                    self.currentIndex = 0
                    print("Current index is: \(self.currentIndex)")
            } else {
                    self.currentIndex += 1
                    print("Current index is: \(self.currentIndex)")
            }
            
                self.nextItem = Int(arc4random_uniform(UInt32(self.itemEmojis.count)))
            }
        }
        
        let currentText = itemEmojis[currentIndex].emoji
        let nextText = itemEmojis[nextItem].emoji
        
        findNextLabel.text = "Find a \(currentText)"
        nextBtnLabel.titleLabel!.text = "\(nextText)"
    }
    
    func checkModelResult(modelIdentifier: String) {
        // Search for item.name in model identifier
        var resultLowecased = modelIdentifier.lowercased()
        
        // TODO - Train model to identify apples
        if resultLowecased.range(of: "granny smith") != nil {
            resultLowecased = "apple"
            print("result: \(resultLowecased) \nEmoji: \(itemEmojis[currentIndex].emoji)")
        }
        
        if resultLowecased.range(of: itemEmojis[currentIndex].name) != nil {
            DispatchQueue.main.async {
                self.prevBtnLabel.isEnabled = true
                let emojiName = self.itemEmojis[self.currentIndex].name.capitalized
                self.classificationLabel.text = "\(emojiName) FOUND"
                self.updateItemLabels()
            }
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
                self?.classificationLabel.text = "\(Int(topResult.confidence * 100))% \(topResult.identifier) detected"
                
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
