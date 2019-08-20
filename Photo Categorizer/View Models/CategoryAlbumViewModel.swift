//
//  File.swift
//  Photo_Categorizer
//
//  Created by Ismael Zavala on 8/19/19.
//  Copyright © 2019 Johansson. All rights reserved.
//

import Foundation
import CoreData

protocol CategoryAlbumViewModelDelegate {
    func fetchedData()
}

class CategoryAlbumViewModel {

    var delegate: CategoryAlbumViewModelDelegate?

    // All pictures within the selected Album
    var allPictures = [Images]()

    // data layer to get images
    var dataLayer = PersistanceLayer<Images>()

    // album selected
    var selectedAlbum: Album?

    init(selectedAlbum: Album) {
        self.selectedAlbum = selectedAlbum
    }

    func fetchLatestPictures() {
        allPictures = dataLayer.getAllByParameter(key: "category", value: self.selectedAlbum?.id ?? "")
        delegate?.fetchedData()
    }
}
