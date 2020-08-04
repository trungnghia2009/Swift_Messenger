//
//  Conversation.swift
//  Messenger
//
//  Created by trungnghia on 8/3/20.
//  Copyright © 2020 trungnghia. All rights reserved.
//

import Foundation

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let date: String
    let text: String
    let isRead: Bool
}
