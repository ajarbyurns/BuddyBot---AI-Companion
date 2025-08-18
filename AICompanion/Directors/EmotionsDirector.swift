//
//  SentimentsDirector.swift
//  AICompanion
//
//  Created by Barry Juans on 11/08/25.
//
import CoreML

enum Emotion: String, CaseIterable {
    case sad
    case happy
    case fear
    case excited
    case angry
    case surprised
    case unknown
}

class EmotionsDirector {
    
    var model: EmotionClassifier?
    
    init() {
        model = try? EmotionClassifier(configuration: MLModelConfiguration())
    }
    
    func getEmotion(for text: String) -> Emotion {
        
        let input = EmotionClassifierInput(text: text)
        let output = try? model?.prediction(input: input)
        let label = output?.label
        
        return Emotion(rawValue: label ?? "unknown") ?? .unknown
    }
}
