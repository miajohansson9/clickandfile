//
//  HomeViewController.swift
//  Photo_Categorizer
//
//  Created by Mia Johansson on 1/9/19.
//  Copyright © 2019 Johansson. All rights reserved.
//

import UIKit
import CoreData
import GoogleMobileAds

private let reuseIdentifier = "Cell"

var image: UIImage?
var imageData:NSData?
var imagesArray = [Images]()
var categories = ["Album 1", "Album 2", "Album 3", "Album 4"]
var send: Int?
var alreadyOpened: Bool?
var categoryAddNum: Int?

var categoriesImageArray = [[UIImage]]()
var categoriesIndexArray = [[Int]]()
var ImagesIDArray = [[Int]]()

var isPopUpOpen = false
let banner1 = GADBannerView(adSize: kGADAdSizeBanner)

private var firstLaunch : Bool = false

public func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
    let scale = newWidth / image.size.width
    let newHeight = image.size.height * scale
    
    UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
    
    image.draw(in: CGRect(x: 0, y: 0,width: newWidth, height: newHeight))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage!
}

class HomeViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, GADBannerViewDelegate {
    
    @IBOutlet var homeCollectionView: UICollectionView!
    @IBOutlet var editLabel: UIBarButtonItem!
    var editSelected = false
    var imageViews = [UIImageView]()
    var selectedArray = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = isFirstLaunch()
        categories = defaults.object(forKey: "AllCategories") as? [String] ?? [String]()
        
        if alreadyOpened == nil {
            categoriesImageArray.removeAll()
            categoriesIndexArray.removeAll()
            getImages()
            alreadyOpened = true
        }
        
        IAPService.shared.getProducts()
        
        homeCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        NotificationCenter.default.addObserver(self, selector: #selector(loadList), name: NSNotification.Name(rawValue: "load"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(goToPopUp), name: NSNotification.Name(rawValue: "goToPopUp"), object: nil)
    }
    
