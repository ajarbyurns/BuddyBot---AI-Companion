//
//  ContentView.swift
//  AICompanion
//
//  Created by Barry Juans on 06/08/25.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var agent = ModelAgent()
    
    var body: some View {
        ZStack {
            ModelView(agent: agent)
            VStack {
                HStack {
                    if agent.isLoading {
                        ProgressView()
                            .padding()
                    }
                    if !agent.errorMessage.isEmpty {
                        Text(agent.errorMessage)
                            .fontWeight(.bold)
                            .fontDesign(.rounded)
                            .foregroundStyle(.black)
                            .padding()
                    }
                    Spacer()
                }
                Spacer()
                ChatView(agent: agent)
            }
        }
        .background(.white)
    }
}
