//
//  User.swift
//  Larry
//
//  Created by Inderpal Singh on 3/5/17.
//  Copyright © 2017 Layer. All rights reserved.
//

import Foundation
import SwiftKeychainWrapper
import Atlas

class User: NSObject, ATLParticipant {
    var presenceStatus: LYRIdentityPresenceStatus
    var deviceID: String?
    var firstName: String = ""
    var lastName: String = ""
    var displayName: String = ""
    var userID: String = ""
    var avatarImageURL: URL?
    var avatarImage: UIImage?
    var avatarInitials: String?
    var languageLocale: Locale?
    
    static internal func == (lhs: User, rhs: User) -> Bool {
        return lhs.userID == rhs.userID
    }
    
    override init() {
        self.presenceStatus = .available
        super.init()
    }
    
    class func getDeviceID() -> String?{
        if let deviceID: String = KeychainWrapper.standard.string(forKey: "DEVICEID") {
            return deviceID
        }
        else{
            return nil
        }
    }
    
    class func setDeviceID(deviceID: String) -> Bool{
        let saveSuccessful: Bool = KeychainWrapper.standard.set(deviceID, forKey: "DEVICEID")
        return saveSuccessful
    }
    
    class func getUserID() -> String?{
        if let userID: String = AppData.get(key: .UserID) {
            return userID
        }
        else{
            return nil
        }
    }
    
    class func setID(id: String){
        AppData.save(key: .UserID, value: id as AnyObject?)
    }
    
//    class func getLanguageLocale() -> Locale {
//        if let languageLocale: Locale = AppData.get(key: .LanguageLocale) {
//            return languageLocale.languageCode
//        } else {
//            return NSLocale.preferredLanguages[0]
//        }
//    }
    
    class func setUser(user: User){
        AppData.save(key: .UserID, value: user.userID as AnyObject?)
        AppData.save(key: .UserFirstName, value: user.firstName as AnyObject?)
        AppData.save(key: .UserLastName, value: user.lastName as AnyObject?)
        AppData.save(key: .UserDisplayName, value: user.displayName as AnyObject?)
        AppData.save(key: .UserDeviceID, value: user.deviceID as AnyObject?)
    }
    
    class func getUser() -> User{
        let user = User()
        if let id: String = AppData.get(key: .UserID) {
            user.userID = id
        }
        if let firstName: String = AppData.get(key: .UserFirstName) {
            user.firstName = firstName
        }
        if let lastName: String = AppData.get(key: .UserLastName) {
            user.lastName = lastName
        }
        if let displayName: String = AppData.get(key: .UserDisplayName) {
            user.displayName = displayName
        }
        if let deviceID: String = AppData.get(key: .UserDeviceID) {
            user.deviceID = deviceID
        }
        
        return user
    }
}
