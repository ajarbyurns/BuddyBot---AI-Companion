//
//  LLMDirector.swift
//  BuddyBot
//
//  Created by Ajarbyurns on 18/08/25.
//
import Foundation
import Kuzco
import NaturalLanguage
import SwiftData

@Model
class DialogueTurn {
    var id: UUID
    var role: DialogueRole
    var text: String
    var timeStamp: Date

    init(id: UUID = UUID(),
         role: DialogueRole,
         text: String,
         timeStamp: Date = Date()) {
        self.id = id
        self.role = role
        self.text = text
        self.timeStamp = timeStamp
    }
    
    init(turn: Turn, timeStamp: Date = Date()) {
        self.id = turn.id
        self.role = turn.role
        self.text = turn.text
        self.timeStamp = timeStamp
    }
}

protocol LLMDirectorDelegate: AnyObject {
    func errorMessage(_ text: String)
    func sentencesFormed(_ sentences: [String])
    func generationFinished()
    func didFinishLoadingModel()
}

class LLMDirector {
    
    private let systemPrompt = "Your name is Ashe, an AI Companion. You have an outgoing personality. Response limited to 50 words max. Don't keep repeating the same sentence"
    private let kuzco = Kuzco.shared
    private let sanitizer: StringSanitizer
    private var model: LlamaInstance?
    weak var delegate: LLMDirectorDelegate?
    
    private var chatContext: ModelContext
    private let chatLimit = 100
    private var chats: [Turn] = []
    
    private var task: Task<Void, Error>?
    
    init(sanitizer: StringSanitizer, chatContext: ModelContext) {
        self.sanitizer = sanitizer
        self.chatContext = chatContext
        
        guard let url = Bundle.main.path(forResource: "Qwen2.5-1.5B-Instruct-Q4_K_M", ofType: "gguf")  else {
            return
        }
        
        let profile = ModelProfile(
            id: "Qwen2.5-1.5B-Instruct-Q4_K_M",
            sourcePath: url,
            architecture: .qwen2
        )
                
        Task {
            let (_, result) = await Kuzco.loadModelSafely(
                profile: profile,
                settings: .standard,
                predictionConfig: .creative
            )
            Task { @MainActor in
                switch result {
                case .success(let loadedInstance):
                    model = loadedInstance
                    let systemTurn = Turn(role: .system, text: systemPrompt)
                    chatContext.insert(DialogueTurn(turn: systemTurn))
                    chats.append(systemTurn)
                    delegate?.didFinishLoadingModel()
                case .failure(_):
                    delegate?.errorMessage("LLM Failed to load")
                }
            }
        }
    }
    
    /*
    private func getChatHistory() {
        let fetchDescriptor = FetchDescriptor<DialogueTurn>(
            sortBy: [SortDescriptor(\.timeStamp, order: .forward)]
        )
        
        do {
            let chatHistory = try chatContext.fetch(fetchDescriptor)
            if chatHistory.isEmpty {
                let systemTurn = Turn(role: .system, text: systemPrompt)
                chatContext.insert(DialogueTurn(turn: systemTurn))
                chats.append(systemTurn)
            } else {
                for chat in chatHistory {
                    chats.append(Turn(id: chat.id, role: chat.role, text: chat.text))
                }
            }
        } catch {
            delegate?.errorMessage("Failed to load chat history: \(error.localizedDescription)")
        }
    }
     */
    
    private func pruneChatHistory(count: Int = 20) {
        
        guard chats.count > chatLimit else { return }
        
        var fetchDescriptor = FetchDescriptor<DialogueTurn>(
            sortBy: [SortDescriptor(\.timeStamp, order: .forward)]
        )
        fetchDescriptor.fetchLimit = chatLimit
        
        do {
            let chatHistory = try chatContext.fetch(fetchDescriptor)
            if chatHistory.count >= chatLimit {
                for i in 0..<(chatHistory.count - chatLimit + count) {
                    if i > chatHistory.count - 1 {
                        break
                    } else {
                        if chatHistory[i].role != .system {
                            chatContext.delete(chatHistory[i])
                        }
                    }
                }
                chats = chats.suffix(chatLimit - count)
            }
        } catch {
            delegate?.errorMessage("Failed to prune chat history: \(error.localizedDescription)")
        }
    }
    
    func generate(prompt: String) {
        guard let model else {
            delegate?.errorMessage("LLM not found")
            return
        }
        
        let turn = Turn(role: .user, text: prompt)
        chats.append(turn)
                
        var response = ""
        var fullResponse = ""
        
        task?.cancel()
        task = Task {
            do {
                let predictionStream = await model.generate(
                    dialogue: chats
                )
                for try await chunk in predictionStream {
                    guard !Task.isCancelled else { return }
                    response += chunk
                    fullResponse += chunk
                    if isPunctuation(chunk) {
                        var sentences = generateSentences(text: response)
                        if sentences.count > 1 {
                            response = sentences.removeLast() + " "
                        } else if sentences.count == 1 {
                            response = ""
                        }
                        delegate?.sentencesFormed(sentences)
                    }
                }
                let sentences = generateSentences(text: response)
                delegate?.sentencesFormed(sentences)
                let modelTurn = Turn(role: .assistant, text: fullResponse)
                chats.append(modelTurn)
                Task { @MainActor in
                    chatContext.insert(DialogueTurn(turn: turn))
                    chatContext.insert(DialogueTurn(turn: modelTurn))
                    pruneChatHistory()
                    delegate?.generationFinished()
                }
            } catch {
                Task { @MainActor in
                    pruneChatHistory()
                    delegate?.errorMessage("Context exceeds buffer, pruning chat history...")
                    delegate?.generationFinished()
                }
            }
        }
    }
    
    func isPunctuation(_ token: String) -> Bool {
        let punctuations: Set<Character> = [".", "!", "?"]
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty &&
               trimmed.allSatisfy { punctuations.contains($0) }
    }
    
    func stop() {
        task?.cancel()
        task = Task {
            await model?.interruptCurrentPrediction()
        }
    }
    
    private func generateSentences(text: String) -> [String] {
        var results: [String] = []
        let tokenizer = NLTokenizer(unit: .sentence)
        let sanitizedText = sanitizer.preSanitize(text)
        tokenizer.string = sanitizedText
        let allowedCharacters: Set<Character> = [
            "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
            ",", ".", "!", "?", "\"", "'", " "
        ]
        
        tokenizer.enumerateTokens(in: sanitizedText.startIndex..<sanitizedText.endIndex) { range, _ in
            var sentence = String(sanitizedText[range])
            var sanitize = false
            
            for character in text {
                let lowercasedCharacter = Character(String(character).lowercased())
                if !allowedCharacters.contains(lowercasedCharacter) {
                    sanitize = true
                    break
                }
            }
            
            if sanitize {
                sentence = sanitizer.postSanitize(sentence)
            }
            
            if !sentence.isEmpty {
                results.append(sentence)
            }
            
            return true
        }
        
        return results
    }
}
