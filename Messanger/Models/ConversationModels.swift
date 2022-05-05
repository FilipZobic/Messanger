//
//  ConversationModels.swift
//  Messanger
//
//  Created by Filip Zobic on 5.5.22..
//

import Foundation


struct Conversation {
    let id: String
    let name: String
    let recipient: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let date: String
    let text: String
    let isRead: Bool
}
