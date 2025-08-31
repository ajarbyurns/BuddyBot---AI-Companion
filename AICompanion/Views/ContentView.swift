//
//  ContentView.swift
//  AICompanion
//
//  Created by Ajarbyurns on 06/08/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    
    @Environment(\.modelContext) private var chatContext
    @ObservedObject var agent: ModelAgent
    @FocusState private var isEditing: Bool
    
    var body: some View {
        ZStack {
            ModelView(agent: agent)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    isEditing = false
                }
            VStack {
                HStack {
                    if agent.isLoading {
                        ProgressView()
                            .scaleEffect(progressBarScale, anchor: .center)
                            .tint(Color("TextAccentColor"))
                            .padding()
                    }
                    if !agent.errorMessage.isEmpty {
                        Text(agent.errorMessage)
                            .fontWeight(.bold)
                            .fontDesign(.rounded)
                            .foregroundStyle(Color("TextAccentColor"))
                            .padding()
                    }
                    Spacer()
                }
                Spacer()
                ChatView(isEditing: $isEditing, agent: agent)
            }
        }
        .background(Color("AccentColor"))
        .onAppear {
            agent.setChatContext(chatContext: chatContext)
        }
    }
}
