//
//  PetBehaviourState.swift
//  BuddyBot
//
//  Created by Ajarbyurns on 07/08/25.
//

import Foundation
import RealityKit

enum BehaviourState {
    case idle
    case speaking(sentence: String, emotion: Emotion, time: Double)
    case thinking
    case dancing
}

protocol BehaviourDirectorDelegate: AnyObject {
    func errorMessage(_ text: String)
    func finishLoading()
}

final class BehaviourDirector {
    
    private let animationsDirector: AnimationsDirector
    private let speechDirector: SpeechDirector
    private let emotionsDirector: EmotionsDirector
    private var behaviourState: BehaviourState = .idle
    private var currentTask: Task<Void, Error>?
    weak var delegate: BehaviourDirectorDelegate?

    init(animations: AnimationsDirector,
         speech: SpeechDirector,
         emotions: EmotionsDirector) {
        self.animationsDirector = animations
        self.speechDirector = speech
        self.emotionsDirector = emotions
        self.speechDirector.delegate = self
    }

    @MainActor func stopAllActions() {
        currentTask?.cancel()
        animationsDirector.stopAllActions()
    }
    
    private func waitRandom(from: Int, to: Int) async {
        guard to > from && from > 0 else { return }
        let randWait = Int.random(in: from...to)
        try? await Task.sleep(nanoseconds: UInt64(randWait) * 1_000_000_000)
    }
    
    func enterState(_ state: BehaviourState, waitSeconds: Int = 0) {
        Task {
            try? await Task.sleep(nanoseconds: UInt64(waitSeconds) * 1_000_000_000)
            self.behaviourState = state
            startStateBehaviour()
        }
    }
    
    func startStateBehaviour() {
        cancelCurrentTask()
        switch self.behaviourState {
        case .idle:
            idle()
        case .thinking:
            thinking()
        case .dancing:
            dancing()
        case .speaking(sentence: let sentence,
                       emotion: let emotion,
                       time: let time):
            switch emotion {
            case .sad:
                speakingSad(sentence: sentence, time: time)
            case .happy:
                speakingHappy(sentence: sentence, time: time)
            case .fear:
                speakingFear(sentence: sentence, time: time)
            case .excited:
                speakingExcited(sentence: sentence, time: time)
            case .angry:
                speakingAngry(sentence: sentence, time: time)
            case .surprised:
                speakingSurprised(sentence: sentence, time: time)
            case .unknown:
                speakingNeutral(sentence: sentence, time: time)
            }
        }
    }
    
    func cancelCurrentTask() {
        currentTask?.cancel()
        currentTask = nil
    }
    
    func idle(waitStart: Int = 10, waitEnd: Int = 15) {
        currentTask = Task {
            guard !Task.isCancelled else { return }
            let duration = Double.random(in: Double(waitStart)...Double(waitEnd))
            await animationsDirector.playActionWithDuration(s: .idle, time: duration)
            guard !Task.isCancelled else { return }
            enterState(.dancing)
        }
    }
    
    func thinking() {
        currentTask = Task {
            guard !Task.isCancelled else { return }
            await animationsDirector.playActionWithDuration(s: .thinking, time: 3.5)
            guard !Task.isCancelled else { return }
            await animationsDirector.playActionWithDuration(s: .idle, time: 3.0)
            guard !Task.isCancelled else { return }
            enterState(.thinking)
        }
    }
    
    func speakingNeutral(sentence: String, time: Double) {
        currentTask = Task {
            guard !Task.isCancelled else { return }
            let action: SkeletalAnimation = [.talking1, .talking2, .talking3].randomElement() ?? .talking2
            await animationsDirector.playSpeakingAction(s: action, sentence: sentence, time: time)
            guard !Task.isCancelled else { return }
            enterState(.idle)
        }
    }
    
    func speakingSad(sentence: String, time: Double) {
        currentTask = Task {
            guard !Task.isCancelled else { return }
            let action: SkeletalAnimation = [.thinking, .angry].randomElement() ?? .thinking
            await animationsDirector.playSpeakingAction(s: action, e: .sad, sentence: sentence, time: time)
            guard !Task.isCancelled else { return }
            enterState(.idle)
        }
    }
    
    func speakingHappy(sentence: String, time: Double) {
        currentTask = Task {
            guard !Task.isCancelled else { return }
            let action: SkeletalAnimation = [.talking2, .talking3].randomElement() ?? .talking3
            await animationsDirector.playSpeakingAction(s: action, e: .happy, sentence: sentence, time: time)
            guard !Task.isCancelled else { return }
            enterState(.idle)
        }
    }
    
    func speakingFear(sentence: String, time: Double) {
        currentTask = Task {
            guard !Task.isCancelled else { return }
            let action: SkeletalAnimation = [.thinking, .surprised2, .angry].randomElement() ?? .thinking
            await animationsDirector.playSpeakingAction(s: action, e: .surprised, sentence: sentence, time: time)
            guard !Task.isCancelled else { return }
            enterState(.idle)
        }
    }
    
