//
//  PopUpViewController.swift
//  Photo_Categorizer
//
//  Created by Mia Johansson on 2/19/18.
//  Copyright © 2018 Johansson. All rights reserved.
//

import UIKit
import CoreData

let defaults = UserDefaults.standard

class PopUpViewController: UIViewController {
    @IBOutlet var popUpView: UIView!
    @IBOutlet var albumLabel: UILabel!
    @IBOutlet var titleOfAlbum: UITextField!
    @IBOutlet var cancelOrDelete: UIButton!
    @IBOutlet var save: UIButton!

    var dataLayer = PersistanceLayer<Album>()
    var selectedAlbum: Album?

    override func viewDidLoad() {
        super.viewDidLoad()
        UIView.animate(withDuration: 0.3 ,
                       animations: {
                        self.popUpView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        },
                       completion: { finish in
                        UIView.animate(withDuration: 0.3, animations: {
                            self.popUpView.transform = CGAffineTransform.identity
                        })
        })
        
        isPopUpOpen = true
        
        cancelOrDelete.layer.cornerRadius = 10
        save.layer.cornerRadius = 10
        popUpView.layer.cornerRadius = 10
        
        dropShadow(color: .black, opacity: 0.5, offSet: CGSize(width: 6, height: 6), radius: 6, scale: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if editCategory == true {
            albumLabel.text = "Edit Album"
            titleOfAlbum.text = existingName
        }
    }
    
    @IBAction func cancelOrDelete(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
        isPopUpOpen = false
        self.view.removeFromSuperview()
    }
    
    func dropShadow(color: UIColor, opacity: Float = 0.5, offSet: CGSize, radius: CGFloat = 1, scale: Bool = true) {
        popUpView.layer.masksToBounds = false
        popUpView.layer.shadowColor = color.cgColor
        popUpView.layer.shadowOpacity = opacity
        popUpView.layer.shadowOffset = offSet
        popUpView.layer.shadowRadius = radius
        
        popUpView.layer.shadowPath = UIBezierPath(rect: popUpView.bounds).cgPath
        popUpView.layer.shouldRasterize = true
        popUpView.layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
    
    @IBAction func saveChanges(_ sender: Any) {
        if editCategory == false {
            // add images
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
            isPopUpOpen = false
            self.view.removeFromSuperview()

        } else if editCategory == true {
            print(existingName!)

            selectedAlbum?.name = titleOfAlbum.text ?? ""

            let newAlbum = dataLayer.create()
            newAlbum.name = titleOfAlbum.text ?? ""
            newAlbum.id = UUID().uuidString
            dataLayer.save()

            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
            editCategory = false
            isPopUpOpen = false
            self.view.removeFromSuperview()
        }
    }
}
