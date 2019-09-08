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
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var captureSession = AVCaptureSession()
    
    // which camera input do we want to use
    var backFacingCamera: AVCaptureDevice?
    var frontFacingCamera: AVCaptureDevice?
    var currentDevice: AVCaptureDevice?
        
    // output device
    var stillImageOutput = AVCapturePhotoOutput()
    var stillImage: UIImage?
    
    // camera preview layer
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    
    // double tap to switch from back to front facing camera
    var toggleCameraGestureRecognizer = UITapGestureRecognizer()

    // Pesistance Layer to save photo objects
    let imagesDataLayer = PersistanceLayer<Images>()

    // Album selected
    var albumSelected: Album?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.activityIndicator.hidesWhenStopped = true

        let leftSwipe = UISwipeGestureRecognizer(target:self, action: #selector(swipeAction(swipe:)))
        leftSwipe.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(leftSwipe)
        
        let devices = AVCaptureDevice.devices(for: AVMediaType.video) as! [AVCaptureDevice]
        for device in devices {
            if device.position == .back {
                backFacingCamera = device
            } else if device.position == .front {
                frontFacingCamera = device
            }
        }
        
        currentDevice = backFacingCamera

        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentDevice!)
            
            captureSession.addInput(captureDeviceInput)
            captureSession.addOutput(stillImageOutput)
            
            // set up the camera preview layer
            cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            view.layer.addSublayer(cameraPreviewLayer!)
            cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            cameraPreviewLayer?.frame = view.layer.frame
            
            view.bringSubview(toFront: cameraButton)
            view.bringSubview(toFront: imageView)
            view.bringSubview(toFront: flip)
            view.bringSubview(toFront: back)
            view.bringSubview(toFront: activityIndicator)
            
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

        // Setting this resolution to not use too much ram in displaying all of the high quality images at once
        captureSession.sessionPreset = .vga640x480

        if let lastImage = getLastPhotoOfAlbum() {
            imageView.isHidden = false
            imageView.image = lastImage
        } else {
            imageView.isHidden = true
        }

        // Hide navigation bar
        navigationController?.setToolbarHidden(true, animated: true)
        self.navigationController?.setNavigationBarHidden(true, animated: true)

        // Starting Camera
        captureSession.startRunning()

        navigationController?.setToolbarHidden(true, animated: true)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }

    func getLastPhotoOfAlbum() -> UIImage? {
        let allImages = imagesDataLayer.getAllByParameter(key: "category", value: albumSelected?.id ?? "")
        guard let lastImage = allImages.last?.image else { return nil }
        return UIImage(data: lastImage)
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

    //tapping on the image preview
    // going to the category VC
    @IBAction func previewButtonAction(_ sender: Any) {

        // Initializing next view controller
        guard let cameraVC = self.storyboard?.instantiateViewController(withIdentifier: "categoryAlbum") as? CategoryAlbumViewController else {
            //Unable to initialize view controller
            return
        }

        cameraVC.selectedAlbum = albumSelected
        self.navigationController?.pushViewController(cameraVC, animated: true)

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
        self.activityIndicator.startAnimating()

        // Initializating the settings and capturing photo
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])
        settings.isHighResolutionPhotoEnabled = false
        stillImageOutput.capturePhoto(with: settings, delegate: self)
    }

    func uploadImage(image: UIImage) {

        guard let data = UIImageJPEGRepresentation(image, 0.5) else {
            print("Unable to get data from image")
            return
        }

        let storedImage = imagesDataLayer.create()
        storedImage.image = data
        storedImage.category = albumSelected?.id
        //TODO: set migration from int to string
        storedImage.id = UUID().uuidString
        imagesDataLayer.save()

        //TODO: reload data
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

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {

        guard let cgImage = photo.cgImageRepresentation()?.takeUnretainedValue(),
            let orientation = photo.metadata[kCGImagePropertyOrientation as String] as? NSNumber,
            let uiOrientation = UIImage.Orientation(rawValue: orientation.intValue) else {
            return
        }

        let image = UIImage(cgImage: cgImage, scale: 1, orientation: uiOrientation)

        self.stillImage = image

        // UI work must be done on the main thread
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.imageView.isHidden = false
            self.imageView.image = image
        }

        self.uploadImage(image: image)
    }
}
