//
//  SkeletalAnimationDirector.swift
//  AICompanion
//
//  Created by Barry Juans on 14/08/25.
//
import RealityKit

enum SkeletalAnimation: String, CaseIterable {
    case idle
    case surprised1
    case surprised2
    case talking1
    case talking2
    case talking3
    case angry
    case dancing
    case thinking
}

class SkeletalAnimationDirector {
    
    let entity: ModelEntity
    private var skeletalAnims: [SkeletalAnimation: AnimationView] = [:]
        
    init(entity: ModelEntity) {
        self.entity = entity
        initAllSkeletalAnimations()
    }
    
    private func initAllSkeletalAnimations() {
        guard let animation = entity.availableAnimations.first else {
            return
        }
                
        var actionsTimeSlot: [String: (Int, Int)] = [:]
        actionsTimeSlot["Idle"] = (43, 542)
        //actionsTimeSlot["Idle 2"] = (589, 989)
        actionsTimeSlot["Surprised 1"] = (1061, 1181)
        actionsTimeSlot["Surprised 2"] = (1239, 1349)
        //actionsTimeSlot["Talking 1"] = (1403, 2027)
        actionsTimeSlot["Talking 1"] = (2096, 2274)
        actionsTimeSlot["Talking 2"] = (2357, 2512)
        actionsTimeSlot["Talking 3"] = (2619, 2927)
        actionsTimeSlot["Angry"] = (4281, 4856)
        //actionsTimeSlot["Happy 1"] = (3011, 3311)
        //actionsTimeSlot["Happy 2"] = (3434, 3631)
        //actionsTimeSlot["Dancing 1"] = (3732, 3957)
        actionsTimeSlot["Dancing"] = (4079, 4150)
        actionsTimeSlot["Thinking"] = (5022, 5149)
        
        let fps = 24.0
        
        for (name, (start, end)) in actionsTimeSlot {
            let runStart = Double(start) / fps
            let runEnd = Double(end - 2) / fps

            let action = AnimationView(
                            source: animation.definition,
                            name: name,
                            bindTarget: nil,
                            blendLayer: 0,
                            repeatMode: .repeat,
                            fillMode: [],
                            trimStart: runStart,
                            trimEnd: runEnd,
                            trimDuration: nil,
                            offset: 0,
                            delay: 0,
                            speed: 1.0)
                        
            if let dictName = SkeletalAnimation(rawValue: name.lowercased().replacingOccurrences(of: " ", with: "")) {
                skeletalAnims[dictName] = action
            }
        }
    }
    
    func getAnimation(_ skeleAnim : SkeletalAnimation) -> AnimationDefinition {
        return skeletalAnims[skeleAnim]!
    }
}
