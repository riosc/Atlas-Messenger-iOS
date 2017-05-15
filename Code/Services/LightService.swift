//
//  LightService.swift
//  Larry
//
//  Created by Inderpal Singh on 3/29/17.
//  Copyright © 2017 Layer. All rights reserved.
//

import Foundation
import SwiftyHue
import Gloss

class LightService{
    let bridgeAccessConfigUserDefaultsKey = "BridgeAccessConfig"
    
    func readBridgeAccessConfig() -> BridgeAccessConfig? {
        let userDefaults = UserDefaults.standard
        let bridgeAccessConfigJSON = userDefaults.object(forKey: bridgeAccessConfigUserDefaultsKey) as? JSON
        
        var bridgeAccessConfig: BridgeAccessConfig?
        if let bridgeAccessConfigJSON = bridgeAccessConfigJSON {
            bridgeAccessConfig = BridgeAccessConfig(json: bridgeAccessConfigJSON)
        }
        
        return bridgeAccessConfig
    }
}
