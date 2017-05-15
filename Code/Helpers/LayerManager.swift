//
//  LayerManager.swift
//  Larry
//
//  Created by Inderpal Singh on 3/5/17.
//  Copyright © 2017 Layer. All rights reserved.
//

import Foundation
import LayerKit
import Atlas

class LayerManager: NSObject, LYRClientDelegate {
    static let sharedInstance = LayerManager()
    lazy var layerClient: LYRClient = {
        var client = LYRClient(appID: Config.layerAppID!, delegate: self as LYRClientDelegate, options: nil)
        return client
    }()
    
    let  LQSPushMessageIdentifierKeyPath: NSObject = "layer.message_identifier" as NSObject
    
    func establishConnection() {
        if (!self.layerClient.isConnected) {
            layerClient.autodownloadMIMETypes = Set(arrayLiteral: "image/png", "image/jpeg", "image/jpeg+preview", "image/gif", "image/gif+preview", "location/coordinate")
            
            layerClient.connect(completion: { (success, error) in
                if (success) {
                    print("Client is Connected!")
                } else {
                    print("Client not Connected due to error: \(error.debugDescription)")
                }
                NotificationCenter.default.post(name: NotificationNames.layerConnected, object: nil)
            })
        }
        else{
            NotificationCenter.default.post(name: NotificationNames.layerConnected, object: nil)
        }
    }
    
    func isConnected() -> Bool {
        return layerClient.isConnected
    }
    
    func isAuthenticated() -> Bool {
        return layerClient.authenticatedUser?.userID != nil
    }
    
    func currentUserID() -> String {
        return (layerClient.authenticatedUser?.userID)!
    }
    
    func pushNotification(deviceToken: Data) {
        do {
            try layerClient.updateRemoteNotificationDeviceToken(deviceToken)
        } catch let error {
            print("notification error:\(error)")
        }
    }
    
    func messageFromRemoteNotification(remoteNotification:[NSObject : AnyObject]) -> LYRMessage? {
        let stringUrl = remoteNotification[LQSPushMessageIdentifierKeyPath] as! String
        let messageUrl = NSURL(string: stringUrl)
        
        
        let query = LYRQuery(queryableClass: LYRMessage.self)
        var values: Set<NSURL> = Set()
        values.insert(messageUrl!)
        
        // The conversation property is equal to the supplied LYRConversation object.
        let conversationPredicate = LYRPredicate(property: "identifier", predicateOperator: LYRPredicateOperator.isIn, value: values)
        query.predicate = conversationPredicate
        
        let messages: NSOrderedSet?
        
        do {
            messages = try layerClient.execute(query)
            print("Query contains %lu messages \(messages!.count)")
            let message = messages!.firstObject as! LYRMessage
            
            if message.parts.count > 0 {
                let messagePart = message.parts[0]
                print("Pushed Message Contents: \(String(data: messagePart.data!, encoding: String.Encoding.utf8) ?? ""))")
            }
            
            return message
            
        } catch let error {
            print("Layer Error: \(error)")
        }
        
        return nil
    }
    
    func getUnreadMessageCountForConversation(senderUserID: Int? = nil) -> Int {
        var unreadMessages :Int = 0
        
        let query = LYRQuery(queryableClass: LYRMessage.self)
        // The conversation property is equal to the supplied LYRConversation object.
        //let conversationPredicate = LYRPredicate(property: "conversation", predicateOperator: LYRPredicateOperator.isEqualTo, value: conversation)
        // Messages must be unread
        let unreadPredicate = LYRPredicate(property: "isUnread", predicateOperator: LYRPredicateOperator.isEqualTo, value: true)
        // Messages must not be sent by the authenticated user
        let userPredicate = LYRPredicate(property: "sender.userID", predicateOperator: LYRPredicateOperator.isNotEqualTo, value: layerClient.authenticatedUser?.userID)
        
        if(senderUserID == nil){
            query.predicate = LYRCompoundPredicate(type: LYRCompoundPredicateType.and, subpredicates: [unreadPredicate, userPredicate])
        }
        else{
            let senderPredicate = LYRPredicate(property: "sender.userID", predicateOperator: LYRPredicateOperator.isEqualTo, value: senderUserID)
            query.predicate = LYRCompoundPredicate(type: LYRCompoundPredicateType.and, subpredicates: [unreadPredicate, userPredicate, senderPredicate])
        }
        
        var error : NSError?
        unreadMessages = Int(layerClient.count(for: query, error: &error))
        //print("Unread messages: \(unreadMessages)")
        
        if error == nil{
            updateApplicationBadge(unreadMessages: unreadMessages)
            return unreadMessages
        } else {
            print("Query failed with error: \(error?.localizedDescription ?? "")")
            updateApplicationBadge(unreadMessages: 0)
            return 0
        }
    }
    
