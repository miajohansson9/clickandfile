//
//  HomeViewModel.swift
//  Photo_Categorizer
//
//  Created by Ismael Zavala on 8/18/19.
//  Copyright © 2019 Johansson. All rights reserved.
//

import Foundation

// Protocol that will inform view controller of updates
protocol HomeViewModelDelegate: class {
    func updatesReady()
}

class HomeViewModel {

    // The delgate of this view model.
    weak var delegate: HomeViewModelDelegate?

    // Albums retrieved from database
    var albums: [Album]?

    // Data layer to fetch albums
    var dataLayer = PersistanceLayer<Album>()

    // Photos layer to fetch images
    var imagesDataLayer = PersistanceLayer<Images>()

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
    }

    /// In version 1 of the database, images were saved based on which albums are saved in user defaults
    /// In version 2 of the database, images are saved based on albums in core data
    /// This handles the differene in how we are saving images by going through images and saving them based on albums in core data
    func reorganizeOldPhotos() {
        // Getting all current images
        var allOldImages = imagesDataLayer.getAll()

        // Sorting them to know how many different albums there are
        allOldImages = allOldImages.sorted(by: { (imageA, imageB) -> Bool in
            guard let categoryA = imageA.category, let categoryB = imageB.category else { return false }
            return categoryA > categoryB
        })

        // Variable used to determine a different album
        var currentAlbum = allOldImages.first?.category ?? ""

        // Temp arrays to section off images
        var tempImageArray = [[Images]]()
        var albumSection = [Images]()

        // Iterating through images to see how many albulms are needed
        for image in allOldImages {
            // Iterate through images and count different albums for images

            guard let categoryName = image.category else { continue }

            if currentAlbum != image.category {
                currentAlbum = categoryName

                // completing the previous section
                tempImageArray.append(albumSection)

                // clearing out previous section
                albumSection.removeAll()

                // adding image to the new section
                albumSection.append(image)

            } else {
                // adding image to section
                albumSection.append(image)
            }
        }

        var ammountOfAlbums =  dataLayer.getAll().count

        // Checking if more albums are needed
        if ammountOfAlbums > 4 {
            ammountOfAlbums -= 4

            // Creating the remaining ammount of albums
            for i in 1...ammountOfAlbums {
                let newAlbum = dataLayer.create()
                newAlbum.id = UUID().uuidString
                newAlbum.name = "Album \(i + 5)"
            }

            // Saving all created albums
            dataLayer.save()
        }

        // Get all albums and sort them
        fetchLatestAlbums()

        guard let currentAlbums = albums, tempImageArray.count != 0 else { return }

        if tempImageArray.count == 1 {
            let imagesForAlbum = tempImageArray[0]
            let currentAlbumForSection = currentAlbums[0]

            // going through images and fixing IDs
            for image in imagesForAlbum {
                image.category = currentAlbumForSection.id
            }
        } else {
            for index in 0...tempImageArray.count - 1 {

                let imagesForAlbum = tempImageArray[index]
                let currentAlbumForSection = currentAlbums[index]

                // going through images and fixing IDs
                for image in imagesForAlbum {
                    image.category = currentAlbumForSection.id
                }
            }
        }

        // Save all changes
        imagesDataLayer.save()

        // updating view model
        update()
    }
}
