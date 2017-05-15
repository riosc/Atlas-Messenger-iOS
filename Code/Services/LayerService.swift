//
//  LayerService.swift
//  Larry
//
//  Created by Inderpal Singh on 3/9/17.
//  Copyright © 2017 Layer. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class LayerService {
    func getNonce(callback: @escaping (String?, Error?)->()) {
        let url = Config.layerApiPath + "nonces"
        let headers = ["Accept":"application/vnd.layer+json; version=2.0"]
        
        Alamofire.request(url, method: .post, headers: headers)
            .validate(statusCode: 200..<300)
            .responseJSON {
                response in
                if(response.result.isSuccess){
                    let json = JSON(response.result.value!)
                    let nonce = json["nonce"].string
                    
                    callback(nonce, nil)
                }
                else{
                    let error = Error()
                    error.title = "Layer Error (LayerService.getNonce)"
                    error.message = response.result.error?.localizedDescription
                    callback(nil, error)
                }
        }
    }
    
    func getSession(identityToken: String, callback: @escaping (String?, Error?)->()) {
        let url = Config.layerApiPath + "sessions"
        let headers = [
            "Accept":"application/vnd.layer+json; version=2.0",
            "Content-Type":"application/json; charset=utf-8",
            ]
        let body: [String : Any] = [
            "identity_token":"\(identityToken)",
            "app_id":"\(Config.layerAppID!.absoluteString)"
        ]
        
        Alamofire.request(url, method: .post, parameters: body, encoding: JSONEncoding.default, headers: headers)
            .validate(statusCode: 200..<300)
            .responseJSON {
                response in
                if(response.result.isSuccess){
                    let json = JSON(response.result.value!)
                    let sessionToken = json["session_token"].string
                    
                    callback(sessionToken, nil)
                }
                else{
                    let error = Error()
                    error.title = "Layer Error (LayerService.getSession)"
                    error.message = response.result.error?.localizedDescription
                    callback(nil, error)
                }
        }
    }
    
    func getConversations(sessionToken: String, callback: @escaping (String?, Error?)->()) {
        let url = Config.layerApiPath + "/conversations"
        let headers = [
            "Accept":"application/vnd.layer+json; version=2.0",
            "Authorization":"Layer session-token=\(sessionToken)"
            ]
        
        Alamofire.request(url, method: .get, encoding: JSONEncoding.default,headers: headers)
            .validate(statusCode: 200..<300)
            .responseJSON {
                response in
                if(response.result.isSuccess){
                    let json = JSON(response.result.value!)
                    callback("CONVOS", nil)
                }
                else{
                    let error = Error()
                    error.title = "Layer Error (LayerService.getConversations)"
                    error.message = response.result.error?.localizedDescription
                    callback(nil, error)
                }
        }
    }
    
    func sendMessage(messageText: String, conversationID: String, sessionToken: String, callback: @escaping (String?, Error?)->()) {
        
        let url = Config.layerApiPath + "conversations/\(conversationID)/messages"
        
        let headers = [
            "Accept":"application/vnd.layer+json; version=2.0",
            "Authorization":"Layer session-token=\(sessionToken)",
            "Content-Type":"application/json; charset=utf-8",
        ]
        
        let body: [String : Any] = [
            "parts": [
                [
                    "mime_type": "text/plain",
                    "body": "\(messageText)"
                ]
            ],
            "notification": [
                "title": "\(messageText)"
            ]
        ]
        
        // Fetch Request
        Alamofire.request(url, method: .post, parameters: body, encoding: JSONEncoding.default, headers: headers)
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                if (response.result.error == nil) {
                    let json = JSON(response.result.value!)
                    callback("MESSAGE SENT", nil)
                }
                else {
                    let error = Error()
                    error.title = "Layer Error (LayerService.sendMessage)"
                    error.message = response.result.error?.localizedDescription
                    callback(nil, error)
                }
        }
    }
}
