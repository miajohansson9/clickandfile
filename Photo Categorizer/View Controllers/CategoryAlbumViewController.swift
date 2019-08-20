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

class CategoryAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, GADBannerViewDelegate {
    var editSelected = false
    var imageViews = [UIImageView]()

    @IBOutlet var selectOrCancel: UIBarButtonItem!
    @IBOutlet var categoryTitle: UINavigationItem!
    @IBOutlet weak var banner2: GADBannerView!
    @IBOutlet var collectionViewAlbum: UICollectionView!
    var i = 0

    // view model to get all data from
    var viewModel: CategoryAlbumViewModel?

    //images data layer
    var dataLayer = PersistanceLayer<Images>()

    // Album selected
    var selectedAlbum: Album?

    // images selected
    var selectedImages: [Images]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let userSelectedAlbum = selectedAlbum else { return }

        viewModel = CategoryAlbumViewModel(selectedAlbum: userSelectedAlbum)
        viewModel?.delegate = self
        viewModel?.fetchLatestPictures()
        
        categoryTitle.title = selectedAlbum?.name
        
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
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth:Int = Int(UIScreen.main.bounds.width / 4)
        return CGSize(width:cellWidth , height: cellWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.allPictures.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell2", for: indexPath) as! CategoryAlbumCollectionViewCell

        guard let imageOfCell = viewModel?.allPictures[indexPath.row].image else {
            return UICollectionViewCell()
        }

        cell.CategoryAlbumCellImage.image = UIImage(data: imageOfCell)

        if cell.contentView.alpha == 1 {
            cell.selectedImageView.isHidden = true
        } else {
            cell.selectedImageView.isHidden = false
            if editSelected == false {
                cell.contentView.alpha = 1
            }
        }

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

            let numberOfPictures = viewModel?.allPictures.count ?? 0
            for index in 1...numberOfPictures {
                collectionViewAlbum.cellForItem(at: [0, index])?.contentView.alpha = 1
            }

            selectedImages?.removeAll()
            collectionViewAlbum.reloadData()
        }
    }
    
    @objc func delete (sender:UIBarButtonItem) {
        var message: String
        if selectedImages?.count == 1 {
            message = "Are you sure you want to delete \(selectedImages?.count) photo?"
        } else {
            message = "Are you sure you want to delete \(selectedImages?.count) photos?"
        }
        
        let alert = UIAlertController(title: "Delete Photos", message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { action in self.alertYesPress() }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func alertYesPress() {

        guard let allImages = selectedImages else { return }

        for image in allImages {
            dataLayer.delete(image)
        }

        selectOrCancel.title = "Select"
        navigationController?.setToolbarHidden(true, animated: true)
        editSelected = false
        for i in imageViews {
            i.isHidden = true
        }

        let numberOfPictures = viewModel?.allPictures.count ?? 0
        for index in 1...numberOfPictures {
            collectionViewAlbum.cellForItem(at: [0, index])?.contentView.alpha = 1
        }

        selectedImages?.removeAll()
        collectionViewAlbum.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        guard let selectedImage = selectedImages?[indexPath.row] else { return }

        if editSelected == true {
            if collectionViewAlbum.cellForItem(at: indexPath)?.contentView.alpha == 1 {
                imageViews[indexPath[1]].isHidden = false
                collectionViewAlbum.cellForItem(at: indexPath)?.contentView.alpha = 0.8
                selectedImages?.append(selectedImage)
            } else {
                imageViews[indexPath[1]].isHidden = true
                collectionViewAlbum.cellForItem(at: indexPath)?.contentView.alpha = 1

                selectedImages?.removeAll(where: { image -> Bool in
                    return image == selectedImage
                })
            }
        } else {
            performSegue(withIdentifier: "fullView", sender: nil)
        }
    }
    
    @IBAction func unwindToVC1(segue:UIStoryboardSegue) { }
}

extension CategoryAlbumViewController: CategoryAlbumViewModelDelegate {
    func fetchedData() {
        collectionViewAlbum.reloadData()
    }
}
