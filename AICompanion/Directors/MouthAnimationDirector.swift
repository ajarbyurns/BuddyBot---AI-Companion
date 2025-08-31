//
//  MouthAnimationDirector.swift
//  AICompanion
//
//  Created by Ajarbyurns on 14/08/25.
//
/***
 BlendShapes:
 ["Fcl_ALL_Neutral", "Fcl_ALL_Angry", "Fcl_ALL_Fun", "Fcl_ALL_Joy", "Fcl_ALL_Sorrow", "Fcl_ALL_Surprised", "Fcl_BRW_Angry", "Fcl_BRW_Fun", "Fcl_BRW_Joy", "Fcl_BRW_Sorrow", "Fcl_BRW_Surprised", "Fcl_EYE_Natural", "Fcl_EYE_Angry", "Fcl_EYE_Close", "Fcl_EYE_Close_R", "Fcl_EYE_Close_L", "Fcl_EYE_Fun", "Fcl_EYE_Joy", "Fcl_EYE_Joy_R", "Fcl_EYE_Joy_L", "Fcl_EYE_Sorrow", "Fcl_EYE_Surprised", "Fcl_EYE_Spread", "Fcl_EYE_Iris_Hide", "Fcl_EYE_Highlight_Hide", "Fcl_MTH_Close", "Fcl_MTH_Up", "Fcl_MTH_Down", "Fcl_MTH_Angry", "Fcl_MTH_Small", "Fcl_MTH_Large", "Fcl_MTH_Neutral", "Fcl_MTH_Fun", "Fcl_MTH_Joy", "Fcl_MTH_Sorrow", "Fcl_MTH_Surprised", "Fcl_MTH_SkinFung", "Fcl_MTH_SkinFung_R", "Fcl_MTH_SkinFung_L", "Fcl_MTH_A", "Fcl_MTH_I", "Fcl_MTH_U", "Fcl_MTH_E", "Fcl_MTH_O", "Fcl_HA_Hide", "Fcl_HA_Fung1", "Fcl_HA_Fung1_Low", "Fcl_HA_Fung1_Up", "Fcl_HA_Fung2", "Fcl_HA_Fung2_Low", "Fcl_HA_Fung2_Up", "Fcl_HA_Fung3", "Fcl_HA_Fung3_Up", "Fcl_HA_Fung3_Low", "Fcl_HA_Short", "Fcl_HA_Short_Up", "Fcl_HA_Short_Low"]
 ***/

import RealityKit
import Foundation

enum MouthAnimation: String, CaseIterable {
    case a, e, i, o, u, neutral, closed
}

struct VisemeResult {
    var mouthAnim: MouthAnimation
    var duration: Double
    var delay: Double
}

class MouthAnimationDirector {
    
    let visemeMap: [Character: MouthAnimation] = [
            "ɑ": .a, "æ": .a, "A": .a, "W": .a, "ʌ": .a,
            "ɛ": .e, "ᵊ": .e, "ɜ": .e, "i": .e,
            "O": .o, "ə": .o,
            "ɪ": .i, "I": .i,
            "u": .u, "ʊ": .u,
    ]
    
    let entity: ModelEntity
    let syllablesCounter: SwiftSyllables
    
    private var mouthAnims: [MouthAnimation: FromToByAnimation<BlendShapeWeights>] = [:]
    private let weightNames: [String] = ["Fcl_MTH_A", "Fcl_MTH_I", "Fcl_MTH_U",
                                         "Fcl_MTH_E", "Fcl_MTH_O", "Fcl_MTH_Neutral",
                                         "Fcl_MTH_Close"]
    
    init(entity: ModelEntity, syllablesCounter: SwiftSyllables) {
        self.entity = entity
        self.syllablesCounter = syllablesCounter
        initAllMouthAnimations()
    }
    
    func getAnimations(sentence: String, duration: Double) -> [FromToByAnimation<BlendShapeWeights>] {
        let visemes = generateVisemeSequence(sentence: sentence, totalDuration: duration)
        let definitions = generateVisemeDefinitons(visemes: visemes)
        return definitions
    }
    
