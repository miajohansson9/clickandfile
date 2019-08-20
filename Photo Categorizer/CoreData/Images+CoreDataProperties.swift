//
//  Images+CoreDataProperties.swift
//  Photo_Categorizer
//
//  Created by Mia Johansson on 2/15/18.
//  Copyright © 2018 Johansson. All rights reserved.
//
//

import Foundation
import CoreData


extension Images {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Images> {
        return NSFetchRequest<Images>(entityName: "Images")
    }

    @NSManaged public var image: Data?
    @NSManaged public var category: String?
    @NSManaged public var id: Int16

}
