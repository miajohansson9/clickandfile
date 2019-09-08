//
//  Album+CoreDataProperties.swift
//  
//
//  Created by Ismael Zavala on 8/18/19.
//
//

import Foundation
import CoreData


extension Album {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Album> {
        return NSFetchRequest<Album>(entityName: "Album")
    }

    @NSManaged public var id: String?
    @NSManaged public var name: String?

}
