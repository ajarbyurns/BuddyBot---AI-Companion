//
//  SpeechDirector.swift
//  AICompanion
//
//  Created by Barry Juans on 07/08/25.
//
import AVFoundation
import NaturalLanguage
import RealityKit

protocol SpeechDirectorDelegate: AnyObject {
    func didFinishTalking()
    func willStartTalking(text: String, duration: Double)
    func foundError(_ text: String)
}

class SpeechDirector: NSObject {

    private var sentences: [String] = []
    private var currentSentenceIndex = 0
    private var currentSentence = ""
    
    var dataCoordinator: DataCoordinator = DataCoordinator()
    let ttsDirector: TTSDirector
    let audioDirector: AudioDirector
    let stringSanitizer: StringSanitizer
    weak var delegate: SpeechDirectorDelegate?
    
    // MARK: Initialization
    init(ttsDirector: TTSDirector,
         audio: AudioDirector,
         sanitizer: StringSanitizer) {
        self.ttsDirector = ttsDirector
        self.audioDirector = audio
        self.stringSanitizer = sanitizer
        super.init()
        self.audioDirector.delegate = self
    }
    
    // MARK: Public API
    func startTalking(text: String) {
        guard let _ = ttsDirector.tts else {
            delegate?.foundError("Text To Speech model not yet initialized. Please wait a while before trying again")
            delegate?.didFinishTalking()
            return
        }
        sentences = generateSentences(text: text)
        currentSentenceIndex = 0
        
        guard sentences.count > 0 else {
            delegate?.didFinishTalking()
            return
        }
        
        dataCoordinator = DataCoordinator()
        audioDirector.startAudio()
        audioDirector.waitAndPlayAudio(dataCoordinator)
        generateTTSArrays()
    }
    
    func stopTalking() {
        dataCoordinator.finish()
        audioDirector.stop()
    }
    
    private func generateSentences(text: String) -> [String] {
        var results: [String] = []
        let tokenizer = NLTokenizer(unit: .sentence)
        let sanitizedText = stringSanitizer.preSanitize(text)
        tokenizer.string = sanitizedText
        
        tokenizer.enumerateTokens(in: sanitizedText.startIndex..<sanitizedText.endIndex) { range, _ in
            let sentence = String(sanitizedText[range])
            let sanitizedSentence = stringSanitizer.postSanitize(sentence)
            if !sanitizedSentence.isEmpty {
                results.append(sanitizedSentence)
            }
            return true
        }
        
        return results
    }
    
    private func generateTTSArrays() {
        guard currentSentenceIndex < sentences.count else {
            dataCoordinator.finish()
            return
        }
        
        currentSentence = sentences[currentSentenceIndex]
        let arg = Unmanaged<SpeechDirector>.passUnretained(self).toOpaque()
        
        let ttsCallback = generateTTSCallBack()
        
        DispatchQueue.global().async { [weak self] in
            guard let self, let tts = self.ttsDirector.tts else {
                print("Text to Speech Model is nil")
                let _ = Unmanaged<SpeechDirector>.fromOpaque(arg).takeUnretainedValue()
                return
            }
            
            let _ = tts.generateWithCallbackWithArg(
                text: currentSentence,
                callback: ttsCallback,
                arg: arg,
                sid: 3,
                speed: 1
            )
        }
        
    }
    
    private func generateTTSCallBack() -> TtsCallbackWithArg {
        let callback = TtsCallbackWithArg { samplesPtr, nSamples, argPtr in
            
            guard let argPtr else {
                print("Callback received nil argPtr")
                return 0
            }
            
            let o = Unmanaged<SpeechDirector>.fromOpaque(argPtr).takeUnretainedValue()

            guard let samplesPtr else {
                print("Callback received nil samplesPtr")
                return 0
            }
            
            let samplesBuffer = UnsafeBufferPointer(start: samplesPtr, count: Int(nSamples))
            let savedSamples: [Float] = Array(samplesBuffer)
            
            DispatchQueue.main.async {
                o.dataCoordinator.addData((o.currentSentence, savedSamples))
                o.currentSentenceIndex += 1
                o.generateTTSArrays()
            }
             
            return 1
            
        }
        return callback
    }
}

extension SpeechDirector: AudioDirectorDelegate {
    
    func willStartTalking(_ text: String, _ duration: Double) {
        delegate?.willStartTalking(text: text, duration: duration)
    }
    
    func foundError(_ text: String) {
        delegate?.foundError(text)
    }
    
    func didFinishPlayingAllBuffers() {
        delegate?.didFinishTalking()
    }
}
