//
//  OpenAiApi.swift
//  Chat
//
//  Created by Jacob Ilin on 5/18/24.
//

import Foundation
import Combine

struct OpenAIResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            var content: String
        }
        var message: Message
        var finish_reason: String?
    }
    struct Usage: Codable {
        var total_tokens: Int
    }
    var choices: [Choice]
    var usage: Usage
}

class OpenAIAPI: ObservableObject {
    @Published var response: String = ""
    private var cancellables = Set<AnyCancellable>()
    private var totalTokensUsed = 0
    
    func sendRequest(apiKey: String, message: String, previousMessages: [[String: String]] = [], maxTries: Int = 1, customSystemPrompt: String? = nil, completion: @escaping (Result<OpenAIResponse, Error>) -> Void) {
        var finalResponse = ""
        var inputMessage = message
        var tries = 0
        
        let apiUrl = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        func requestOpenAI() {
            print("Attempt \(tries + 1) to get response from OpenAI API")
            
            let adjustedMaxTokens = getAdjustedMaxTokens(inputMessage)
            let model = "gpt-4o" // Replace with your model name
            let systemPrompt = customSystemPrompt ?? "You are Glowby, super helpful, nice, and humorous AI assistant ready to help with anything. I like to joke around. Always be super concise. Max 1 sentence."
            
            var messages: [[String: String]] = [["role": "system", "content": systemPrompt]]
            messages.append(contentsOf: previousMessages)
            messages.append(["role": "user", "content": inputMessage])
            
            let data: [String: Any] = [
                "model": model,
                "messages": messages,
                "max_tokens": adjustedMaxTokens,
                "n": 1,
                "stop": NSNull(),
                "temperature": 1
            ]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: data)
                print("Request data: \(data)")
            } catch {
                print("Error serializing request body: \(error)")
                completion(.failure(error))
                return
            }
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error during URLSession dataTask: \(error)")
                    if tries + 1 < maxTries {
                        tries += 1
                        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                            requestOpenAI()
                        }
                    } else {
                        completion(.failure(error))
                    }
                    return
                }
                
                guard let data = data, let response = response as? HTTPURLResponse else {
                    print("No data or invalid response")
                    if tries + 1 < maxTries {
                        tries += 1
                        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                            requestOpenAI()
                        }
                    } else {
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get response from OpenAI API"])))
                    }
                    return
                }
                
                print("Response status code: \(response.statusCode)")
                
                guard response.statusCode == 200 else {
                    print("Unexpected response status code: \(response.statusCode)")
                    if tries + 1 < maxTries {
                        tries += 1
                        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                            requestOpenAI()
                        }
                    } else {
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get response from OpenAI API"])))
                    }
                    return
                }
                
                do {
                    let decodedResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                    if let firstChoice = decodedResponse.choices.first {
                        print("Received response from OpenAI API")
                        finalResponse += firstChoice.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
                        self.totalTokensUsed += decodedResponse.usage.total_tokens
                        let cost = Double(decodedResponse.usage.total_tokens) * 0.002 / 1000
                        print("Tokens used in this response: \(decodedResponse.usage.total_tokens)")
                        print("Cost of this response: $\(cost)")
                        print("Total tokens used so far: \(self.totalTokensUsed)")
                        let totalCost = Double(self.totalTokensUsed) * 0.002 / 1000
                        print("Total cost so far: $\(totalCost)")
                        
                        if firstChoice.finish_reason == "length" {
                            inputMessage += firstChoice.message.content
                            let maxLength = 10240
                            if inputMessage.count > maxLength {
                                inputMessage = String(inputMessage.suffix(maxLength))
                            }
                            tries += 1
                            requestOpenAI()
                        } else {
                            DispatchQueue.main.async {
                                completion(.success(decodedResponse))
                            }
                        }
                    }
                } catch {
                    print("Error decoding response: \(error)")
                    if tries + 1 < maxTries {
                        tries += 1
                        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                            requestOpenAI()
                        }
                    } else {
                        completion(.failure(error))
                    }
                }
            }.resume()
        }
        
        requestOpenAI()
    }





    
    private func getAdjustedMaxTokens(_ input: String) -> Int {
        // Your logic for adjusting max tokens
        return 1024 // Example value, replace with your logic
    }
}
