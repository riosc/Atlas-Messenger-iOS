//
//  VoxeetBridge.swift
//  Atlas Messenger
//
//  Created by Daniel Maness on 4/11/17.
//  Copyright © 2017 Layer, Inc. All rights reserved.
//

import Foundation
import VoxeetSDK
import VoxeetConferenceKit

@objc public class VoxeetBridge: NSObject {
    
    public static func initializeVoxeetConferenceKit(consumerKey: String, consumerSecret: String) {
        VoxeetSDK.shared.initializeSDK(consumerKey: consumerKey, consumerSecret: consumerSecret, userInfo: nil)
    }
    
    public static func create(completion: @escaping (_ conferenceID: String?) -> Void) {
        VoxeetSDK.shared.conference.create(parameters: nil, success: { (confId, confAlias) in
            print("voxeet conference created")
            completion(confId)
        }) { (error) in
            print("failed to created voxeet conference\(error)")
            completion(nil)
        }
    }
    
    public static func status(conferenceID confID: String, success successCompletion: ((Any) -> Swift.Void)?) {
        VoxeetSDK.shared.conference.status(conferenceID: confID, success: { (json) in
            successCompletion!(json)
        }) { (error) in
            //failCompletion?(error)
        }
    }
    
    public static func history(conferenceID confID: String, success successCompletion: ((Any) -> Swift.Void)?) {
        VoxeetSDK.shared.conference.history(conferenceID: confID, success: { (json) in
            successCompletion!(json)
        }) { (error) in
            if let error = error {
                //failCompletion?(error)
            }
        }
    }
}