    func getAnimation(_ mouthAnim: MouthAnimation) -> FromToByAnimation<BlendShapeWeights> {
        return mouthAnims[mouthAnim]!
    }
    
    private func initAllMouthAnimations() {
        for viseme in MouthAnimation.allCases {
            mouthAnims[viseme] = createMouthAnim(viseme: viseme)
        }
    }
    
    private func createMouthAnim(
                            viseme: MouthAnimation,
                            seconds: Double = 0.5,
                            delay: Double = 0,
                            namesToReset: [String] = []) -> FromToByAnimation<BlendShapeWeights> {
        
        var namesToReset = weightNames
        let anim: FromToByAnimation<BlendShapeWeights>
        
        switch viseme {
        case .a:
            namesToReset.removeAll(where: { $0 == "Fcl_MTH_A"})
            anim = createMouthA(seconds: seconds, delay: delay, namesToReset: namesToReset)
        case .e:
            namesToReset.removeAll(where: { $0 == "Fcl_MTH_E"})
            anim = createMouthE(seconds: seconds, delay: delay, namesToReset: namesToReset)
        case .i:
            namesToReset.removeAll(where: { $0 == "Fcl_MTH_I"})
            anim = createMouthI(seconds: seconds, delay: delay, namesToReset: namesToReset)
        case .o:
            namesToReset.removeAll(where: { $0 == "Fcl_MTH_O"})
            anim = createMouthO(seconds: seconds, delay: delay, namesToReset: namesToReset)
        case .u:
            namesToReset.removeAll(where: { $0 == "Fcl_MTH_U"})
            anim = createMouthU(seconds: seconds, delay: delay, namesToReset: namesToReset)
        case .neutral:
            anim = createMouthNeutral(seconds: seconds, delay: delay, namesToReset: namesToReset)
        case .closed:
            namesToReset.removeAll(where: { $0 == "Fcl_MTH_Close"})
            anim = createMouthClosed(seconds: seconds, delay: delay, namesToReset: namesToReset)
        }
        
        return anim
    }
    
    private func createMouthDefinition(weightNames: [String],
                                       seconds: Double = 0.5,
                                       delay: Double = 0,
                                       namesToReset: [String] = []) -> FromToByAnimation<BlendShapeWeights> {
        let animation = FromToByAnimation(
            weightNames: weightNames + namesToReset,
            from: BlendShapeWeights(
                Array(repeating: 0, count: namesToReset.count + weightNames.count)),
            to: BlendShapeWeights(
                Array(repeating: 1, count: weightNames.count) +
                Array(repeating: 0, count: namesToReset.count)),
            duration: seconds,
            timing: .easeInOut,
            isAdditive: false,
            bindTarget: .blendShapeWeights,
            repeatMode: .autoReverse,
            delay: delay
        )
        return animation
    }
    
    private func createMouthNeutral(seconds: Double = 0.5, delay: Double = 0, namesToReset: [String] = []) -> FromToByAnimation<BlendShapeWeights> {
        let animation = createMouthDefinition(weightNames: [],
                                              seconds: seconds,
                                              delay: delay,
                                              namesToReset: namesToReset)
        return animation
    }
    
    private func createMouthClosed(seconds: Double = 0.5, delay: Double = 0, namesToReset: [String] = []) -> FromToByAnimation<BlendShapeWeights> {
        let animation = createMouthDefinition(weightNames: ["Fcl_MTH_Close"],
                                              seconds: seconds,
                                              delay: delay,
                                              namesToReset: namesToReset)
        return animation
    }
    
    private func createMouthU(seconds: Double = 0.5, delay: Double = 0, namesToReset: [String] = []) -> FromToByAnimation<BlendShapeWeights> {
        let animation = createMouthDefinition(weightNames: ["Fcl_MTH_U"],
                                              seconds: seconds,
                                              delay: delay,
                                              namesToReset: namesToReset)
        return animation
    }
    
    private func createMouthO(seconds: Double = 0.5, delay: Double = 0, namesToReset: [String] = []) -> FromToByAnimation<BlendShapeWeights> {
        let animation = createMouthDefinition(weightNames: ["Fcl_MTH_O"],
                                              seconds: seconds,
                                              delay: delay,
                                              namesToReset: namesToReset)
        return animation
    }
    
