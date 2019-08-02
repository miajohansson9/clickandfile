//
//  Firstlaunch.swift
//  Photo_Categorizer
//
//  Created by Mia Johansson on 2/17/18.
//  Copyright © 2018 Johansson. All rights reserved.
//

import Foundation

final class FirstLaunch {
    
    let userDefaults: UserDefaults = .standard
    
    let wasLaunchedBefore: Bool
    var isFirstLaunch: Bool {
        return !wasLaunchedBefore
    }
    
    init() {
        let key = "com.any-suggestion.FirstLaunch.WasLaunchedBefore"
        let wasLaunchedBefore = userDefaults.bool(forKey: key)
        self.wasLaunchedBefore = wasLaunchedBefore
        if !wasLaunchedBefore {
            userDefaults.set(true, forKey: key)
        }
    }
    
}
