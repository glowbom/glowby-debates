//
//  TextToSpeech.swift
//  Chat
//
//  Created by Jacob Ilin on 4/9/23.
//

import AVFoundation
import Combine

class TextToSpeech: ObservableObject {
    private let synthesizer: AVSpeechSynthesizer
    @Published var isSpeaking = false
    
    private let languageCodes = [
        "Italian": "it-IT",
        "German": "de-DE",
        "Portuguese": "pt-PT",
        "Dutch": "nl-NL",
        "Russian": "ru-RU",
        "American Spanish": "es-US",
        "Mexican Spanish": "es-MX",
        "Canadian French": "fr-CA",
        "French": "fr-FR",
        "Spanish": "es-ES",
        "American English": "en-US",
        "British English": "en-GB",
        "Australian English": "en-AU",
        "English": "en-US"
    ]
    
    init() {
        self.synthesizer = AVSpeechSynthesizer()
    }
    
    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
        }
    }
    
    func speakText(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: languageCode(for: text))
        isSpeaking = true
        self.synthesizer.speak(utterance)
    }
    
    private func languageCode(for text: String) -> String? {
        for (language, code) in languageCodes {
            if text.starts(with: "\(language):") {
                return code
            }
        }
        return nil
    }
    
    // Add this delegate function to update the isSpeaking property
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
}
