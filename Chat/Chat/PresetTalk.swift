//
//  PresetTalk.swift
//  Chat
//
//  Created by Jacob Ilin on 4/9/23.
//

import SwiftUI

struct TalkView: View {
    @State private var content: [String: Any]?
    @State private var title: String?
    @State private var mainColor: Color = Color.blue
    @State private var voice: Bool = false
    @State private var questions: [[String: Any]] = []
    
    init(content: [String: Any]?) {
        self._content = State(initialValue: content)
    }
    
    func loadContentFromAssets() {
        guard let theURL = Bundle.main.url(forResource: "talk", withExtension: "glowbom") else {
            print("No URL!")
            return
        }
        
        guard let data = try? Data(contentsOf: theURL) else {
            print("No Data!")
            return
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            if let jsonDict = json as? [String: Any] {
                self.content = jsonDict
                initializeTalkState()
            } else {
                print("Invalid JSON format")
            }
        } catch let err {
            print("Some decoding error happened \(err)")
        }
    }
    
    func initializeTalkState() {
        if let content = content {
            questions = content["questions"] as? [[String: Any]] ?? []
            title = content["title"] as? String
            if let mainColorString = content["main_color"] as? String {
                mainColor = getColorFromString(mainColorString)
            } else {
                mainColor = Color.blue
            }
            voice = content["voice"] as? Bool ?? false
            
            print(mainColor)
        } else {
            loadContentFromAssets()
        }
    }
    
    func getColorFromString(_ colorString: String) -> Color {
        switch colorString.lowercased() {
        case "black":
            return Color.black
        case "blue":
            return Color.blue
        case "green":
            return Color.green
        case "grey":
            return Color.gray
        case "red":
            return Color.red
        default:
            return Color.blue
        }
    }
    
    var body: some View {
        VStack {
            if content == nil {
                Text("Loading...")
            } else {
                ChatScreen(
                    questions: questions,
                    name: content?["start_over"] as? String ?? "AI",
                    voice: voice,
                    mainColor: mainColor
                )
            }
        }
        .navigationBarTitle(title ?? "Chat App", displayMode: .inline)
        .onAppear {
            initializeTalkState()
        }
    }
}


