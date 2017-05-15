//
//  ConversationParticipant.swift
//  Larry
//
//  Created by Inderpal Singh on 3/5/17.
//  Copyright © 2017 Layer. All rights reserved.
//

import Atlas

class ConversationParticipant: NSObject, ATLParticipant, ATLAvatarItem {
    var presenceStatus: LYRIdentityPresenceStatus
    var firstName: String = ""
    var lastName: String = ""
    var displayName: String = ""
    var userID: String = ""
    var avatarImageURL: URL?
    var avatarImage: UIImage?
    var avatarInitials: String?
    
    init(layerIdentity: LYRIdentity) {
        if(layerIdentity.displayName != nil){
            self.displayName = layerIdentity.displayName!
        }
        
        if(layerIdentity.firstName != nil){
            self.firstName = layerIdentity.firstName!
        }
        
        if(layerIdentity.lastName != nil){
            self.lastName = layerIdentity.lastName!
        }
        
        self.userID = layerIdentity.userID
        self.avatarImage = layerIdentity.avatarImage
        self.avatarInitials = layerIdentity.avatarInitials
        self.presenceStatus = layerIdentity.presenceStatus
        
        if (self.userID == Config.larryUserID) {
            self.avatarImage = UIImage(named: "larry-avatar")
        } else if(layerIdentity.avatarImageURL != nil) {
            if(!(layerIdentity.avatarImageURL?.absoluteString.contains("no-user-image"))!){
                var avatarURL = layerIdentity.avatarImageURL?.relativeString
                avatarURL = avatarURL?.replacingOccurrences(of: "http:", with: "https:")
                self.avatarImageURL = URL(string: avatarURL!)
            }
        }
    }
    
    func avatar() -> ConversationAvatar{
        return ConversationAvatar(conversationParticipant: self)
    }
}
