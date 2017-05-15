//
//  NotificationNames.swift
//  Larry
//
//  Created by Inderpal Singh on 3/5/17.
//  Copyright © 2017 Layer. All rights reserved.
//

import Foundation

struct NotificationNames {
    static let layerConnected = NSNotification.Name(rawValue: "LayerConnected")
    static let layerUpdateTabBarBadge = NSNotification.Name(rawValue: "LayerUpdateTabBarBadge")
    static let layerAuthenticated = NSNotification.Name(rawValue: "LayerAuthenticated")
    static let layerClientDidChange = NSNotification.Name.LYRClientObjectsDidChange
    
    static func layerConversationWithUser(userID: String) -> NSNotification.Name {
        return NSNotification.Name("LayerConversationWithUser_\(userID)")
    }
}

