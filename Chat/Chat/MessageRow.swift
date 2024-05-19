//
//  MessageRow.swift
//  Chat
//
//  Created by Jacob Ilin on 4/9/23.
//

import SwiftUI

struct MessageRow: View {
    let message: Message
    let mainColor: Color

    var body: some View {
        HStack {
            if message.userId == "Me" {
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                if let username = message.username {
                    Text(username)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }

                Text(message.text)
                    .padding(8)
                    .background(message.userId == "Me" ? mainColor : Color.gray.opacity(0.2))
                    .foregroundColor(message.userId == "Me" ? .white : .primary)
                    .cornerRadius(8)
            }

            if message.userId != "Me" {
                Spacer()
            }
        }
    }
}

struct MessageRow_Previews: PreviewProvider {
    static var previews: some View {
        MessageRow(message: Message(text: "Hello, world!", createdAt: Timestamp.now(), userId: "Me"), mainColor: Color.red)
            .previewLayout(.sizeThatFits)
    }
}

