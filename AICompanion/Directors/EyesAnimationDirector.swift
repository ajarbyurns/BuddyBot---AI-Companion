//
//  EyesAnimationDirector.swift
//  AICompanion
//
//  Created by Barry Juans on 14/08/25.
//
/***
 BlendShapes:
 ["Fcl_ALL_Neutral", "Fcl_ALL_Angry", "Fcl_ALL_Fun", "Fcl_ALL_Joy", "Fcl_ALL_Sorrow", "Fcl_ALL_Surprised", "Fcl_BRW_Angry", "Fcl_BRW_Fun", "Fcl_BRW_Joy", "Fcl_BRW_Sorrow", "Fcl_BRW_Surprised", "Fcl_EYE_Natural", "Fcl_EYE_Angry", "Fcl_EYE_Close", "Fcl_EYE_Close_R", "Fcl_EYE_Close_L", "Fcl_EYE_Fun", "Fcl_EYE_Joy", "Fcl_EYE_Joy_R", "Fcl_EYE_Joy_L", "Fcl_EYE_Sorrow", "Fcl_EYE_Surprised", "Fcl_EYE_Spread", "Fcl_EYE_Iris_Hide", "Fcl_EYE_Highlight_Hide", "Fcl_MTH_Close", "Fcl_MTH_Up", "Fcl_MTH_Down", "Fcl_MTH_Angry", "Fcl_MTH_Small", "Fcl_MTH_Large", "Fcl_MTH_Neutral", "Fcl_MTH_Fun", "Fcl_MTH_Joy", "Fcl_MTH_Sorrow", "Fcl_MTH_Surprised", "Fcl_MTH_SkinFung", "Fcl_MTH_SkinFung_R", "Fcl_MTH_SkinFung_L", "Fcl_MTH_A", "Fcl_MTH_I", "Fcl_MTH_U", "Fcl_MTH_E", "Fcl_MTH_O", "Fcl_HA_Hide", "Fcl_HA_Fung1", "Fcl_HA_Fung1_Low", "Fcl_HA_Fung1_Up", "Fcl_HA_Fung2", "Fcl_HA_Fung2_Low", "Fcl_HA_Fung2_Up", "Fcl_HA_Fung3", "Fcl_HA_Fung3_Up", "Fcl_HA_Fung3_Low", "Fcl_HA_Short", "Fcl_HA_Short_Up", "Fcl_HA_Short_Low"]
 ***/

import RealityKit

enum EyeAnimation: String, CaseIterable {
    case angry
    case sad
    case happy
    case surprised
    case blink
}

class EyesAnimationDirector {
    
    let entity: ModelEntity
    private var eyeAnims: [EyeAnimation: FromToByAnimation<BlendShapeWeights>] = [:]
    let weightNames: [String] = ["Fcl_EYE_Angry", "Fcl_EYE_Close", "Fcl_EYE_Fun",
                                 "Fcl_EYE_Sorrow", "Fcl_EYE_Surprised", "Fcl_BRW_Angry",
                                 "Fcl_BRW_Fun", "Fcl_BRW_Sorrow","Fcl_BRW_Surprised"]
    
    init(entity: ModelEntity) {
        self.entity = entity
        self.initAllEyeAnimations()
    }
    
    func getAnimation(_ anim: EyeAnimation) -> FromToByAnimation<BlendShapeWeights> {
        return eyeAnims[anim]!
    }
    
