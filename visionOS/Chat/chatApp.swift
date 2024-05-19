//
//  ChatApp.swift
//  Chat
//
//  Created by Jacob Ilin on 4/14/24.
//

import SwiftUI

@main
struct ChatApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }.immersionStyle(selection: .constant(.full), in: .full)
    }
}
