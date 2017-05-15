//
//  UserService.swift
//  Larry
//
//  Created by Inderpal Singh on 3/5/17.
//  Copyright © 2017 Layer. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class UserService {
    func signIn(deviceID: String, name: String, callback: @escaping (User?, Error?)->()) {
        let nameFormatter = PersonNameComponentsFormatter()
        let nameComps  = nameFormatter.personNameComponents(from: name)
        let givenName  = nameComps?.givenName
        let familyName = nameComps?.familyName
        
        let url = Config.apiPath + "/sign_in"
        
        var userParams = [
            "device_id":deviceID,
            "password":UUID().uuidString
        ]
        
        if let familyName = familyName{
            userParams["last_name"] = familyName
            userParams["display_name"] = familyName
        }
        
        if let givenName = givenName{
            userParams["first_name"] = givenName
            userParams["display_name"] = givenName
        }
        
        let urlParams = [
            "user":userParams
        ]
        
        Alamofire.request(url, method: .post, parameters: urlParams)
            .validate(statusCode: 200..<300)
            .responseJSON {
                response in
                if(response.result.isSuccess){
                    let object = self.objectHandler(data: response.result.value! as AnyObject?)
                    callback(object.User, object.Error)
                }
                else{
                    let error = Error()
                    error.title = "User Error (UserService.signIn)"
                    error.message = response.result.error?.localizedDescription
                    callback(nil, error)
                }
        }
    }
    
    func getLayerToken(deviceID: String, nonce: String, callback: @escaping (String?, Error?)->()) {
        let url = Config.apiPath + "/authenticate"
        
        let urlParams = [
            "device_id":deviceID,
            "nonce":nonce
        ]
        
        Alamofire.request(url, method: .post, parameters: urlParams)
            .validate(statusCode: 200..<300)
            .responseJSON {
                response in
                if(response.result.isSuccess){
                    let identityJSON = JSON(response.result.value!)
                    let layerIdentityToken = identityJSON["layer_identity_token"].string
                    
                    callback(layerIdentityToken, nil)
                }
                else{
                    let error = Error()
                    error.title = "User Error (UserService.getLayerToken)"
                    error.message = response.result.error?.localizedDescription
                    callback(nil, error)
                }
        }
    }
    
    func getUsers(callback: @escaping ([User]?, Error?)->()) {
        let url = Config.apiPath + "/users.json"
        
        Alamofire.request(url, method: .get)
            .validate(statusCode: 200..<300)
            .responseJSON {
                response in
                if(response.result.isSuccess){
                    let object = self.listHandler(data: response.result.value! as AnyObject?)
                    callback(object.Users, object.Error)
                }
                else{
                    let error = Error()
                    error.title = "User Error (UserService.getUsers)"
                    error.message = response.result.error?.localizedDescription
                    callback(nil, error)
                }
        }
    }
    
    func objectHandler(data: AnyObject?) -> (User: User?, Error: Error?) {
        let error = ErrorService().errorHandler(data: data)
        var object = User()
        if (error == nil){
            object = self.translateFromObject(data: data)!
        }
        
        return(object, error)
    }
    
    func listHandler(data: AnyObject?) -> (Users: [User]?, Error: Error?) {
        let error = ErrorService().errorHandler(data: data)
        var objectList = [User]()
        if (error == nil){
            let json = JSON(data!)
            let list = json["users"]
            if let items = list.array {
                for item in items {
                    let object = self.translateFromJSON(json: item)
                    if(object.userID != User.getUserID() && object.userID != Config.larryUserID){
                        objectList.append(object)
                    }
                }
            }
        }
        
        return(objectList, error)
    }
    
    func translateFromObject(data: AnyObject?) -> User? {
        return translateFromJSON(json: JSON(data!)["user"])
    }
    
    func translateFromJSON(json: JSON) -> User {
        let object = User()
        
        object.userID = json["id"].string!
        if let firstName = json["first_name"].string {
            object.firstName = firstName
        }
        
        if let lastname = json["last_name"].string {
            object.lastName = lastname
        }
        
        if let displayName = json["display_name"].string {
            object.displayName = displayName
        }
        
        object.deviceID = json["device_id"].string
        
        return object
    }
}
