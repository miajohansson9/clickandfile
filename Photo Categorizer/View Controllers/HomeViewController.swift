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

var isPopUpOpen = false
let banner1 = GADBannerView(adSize: kGADAdSizeBanner)

class HomeViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, GADBannerViewDelegate {
    
    @IBOutlet var homeCollectionView: UICollectionView!
    @IBOutlet var editLabel: UIBarButtonItem!
    var editSelected = false

    // View model in charge of getting all information needed for this view controller
    var viewModel = HomeViewModel()

    // data layer to create albums if needed
    var dataLayer = PersistanceLayer<Album>()

    // data layer to fetch image data
    var imageDataLayer = PersistanceLayer<Images>()

    // array to keep track of which albums are being selected
    var selectedAlbums = [Album]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //TODO: use this in migration to convert objects saved in user defaults into core data
//        categories = defaults.object(forKey: "AllCategories") as? [String] ?? [String]()

        viewModel.delegate = self

        addBasicAlbumsIfNecessary()
        
        IAPService.shared.getProducts()
        
        homeCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        NotificationCenter.default.addObserver(self, selector: #selector(loadList), name: NSNotification.Name(rawValue: "load"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(goToPopUp), name: NSNotification.Name(rawValue: "goToPopUp"), object: nil)
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

    func addBasicAlbumsIfNecessary() {

        viewModel.fetchLatestAlbums()

        guard viewModel.albums?.count ?? 0 < 1 else {
            // No need to create 5 new albums, at least one exists
            viewModel.update()
            return
        }

        for i in 1...4 {
            // I want to create 4 new albums
            let newAlbum = dataLayer.create()
            newAlbum.id = UUID().uuidString
            newAlbum.name = "Album \(i)"
        }

        // Save all newly created albums
        dataLayer.save()

        // Assign prevous photos to these new albums
        viewModel.reorganizeOldPhotos()

        viewModel.update()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return .portrait
        }
    }

    @objc func loadList(notification: NSNotification){
        //load data here
        homeCollectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth:Int = Int(UIScreen.main.bounds.width / 2)
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
        // The + 1 is to allow the user to select to add an album
        return (viewModel.albums?.count ?? 0) + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "album", for: indexPath) as! AlbumCollectionViewCell
        
        let longPressGesture:UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress))
        longPressGesture.minimumPressDuration = 0.7
        longPressGesture.delegate = self as? UIGestureRecognizerDelegate
        cell.thumbnailImage.layer.cornerRadius = 5.0
        cell.thumbnailImage.clipsToBounds = true
        
        if indexPath.row < viewModel.albums?.count ?? 0 {

            // Getting specific album for this cell
            guard let cellAlbum = viewModel.albums?[indexPath.row] else {
                // Unable to get album
                return UICollectionViewCell()
            }

            // Getting last image related to this specific album
            if let cellImage = imageDataLayer.getAllByParameter(key: "category", value: cellAlbum.id ?? "").last {

                if let fetchedImage = cellImage.image {
                    cell.thumbnailImage.image = UIImage(data: fetchedImage)
                    cell.edit.isHidden = false
                }

                cell.CategoryName.text = cellAlbum.name ?? ""

            } else {
                cell.thumbnailImage.image = UIImage(named: "add-image")!
                cell.edit.isHidden = false
                //TODO: what's this category name for
                cell.CategoryName.text = cellAlbum.name
            }

        } else {
            // Add album cell

            cell.thumbnailImage.image = UIImage(named: "add-2")!
            cell.edit.isHidden = true
            cell.CategoryName.text = ""
            cell.CategoryName.backgroundColor = UIColor(white: 1, alpha: 0)
            cell.contentView.alpha = 1
        }
        
        cell.addGestureRecognizer(longPressGesture)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        //selectedArray is what's keeping track of which albums are being selected

        guard let albumSelected = viewModel.albums?[indexPath.row] else {
            // Unable to get selected album
            return
        }

        // edit selected is based on the bar button to select multiple albums
        if editSelected && indexPath.row < viewModel.albums?.count ?? 0 {

            // Checking if the album was previously selected
            let albumPreviouslySelected = selectedAlbums.contains(albumSelected)

            // Setting the alpha based on it being selected or not
            homeCollectionView.cellForItem(at: indexPath)?.contentView.alpha = albumPreviouslySelected ? 1 : 0.4

            // Keeping track or removing album based on it being previously selected
            if albumPreviouslySelected {
                selectedAlbums.removeAll(where: { album -> Bool in
                    return album == albumSelected
                })
            } else {
                selectedAlbums.append(albumSelected)
            }

        } else {
            if indexPath.row < viewModel.albums?.count ?? 0 {

                // Initializing next view controller
                guard let cameraVC = self.storyboard?.instantiateViewController(withIdentifier: "Camera") as? CameraViewController else {
                    //Unable to initialize view controller
                    return
                }

                cameraVC.albumSelected = albumSelected
                self.navigationController?.pushViewController(cameraVC, animated: true)

            } else {
                if editSelected {
                    homeCollectionView.cellForItem(at: indexPath)?.contentView.alpha = 1
                    deselectAll()
                    selectedAlbums.removeAll()
                    homeCollectionView.reloadData()
                }

                if let savedPremium = UserDefaults.standard.object(forKey: "premium") as? Bool, savedPremium {
                    editCategory = false
                    goToPopUp()
                } else {
                    goToPremiumPopUp()
                }
            }
        }
    }

    @IBAction func editAllCategories(_ sender: Any) {
        if !isPopUpOpen {
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

                let numberOfAlbums = viewModel.albums?.count ?? 0
                for index in 1...numberOfAlbums {
                    homeCollectionView.cellForItem(at: [0, index])?.contentView.alpha = 1
                }

                selectedAlbums.removeAll()
                homeCollectionView.reloadData()
            }
        }
    }
    
    @objc func delete (sender:UIBarButtonItem) {
        var message: String
        if selectedAlbums.count == 1 {
            message = "Are you sure you want to delete \(selectedAlbums.count) album?"
        } else {
            message = "Are you sure you want to delete \(selectedAlbums.count) albums?"
        }
        
        let alert = UIAlertController(title: "Delete Albums", message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { action in self.alertYesPress() }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func plusSignPressed(_ sender: Any) {
        if !isPopUpOpen {
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

        let numberOfAlbums = viewModel.albums?.count ?? 0
        for index in 1...numberOfAlbums {
            homeCollectionView.cellForItem(at: [0, index])?.contentView.alpha = 1
        }
    }
    
    func alertYesPress() {

        // Iterate and delete album from core data
        for album in selectedAlbums {
            dataLayer.delete(album)
        }

        dataLayer.save()

        deselectAll()
        selectedAlbums.removeAll()
        viewModel.update()
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

                guard let selectedAlbum = viewModel.albums?[indexPath.row] else {
                    print("unable to get selected album")
                    return
                }

                if indexPath.row < viewModel.albums?.count ?? 0 {

                    // Initializing next view controller
                    guard let categoryAlbumVC = self.storyboard?.instantiateViewController(withIdentifier: "categoryAlbum") as? CategoryAlbumViewController else {
                        //Unable to initialize view controller
                        return
                    }

                    categoryAlbumVC.selectedAlbum = selectedAlbum

                    self.navigationController?.pushViewController(categoryAlbumVC, animated: true)

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
}

extension HomeViewController: HomeViewModelDelegate {
    func updatesReady() {
        homeCollectionView.reloadData()
    }
}