    func speakingAngry(sentence: String, time: Double) {
        currentTask = Task {
            guard !Task.isCancelled else { return }
            let action: SkeletalAnimation = [.angry, .talking1, .talking3,.thinking].randomElement() ?? .angry
            await animationsDirector.playSpeakingAction(s: action, e: .angry, sentence: sentence, time: time)
            guard !Task.isCancelled else { return }
            enterState(.idle)
        }
    }
    
    func speakingSurprised(sentence: String, time: Double) {
        currentTask = Task {
            guard !Task.isCancelled else { return }
            let action: SkeletalAnimation = [.surprised1, .surprised2].randomElement() ?? .surprised1
            await animationsDirector.playSpeakingAction(s: action, e: .surprised, sentence: sentence, time: time)
            guard !Task.isCancelled else { return }
            enterState(.idle)
        }
    }
    
    func speakingExcited(sentence: String, time: Double) {
        currentTask = Task {
            guard !Task.isCancelled else { return }
            let action: SkeletalAnimation = [.surprised1,.talking3, .dancing].randomElement() ?? .dancing
            await animationsDirector.playSpeakingAction(s: action, e: .happy, sentence: sentence, time: time)
            guard !Task.isCancelled else { return }
            enterState(.idle)
        }
    }
    
    func dancing() {
        currentTask = Task {
            guard !Task.isCancelled else { return }
            let action: SkeletalAnimation = [.surprised1, .dancing, .angry].randomElement() ?? .dancing
            await animationsDirector.playActionWithDuration(s: action, e: .happy, time: 4.0)
            guard !Task.isCancelled else { return }
            enterState(.idle)
        }
    }
    
    func startTalking(sentenceCoordinator: DataCoordinator<String>) {
        enterState(.thinking)
        speechDirector.startTalking(sentenceCoordinator: sentenceCoordinator)
    }
    
    func stopTalking() {
        enterState(.idle)
        speechDirector.stopTalking()
    }
    
    deinit {
        currentTask?.cancel()
        currentTask = nil
    }
}

extension BehaviourDirector: SpeechDirectorDelegate {
    
    func willStartTalking(text: String, duration: Double) {
        
        guard duration > 0.2 else { return }
        
        let emotion = emotionsDirector.getEmotion(for: text)
        let nextState: BehaviourState = .speaking(sentence: text,
                                                  emotion: emotion,
                                                  time: duration)
        enterState(nextState)
    }
    
    func didFinishTalking() {
        delegate?.finishLoading()
        enterState(.idle)
    }
    
    func foundError(_ text: String) {
        delegate?.errorMessage(text)
    }
    
}

extension BehaviourDirector {
    
    @MainActor func testAllSkeletalAnimations() {
        animationsDirector.testAllSkeletalActions()
    }
    
    @MainActor func testAllMouthAnimations() {
        animationsDirector.testAllMouthActions()
    }
    
    @MainActor func testAllEyesAnimations() {
        animationsDirector.testAllEyesActions()
    }
    
    func testAllStatesAnimations() {
        Task {
            print("idle")
            idle()
            try? await Task.sleep(nanoseconds: 5000000000)
            cancelCurrentTask()
            print("thinking")
            thinking()
            try? await Task.sleep(nanoseconds: 5000000000)
            cancelCurrentTask()
            print("dancing")
            dancing()
            try? await Task.sleep(nanoseconds: 5000000000)
            cancelCurrentTask()
            print("speaking angry")
            speakingAngry(sentence: "I'm so mad right now", time: 4.0)
            try? await Task.sleep(nanoseconds: 5000000000)
            cancelCurrentTask()
            print("speaking neutral")
            speakingNeutral(sentence: "I'm so mad right now", time: 4.0)
            try? await Task.sleep(nanoseconds: 5000000000)
            cancelCurrentTask()
            print("speaking happy")
            speakingHappy(sentence: "I'm so mad right now", time: 4.0)
            try? await Task.sleep(nanoseconds: 5000000000)
            cancelCurrentTask()
            print("speaking sad")
            speakingSad(sentence: "I'm so mad right now", time: 4.0)
            try? await Task.sleep(nanoseconds: 5000000000)
            cancelCurrentTask()
            print("speaking fear")
            speakingFear(sentence: "I'm so mad right now", time: 4.0)
            try? await Task.sleep(nanoseconds: 5000000000)
            cancelCurrentTask()
            print("speaking excited")
            speakingExcited(sentence: "I'm so mad right now", time: 4.0)
            try? await Task.sleep(nanoseconds: 5000000000)
            cancelCurrentTask()
            print("speaking surprised")
            speakingSurprised(sentence: "I'm so mad right now", time: 4.0)
            try? await Task.sleep(nanoseconds: 5000000000)
            print("finished")
        }
    }
    
    
}
