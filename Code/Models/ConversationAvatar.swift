//
//  ConversationAvatar.swift
//  Larry
//
//  Created by Inderpal Singh on 3/5/17.
//  Copyright © 2017 Layer. All rights reserved.
//

import Atlas

class ConversationAvatar: NSObject, ATLAvatarItem {
    var presenceStatus: LYRIdentityPresenceStatus
    var avatarImageURL: URL?
    var avatarImage: UIImage?
    var avatarInitials: String?
    
    init(conversationParticipant: ConversationParticipant) {
        self.presenceStatus = .available
        
        if conversationParticipant.userID == Config.larryUserID {
            self.avatarImage = UIImage(named: "larry-avatar")
//            self.avatarInitials = "LB"
//            self.avatarImageURL = URL(string: "AppIcon")
            self.presenceStatus = .available
        } else {
            self.avatarImage = conversationParticipant.avatarImage
            self.avatarInitials = conversationParticipant.avatarInitials
            self.avatarImageURL = conversationParticipant.avatarImageURL
            self.presenceStatus = conversationParticipant.presenceStatus
        }
        
        if(conversationParticipant.avatarImageURL != nil){
            if(!(conversationParticipant.avatarImageURL!.absoluteString.contains("no-user-image"))){
                var avatarURL = conversationParticipant.avatarImageURL!.relativeString
                avatarURL = avatarURL.replacingOccurrences(of: "http:", with: "https:")
                self.avatarImageURL = URL(string: avatarURL)
            }
        }
        
    }
}
