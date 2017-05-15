//
//  Config.swift
//  Larry
//
//  Created by Inderpal Singh on 3/5/17.
//  Copyright © 2017 Layer. All rights reserved.
//

import Foundation
import UIKit

//Simulator
#if arch(i386) || arch(x86_64)
    struct Config {
        static let apiPath = "https://layer-larry.herokuapp.com/"
        static let layerApiPath = "https://api.layer.com/"
        static let apiTimeout = TimeInterval(30)
        static let layerAppID = URL(string: "layer:///apps/staging/d038178a-1953-11e7-8d98-6f831d18e9c6")
        static let apiAIToken = "0bd4b167b4cf4a8f88a2e33951562ad9"
        static let larryDeviceID = "LARRY-DEVICE-ID"
        static let larryUserID = "fdfc15db-e66e-4cbc-b780-a95cd0d3628f"
    }
    
    //Staging/Test
#elseif DEBUG
    struct Config {
        static let apiPath = "https://layer-larry.herokuapp.com/"
        static let layerApiPath = "https://api.layer.com/"
        static let apiTimeout = TimeInterval(30)
        static let layerAppID = URL(string: "layer:///apps/staging/d038178a-1953-11e7-8d98-6f831d18e9c6")
        static let apiAIToken = "0bd4b167b4cf4a8f88a2e33951562ad9"
        static let larryDeviceID = "LARRY-DEVICE-ID"
        static let larryUserID = "fdfc15db-e66e-4cbc-b780-a95cd0d3628f"
    }
    
    //Production
#else
    struct Config {
        static let apiPath = "https://layer-larry.herokuapp.com/"
        static let layerApiPath = "https://api.layer.com/"
        static let apiTimeout = TimeInterval(30)
        static let layerAppID = URL(string: "layer:///apps/staging/d038178a-1953-11e7-8d98-6f831d18e9c6")
        static let apiAIToken = "0bd4b167b4cf4a8f88a2e33951562ad9"
        static let larryDeviceID = "LARRY-DEVICE-ID"
        static let larryUserID = "fdfc15db-e66e-4cbc-b780-a95cd0d3628f"
    }
#endif
