//
//  CoreDataManager.swift
//  Photo_Categorizer
//
//  Created by Ismael Zavala on 8/18/19.
//  Copyright © 2019 Johansson. All rights reserved.
//

import Foundation
import CoreData

final class CoreDataManager {
    static let sharedManager = CoreDataManager()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Photo_Categorizer")
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                print("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    func saveContext () {
        let context = CoreDataManager.sharedManager.persistentContainer.viewContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let error = error as NSError
                print("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
}
