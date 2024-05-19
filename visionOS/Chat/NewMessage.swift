//
//  NewMessage.swift
//  Chat
//
//  Created by Jacob Ilin on 4/9/23.
//

import SwiftUI
import GoogleGenerativeAI
import Combine

struct NewMessage: View {
    @State private var callOpenAI = true
    
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
    @State private var apiKeyGemini: String = ""
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
    
    func tryLoadKeys() {
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
        
        let queryGemini: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "GlowbyGeminiKey",
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var itemGemini: CFTypeRef?
        if SecItemCopyMatching(queryGemini as CFDictionary, &itemGemini) == noErr {
            if let itemGemini = itemGemini as? Data,
               let apiKeyString = String(data: itemGemini, encoding: .utf8) {
                self.apiKeyGemini = apiKeyString
            }
        }
    }
    
    func convertMessagesToChats(messages: [Message]) -> [[String: String]] {
        guard messages.count > 1 else { return [] }
        
        return messages.dropFirst().map { message in
            let role: String = message.userId == "Me" ? "user" : "assistant"
            return ["role": role, "content": message.text]
        }
    }
    
    func convertMessagesToChatsForGemini(messages: [Message]) -> [ModelContent] {
        guard messages.count > 1 else { return [] }
        
        return messages.dropFirst().map { message in
            let role: String = message.userId == "Me" ? "user" : "model"
            return ModelContent(role: role, parts: message.text)
        }
    }
    
    func callGemini(prompt: String) async {
        
        if apiKeyGemini == "" {
            tryLoadKeys()
        }
        
        // Call Gemini
        // Access your API key from your on-demand resource .plist file
        // (see "Set up your API key" above)
        let model = GenerativeModel(name: "gemini-1.5-flash-latest", apiKey: apiKeyGemini)
        
        // Convert previous messages to chat history
        var history = convertMessagesToChatsForGemini(messages: self.messages)
        
        // Add system message to history
        let systemMessage = ModelContent(role: "user", parts: "You are Glowby, super helpful, nice, and humorous AI assistant ready to help with anything. I like to joke around. Always be super concise. Max 1 sentence.")
        history.insert(systemMessage, at: 0)
            
        // Initialize the chat
        let chat = model.startChat(history: history)
        
        do {
            let r = try await chat.sendMessage(prompt)
            if let text = r.text {
                print(text)
                let aiResponse = Message(
                    text: text,
                    createdAt: Timestamp(date: Date()),
                    userId: AI.defaultUserId,
                    username: "Glowby (Powered by Gemini 1.5 Flash)",
                    link: nil
                )
                self.messages.insert(aiResponse, at: 0)
                self.enteredMessage = ""
                self.onMessageSent()
            }
        } catch {
            print("Error generating content: \(error)")
            // Optionally, you can add code to handle the error here
            let errorResponse = Message(
                text: "Something went wrong. Please try again later.",
                createdAt: Timestamp(date: Date()),
                userId: AI.defaultUserId,
                username: "Glowby (Powered by Gemini 1.5 Flash)",
                link: nil
            )
            self.messages.insert(errorResponse, at: 0)
            self.enteredMessage = ""
            self.onMessageSent()
        }
    }
    
    func callOpenAI(prompt: String) {
        if apiKey == "" {
            tryLoadKeys()
        }
        
        loading = true
         let previousMessages = convertMessagesToChats(messages: messages)
         openAIAPI.sendRequest(apiKey: apiKey, message: prompt, previousMessages: previousMessages) { result in
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
    }

    func sendMessage() {
        if loading {
            return
        }
        
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
                if callOpenAI {
                    callOpenAI(prompt: message)
                    callOpenAI = false
                } else {
                    loading = true
                    // Wrap the call to callGemini in a Task and handle completion
                                    Task {
                                        await callGemini(prompt: message)
                                        DispatchQueue.main.async {
                                            self.loading = false // Hide loading spinner after task completion
                                        }
                                    }
                    
                    callOpenAI = true
                }
                
                
                
                // Call OpenAI Here
               /* loading = true
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
                                }*/
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
            tryLoadKeys()
        }
    }
}
