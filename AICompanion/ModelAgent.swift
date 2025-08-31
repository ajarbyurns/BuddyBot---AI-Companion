//
//  ModelAgent.swift
//  AICompanion
//
//  Created by Ajarbyurns on 06/08/25.
//
import RealityKit
import SwiftUI
import SwiftData

@MainActor
class ModelAgent: ObservableObject {
        
    private var behaviourDirector: BehaviourDirector?
    private var listenerDirector: ListenerDirector?
    private var llmDirector: LLMDirector?
        
    private var sentenceCoordinator: DataCoordinator<String> = DataCoordinator()
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    
    @Published var ttsFinishedLoading = false
    @Published var llmFinishedLoading = false
    
    func setChatContext(chatContext: ModelContext) {
        self.llmDirector = .init(sanitizer: StringSanitizer(),
                                 chatContext: chatContext)
        self.llmDirector?.delegate = self
    }
    
    func setEntity(_ entity: ModelEntity) {
        self.behaviourDirector = BehaviourDirector(
            animations: .init(entity: entity,
                              skeletal: .init(entity: entity),
                              eyes: .init(entity: entity),
                              mouth: .init(entity: entity,
                                           syllablesCounter: .init())),
            speech: .init(tts:
                            TTSDirector(initCompletion: {
                                self.ttsFinishedLoading = true
                            }),
                          audio: .init()),
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
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = true
        #endif
        sentenceCoordinator = DataCoordinator()
        behaviourDirector?.startTalking(sentenceCoordinator: sentenceCoordinator)
        llmDirector?.generate(prompt: input)
    }
    
    func requestSpeechAuthorization(completion: (()->Void)? = nil) {
        listenerDirector?.requestAuthorization(completion: completion)
    }
    
    func startListening() {
        listenerDirector?.startListening()
    }
    
    func stop() {
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = false
        #endif
        llmDirector?.stop()
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
    
    func finishLoading() {
        Task { @MainActor in
            #if os(iOS)
            UIApplication.shared.isIdleTimerDisabled = false
            #endif
            self.isLoading = false
        }
    }
    
}

extension ModelAgent: @preconcurrency ListenerDirectorDelegate {
    
    func didDetectSentence(_ text: String) {
        receiveText(input: text)
    }
    
    func errorMessage(_ text: String) {
        receiveError(text: text)
    }
        
}

extension ModelAgent: @preconcurrency LLMDirectorDelegate {
    
    func didFinishLoadingModel() {
        self.llmFinishedLoading = true
    }
    
    func sentencesFormed(_ sentences: [String]) {
        if !sentences.joined().isEmpty {
            sentenceCoordinator.addData(sentences.joined(separator: ". "))
        }
    }
    
    func generationFinished() {
        sentenceCoordinator.finish()
    }
}
