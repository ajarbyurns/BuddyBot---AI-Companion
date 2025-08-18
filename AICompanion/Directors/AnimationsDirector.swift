//
//  AnimationsDirector.swift
//  AICompanion
//
//  Created by Barry Juans on 14/08/25.
//
import RealityKit

class AnimationsDirector {
    
    let entity: ModelEntity
    let skeletal: SkeletalAnimationDirector
    let eyes: EyesAnimationDirector
    let mouth: MouthAnimationDirector
    let transition = 0.5
    let buffer = 5.0
    
    init(entity: ModelEntity, skeletal: SkeletalAnimationDirector, eyes: EyesAnimationDirector, mouth: MouthAnimationDirector) {
        self.entity = entity
        self.skeletal = skeletal
        self.eyes = eyes
        self.mouth = mouth
    }
    
    func stopAllActions() {
        entity.stopAllAnimations()
    }
    
        
    func playActionWithRepeatCount(s: SkeletalAnimation = .idle,
                                   e: EyeAnimation = .blink,
                                   m: MouthAnimation = .neutral,
                                   repeatCount: Int,
                                   blocking: Bool = true) async {
        guard repeatCount > 0 else {
            return
        }
        
        let sAnim = skeletal.getAnimation(s)
        let eAnim = eyes.getAnimation(e)
        let mAnim = mouth.getAnimation(m)
        
        let group = AnimationGroup(group: [sAnim, eAnim, mAnim])
        
        if let anim = try? await AnimationResource.generate(with: group) {
            await entity.playAnimation(anim.repeat(count: repeatCount), transitionDuration: transition)
            
            if blocking {
                guard let start = sAnim.trimStart,
                      let end = sAnim.trimEnd else {
                    return
                }
                let duration = ((end - start) * Double(repeatCount)) + transition
                try? await Task.sleep(nanoseconds: UInt64(duration * 1000000000))
            }
        } else {
            print("Failed to generate animation")
        }
    }
    
    func playActionWithDuration(s: SkeletalAnimation = .idle,
                                e: EyeAnimation = .blink,
                                m: MouthAnimation = .neutral,
                                time: Double,
                                blocking: Bool = true) async {
        guard time > 0 else {
            return
        }
        
        let sAnim = skeletal.getAnimation(s)
        let eAnim = eyes.getAnimation(e)
        let mAnim = mouth.getAnimation(m)
        
        let group = AnimationGroup(group: [sAnim, eAnim, mAnim])
        
        if let anim = try? await AnimationResource.generate(with: group) {
            await entity.playAnimation(anim.repeat(duration: time + buffer), transitionDuration: transition)
            
            if blocking {
                try? await Task.sleep(nanoseconds: UInt64((time + transition) * 1000000000))
            }
        } else {
            print("Failed to generate animation")
        }
    }
    
    func playAction(s: SkeletalAnimation = .idle,
                    e: EyeAnimation = .blink,
                    m: MouthAnimation = .neutral,
                    blocking: Bool = true) async {
        await playActionWithRepeatCount(s: s, e: e, m: m, repeatCount: 1, blocking: blocking)
    }
    
    func playActionLooped(s: SkeletalAnimation = .idle,
                          e: EyeAnimation = .blink,
                          m: MouthAnimation = .neutral) async {
        
        let sAnim = skeletal.getAnimation(s)
        let eAnim = eyes.getAnimation(e)
        let mAnim = mouth.getAnimation(m)
        
        let group = AnimationGroup(group: [sAnim, eAnim, mAnim])
        
        if let anim = try? await AnimationResource.generate(with: group) {
            await entity.playAnimation(anim.repeat(), transitionDuration: transition)
        } else {
            print("Failed to generate animation")
        }
    }
    
    func playSpeakingAction(s: SkeletalAnimation = .idle,
                            e: EyeAnimation = .blink,
                            sentence: String,
                            time: Double,
                            blocking: Bool = true) async {
        guard time > 0 else {
            return
        }
        
        let sAnim = skeletal.getAnimation(s)
        let eAnim = eyes.getAnimation(e)
        let mAnim = mouth.getAnimations(sentence: sentence, duration: time)
        
        let group = AnimationGroup(group: [sAnim, eAnim] + mAnim)
        
        if let anim = try? await AnimationResource.generate(with: group) {
            await entity.playAnimation(anim.repeat(duration: time + buffer), transitionDuration: transition)
            
            if blocking {
                try? await Task.sleep(nanoseconds: UInt64((time + transition) * 1000000000))
            }
        } else {
            print("Failed to generate animation")
        }
    }
}

extension AnimationsDirector {
    
    func testAllSkeletalActions() {
        Task {
            for s in SkeletalAnimation.allCases {
                print("Playing \(s)")
                await playActionWithDuration(s: s, time: 5.0)
            }
            print("finished")
        }
    }
    
    func testAllMouthActions() {
        Task {
            for m in MouthAnimation.allCases {
                print("Playing \(m)")
                await playActionWithDuration(s: .idle, m: m, time: 5.0)
            }
            print("finished")
        }
    }
    
    func testAllEyesActions() {
        Task {
            for e in EyeAnimation.allCases {
                print("Playing \(e)")
                await playActionWithDuration(s: .idle, e: e, time: 5.0)
            }
            print("finished")
        }
    }
}
