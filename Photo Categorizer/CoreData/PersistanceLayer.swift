//
//  PersistanceLayer.swift
//  Photo_Categorizer
//
//  Created by Ismael Zavala on 8/18/19.
//  Copyright © 2019 Johansson. All rights reserved.
//

import Foundation
import CoreData

class PersistanceLayer<T: NSManagedObject> {

    private var context: NSManagedObjectContext {
        CoreDataManager.sharedManager.persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return CoreDataManager.sharedManager.persistentContainer.viewContext
    }

    private var items = [T]()

    init() {
        self.items = getAll()
    }

    /// Saves the current context only if it has change
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch let error as NSError {
                print("Saving of \(self) failed. Error: \(error)")
            }
        }
    }

    /// Returns an NSManagedObject
    func create() -> T {
        return T.init(entity: T.entity(), insertInto: context)
    }

    /// Deletes a NSManagedObject based on the instance passed
    func delete(_ item: T) {
        if let index = items.firstIndex(of: item) {
            items.remove(at: index)
        }

        context.delete(item)
        save()
    }

    /// Returns every NSManagedObject of the specified Data Type.
    func getAll() -> [T] {
        let list: [T]
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: T.self))

        do {
            list = try context.fetch(fetchRequest)
        } catch let error as NSError {
            print("Fetching of \(self) failed. Error: \(error)")
            return [T]()
        }
        return list
    }

    /// Returns a [NSManagedObject] of the specified Data Type
    func getAllByParameter(key: String, value: CVarArg) -> [T] {
        let items: [T]
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: T.self))
        fetchRequest.predicate = NSPredicate(format: "%K == %@", key, value)

        do {
            items = try context.fetch(fetchRequest)
        } catch let error as NSError {
            print("Fetching of \(String(describing: self)) with key: \(String(describing: key)) failed. Error: \(error)")
            return [T]()
        }

        return items
    }

    func getByObjectId(objectId: NSManagedObjectID) -> T? {
        do {
            guard let object: T = try context.existingObject(with: objectId) as? T else {
                return nil
            }
            return object
        } catch let error as NSError {
            print("Unable to fetch object with object id: \(objectId) with error: \(error)")
            return nil
        }
    }

    /// Returns a [NSManagedObject] of the specified Data Type
    func getAllByParameters(parameters: [(key: String, value: String)]) -> [T] {
        let items: [T]
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: T.self))

        var predicates = [NSPredicate]()

        parameters.forEach { parameter in
            predicates.append(NSPredicate(format: "%K == %@", parameter.key, parameter.value))
        }

        fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: predicates)

        do {
            items = try context.fetch(fetchRequest)
        } catch let error as NSError {
            let requestParameters = parameters.map { parameter in
                parameter.key
                }.joined(separator: ", ")

            print("Fetching of \(String(describing: self)) with key: \(requestParameters) failed. Error: \(error)")

            return [T]()
        }

        return items
    }

    /// Deletes every NSManagedObject persisted on the container
    func deleteAll() {
        guard let fetchRequest = NSFetchRequest<T>(entityName: String(describing: T.self)) as? NSFetchRequest<NSFetchRequestResult> else {return}

        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.persistentStoreCoordinator?.execute(deleteRequest, with: context)
        } catch let error as NSError {
            print("Deleting all records for \(String(describing: T.self)) failed. Error: \(error)")
        }
    }
}

