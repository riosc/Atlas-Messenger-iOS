//
//  AppData.swift
//  Larry
//
//  Created by Inderpal Singh on 3/5/17.
//  Copyright © 2017 Layer. All rights reserved.
//

import Foundation

struct AppData {
    private static let userDefaults = UserDefaults.standard
    
    static func save(key: AppDataKey, value: AnyObject?) {
        userDefaults.set(value, forKey: key.rawValue)
        userDefaults.synchronize()
    }
    
    static func remove(key: AppDataKey) {
        userDefaults.removeObject(forKey: key.rawValue)
        userDefaults.synchronize()
    }
    
    static func get<T>(key: AppDataKey) -> T? {
        return userDefaults.object(forKey: key.rawValue) as? T
    }
}

enum AppDataKey: String {
    case DeviceToken
    case LanguageLocale
    case UserID
    case UserFirstName
    case UserLastName
    case UserDisplayName
    case UserDeviceID
    case UUID
    case SessionToken
}