    @objc func loadList(notification: NSNotification){
        //load data here
        homeCollectionView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        // Show the Navigation Bar
        navigationController?.setToolbarHidden(true, animated: true)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        homeCollectionView.reloadData()
        print("view will appear")
        didUpgrade()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return .portrait
        }
    }
    
    public var screenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth:Int = Int(screenWidth / 2)
        return CGSize(width:cellWidth , height:250)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout
        collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return categories.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "album", for: indexPath) as! AlbumCollectionViewCell
        
        let longPressGesture:UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress))
        longPressGesture.minimumPressDuration = 0.7
        longPressGesture.delegate = self as? UIGestureRecognizerDelegate
        cell.thumbnailImage.layer.cornerRadius = 5.0
        cell.thumbnailImage.clipsToBounds = true
        
        if indexPath[1] < (categories.count) {
            if categoriesIndexArray[indexPath[1]].last != nil {
                cell.thumbnailImage.image = resizeImage(image: UIImage(data: imagesArray[categoriesIndexArray[indexPath[1]].last!].image! as Data,scale:0.01)!, newWidth: 350)
                cell.edit.isHidden = false
                cell.CategoryName.text = categories[indexPath[1]]
            } else {
                cell.thumbnailImage.image = UIImage(named: "add-image")!
                cell.edit.isHidden = false
                cell.CategoryName.text = categories[indexPath[1]]
            }
        } else {
            cell.thumbnailImage.image = UIImage(named: "add-2")!
            cell.edit.isHidden = true
            cell.CategoryName.text = ""
            cell.CategoryName.backgroundColor = UIColor(white: 1, alpha: 0)
            if cell.contentView.alpha == 1 {
            } else {
                cell.contentView.alpha = 1
            }
        }
        
        cell.addGestureRecognizer(longPressGesture)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if editSelected == true && indexPath[1] < categories.count {
            if homeCollectionView.cellForItem(at: indexPath)?.contentView.alpha == 1 {
                //                imageViews[indexPath[1]].isHidden = false
                homeCollectionView.cellForItem(at: indexPath)?.contentView.alpha = 0.4
                selectedArray.append(indexPath[1])
            } else {
                //                imageViews[indexPath[1]].isHidden = true
                homeCollectionView.cellForItem(at: indexPath)?.contentView.alpha = 1
                selectedArray.remove(at: selectedArray.index(of: indexPath[1])!)
            }
        } else {
            send = indexPath[1]
            if send! < categories.count {
                performSegue(withIdentifier: "toCamera", sender: nil)
            } else {
                if editSelected == true {
                    homeCollectionView.cellForItem(at: indexPath)?.contentView.alpha = 1
                    deselectAll()
                    selectedArray.removeAll()
                    homeCollectionView.reloadData()
                }
                
                let savedPremium = UserDefaults.standard.object(forKey: "premium")
                if let premium = savedPremium as? Bool {
                    if premium == true {
                        editCategory = false
                        goToPopUp()
                    }
                } else {
                    goToPremiumPopUp()
                }
            }
        }
    }

    @IBAction func editAllCategories(_ sender: Any) {
        if isPopUpOpen == false {
            if editLabel.title == "Select" {
                editSelected = true
                editLabel.title = "Cancel"
                navigationController?.setToolbarHidden(false, animated: true)
                var items = [UIBarButtonItem]()
                items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil))
                items.append(UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(HomeViewController.delete(sender:))))
                self.navigationController?.toolbar.setItems(items, animated: false)
            } else {
                editLabel.title = "Select"
                navigationController?.setToolbarHidden(true, animated: true)
                editSelected = false
                for i in imageViews {
                    i.isHidden = true
                }
                for (p, _) in categories.enumerated() {
                    homeCollectionView.cellForItem(at: [0, p])?.contentView.alpha = 1
                }
                selectedArray.removeAll()
                homeCollectionView.reloadData()
            }
        }
    }
    
    @objc func delete (sender:UIBarButtonItem) {
        var message: String
        if selectedArray.count == 1 {
            message = "Are you sure you want to delete \(selectedArray.count) album?"
        } else {
            message = "Are you sure you want to delete \(selectedArray.count) albums?"
        }
        
        let alert = UIAlertController(title: "Delete Albums", message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { action in self.alertYesPress() }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func plusSignPressed(_ sender: Any) {
        if isPopUpOpen == false {
            let savedPremium = UserDefaults.standard.object(forKey: "premium")
            if let premium = savedPremium as? Bool {
                if premium == true {
                    goToPopUp()
                }
            } else {
                goToPremiumPopUp()
            }
        }
    }
    
    func deselectAll() {
        editLabel.title = "Select"
        navigationController?.setToolbarHidden(true, animated: true)
        editSelected = false
        for (p, _) in categories.enumerated() {
            homeCollectionView.cellForItem(at: [0, p])?.contentView.alpha = 1
        }
        for i in imageViews {
            i.isHidden = true
        }
    }
    
    func alertYesPress() {
        deselectAll()
        selectedArray = selectedArray.sorted(by: >)
        for (_, item) in self.selectedArray.enumerated() {
            let categoryName = categories[item]
            
            if categories.count > 4 {
                categories.remove(at: item)
                defaults.set(categories, forKey: "AllCategories")
            } else {
                categories.remove(at: item)
                categoryAddNum = defaults.object(forKey: "categoryAddNum") as? Int
                categories.append("Album \(categoryAddNum!)")
                categoryAddNum! += 1
                defaults.set(categories, forKey: "AllCategories")
                defaults.set(categoryAddNum, forKey: "categoryAddNum")
            }
            
            let fetchPredicate = NSPredicate(format: "category == %@", "\(categoryName)")
            let fetchUsers                      = NSFetchRequest<NSFetchRequestResult>(entityName: "Images")
            fetchUsers.predicate                = fetchPredicate
            fetchUsers.returnsObjectsAsFaults   = false
            
            do {
                let fetchedUsers = try PersistanceService.context.fetch(fetchUsers) as! [NSManagedObject]
                for fetchedUser in fetchedUsers {
                    PersistanceService.context.delete(fetchedUser)
                    PersistanceService.saveContext()
                }
            } catch { print(error) }
        }
        
        categories = defaults.object(forKey: "AllCategories") as? [String] ?? [String]()
        categoriesImageArray.removeAll()
        categoriesIndexArray.removeAll()
        getImages()
        selectedArray.removeAll()
        homeCollectionView.reloadData()
    }
    
    func didUpgrade() {
        let savedPremium = UserDefaults.standard.object(forKey: "premium")
        if let premium = savedPremium as? Bool {
            print(premium)
            if premium == true {
                print("has premium")
                banner1.isHidden = true
            }
        } else {
            print("add view did recieve ad")
            addBannerViewToView(banner1)
            let request = GADRequest()
            banner1.adUnitID = "ca-app-pub-4566416931763342/1751474297"
            banner1.rootViewController = self
            banner1.delegate = self
            banner1.load(GADRequest())
            banner1.isHidden = false
            print("banner")
        }
    }
    
    func addBannerViewToView(_ banner1: GADBannerView) {
        print("adding")
        var constraint = 0
        
        if UIDevice().userInterfaceIdiom == .phone {
            switch UIScreen.main.nativeBounds.height {
            case 2436:
                constraint = 30
                
            case 2688:
                constraint = 30
                
            case 1792:
                constraint = 30
            default:
                print("other")
            }
        }
        banner1.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(banner1)
        view.addConstraints(
            [NSLayoutConstraint(item: banner1,
                                attribute: .bottom,
                                relatedBy: .equal,
                                toItem: bottomLayoutGuide,
                                attribute: .top,
                                multiplier: 1,
                                constant: CGFloat(constraint)),
             NSLayoutConstraint(item: banner1,
                                attribute: .centerX,
                                relatedBy: .equal,
                                toItem: view,
                                attribute: .centerX,
                                multiplier: 1,
                                constant: 0)
            ])
    }
    
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: homeCollectionView)
            if let indexPath = homeCollectionView.indexPathForItem(at: touchPoint) {
                send = indexPath[1]
                if send! < categories.count {
                    performSegue(withIdentifier: "toCategoryAlbum", sender: nil)
                } else {
                    goToPopUp()
                }
            }
        }
    }
    
    @objc func goToPopUp() {
        let popOverVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "sbPopUpID") as! PopUpViewController
        self.addChildViewController(popOverVC)
        popOverVC.view.frame = self.view.frame
        self.view.addSubview(popOverVC.view)
        popOverVC.didMove(toParentViewController: self)
    }
    
    @objc func goToPremiumPopUp() {
        let popOverVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "premiumPopUp") as! PremiumViewController
        self.addChildViewController(popOverVC)
        popOverVC.view.frame = self.view.frame
        self.view.addSubview(popOverVC.view)
        popOverVC.didMove(toParentViewController: self)
    }
    
    func isFirstLaunch() {
        let launchedBefore = UserDefaults.standard.bool(forKey: "launchedBefore")
        if launchedBefore  {
            print("Not first launch.")
        } else {
            print("First launch, setting UserDefault.")
            categories = ["Album 1", "Album 2", "Album 3", "Album 4"]
            categoryAddNum = 5
            defaults.set(categoryAddNum, forKey: "categoryAddNum")
            defaults.set(categories, forKey: "AllCategories")
            UserDefaults.standard.set(true, forKey: "launchedBefore")
            UserDefaults.standard.synchronize()
        }
    }
}

