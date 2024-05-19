//
//  ContentView.swift
//  Chat
//
//  Created by Jacob Ilin on 4/14/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {

    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    var body: some View {
        VStack {
            TalkView(content: nil)
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
