//
//  ErrorService.swift
//  Larry
//
//  Created by Inderpal Singh on 3/5/17.
//  Copyright © 2017 Layer. All rights reserved.
//

import Foundation
import SwiftyJSON

class ErrorService {
    
    func errorHandler(data: AnyObject?) -> Error?{
        var json = JSON(data!)
        if (json["errors"] != JSON.null) {
            return translateFromJSON(json: json["errors"])
        }
        else if (json["message"] != JSON.null) {
            return translateFromMessageJSON(json: json["message"])
        }
        else{
            return nil
        }
    }
    
    func translateFromJSON(json: JSON) -> Error {
        let object = Error()
        object.title = "Error!"
        object.message = json.array?.first?.string
        
        return object
    }
    
    func translateFromMessageJSON(json: JSON) -> Error {
        let object = Error()
        object.title = "Error!"
        object.message = json.stringValue
        
        return object
    }
}
