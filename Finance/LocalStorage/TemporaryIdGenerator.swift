//
//  TemporaryIdGenerator.swift
//  Finance
//
//  Created by Stepan Polyakov on 16.07.2025.
//

import Foundation

final class TemporaryIDGenerator {
    private let userDefaults: UserDefaults
    private let key = "lastTemporaryID"
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func generate() -> Int {
        let lastID = userDefaults.integer(forKey: key)
        let newID = lastID > 0 ? -lastID - 1 : -1
        userDefaults.set(abs(newID), forKey: key)
        return newID
    }
    
    func reset() {
        userDefaults.removeObject(forKey: key)
    }
}