    func getUnreadMessageCount() -> Int {
        let query = LYRQuery(queryableClass: LYRMessage.self)
        let unreadPredicate = LYRPredicate(property: "isUnread", predicateOperator: .isEqualTo, value: true)
        let userPredicate = LYRPredicate(property: "sender.userID", predicateOperator: .isEqualTo, value: self.layerClient.authenticatedUser?.userID)
        query.predicate = LYRCompoundPredicate(type: .and, subpredicates: [unreadPredicate, userPredicate])
        
        return Int(self.layerClient.count(for: query, error: nil))
    }
    
    func updateApplicationBadge(unreadMessages: Int){
        UIApplication.shared.applicationIconBadgeNumber = unreadMessages
    }
    
    func getMessageForConversation(newConservation:LYRConversation) {
        let query = LYRQuery(queryableClass: LYRMessage.self)
        // The conversation property is equal to the supplied LYRConversation object.
        let conversationPredicate = LYRPredicate(property: "conversation", predicateOperator: LYRPredicateOperator.isEqualTo, value: newConservation)
        
        // Messages must be unread
        query.predicate = LYRCompoundPredicate(type: LYRCompoundPredicateType.and, subpredicates: [conversationPredicate])
        
        
        layerClient.execute(query) { (messages, error) in
            print("Last Message \(messages?.lastObject ?? "")")
        }
        
    }
    
    func deAuthenticateUser(completion: @escaping (Bool) -> Void) {
        layerClient.deauthenticate { (success, error) in
            if (!success) {
                print("Failed to deauthenticate user:  \(error.debugDescription)")
            } else {
                print("User was deauthenticated")
            }
            completion(success)
        }
    }
    
    func authenticateUser(completion: ((Bool, NSError?) -> Void)!) {
        layerClient.requestAuthenticationNonce { (nonce, error) in
            if let nonce = nonce
            {
                self.getLayerToken(nonce: nonce, completion: completion)
            }
            else {
                if (completion != nil) {
                    print(error ?? "Error: authenticateUser")
                }
            }
        }
    }
    
    func getLayerToken(nonce: String, completion: ((Bool, NSError?) -> Void)!){
        if let deviceID = User.getDeviceID()
        {
            UserService().getLayerToken(deviceID: deviceID, nonce: nonce, callback: { (identityToken, error) in
                if(error == nil) {
                    self.layerClient.authenticate(withIdentityToken: identityToken!, completion: { (authenticatedUser, error) in
                        if ((completion) != nil) {
                            if (error == nil) {
                                print("Layer Authenticated as User: \(self.layerClient.authenticatedUser!.userID)");
                                completion(true, nil)
                            }
                            else {
                                print(error ?? "Error: layerClient.authenticate")
                            }
                        }
                    })
                }
                else {
                    print(error ?? "Error: getLayerToken")
                }
            })
        }
        else{
            completion(false, nil)
        }
    }
    
