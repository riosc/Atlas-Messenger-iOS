//
//  AIManager.swift
//  Larry
//
//  Created by Inderpal Singh on 3/8/17.
//  Copyright © 2017 Layer. All rights reserved.
//

import Foundation
import ApiAI

class AIManager:NSObject {
    
    func getResponse(text: String?, callback: @escaping (String, String, Dictionary<String, Any>?)->()){
        let request = ApiAI.shared().textRequest()
        if let text = text {
            request?.query = [text]
        } else {
            request?.query = [""]
        }
        
        request?.setMappedCompletionBlockSuccess({ (request, response) in
            let response = response as! AIResponse
            var action = ""
            var options = Dictionary<String, Any>()
            
            if let result = response.result,
            let fulfillment = result.fulfillment,
            let speech = fulfillment.speech {
                if response.result.action == "lights" {
                    if let parameters = response.result.parameters as? [String: AIResponseParameter]{
                        let lightState = parameters["light"]!.stringValue
                        action = "lights_\(lightState!)"
                        
                        if let lightHue = parameters["hue"] {
                            options["hue"] = lightHue.stringValue
                        }
                        
                        if let lightEffect = parameters["effect"] {
                            options["effect"] = lightEffect.stringValue
                        }
                    }
                }
                
                callback(speech, action, options)
            }
            else{
                callback("I dunno", "", nil)
            }
            
        }, failure: { (request, error) in
            // TODO: handle error
            callback("Damn something screwed up..", "", nil)
        })
        
        //        request?.setCompletionBlockSuccess({ (request, response) in
        //            print(response)
        //        }, failure: { (request, error) in
        //            print(request.debugDescription)
        //        })
        
        //        request?.setCompletionBlockSuccess({[unowned self] (request, response) -> Void in
        //
        //
        //            }, failure: { (request, error) -> Void in
        //                
        //                print(request.debugDescription)
        //                
        //        })
        
        ApiAI.shared().enqueue(request)
        
    }
}
