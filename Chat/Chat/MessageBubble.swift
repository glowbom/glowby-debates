//
//  MessageBubble.swift
//  Chat
//
//  Created by Jacob Ilin on 4/9/23.
//

import SwiftUI

struct MessageBubble: View {
    let text: String
    let username: String
    let isCurrentUser: Bool
    let link: URL?

    func launchLink() {
        if let link = link, UIApplication.shared.canOpenURL(link) {
            UIApplication.shared.open(link)
        } else {
            print("Could not launch \(String(describing: link))")
        }
    }

    var imageURL: URL? {
        if text.contains("[SCREENSHOT]") {
            let parts = text.split(separator: " ")
            if let urlPart = parts.first(where: { $0.hasPrefix("http") }) {
                return URL(string: String(urlPart))
            }
        }
        return nil
    }

    @ViewBuilder
    var messageContent: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading) {
            Text(username)
                .fontWeight(.bold)
                .foregroundColor(isCurrentUser ? .black : .white)
            
            if let imageURL = imageURL {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    Text("Loading...")
                        .foregroundColor(isCurrentUser ? .black : .white)
                }
                .frame(maxWidth: 250)
                .cornerRadius(8)
            } else if link != nil {
                Button(action: launchLink) {
                    Text(text)
                        .foregroundColor(isCurrentUser ? .black : .white)
                }
                .padding()
                .background(Color.blue)
                .cornerRadius(8)
            } else {
                Text(text)
                    .foregroundColor(isCurrentUser ? .black : .white)
            }
        }
    }

    var body: some View {
        HStack {
            if !isCurrentUser {
                Spacer()
            }
            
            messageContent
                .padding()
                .background(isCurrentUser ? Color.gray.opacity(0.3) : Color.blue)
                .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                .frame(width: 280, alignment: isCurrentUser ? .trailing : .leading)

            if isCurrentUser {
                Spacer()
            }
        }
    }
}

struct MessageBubble_Previews: PreviewProvider {
    static var previews: some View {
        MessageBubble(text: "Hello, World! [SCREENSHOT]http://example.com/image.jpg", username: "AI", isCurrentUser: false, link: nil)
    }
}
