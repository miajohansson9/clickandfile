//
//  HomeViewModel.swift
//  Photo_Categorizer
//
//  Created by Ismael Zavala on 8/18/19.
//  Copyright © 2019 Johansson. All rights reserved.
//

import Foundation

// Protocol that will inform view controller of updates
protocol HomeViewModelDelegate {
    func updatesReady()
}

class HomeViewModel {

    // The delgate of this view model.
    var delegate: HomeViewModelDelegate?

    // Albums retrieved from database
    var albums: [Album]?

    // Data layer to fetch albums
    var dataLayer = PersistanceLayer<Album>()

    func update() {
        fetchLatestAlbums()
         delegate?.updatesReady()
    }

    func fetchLatestAlbums() {

        let allAlbums = dataLayer.getAll()
        albums = allAlbums.sorted(by: { (album1, album2) -> Bool in
            guard let name1 = album1.name, let name2 = album2.name else {
                return true
            }

            return name1 > name2
        })

        albums = dataLayer.getAll()
    }
}
