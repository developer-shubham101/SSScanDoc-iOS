//
//  ViewController.swift
//  Scan-app
//
//  Created by Shubham Sharma on 21.12.2018.
//  Copyright © 2018 Shubham Sharma. All rights reserved.
//

import UIKit
import WeScan
import PDFKit
import Photos

class ViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var documents = [URL]()
    var scannedImage: ImageScannerScan!
    var documentOrderNumber = 0
    private let pickerController: UIImagePickerController = UIImagePickerController()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        collectionView.backgroundColor = .white
        collectionView?.contentInset = UIEdgeInsets(top: 5, left: 10, bottom: 0, right: 10)
        
        
        
        self.pickerController.delegate = self
        //        self.pickerController.allowsEditing = false
        self.pickerController.mediaTypes = ["public.image"]
        
        
        
        //        let scannerVC = ImageScannerController()
        //        scannerVC.imageScannerDelegate = self
        //        present(scannerVC, animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        documents = Utilities.getDocuments()
        collectionView.reloadData()
    }
    
    @IBAction func scanButtonTapped(_ sender: UIButton) {
        let scannerVC = ImageScannerController()
        scannerVC.imageScannerDelegate = self
        
        present(scannerVC, animated: true, completion: nil)
    }
    
    @IBAction func pickButtonTapped(_ sender: UIButton) {
        self.pickerController.sourceType =  .photoLibrary
        self.present(self.pickerController, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var documentTitle = documents[documentOrderNumber].path.components(separatedBy: "Documents/")[1]
        documentTitle = String(Array(documentTitle)[0..<(documentTitle.count-4)])
        
        if segue.identifier == "goImageDetail" {
            let imageDetailVC = segue.destination as! ImageDetailViewController
            imageDetailVC.pictureOrderNumber = documentOrderNumber
            imageDetailVC.imageTitle = documentTitle
        } else if segue.identifier == "goPdfDetail" {
            let pdfDetailVC = segue.destination as! PDFDetailViewController
            pdfDetailVC.pdfOrderNumber = documentOrderNumber
            pdfDetailVC.pdfTitle = documentTitle
        }
    }
    
    func savePicture(picture: ImageScannerScan, imageName: String) {
        let imagePath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(imageName)
        let data = picture.image.jpegData(compressionQuality: 0.9)
        FileManager.default.createFile(atPath: imagePath, contents: data, attributes: nil)
    }
    
    func showSaveDialog(scannedImage: ImageScannerScan) {
        let now = Utilities.getTime()
        let alertController = UIAlertController(title: "Save Documents", message: "Enter document name", preferredStyle: .alert)
        
        //the confirm action taking the inputs
        let confirmAction = UIAlertAction(title: "Save", style: .default) { (_) in
            let name = alertController.textFields?[0].text
            if name != "" {
                if Utilities.checkSameName(fileName: name!, documents: self.documents) {
                    self.savePicture(picture: scannedImage, imageName: "\(name!) (1).jpg")
                } else {
                    self.savePicture(picture: scannedImage, imageName: "\(name!).jpg")
                }
            } else {
                self.savePicture(picture: scannedImage, imageName: "\(now).jpg")
            }
            self.documents = Utilities.getDocuments()
            self.collectionView.reloadData()
        }
        
        //the cancel action doing nothing
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        //adding textfields to our dialog box
        alertController.addTextField { (textField) in
            textField.placeholder = "\(now)"
        }
        
        //adding the action to dialogbox
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        //finally presenting the dialog box
        present(alertController, animated: true, completion: nil)
    }
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return documents.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionCell", for: indexPath) as! CustomCollectionViewCell
        let documentPath = documents[indexPath.row].path
        let documentExtensition = documentPath.suffix(3)
        let title = documentPath.components(separatedBy: "Documents/")[1]
        cell.label.text = String(Array(title)[0..<(title.count-4)])
        cell.layer.cornerRadius = 8
        cell.layer.borderColor = UIColor.black.cgColor
        cell.layer.borderWidth = 0.25
        
        if documentExtensition == "jpg" {
            cell.imageView.image = UIImage(contentsOfFile: documentPath)
            cell.documentType.text = "JPG"
        } else if documentExtensition == "pdf" {
            if let pdfDocument = PDFDocument(url: documents[indexPath.row]) {
                if let page1 = pdfDocument.page(at: 0) {
                    cell.imageView.image = page1.thumbnail(of: CGSize(
                        width: cell.imageView.frame.size.width*4,
                        height: cell.imageView.frame.size.height*4), for: .trimBox)
                }
            }
            cell.documentType.text = "PDF"
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let documentExtensition = documents[indexPath.row].path.suffix(3)
        documentOrderNumber = indexPath.row
        if documentExtensition == "jpg" {
            performSegue(withIdentifier: "goImageDetail", sender: nil)
        } else if documentExtensition == "pdf" {
            performSegue(withIdentifier: "goPdfDetail", sender: nil)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemSize = (collectionView.frame.width - (collectionView.contentInset.left + collectionView.contentInset.right + 10)) / 2
        return CGSize(width: itemSize, height: itemSize)
    }
}


extension ViewController: ImageScannerControllerDelegate {
    
    func imageScannerController(_ scanner: ImageScannerController, didFailWithError error: Error) {
        print(error)
    }
    
    func imageScannerController(_ scanner: ImageScannerController, didFinishScanningWithResults results: ImageScannerResults) {
        if results.doesUserPreferEnhancedScan {
            scannedImage = results.enhancedScan
        } else {
            scannedImage = results.croppedScan
        }
        scanner.dismiss(animated: true, completion: nil)
        showSaveDialog(scannedImage: scannedImage)
    }
    
    func imageScannerControllerDidCancel(_ scanner: ImageScannerController) {
        scanner.dismiss(animated: true, completion: nil)
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func didSelect(image: UIImage?) {
        if let image = image {
            let scannerVC = ImageScannerController()
            scannerVC.imageScannerDelegate = self
            scannerVC.useImage(image: image)
            present(scannerVC, animated: true, completion: nil)
        }
    }
    
    
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
    }
    
    
    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        
        
        
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let scannerVC = ImageScannerController()
                scannerVC.imageScannerDelegate = self
                scannerVC.useImage(image: image)
                self.present(scannerVC, animated: true, completion: nil)
            }
            
        }
        
        
        
    }
}
