//
//  CategoryAlbumCollectionViewController.swift
//  Photo_Categorizer
//
//  Created by Mia Johansson on 2/17/18.
//  Copyright © 2018 Johansson. All rights reserved.
//

import UIKit
import CoreData
import GoogleMobileAds

private let reuseIdentifier = "Cell"
var selectedCell: Int?

func getImages() {
    let fetchRequest: NSFetchRequest<Images> = Images.fetchRequest()
    do {
        let images = try PersistanceService.context.fetch(fetchRequest)
        imagesArray = images
    } catch { print(error) }
    
    for _ in categories.enumerated() {
        categoriesImageArray.append([UIImage]())
        categoriesIndexArray.append([Int]())
        ImagesIDArray.append([Int]())
    }
    
    for (indexOfImage, i) in imagesArray.enumerated() {
        let indexOfCategory: Int = categories.index(of: i.category!)!
        if let imageData = i.image {

            guard let image = UIImage(data: imageData as Data, scale: 0.01) else {
                print("Unable to get image")
                return
            }

            categoriesImageArray[indexOfCategory].append(image.resizeImage(newWidth: 150))
            categoriesIndexArray[indexOfCategory].append(indexOfImage)
            ImagesIDArray[indexOfCategory].append(Int(i.id))
        }
    }
}

class CategoryAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, GADBannerViewDelegate {
    var editSelected = false
    var imageViews = [UIImageView]()
    var selectedArray = [Int]()
    
    @IBOutlet var selectOrCancel: UIBarButtonItem!
    @IBOutlet var categoryTitle: UINavigationItem!
    @IBOutlet weak var banner2: GADBannerView!
    @IBOutlet var collectionViewAlbum: UICollectionView!
    var i = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        categoryTitle.title = categories[send!]
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 2, right: 0)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionViewAlbum.collectionViewLayout = layout
        
        let savedPremium = UserDefaults.standard.object(forKey: "premium")
        if let premium = savedPremium as? Bool {
            print(premium)
            if premium == true {
                print("has premium")
            }
        } else {
            let request = GADRequest()
            banner2.adUnitID = "ca-app-pub-4566416931763342/1559902605"
            banner2.rootViewController = self
            banner2.delegate = self
            banner2.load(request)
            print("banner")
        }
        
        collectionViewAlbum.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        // Show the Navigation Bar
        navigationController?.setToolbarHidden(true, animated: true)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        collectionViewAlbum.reloadData()
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
        let cellWidth:Int = Int(screenWidth / 4)
        return CGSize(width:cellWidth , height: cellWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categoriesImageArray[send!].count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell2", for: indexPath) as! CategoryAlbumCollectionViewCell
        cell.CategoryAlbumCellImage.image = categoriesImageArray[send!][indexPath[1]]
        
        imageViews.append(UIImageView(image: UIImage(named: "selected")))
        imageViews[indexPath[1]].frame = CGRect(x: 5, y: 5, width: 25, height: 25)
        imageViews[indexPath[1]].tag = 1000
        if cell.contentView.alpha == 1 {
            imageViews[indexPath[1]].isHidden = true
        } else {
            if editSelected == false {
                cell.contentView.alpha = 1
            }
        }
        cell.contentView.addSubview(imageViews[indexPath[1]])
        
        return cell
    }

    @IBAction func selectOrCancel(_ sender: Any) {
        if selectOrCancel.title == "Select" {
            editSelected = true
            selectOrCancel.title = "Cancel"
            navigationController?.setToolbarHidden(false, animated: true)
            var items = [UIBarButtonItem]()
            items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil))
            items.append(UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(CategoryAlbumViewController.delete(sender:))))
            self.navigationController?.toolbar.setItems(items, animated: false)
        } else {
            selectOrCancel.title = "Select"
            navigationController?.setToolbarHidden(true, animated: true)
            editSelected = false
            for i in imageViews {
                i.isHidden = true
            }
            for (p, _) in categories.enumerated() {
                collectionViewAlbum.cellForItem(at: [0, p])?.contentView.alpha = 1
            }
            selectedArray.removeAll()
            collectionViewAlbum.reloadData()
        }
    }
    
    @objc func delete (sender:UIBarButtonItem) {
        var message: String
        if selectedArray.count == 1 {
            message = "Are you sure you want to delete \(selectedArray.count) photo?"
        } else {
            message = "Are you sure you want to delete \(selectedArray.count) photos?"
        }
        
        let alert = UIAlertController(title: "Delete Photos", message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { action in self.alertYesPress() }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func alertYesPress() {
        selectedArray = selectedArray.sorted(by: >)

        for (_, item) in self.selectedArray.enumerated() {
            let fetchPredicate = NSPredicate(format: "id == %@", "\(imagesArray[categoriesIndexArray[send!][item]].id)")
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

        categoriesImageArray.removeAll()
        categoriesIndexArray.removeAll()
        
        getImages()
        selectOrCancel.title = "Select"
        navigationController?.setToolbarHidden(true, animated: true)
        editSelected = false
        for i in imageViews {
            i.isHidden = true
        }
        for (p, _) in categories.enumerated() {
            collectionViewAlbum.cellForItem(at: [0, p])?.contentView.alpha = 1
        }
        selectedArray.removeAll()
        collectionViewAlbum.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedCell = indexPath[1]
        if editSelected == true {
            if collectionViewAlbum.cellForItem(at: indexPath)?.contentView.alpha == 1 {
                imageViews[indexPath[1]].isHidden = false
                collectionViewAlbum.cellForItem(at: indexPath)?.contentView.alpha = 0.8
                selectedArray.append(indexPath[1])
            } else {
                imageViews[indexPath[1]].isHidden = true
                collectionViewAlbum.cellForItem(at: indexPath)?.contentView.alpha = 1
                selectedArray.remove(at: selectedArray.index(of: indexPath[1])!)
            }
        } else {
            performSegue(withIdentifier: "fullView", sender: nil)
        }
    }
    
    @IBAction func unwindToVC1(segue:UIStoryboardSegue) { }
}
