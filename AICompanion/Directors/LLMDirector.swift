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
    
    private let systemPrompt = "Your name is Ashe, an AI Companion. You have an outgoing personality. No Emojis. Response limited to 200 words max. Don't keep mentioning that you are an AI companion"
    private let kuzco = Kuzco.shared
    private let sanitizer: StringSanitizer
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
            let (instance, result) = await Kuzco.loadModelSafely(
                profile: profile,
                settings: .performanceFocused,
                predictionConfig: .creative
            )
            let _ = await instance?.generate(dialogue: [Turn(role: .user, text: "Hello")])
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
        
        task?.cancel()
        task = Task {
            do {
                let predictionStream = await model.generate(
                    dialogue: turns,
                    overrideSystemPrompt: systemPrompt
                )
                for try await chunk in predictionStream {
                    guard !Task.isCancelled else { return }
                    response += chunk
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
                delegate?.sentencesFormed([response.trimmingCharacters(in: .whitespacesAndNewlines)])
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
        
        tokenizer.enumerateTokens(in: sanitizedText.startIndex..<sanitizedText.endIndex) { range, _ in
            var sentence = String(sanitizedText[range])
            if sentence.rangeOfCharacter(from: .decimalDigits) != nil {
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
