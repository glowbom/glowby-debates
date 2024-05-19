//
//  NewMessage.swift
//  Chat
//
//  Created by Jacob Ilin on 4/9/23.
//

import SwiftUI
import Combine

struct NewMessage: View {
    @State private var enteredMessage: String = ""
    @State private var isRecording: Bool = false
    @State private var ai: AI
    @State private var refreshKey: UUID = UUID()
    @Binding var messages: [Message]
    let questions: [[String: Any]]?
    let name: String?
    let onMessageSent: () -> Void
    @State private var lastSessionId: String = ""
    @State private var finalResponse: String = ""
    @State private var loading: Bool = false
    @State private var apiKey: String = ""
    private let openAIAPI = OpenAIAPI()
    
    private let networkManager: NetworkManager
    
    init(refresh: @escaping () -> Void, messages: Binding<[Message]>, questions: [[String: Any]]?, name: String?, onMessageSent: @escaping () -> Void) {
        self._messages = messages
        self.questions = questions
        self.name = name
        self._ai = State(initialValue: AI(name: name, questions: questions))
        self.onMessageSent = onMessageSent
        self.networkManager = NetworkManager(apiProvider: MultiOnAPI())
    }
    
    func convertMessagesToChats(messages: [Message]) -> [[String: String]] {
        guard messages.count > 1 else { return [] }
        
        return messages.dropFirst().map { message in
            let role: String = message.userId == "Me" ? "user" : "assistant"
            return ["role": role, "content": message.text]
        }
    }

    func sendMessage() {
        messages.insert(
            Message(text: enteredMessage.trimmingCharacters(in: .whitespacesAndNewlines),
                    createdAt: Timestamp(date: Date()),
                    userId: "Me",
                    username: "Me"),
            at: 0
        )
        
        let message = enteredMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        enteredMessage = ""
        
        ai.message(message) { response in
            if response.count > 0 {
                for m in response {
                    self.messages.insert(m, at: 0)
                }
                self.enteredMessage = ""
                self.onMessageSent()
            } else {
                // Call OpenAI Here
                loading = true
                let previousMessages = convertMessagesToChats(messages: messages)
                openAIAPI.sendRequest(apiKey: apiKey, message: message, previousMessages: previousMessages) { result in
                                    DispatchQueue.main.async {
                                        loading = false
                                        switch result {
                                        case .success(let openAIResponse):
                                            if let finalResponse = openAIResponse.choices.first?.message.content {
                                                let aiResponse = Message(
                                                    text: finalResponse,
                                                    createdAt: Timestamp(date: Date()),
                                                    userId: AI.defaultUserId,
                                                    username: "Glowby (Powered by GPT-4o)",
                                                    link: nil
                                                )
                                                self.messages.insert(aiResponse, at: 0)
                                                self.enteredMessage = ""
                                                self.onMessageSent()
                                            }
                                        case .failure:
                                            let aiResponse = Message(
                                                text: "Something went wrong. Try again later...",
                                                createdAt: Timestamp(date: Date()),
                                                userId: AI.defaultUserId,
                                                username: "Glowby",
                                                link: nil
                                            )
                                            self.messages.insert(aiResponse, at: 0)
                                            self.enteredMessage = ""
                                            self.onMessageSent()
                                        }
                                        self.loading = false // Hide loading spinner
                                    }
                                }
                // call MultiOn Here
                /*
                 networkManager.sendMessage(message: message, sessionId: lastSessionId.isEmpty ? "" : lastSessionId) { result in
                     DispatchQueue.main.async {
                         loading = false
                         switch result {
                         case .success(let decodedResponse):
                             let receivedResponse = decodedResponse.result.trimmingCharacters(in: .whitespacesAndNewlines)
                             let sessionId = decodedResponse.session_id.trimmingCharacters(in: .whitespacesAndNewlines)
                             let screenshot = decodedResponse.screenshot.trimmingCharacters(in: .whitespacesAndNewlines)
                             
                             lastSessionId = sessionId
                             
                             finalResponse += receivedResponse
                             finalResponse += "[SCREENSHOT]\(screenshot)"
                             
                             let aiResponse = Message(
                                 text: finalResponse,
                                 createdAt: Timestamp.now(),
                                 userId: AI.defaultUserId,
                                 username: "Glowby",
                                 link: nil
                             )
                             self.messages.insert(aiResponse, at: 0)
                             self.enteredMessage = ""
                             self.onMessageSent()
                         case .failure:
                             let aiResponse = Message(
                                 text: "Something went wrong. Try again later...",
                                 createdAt: Timestamp.now(),
                                 userId: AI.defaultUserId,
                                 username: "Glowby",
                                 link: nil
                             )
                             self.messages.insert(aiResponse, at: 0)
                             self.enteredMessage = ""
                             self.onMessageSent()
                         }
                     }
                 }
                 */
            }
        }
        
        DispatchQueue.main.async {
            self.refreshKey = UUID() // Force the view to update
            self.enteredMessage = "" // Clear the message
            self.onMessageSent()
        }
    }
    
    func stopMessage() {
        DispatchQueue.main.async {
            enteredMessage = "" // Clear the message
            refreshKey = UUID() // Force the view to update
            // Provide feedback to the user that the operation was stopped, if necessary
        }
    }
    
    var body: some View {
        HStack {
            TextField("Send message...", text: $enteredMessage, onCommit: {
                
            })
            .id(refreshKey)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.bottom, 8)
            .multilineTextAlignment(.leading)
            .lineLimit(nil)
            .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 0))
            
            if loading {
                ProgressView() // This will show a spinner when the model is processing
                    .progressViewStyle(CircularProgressViewStyle()).padding()
            } else {
                Button(action: {
                    sendMessage()
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(enteredMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .white)
                }.disabled(enteredMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }.onAppear() {
            // Load the API key from the Keychain
                let query: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrAccount as String: "GlowbyOpenAIKey",
                    kSecReturnData as String: kCFBooleanTrue!,
                    kSecMatchLimit as String: kSecMatchLimitOne
                ]

                var item: CFTypeRef?
                if SecItemCopyMatching(query as CFDictionary, &item) == noErr {
                    if let item = item as? Data,
                       let apiKeyString = String(data: item, encoding: .utf8) {
                        self.apiKey = apiKeyString
                    }
                }
        }
    }
}
