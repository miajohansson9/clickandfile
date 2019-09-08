//
//  IntToStringMigration.swift
//  Photo_Categorizer
//
//  Created by Ismael Zavala on 8/22/19.
//  Copyright © 2019 Johansson. All rights reserved.
//

import CoreData

public class IntToStringMigration: NSEntityMigrationPolicy {
    @objc public func convertIntToString(_ input: Int16) -> String? {
        print("going through migration")
        return String(input)
    }
}
