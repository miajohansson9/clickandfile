//
//  ShowFullViewController.swift
//  Photo_Categorizer
//
//  Created by Mia Johansson on 2/20/18.
//  Copyright © 2018 Johansson. All rights reserved.
//

import UIKit
import CoreData
import GoogleMobileAds

class ShowFullViewController: UIViewController, UIScrollViewDelegate, GADBannerViewDelegate {

    @IBOutlet var toolBar: UIToolbar!
    @IBOutlet var image: UIImageView!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var banner3: GADBannerView!
    @IBOutlet var toolBarContraintTop: NSLayoutConstraint!
    var showing = true

    //TODO: rename to image
    var selectedPhoto: Images?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.maximumZoomScale = 6.0
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(ShowFullViewController.toggle))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(gesture)
        
        let savedPremium = UserDefaults.standard.object(forKey: "premium")
        if let premium = savedPremium as? Bool {
            print(premium)
            if premium == true {
                print("has premium")
            }
        } else {
            let request = GADRequest()
            banner3.adUnitID = "ca-app-pub-4566416931763342/4930024176"
            banner3.rootViewController = self
            banner3.delegate = self
            banner3.load(request)
            print("banner")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.enableAllOrientation = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.enableAllOrientation = false
        
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.image
    }
    
    @objc func toggle() {
        navigationController?.setNavigationBarHidden(navigationController?.isNavigationBarHidden == false, animated: false)
        if toolBar.isHidden == true {
            toolBar.isHidden = false
            toolBarContraintTop.constant = 0
            self.view.backgroundColor = UIColor.white
        } else {
            toolBar.isHidden = true
            self.view.backgroundColor = UIColor.black
            toolBarContraintTop.constant = -44
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return navigationController?.isNavigationBarHidden == true
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return UIStatusBarAnimation.slide
    }
    
    @IBAction func trash(_ sender: Any) {
        var message = "Are you sure you want to delete this photo?"
        let alert = UIAlertController(title: "Delete Photo", message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { action in self.alertYesPress() }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func alertYesPress() {

        //TODO: delete photo from database and continue with segue 
        
        performSegue(withIdentifier: "unwindToCategory", sender: self)
    }
    
    @IBAction func downloadImage(_ sender: Any) {
        // TODO: Save photo to album
//        UIImageWriteToSavedPhotosAlbum(photo!, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        // Getting alert title and message
        let alertTitle = (error == nil) ? "Saved" : "An error occured"
        let alertMessage = (error == nil) ? "Your image was not saved to your camera roll." : "Your image was saved to your camera roll."

        // Creating and presenting alert.
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}