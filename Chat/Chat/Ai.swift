//  Ai.swift
//  Chat
//
//  Created by Jacob Ilin on 4/9/23.
//

import Foundation

class AI {
    let questions: [[String: Any]]?
    let name: String?
    
    static let defaultUserId = "007"
    
    init(name: String?, questions: [[String: Any]]?) {
        self.name = name
        self.questions = questions
    }
    
    func message(_ message: String, completion: @escaping ([Message]) -> Void) {
        let foundQuestions = findMatchingQuestions(message)
        
        if !foundQuestions.isEmpty {
            generateResponseMessage(foundQuestions, completion: completion)
        } else {
            completion([])
        }
    }
    
    private func findMatchingQuestions(_ message: String) -> [[String: Any]] {
        var foundQuestions: [[String: Any]] = []
        let userMessage = sanitizeMessage(message)

        for (_, questionMap) in (questions ?? []).enumerated() {
            let question = questionMap["description"] as? String ?? ""

            let sanitizedQuestion = sanitizeMessage(question)
            
            if sanitizedQuestion == userMessage {
                foundQuestions.append(questionMap)
                break
            }
        }

        if foundQuestions.isEmpty {
            foundQuestions = searchForQuestions(userMessage)
        }

        return foundQuestions
    }


    private func searchForQuestions(_ userMessage: String) -> [[String: Any]] {
        var foundQuestions: [[String: Any]] = []

        for questionMap in questions ?? [] {
            let question = questionMap["description"] as? String ?? ""

            if sanitizeMessage(question).contains(userMessage) {
                foundQuestions.append(questionMap)
            }
        }

        return foundQuestions
    }
    
    private func sanitizeMessage(_ message: String) -> String {
        let unwantedCharacters = CharacterSet(charactersIn: "?.!,")
        let cleanedMessage = message.replacingOccurrences(of: "’", with: "'")
        return cleanedMessage.trimmingCharacters(in: unwantedCharacters).lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    
    private func generateResponseMessage(_ foundQuestions: [[String: Any]], completion: @escaping ([Message]) -> Void) {
        let rnd = Int.random(in: 0...Int.max)
        var messages: [String] = []
        
        for questionMap in foundQuestions {
            messages.append(contentsOf: questionMap["buttonsTexts"] as? [String] ?? [])
        }
        
        let index = rnd % messages.count
        
        let response = [
            Message(
                text: messages[index],
                createdAt: Timestamp.now(),
                userId: AI.defaultUserId,
                username: "Glowby",
                link: nil
            ),
        ]
        completion(response)
    }
    
}
