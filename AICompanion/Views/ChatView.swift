//
//  ChatView.swift
//  AICompanion
//
//  Created by Barry Juans on 06/08/25.
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
    @FocusState private var isEditing: Bool
    @State private var textHeight: CGFloat = 50
    
    @ObservedObject var agent: ModelAgent
    
    var body: some View {
        if agent.llmFinishedLoading && agent.ttsFinishedLoading {
            if mode == .text {
                VStack {
                    ZStack(alignment: .topLeading) {
                        if text.isEmpty && !isEditing {
                            Text("Type your message...")
                                .foregroundColor(.gray)
                                .font(.title2)
                                .padding(.top)
                                .padding(.leading, 5)
                        }
                        
                        TextEditor(text: $text)
                            .focused($isEditing)
                            .foregroundColor(.black)
                            .font(.title2)
                            .accentColor(.black)
                            .padding(.top)
                            .padding(.leading, 5)
                    }
                    .frame(height: textHeight)
                    .padding(.horizontal, 10)
                    .onChange(of: text, { _, _ in
                        recalcHeight()
                    })
                    
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
                            if agent.isLoading {
                                agent.stop()
                            } else if text.isEmpty {
                                agent.requestSpeechAuthorization {
                                    mode = .audio
                                }
                            } else {
                                agent.receiveText(input: text) //test
                                text = ""
                            }
                        }, label: {
                            Image(systemName: agent.isLoading ? "stop.circle.fill" : text.isEmpty ? "mic.circle.fill" : "arrow.up.circle.fill")
                                .foregroundStyle(.black)
                                .font(.largeTitle)
                        })
                        .buttonStyle(.plain)
                        .background(.clear)
                        .padding(.trailing, 15)
                        .padding(.bottom, 10)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.thinMaterial)
                )
                .padding(.horizontal)
                .padding(.bottom)
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
                    .foregroundStyle(.black)
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
    
    func recalcHeight() {
        #if os(macOS)
        let size = CGSize(width: (NSScreen.main?.frame.width ?? 300) - 100, height: .infinity)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 17)
        ]
        let boundingBox = text.boundingRect(with: size,
                                            options: [.usesLineFragmentOrigin, .usesFontLeading],
                                            attributes: attributes,
                                            context: nil)
        textHeight = min(max(50, boundingBox.height + 20), 300)
        #else
        let screenWidth = UIScreen.main.bounds.width
        let size = CGSize(width: screenWidth - 100, height: CGFloat.greatestFiniteMagnitude)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17)
        ]
        let boundingBox = text.boundingRect(with: size,
                                            options: [.usesLineFragmentOrigin, .usesFontLeading],
                                            attributes: attributes,
                                            context: nil)
        textHeight = min(max(50, boundingBox.height + 20), 300)
        #endif
    }
}
