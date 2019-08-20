//
//  PremiumViewController.swift
//  Photo_Categorizer
//
//  Created by Mia Johansson on 12/30/18.
//  Copyright © 2018 Johansson. All rights reserved.
//

import UIKit

class PremiumViewController: UIViewController {
    @IBOutlet var popUpView: UIView!
    @IBOutlet var upgradeToPremiumView: UIView!
    @IBOutlet var premiumButton: UIButton!
    
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
        
        upgradeToPremiumView.layer.cornerRadius = 10
        premiumButton.layer.cornerRadius = 10
        popUpView.layer.cornerRadius = 10
        
        dropShadow(view: popUpView, color: .black, opacity: 0.8, offSet: CGSize(width: 4, height: 4), radius: 6, scale: true)
        dropShadow(view: upgradeToPremiumView, color: .black, opacity: 0.5, offSet: CGSize(width: 4, height: 4), radius: 4, scale: true)
    }
    
    @IBAction func cancel(_ sender: Any) {
        isPopUpOpen = false
        self.view.removeFromSuperview()
    }
    
    func dropShadow(view: UIView, color: UIColor, opacity: Float = 0.5, offSet: CGSize, radius: CGFloat = 1, scale: Bool = true) {
        view.layer.masksToBounds = false
        view.layer.shadowColor = color.cgColor
        view.layer.shadowOpacity = opacity
        view.layer.shadowOffset = offSet
        view.layer.shadowRadius = radius
        
        view.layer.shadowPath = UIBezierPath(rect: view.bounds).cgPath
        view.layer.shouldRasterize = true
        view.layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
    
    @IBAction func goPremium(_ sender: Any) {
        IAPService.shared.purchase(product: .nonConsumable)
        IAPService.shared.restorePurchases()
        sleep(UInt32(1.5))
        isPopUpOpen = false
        self.view.removeFromSuperview()
    }
}
