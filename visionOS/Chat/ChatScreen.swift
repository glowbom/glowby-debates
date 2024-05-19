//
//  ChatScreen.swift
//  Chat
//
//  Created by Jacob Ilin on 4/9/23.
//

import SwiftUI

struct ChatScreen: View {
    let questions: [[String: Any]]
    let name: String
    let voice: Bool
    let mainColor: Color
    
    @StateObject private var textToSpeech = TextToSpeech()
    @State private var messages: [Message] = []
    @State var progress: CGFloat = 0
    @State private var modelDownloadConcent = false
    
    @State private var isApiKeyDialogPresented = false
    @State private var apiKey: String = ""
    @State private var obscureApiKey = true
    
    private func refresh() {
        if voice, let latestMessage = messages.first, latestMessage.userId == "007" {
            textToSpeech.stopSpeaking()
            textToSpeech.speakText(latestMessage.text)
        }
    }
    
    func updateProgress(_ progress: Double) {
        self.progress = CGFloat(progress)
    }
    
    func toggleApiKeyVisibility() {
        obscureApiKey.toggle()
    }
    
    
    var body: some View {
        VStack {
            // Top Bar
            HStack {
                Text("Glowby")
                    .font(.title)
                    .fontWeight(.bold).padding()

                Spacer()
                
                Button("Clear") {
                    self.messages.removeAll()
                    textToSpeech.stopSpeaking()
                }
                .padding(.horizontal)

                Spacer()

                /*Text("Powered by Glowbom")
                    .font(.title)
                    .fontWeight(.light)*/
                
                // API KEY
                    // Image Download Button
                    Button(action: {
                        isApiKeyDialogPresented = true
                        /*if let imageToSave = self.selectedImage {
                            UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil)
                        }*/
                    }) {
                        //Image(systemName: "square.and.arrow.down")
                        Text("Enter API Key")
                    }.sheet(isPresented: $isApiKeyDialogPresented) {
                        VStack {
                            Text("Enter OpenAI API Key")
                                .font(.headline)
                                .padding()
                            
                            Text("Get your API key →")
                                .foregroundColor(.white)
                                .underline()
                                .onTapGesture {
                                    // Open URL using UIApplication.shared.open
                                    guard let url = URL(string: "https://platform.openai.com/account/api-keys") else { return }
                                    UIApplication.shared.open(url)
                                }
                            
                            if obscureApiKey {
                                SecureField("sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", text: $apiKey)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding()
                                    .overlay(
                                        Button(action: toggleApiKeyVisibility) {
                                            Image(systemName: "eye")
                                                .foregroundColor(.gray)
                                        }
                                            .padding(.trailing, 8),
                                        alignment: .trailing
                                    )
                            } else {
                                TextField("sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", text: $apiKey)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding()
                                    .overlay(
                                        Button(action: toggleApiKeyVisibility) {
                                            Image(systemName: "eye.slash")
                                                .foregroundColor(.gray)
                                        }
                                            .padding(.trailing, 8),
                                        alignment: .trailing
                                    )
                            }
                            
                            
                            Text("API Key is stored locally and not shared.")
                                .font(.caption)
                                .padding()
                            
                            Button("Save") {
                                if apiKey.isEmpty {
                                    // Delete the API key from the Keychain
                                    let query: [String: Any] = [
                                        kSecClass as String: kSecClassGenericPassword,
                                        kSecAttrAccount as String: "GlowbyOpenAIKey"
                                    ]
                                    SecItemDelete(query as CFDictionary)
                                } else {
                                    let query: [String: Any] = [
                                        kSecClass as String: kSecClassGenericPassword,
                                        kSecAttrAccount as String: "GlowbyOpenAIKey"
                                    ]
                                    
                                    let attributesToUpdate: [String: Any] = [
                                        kSecValueData as String: apiKey.data(using: .utf8)!
                                    ]
                                    
                                    let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
                                    
                                    if status == errSecItemNotFound { // If the item does not exist, add it
                                        let keychainItemQuery: [String: Any] = [
                                            kSecClass as String: kSecClassGenericPassword,
                                            kSecAttrAccount as String: "GlowbyOpenAIKey",
                                            kSecValueData as String: apiKey.data(using: .utf8)!
                                        ]
                                        SecItemAdd(keychainItemQuery as CFDictionary, nil)
                                    } else if status != errSecSuccess {
                                        print("Error updating the API key in Keychain: \(status)")
                                    }
                                }
                                
                                // Dismiss the sheet
                                isApiKeyDialogPresented = false
                            }
                            .padding()
                            
                            
                            Spacer()
                        }
                        .frame(width: 340)
                        .padding()
                    }
                    
            }
            .padding()
            .background(mainColor.opacity(0.2))
            
            GeometryReader { geometry in
                ScrollView(.vertical, showsIndicators: true) {
                    ScrollViewReader { scrollViewProxy in
                        LazyVStack(spacing: 8) {
                            ForEach(messages.reversed()) { message in
                                MessageRow(message: message, mainColor: mainColor)
                            }
                        }
                        .padding()
                        .onChange(of: messages) {
                            withAnimation(.linear(duration: 0.1)) {
                                if let lastMessage = messages.first {
                                    scrollViewProxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }
            NewMessage(refresh: refresh, messages: $messages, questions: questions, name: name, onMessageSent: refresh)
                .padding(.bottom).padding(.leading, 10).padding(.trailing, 10).padding(.top, 2)
            
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
        .background(Color(UIColor.systemBackground))
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct ChatScreen_Previews: PreviewProvider {
    static var previews: some View {
        ChatScreen(questions: [], name: "AI", voice: false, mainColor: Color.black)
    }
}

