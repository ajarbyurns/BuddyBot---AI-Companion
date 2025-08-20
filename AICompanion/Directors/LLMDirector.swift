//
//  LLMDirector.swift
//  AICompanion
//
//  Created by Barry Juans on 18/08/25.
//
import Foundation
import Kuzco
import NaturalLanguage

protocol LLMDirectorDelegate: AnyObject {
    func errorMessage(_ text: String)
    func sentencesFormed(_ sentences: [String])
    func generationFinished()
    func didFinishLoadingModel()
}

class LLMDirector {
    
    private let systemPrompt = "Your name is Ashe, an AI Companion. You have an outgoing personality. No Emojis. Response limited to 200 words max"
    private let kuzco = Kuzco.shared
    private let sanitizer: StringSanitizer
    private let minTokens = 20
    private var model: LlamaInstance?
    weak var delegate: LLMDirectorDelegate?
    
    private var task: Task<Void, Error>?
    
    init(sanitizer: StringSanitizer) {
        self.sanitizer = sanitizer
        
        guard let url = Bundle.main.path(forResource: "gemma-2-2b-it-Q4_K_M", ofType: "gguf")  else {
            return
        }
        
        let profile = ModelProfile(
            id: "gemma-2-2b-it-Q4_K_M",
            sourcePath: url,
            architecture: .gemmaInstruct
        )
                
        Task {
            let (_, result) = await Kuzco.loadModelSafely(
                profile: profile,
                settings: .performanceFocused,
                predictionConfig: .creative
            )
            Task { @MainActor in
                switch result {
                case .success(let loadedInstance):
                    model = loadedInstance
                    delegate?.didFinishLoadingModel()
                case .failure(_):
                    delegate?.errorMessage("LLM Failed to load")
                }
            }
        }
    }
    
    func generate(prompt: String) {
        guard let model else {
            delegate?.errorMessage("LLM not found")
            return
        }
        
        let turns = [Turn(role: .user, text: prompt)]
                
        var response = ""
        var tokenCounter = 0
        
        task?.cancel()
        task = Task {
            do {
                let predictionStream = await model.generate(
                    dialogue: turns,
                    overrideSystemPrompt: systemPrompt
                )
                for try await chunk in predictionStream {
                    guard !Task.isCancelled else { return }
                    tokenCounter += 1
                    response += chunk
                    if tokenCounter >= minTokens {
                        var sentences = generateSentences(text: response)
                        if sentences.count > 1 {
                            response = sentences.removeLast() + " "
                        } else if sentences.count == 1 {
                            response = ""
                        }
                        delegate?.sentencesFormed(sentences)
                        tokenCounter = 0
                    }
                }
                delegate?.sentencesFormed([response])
                Task { @MainActor in
                    delegate?.generationFinished()
                }
            } catch {
                Task { @MainActor in
                    delegate?.errorMessage("Error while generating text")
                }
            }
        }
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
        
        tokenizer.enumerateTokens(in: sanitizedText.startIndex..<sanitizedText.endIndex) { range, _ in
            let sentence = String(sanitizedText[range])
            let sanitizedSentence = sanitizer.postSanitize(sentence)
            if !sanitizedSentence.isEmpty {
                results.append(sanitizedSentence)
            }
            return true
        }
        
        return results
    }
}
