//
//  SpeechDirector.swift
//  BuddyBot
//
//  Created by Ajarbyurns on 07/08/25.
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

    private var currentSentence = ""
    
    private var audioCoordinator: DataCoordinator<(String, [Float])> = DataCoordinator()
    private var continuation: CheckedContinuation<(), Never>?
    
    private let ttsDirector: TTSDirector
    private let audioDirector: AudioDirector
    
    weak var delegate: SpeechDirectorDelegate?
    private var receiveStringTask: Task<Void, Error>?
    private var isGeneratingTTS = false
    
    // MARK: Initialization
    init(tts: TTSDirector,
         audio: AudioDirector) {
        self.ttsDirector = tts
        self.audioDirector = audio
        super.init()
        self.audioDirector.delegate = self
    }
    
    // MARK: Public API
    func startTalking(sentenceCoordinator: DataCoordinator<String>) {
        guard let _ = ttsDirector.tts else {
            delegate?.foundError("TTS model not yet initialized")
            delegate?.didFinishTalking()
            return
        }
        
        isGeneratingTTS = false
        audioCoordinator = DataCoordinator()
        audioDirector.startAudio()
        audioDirector.waitAndPlayAudio(audioCoordinator)
        
        receiveStringTask?.cancel()
        receiveStringTask = Task {
            for await sentence in sentenceCoordinator.buffer {
                guard !Task.isCancelled else { return }
                await generateTTSArray(sentence: sentence)
            }
            audioCoordinator.finish()
        }
    }
    
    func stopTalking() {
        receiveStringTask?.cancel()
        audioCoordinator.finish()
        audioDirector.stop()
    }
    
    private func generateTTSArray(sentence: String) async {
        
        await withCheckedContinuation { continuation in
            
            self.currentSentence = sentence
            self.isGeneratingTTS = true
            self.continuation = continuation
            let arg = Unmanaged<SpeechDirector>.passUnretained(self).toOpaque()
            
            let ttsCallback = generateTTSCallBack()
            
            Task {
                guard let tts = ttsDirector.tts else {
                    print("Text to Speech Model is not found.")
                    let _ = Unmanaged<SpeechDirector>.fromOpaque(arg).takeUnretainedValue()
                    continuation.resume()
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
    }
    
    private func generateTTSCallBack() -> TtsCallbackWithArg {
        let callback = TtsCallbackWithArg { samplesPtr, nSamples, argPtr in
            
            guard let argPtr else {
                print("Error when generating audio")
                return 0
            }
            
            guard let samplesPtr else {
                print("Error when generating audio buffer")
                return 0
            }
            
            let o = Unmanaged<SpeechDirector>.fromOpaque(argPtr).takeUnretainedValue()
            
            let samplesBuffer = UnsafeBufferPointer(start: samplesPtr, count: Int(nSamples))
            let savedSamples: [Float] = Array(samplesBuffer)
            
            Task { @MainActor in
                if !o.currentSentence.isEmpty {
                    o.audioCoordinator.addData((o.currentSentence, savedSamples))
                }
                if o.isGeneratingTTS {
                    o.continuation?.resume()
                    o.continuation = nil
                    o.isGeneratingTTS = false
                }
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