    private func createMouthI(seconds: Double = 0.5, delay: Double = 0, namesToReset: [String] = []) -> FromToByAnimation<BlendShapeWeights> {
        let animation = createMouthDefinition(weightNames: ["Fcl_MTH_I"],
                                              seconds: seconds,
                                              delay: delay,
                                              namesToReset: namesToReset)
        return animation
    }
    
    private func createMouthE(seconds: Double = 0.5, delay: Double = 0, namesToReset: [String] = []) -> FromToByAnimation<BlendShapeWeights> {
        let animation = createMouthDefinition(weightNames: ["Fcl_MTH_E"],
                                              seconds: seconds,
                                              delay: delay,
                                              namesToReset: namesToReset)
        return animation
    }
    
    private func createMouthA(seconds: Double = 0.5,
                      delay: Double = 0,
                              namesToReset: [String] = []) -> FromToByAnimation<BlendShapeWeights> {
        let animation = createMouthDefinition(weightNames: ["Fcl_MTH_A"],
                                              seconds: seconds,
                                              delay: delay,
                                              namesToReset: namesToReset)
        return animation
    }
    
    private func generateVisemeDefinitons(visemes: [VisemeResult]) -> [FromToByAnimation<BlendShapeWeights>] {
        var result: [FromToByAnimation<BlendShapeWeights>] = []
        
        for vis in visemes {
            if var definition = mouthAnims[vis.mouthAnim] {
                definition.duration = vis.duration
                definition.delay = vis.delay
                result.append(definition)
            }
        }
        
        return result
    }
    
    private func generateVisemeSequence(sentence: String, totalDuration: Double) -> [VisemeResult] {
        let phonemesAndSyllables = syllablesCounter.getPhonemesAndSyllables(sentence)
        let rawVisemes = convertIPAtoVisemes(input: phonemesAndSyllables)

        let minimumVisemeDuration: Double = 0.25

        var combinedVisemeResults: [VisemeResult] = []
        
        let idealPerRawVisemeDuration: Double = rawVisemes.isEmpty ? 0 : totalDuration / Double(rawVisemes.count)

        var currentBatchViseme: MouthAnimation = .neutral
        var currentBatchDuration: Double = 0.0
        var currentDelayOffset: Double = 0.0

        for (index, visemeName) in rawVisemes.enumerated() {
            currentBatchViseme = visemeName
            currentBatchDuration += idealPerRawVisemeDuration

            let isLastRawViseme = (index == rawVisemes.count - 1)

            if currentBatchDuration >= minimumVisemeDuration || isLastRawViseme {
                let viseme = VisemeResult(mouthAnim: currentBatchViseme,
                                          duration: currentBatchDuration,
                                          delay: currentDelayOffset)
                combinedVisemeResults.append(viseme)
                
                currentDelayOffset += currentBatchDuration
                currentBatchDuration = 0.0
            }
        }

        let currentTotalCombinedDuration = combinedVisemeResults.reduce(0.0) { $0 + $1.duration }

        if currentTotalCombinedDuration > 0 && currentTotalCombinedDuration != totalDuration {
            let adjustmentFactor = totalDuration / currentTotalCombinedDuration
            var adjustedDelay = 0.0
            for i in 0..<combinedVisemeResults.count {
                combinedVisemeResults[i].duration *= adjustmentFactor
                combinedVisemeResults[i].delay = adjustedDelay
                adjustedDelay += combinedVisemeResults[i].duration
            }
        }

        return combinedVisemeResults
    }
    
    private func convertIPAtoVisemes(input: [(String, Int)]) -> [MouthAnimation] {
        var result: [MouthAnimation] = []
        
        for (text, count) in input {
            var arr = Array(repeating: MouthAnimation.a, count: count)
            var counter = 0
            for char in text {
                if let vis = visemeMap[char] {
                    arr[counter] = vis
                    counter += 1
                    if counter >= count {
                        break
                    }
                }
            }
            result += arr
        }
        
        return result
    }
}
