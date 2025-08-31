//
//  AICompanionApp.swift
//  AICompanion
//
//  Created by Ajarbyurns on 06/08/25.
//

import SwiftUI

@main
struct AICompanionApp: App {
    @StateObject var agent = ModelAgent()
    
    var body: some Scene {
        WindowGroup {
            ContentView(agent: agent)
        }
        .modelContainer(for: DialogueTurn.self)
    }
}