    func userAuthenticated(){
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveLayerObjectsDidChangeNotification), name: NotificationNames.layerClientDidChange, object: nil)
        NotificationCenter.default.post(name: NotificationNames.layerAuthenticated, object: nil)
    }
    
    func goToConversationWithUser(userID: String){
        let conversation = getConversationWithUser(userID: userID)
        if(conversation != nil){
            goToConversation(conversation: conversation!)
        }
    }
    
    func goToConversation(conversation: LYRConversation){
//        let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController
//        if(mainTabBarController is MainTabBarController){
//            (mainTabBarController as! MainTabBarController).goToConversation(conversation: conversation)
//        }
    }
    
    func getConversationWithUser(userID: String) -> LYRConversation?{
        var conversation: LYRConversation? = nil
        let query:LYRQuery = LYRQuery(queryableClass: LYRConversation.self)
        query.predicate = LYRPredicate(property: "participants", predicateOperator: LYRPredicateOperator.isEqualTo, value: ["\(userID)"])
        
        query.sortDescriptors = [NSSortDescriptor(key:"createdAt", ascending:false)]
        do {
            let conversations = try LayerManager.sharedInstance.layerClient.execute(query)
            conversation = conversations.lastObject as? LYRConversation
        }
        catch
        {
            return nil
        }
        
        if(conversation == nil){
            do {
                var senders = Set<String>()
                senders.insert("\(userID)")
                let options = LYRConversationOptions()
                options.distinctByParticipants = true
                conversation = try layerClient.newConversation(withParticipants: senders, options: options)
                return conversation
            }
            catch{
                print("ERROR")
                return nil
            }
        }
        else{
            return conversation
        }
    }
    
    func didReceiveLayerObjectsDidChangeNotification(notification:NSNotification) {
        let userInfo = notification.userInfo
        let changes = userInfo?[LYRClientObjectChangesUserInfoKey] as? [LYRObjectChange]
        
        if let unwrappedChanges = changes {
            for change in unwrappedChanges {
                let changeObject = change.object
                //let updateKey = change.type
                if (changeObject is LYRConversation) {
                    
                    //print("CONVO")
                    
                    // Object is a conversation
                    //                    let message = changeObject as! LYRConversation
                    //
                    //                    switch(updateKey) {
                    //                        case .Create: break
                    //                        case .Update: break
                    //                        case .Delete: break
                    //                    }
                } else if (changeObject is LYRMessage){
                    //print("MESSAGE")
                    
                    NotificationCenter.default.post(name: NotificationNames.layerUpdateTabBarBadge, object: nil)
                    
                    // Object is a message
                    let message = changeObject as! LYRMessage
                    NotificationCenter.default.post(name: NotificationNames.layerConversationWithUser(userID: message.sender.userID), object: nil)
                    
                    if message.isUnread {
                        let messageParts = message.parts
                        if messageParts.count > 0 {
                            let messagePart = messageParts.last
                            var messageText = "💬"
                            
                            switch messagePart!.mimeType {
                            case "text/plain":
                                if let unwrappedData = messagePart?.data {
                                    messageText = String(data: unwrappedData, encoding: String.Encoding.utf8)!
                                }
                            case "location/coordinate":
                                messageText = "📍"
                            case "application/json+imageSize", "image/png","image/jpeg", "image/jpeg+preview", "image/gif", "image/gif+preview", "video/mp4":
                                messageText = "📷"
                            default:
                                break
                            }
                            
                            let displayName = (message.sender.displayName == nil) ? "👤" : message.sender.displayName!
                            
//                            NotificationView.show(
//                                message: "\(displayName): \(messageText)",
//                                duration: 3,
//                                onTap: {
//                                    self.goToConversation(conversation: message.conversation!)
//                            })
                        }
                    }
                    //                    switch(updateKey) {
                    //                    case .create: break
                    //                    case .update: break
                    //                    case .delete: break
                    //                    }
                } else if (changeObject is LYRMessagePart) {
                    //print("MESSAGEPART")
                    //                    let message = changeObject as! LYRMessagePart
                    //                    switch(updateKey) {
                    //                    case .Create: break
                    //                    case .Update: break
                    //                    case .Delete: break
                    //                    }
                }
            }
            
        }
    }
    
    
    
    //    func sendMessage(message: String,userId: String) {
    //        let users = Set([userId])
    //        let MIMETypeTextPlain = "text/plain"
    //        let messageData = message.data(using: String.Encoding.utf8)
    //        let messagePart = LYRMessagePart(mimeType: MIMETypeTextPlain, data: messageData!)
    //        let defaultConfiguration = LYRPushNotificationConfiguration()
    //        defaultConfiguration.alert = message
    //        defaultConfiguration.sound = "layerbell.caf"
    //        let messageOptions = LYRMessageOptions()
    //        messageOptions.pushNotificationConfiguration = defaultConfiguration
    //        let message =  try! layerClient.newMessage(with: [messagePart], options: messageOptions)
    //        do {
    //            let options = LYRConversationOptions()
    //            options.distinctByParticipants = true
    //            conversation = try layerClient.newConversation(withParticipants: users, options: options)
    //            sendMessage(message: message)
    //        } catch let error {
    //            print("already exist\(error)")
    //            let query = LYRQuery(queryableClass: LYRConversation.self)
    //            let value: [AnyObject] = Array(users) as [AnyObject]
    //
    //            query.predicate = LYRPredicate(property: "participants", predicateOperator: LYRPredicateOperator.isEqualTo, value:value)
    //
    //            LayerManager.sharedInstance.layerClient.execute(query, completion: { (conversations, error) in
    //                self.conversation = conversations?.lastObject as? LYRConversation
    //                self.sendMessage(message: message)
    //            })
    //        }
    //    }
    
    func userID() -> String?{
        if(LayerManager().isAuthenticated()){
            return LayerManager.sharedInstance.layerClient.authenticatedUser?.userID
        }
        
        return nil
    }
    
    //    func sendMessage(message: LYRMessage) {
    //        do {
    //            try self.conversation!.send(message)
    //        } catch let error {
    //            print("error:\(error)")
    //        }
    //    }
    
    func layerClient(_ client: LYRClient, didReceiveAuthenticationChallengeWithNonce nonce: String) {
        self.getLayerToken(nonce: nonce, completion: { (success, error) in
            if(success){
                LayerManager.sharedInstance.userAuthenticated()
            }
            else{
                print(error.debugDescription)
            }
        })
    }
    
    func firstOtherParticipant(conversation: LYRConversation) -> LYRIdentity? {
        for participant in conversation.participants{
            if(LayerManager.sharedInstance.layerClient.authenticatedUser != participant){
                return participant
            }
        }
        return nil
    }
    
    func displayNameForConversation(conversation: LYRConversation) -> String {
        if let title = conversation.metadata?["title"] {
            return conversation.participants.count > 2 ? "\(title) (\(conversation.participants.count))" : String(describing: title)
        } else if let p = firstOtherParticipant(conversation: conversation) {
            if(p.displayName != nil){
                return p.displayName!
            }
        }
        return ""
    }
    
    func avatarForConversation(conversation: LYRConversation) -> ATLAvatarItem? {
        if let participant = firstOtherParticipant(conversation: conversation) {
            return ConversationParticipant(layerIdentity: participant).avatar()
        }
        return nil
    }
    
    func getTextFromMessage(message: LYRMessage) -> String{
        let messageParts = message.parts
        var messageText = ""
        if messageParts.count > 0 {
            let messagePart = messageParts.last
            
            switch messagePart!.mimeType {
            case "text/plain":
                if let unwrappedData = messagePart?.data {
                    messageText = String(data: unwrappedData, encoding: String.Encoding.utf8)!
                }
            case "location/coordinate":
                messageText = "📍"
            case "application/json+imageSize", "image/png","image/jpeg", "image/jpeg+preview", "image/gif", "image/gif+preview", "video/mp4":
                messageText = "📷"
            default:
                break
            }
            
        }
        
        return messageText
    }
    
}
