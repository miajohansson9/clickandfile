//
//  CameraViewController.swift
//  Photo Categorizer
//
//  Created by Mia Johansson on 1/6/18.
//  Copyright © 2018 Johansson. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData

class CameraViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet var flip: UIButton!
    @IBOutlet var back: UIButton!
    
    var captureSession = AVCaptureSession()
    
    // which camera input do we want to use
    var backFacingCamera: AVCaptureDevice?
    var frontFacingCamera: AVCaptureDevice?
    var currentDevice: AVCaptureDevice?
        
    // output device
    var stillImageOutput: AVCaptureStillImageOutput?
    var stillImage: UIImage?
    
    // camera preview layer
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    
    // double tap to switch from back to front facing camera
    var toggleCameraGestureRecognizer = UITapGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let leftSwipe = UISwipeGestureRecognizer(target:self, action: #selector(swipeAction(swipe:)))
        leftSwipe.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(leftSwipe)
        
        alreadyOpened = true
        
        let devices = AVCaptureDevice.devices(for: AVMediaType.video) as! [AVCaptureDevice]
        for device in devices {
            if device.position == .back {
                backFacingCamera = device
            } else if device.position == .front {
                frontFacingCamera = device
            }
        }
        
        currentDevice = backFacingCamera
        
        // configure the session with the output for capturing our still image
        stillImageOutput = AVCaptureStillImageOutput()
        stillImageOutput?.outputSettings = [AVVideoCodecKey : AVVideoCodecJPEG]
        
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentDevice!)
            
            captureSession.addInput(captureDeviceInput)
            captureSession.addOutput(stillImageOutput!)
            
            // set up the camera preview layer
            cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            view.layer.addSublayer(cameraPreviewLayer!)
            cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            cameraPreviewLayer?.frame = view.layer.frame
            
            view.bringSubview(toFront: cameraButton)
            view.bringSubview(toFront: imageView)
            view.bringSubview(toFront: flip)
            view.bringSubview(toFront: back)
            
            captureSession.startRunning()
            
            // toggle the camera
            toggleCameraGestureRecognizer.numberOfTapsRequired = 2
            toggleCameraGestureRecognizer.addTarget(self, action: #selector(toggleCamera))
            view.addGestureRecognizer(toggleCameraGestureRecognizer)
        } catch let error {
            print(error)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        if categoriesImageArray[send!].last != nil {
            imageView.isHidden = false
            imageView.image = categoriesImageArray[send!].last!
        } else {
            imageView.isHidden = true
        }
        
        navigationController?.setToolbarHidden(true, animated: true)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    @objc private func toggleCamera() {
        switchCamera()
    }
    
    @IBAction func flipCamera(_ sender: Any) {
        switchCamera()
    }
    
    @IBAction func back(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    func switchCamera() {
        // start the configuration change
        captureSession.beginConfiguration()
        
        let newDevice = (currentDevice?.position == . back) ? frontFacingCamera : backFacingCamera
        
        for input in captureSession.inputs {
            captureSession.removeInput(input as! AVCaptureDeviceInput)
        }
        
        let cameraInput: AVCaptureDeviceInput
        do {
            cameraInput = try AVCaptureDeviceInput(device: newDevice!)
        } catch let error {
            print(error)
            return
        }
        
        if captureSession.canAddInput(cameraInput) {
            captureSession.addInput(cameraInput)
        }
        
        currentDevice = newDevice
        captureSession.commitConfiguration()
    }
    
    @IBAction func shutterButtonDidTap()
    {
        let myActivityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
        myActivityIndicator.center = view.center
        myActivityIndicator.hidesWhenStopped = true
        myActivityIndicator.startAnimating()
        view.addSubview(myActivityIndicator)
        
        let videoConnection = stillImageOutput?.connection(with: AVMediaType.video)

        // capture a still image asynchronously
        stillImageOutput?.captureStillImageAsynchronously(from: videoConnection!, completionHandler: { (imageDataBuffer, error) in
            if let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: imageDataBuffer!, previewPhotoSampleBuffer: imageDataBuffer!) {
                self.stillImage = UIImage(data: imageData)
                let image = self.stillImage
                self.imageView.isHidden = false
                myActivityIndicator.stopAnimating()
                self.imageView.image = resizeImage(image: image!, newWidth: 200)
                self.uploadImage(image: image!)
            }
        })
    }

    func uploadImage(image: UIImage) {
        imageData = NSData(data: UIImageJPEGRepresentation(image, 0.5)!)
        let storedImage = Images(context: PersistanceService.context)
        storedImage.image = imageData
        storedImage.category = categories[send!]
        storedImage.id = Int16(imagesArray.count)
        PersistanceService.saveContext()
        imagesArray.append(storedImage)
        
        categoriesImageArray[send!].append(resizeImage(image: UIImage(data: storedImage.image! as Data,scale:0.01)!, newWidth: 150))
        categoriesIndexArray[send!].append(imagesArray.count - 1)
    }
    
    @IBAction func zoom(_ sender: Any) {
        guard let device = currentDevice else { return }
        
        if (sender as AnyObject).state == .changed {
            
            let maxZoomFactor = device.activeFormat.videoMaxZoomFactor
            let pinchVelocityDividerFactor: CGFloat = 10.0
            
            do {
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }
                let desiredZoomFactor = device.videoZoomFactor + atan2((sender as AnyObject).velocity, pinchVelocityDividerFactor)
                device.videoZoomFactor = max(1.0, min(desiredZoomFactor, maxZoomFactor))
            } catch {
                print(error)
            }
        }
    }
}

extension UIViewController {
    @objc func swipeAction(swipe: UISwipeGestureRecognizer) {
        navigationController?.popViewController(animated: true)
    }
}

