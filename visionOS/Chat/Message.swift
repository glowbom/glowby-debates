//
//  Message.swift
//  Chat
//
//  Created by Jacob Ilin on 4/9/23.
//

import Foundation

class Message: CustomStringConvertible, Identifiable, Equatable {
    let text: String
    let createdAt: Timestamp
    let userId: String
    let username: String?
    let link: String?

    init(text: String, createdAt: Timestamp, userId: String, username: String? = nil, link: String? = nil) {
        self.text = text
        self.createdAt = createdAt
        self.userId = userId
        self.username = username
        self.link = link
    }

    var description: String {
        return "Message(text: \(text), createdAt: \(createdAt), userId: \(userId), username: \(String(describing: username)), link: \(String(describing: link)))"
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.text == rhs.text &&
            lhs.createdAt == rhs.createdAt &&
            lhs.userId == rhs.userId &&
            lhs.username == rhs.username &&
            lhs.link == rhs.link
    }

}
