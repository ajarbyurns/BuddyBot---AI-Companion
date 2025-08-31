//
//  ChatView.swift
//  AICompanion
//
//  Created by Ajarbyurns on 06/08/25.
//
import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct ChatView: View {
    
    enum ChatMode {
        case text
        case audio
    }
    
    @State private var mode: ChatMode = .text
    @State private var text: String = ""
    @State private var pulse = false
    @FocusState.Binding var isEditing: Bool
    
    @ObservedObject var agent: ModelAgent
    
    var body: some View {
        if agent.llmFinishedLoading && agent.ttsFinishedLoading {
            if mode == .text {
                VStack {
                    TextField("Type your message...", text: $text, axis: .vertical)
                        .lineLimit(5)
                        .textFieldStyle(.plain)
                        .focused($isEditing)
                        .accentColor(Color("TextAccentColor"))
                        .foregroundColor(Color("TextAccentColor"))
                        .font(textEditorFont)
                        .padding(paddingSize)
                    
                    HStack(alignment: .bottom) {
                        
                        /*
                         Button(action: {
                         guard !isLoading else { return }
                         //Upload Photo
                         }, label: {
                         Image(systemName: "plus")
                         .foregroundStyle(isLoading ? .gray : .black)
                         .font(.title)
                         })
                         .buttonStyle(.plain)
                         .background(.clear)
                         .padding(.leading, 15)
                         .padding(.bottom, 10)
                         */
                        
                        Spacer()
                        
                        Button(action: {
                            isEditing = false
                            if agent.isLoading {
                                agent.stop()
                            } else if text.isEmpty {
                                agent.requestSpeechAuthorization {
                                    mode = .audio
                                }
                            } else {
                                agent.receiveText(input: text)
                                text = ""
                            }
                        }, label: {
                            Image(systemName: agent.isLoading ? "stop.circle.fill" : text.isEmpty ? "mic.circle.fill" : "arrow.up.circle.fill")
                                .foregroundStyle(Color("TextAccentColor"))
                                .font(buttonSize)
                        })
                        .buttonStyle(.plain)
                        .background(.clear)
                        .padding(.trailing, 15)
                        .padding(.bottom, 10)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.regularMaterial)
                )
                .padding(.horizontal, paddingSize)
                .padding(.bottom, paddingSize)
            } else {
                VStack {
                    Button(action: {
                        if agent.isLoading {
                            agent.stop()
                        } else {
                            agent.stop()
                            mode = .text
                        }
                    }, label: {
                        Image(systemName: agent.isLoading ? "stop.circle.fill" : "mic.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundStyle(agent.isLoading ? .red : .purple)
                            .scaleEffect(pulse ? 1.2 : 1.0)
                            .opacity(pulse ? 0.7 : 1.0)
                            .animation(
                                .easeInOut(duration: 0.8)
                                .repeatForever(autoreverses: true),
                                value: pulse
                            )
                    })
                    .buttonStyle(.plain)
                    .background(.clear)
                    .onAppear {
                        pulse = true
                        if !agent.isLoading {
                            agent.startListening()
                        }
                    }
                    .onDisappear {
                        pulse = false
                    }
                    .onChange(of: agent.isLoading, { old, new in
                        if new == false {
                            agent.startListening()
                        }
                    })
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        } else {
            VStack {
                Text("Loading...")
                    .font(.system(size: 200))
                    .fontDesign(.rounded)
                    .lineLimit(1)
                    .minimumScaleFactor(0.1)
                    .frame(maxWidth: .infinity, maxHeight: 80)
                    .foregroundStyle(Color("TextAccentColor"))
                    .opacity(pulse ? 0.7 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true),
                        value: pulse
                    )
                    .onAppear {
                        pulse = true
                    }
                    .onDisappear {
                        pulse = false
                    }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }
}