    private func initAllEyeAnimations() {
        for eye in EyeAnimation.allCases {
            var temp = weightNames
            switch eye {
            case .angry:
                temp.removeAll(where: { $0 == "Fcl_BRW_Angry" || $0 == "Fcl_EYE_Angry"})
                eyeAnims[eye] = createAngryEyes(namesToReset: temp)
            case .sad:
                temp.removeAll(where: { $0 == "Fcl_BRW_Sorrow" || $0 == "Fcl_EYE_Sorrow"})
                eyeAnims[eye] = createSadEyes(namesToReset: temp)
            case .happy:
                temp.removeAll(where: { $0 == "Fcl_BRW_Fun" || $0 == "Fcl_EYE_Fun"})
                eyeAnims[eye] = createHappyEyes(namesToReset: temp)
            case .surprised:
                temp.removeAll(where: { $0 == "Fcl_BRW_Surprised" || $0 == "Fcl_EYE_Surprised"})
                eyeAnims[eye] = createSurprisedEyes(namesToReset: temp)
            case .blink:
                temp.removeAll(where: { $0 == "Fcl_EYE_Close"})
                eyeAnims[eye] = createBlinkingEyes(namesToReset: temp)
            }
        }
    }
    
    private func createSurprisedEyes(seconds: Double = 10, namesToReset: [String] = []) -> FromToByAnimation<BlendShapeWeights> {
        let animation = FromToByAnimation(
            weightNames: ["Fcl_BRW_Surprised", "Fcl_EYE_Surprised"] + namesToReset,
            from: BlendShapeWeights([1, 1] + Array(repeating: 0, count: namesToReset.count)),
            to: BlendShapeWeights([1, 1] + Array(repeating: 0, count: namesToReset.count)),
            duration: seconds,
            isAdditive: true,
            bindTarget: .blendShapeWeights,
        )
        return animation
    }
    
    private func createHappyEyes(seconds: Double = 10, namesToReset: [String] = []) -> FromToByAnimation<BlendShapeWeights> {
        let animation = FromToByAnimation(
            weightNames: ["Fcl_BRW_Fun", "Fcl_EYE_Fun"] + namesToReset,
            from: BlendShapeWeights([1, 1] + Array(repeating: 0, count: namesToReset.count)),
            to: BlendShapeWeights([1, 1] + Array(repeating: 0, count: namesToReset.count)),
            duration: seconds,
            isAdditive: true,
            bindTarget: .blendShapeWeights,
        )
        return animation
    }
    
    private func createSadEyes(seconds: Double = 10, namesToReset: [String] = []) -> FromToByAnimation<BlendShapeWeights> {
        let animation = FromToByAnimation(
            weightNames: ["Fcl_BRW_Sorrow", "Fcl_EYE_Sorrow"] + namesToReset,
            from: BlendShapeWeights([1, 1] + Array(repeating: 0, count: namesToReset.count)),
            to: BlendShapeWeights([1, 1] + Array(repeating: 0, count: namesToReset.count)),
            duration: seconds,
            isAdditive: true,
            bindTarget: .blendShapeWeights,
        )
        return animation
    }
    
    private func createAngryEyes(seconds: Double = 10, namesToReset: [String] = []) -> FromToByAnimation<BlendShapeWeights> {
        let animation = FromToByAnimation(
            weightNames: ["Fcl_BRW_Angry", "Fcl_EYE_Angry"] + namesToReset,
            from: BlendShapeWeights([1, 1] + Array(repeating: 0, count: namesToReset.count)),
            to: BlendShapeWeights([1, 1] + Array(repeating: 0, count: namesToReset.count)),
            duration: seconds,
            isAdditive: true,
            bindTarget: .blendShapeWeights,
        )
        return animation
    }
    
    private func createBlinkingEyes(spacing: Double = 4, namesToReset: [String] = []) -> FromToByAnimation<BlendShapeWeights> {
        let animation = FromToByAnimation(
            weightNames: ["Fcl_EYE_Close"] + namesToReset,
            from: BlendShapeWeights([0] + Array(repeating: 0, count: namesToReset.count)),
            to: BlendShapeWeights([1] + Array(repeating: 0, count: namesToReset.count)),
            duration: 0.2,
            timing: .easeInOut,
            isAdditive: true,
            bindTarget: .blendShapeWeights,
            repeatMode: .autoReverse,
            fillMode: [.backwards],
            trimStart: (-1 * spacing),
        )
        return animation
    }
}
