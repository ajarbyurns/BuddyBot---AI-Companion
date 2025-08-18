//
//  ModelAgent.swift
//  AICompanion
//
//  Created by Barry Juans on 06/08/25.
//
import RealityKit
import SwiftUI

@MainActor
class ModelAgent: ObservableObject {
    
    private var behaviourDirector: BehaviourDirector?
    private var listenerDirector: ListenerDirector?
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var infoMessage: String = ""
    
    func setEntity(_ entity: ModelEntity) {
        isLoading = true
        self.behaviourDirector = BehaviourDirector(
            animations: .init(entity: entity,
                              skeletal: .init(entity: entity),
                              eyes: .init(entity: entity),
                              mouth: .init(entity: entity,
                                           syllablesCounter: .init())),
            speech: .init(ttsDirector:
                            TTSDirector(initCompletion: {
                                self.isLoading = false
                            }),
                          audio: .init(),
                          sanitizer: .init()),
            emotions: .init())
        self.listenerDirector = .init()
        self.behaviourDirector?.delegate = self
        self.listenerDirector?.delegate = self
        self.behaviourDirector?.startStateBehaviour()
        //self.behaviourDirector?.testAllSkeletalAnimations()
        //self.behaviourDirector?.testAllEyesAnimations()
        //self.behaviourDirector?.testAllMouthAnimations()
        //self.behaviourDirector?.testAllStatesAnimations()
    }
    
    func receiveText(input: String) {
        isLoading = true
        behaviourDirector?.startTalking(text: input)
    }
    
    func requestSpeechAuthorization(completion: (()->Void)? = nil) {
        listenerDirector?.requestAuthorization(completion: completion)
    }
    
    func startListening() {
        listenerDirector?.startListening()
    }
    
    func stop() {
        listenerDirector?.stopListening()
        behaviourDirector?.stopTalking()
        isLoading = false
    }
    
    private func receiveError(text: String) {
        self.errorMessage = text
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: { [weak self] in
            guard let self else { return }
            if errorMessage == text {
                errorMessage = ""
            }
        })
    }
}

extension ModelAgent: @preconcurrency BehaviourDirectorDelegate {
    
    func errorMessage(text: String) {
        receiveError(text: text)
    }
    
    func startLoading() {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
        }
    }
    
    func finishLoading() {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
        }
    }
    
}

extension ModelAgent: @preconcurrency ListenerDirectorDelegate {
    
    func didDetectSentence(_ text: String) {
        isLoading = true
        behaviourDirector?.startTalking(text: text)
    }
    
    func errorMessage(_ text: String) {
        receiveError(text: text)
    }
        
}
