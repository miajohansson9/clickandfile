//
//  AlbumCollectionViewCell.swift
//  Photo Categorizer
//
//  Created by Mia Johansson on 1/6/18.
//  Copyright © 2018 Johansson. All rights reserved.
//

import UIKit

var editCategory: Bool = false
var existingName: String?

class AlbumCollectionViewCell: UICollectionViewCell {
    @IBOutlet var thumbnailImage: UIImageView!
    @IBOutlet var CategoryName: UILabel!
    @IBAction func edit(_ sender: Any) {
        existingName = self.CategoryName.text
        editCategory = true
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "goToPopUp"), object: nil)
    }
    
    @IBOutlet var edit: UIButton!

}
