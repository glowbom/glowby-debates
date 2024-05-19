//
//  Messages.swift
//  Chat
//
//  Created by Jacob Ilin on 4/9/23.
//

import SwiftUI

struct Messages: View {
    @State var messages: [Message]

    func processMessageText(_ messageText: String) -> String {
        let languagePrefixes = [
            "Italian: ",
            "German: ",
            "Portuguese: ",
            "Dutch: ",
            "Russian: ",
            "American Spanish: ",
            "Mexican Spanish: ",
            "Canadian French: ",
            "French: ",
            "Spanish: ",
            "American English: ",
            "Australian English: ",
            "British English: ",
            "English: "
        ]

        var processedText = messageText
        for prefix in languagePrefixes {
            processedText = processedText.replacingOccurrences(of: prefix, with: "")
        }

        return processedText
    }

    var body: some View {
        List {
            ForEach(messages.reversed()) { message in
                let processedText = processMessageText(message.text)
                MessageBubble(
                    text: processedText,
                    username: message.username ?? "",
                    isCurrentUser: message.userId == "Me",
                    link: message.link.flatMap(URL.init(string:))

                )
            }
        }
        .listStyle(.plain)
    }
}

struct Messages_Previews: PreviewProvider {
    static var previews: some View {
        Messages(messages: [])
    }
}
