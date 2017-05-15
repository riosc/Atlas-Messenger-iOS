//
//  VoxeetHelper.swift
//  Atlas Messenger
//
//  Created by Daniel Maness on 4/11/17.
//  Copyright © 2017 Layer, Inc. All rights reserved.
//

import Foundation
import VoxeetSDK
import VoxeetConferenceKit

@objc public class VoxeetHelper: NSObject {
    static public func create(completion: @escaping (String) -> Void) {
        VoxeetSDK.shared.conference.create(parameters: nil, success: { (confId, confAlias) in
            print("voxeet conference created")
            completion(confId)
        }) { (error) in
            print("failed to created voxeet conference\(error)")
        }
    }
}
