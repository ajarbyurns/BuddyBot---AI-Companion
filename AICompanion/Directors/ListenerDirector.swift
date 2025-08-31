//
//  ListenerDirector.swift
//  BuddyBot
//
//  Created by Ajarbyurns on 17/08/25.
//
import Foundation
import AVFoundation
import Speech

protocol ListenerDirectorDelegate: AnyObject {
    func didDetectSentence(_ text: String)
    func errorMessage(_ text: String)
}

class ListenerDirector {
    
    private var transcription = ""
    private var inputComplete = false
    
    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var timer: Timer?
    weak var delegate: ListenerDirectorDelegate?
    
    init() {
        audioEngine = AVAudioEngine()
        speechRecognizer = SFSpeechRecognizer(locale: .init(identifier: "en_US"))
    }
    
    func requestAuthorization(completion: (()->Void)? = nil) {
        let status = AVAudioApplication.shared.recordPermission
        
        switch status {
        case .undetermined:
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async { [weak self] in
                    if granted {
                        self?.requestSpeechAuthorization(completion: completion)
                    } else {
                        self?.delegate?.errorMessage("Microphone access denied. Allow microphone usage in System Settings to use this feature")
                    }
                }
            }
        case .denied:
            delegate?.errorMessage("Microphone access denied. Allow microphone usage in System Settings to use this feature")
        case .granted:
            requestSpeechAuthorization(completion: completion)
        @unknown default:
            delegate?.errorMessage("Microphone access denied. Allow Microphone usage in System Settings to use this feature")
        }
    }
    
    private func requestSpeechAuthorization(completion: (() -> Void)? = nil) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async { [weak self] in
                switch authStatus {
                case .authorized:
                    completion?()
                case .denied, .restricted, .notDetermined:
                    self?.delegate?.errorMessage("Speech Recognition not authorized. Allow Speech Recognition in System Settings to use this feature")
                @unknown default:
                    self?.delegate?.errorMessage("Unknown Authorization status. Allow Speech Recognition in System Settings to use this feature")
                }
            }
        }
    }
    
    func startListening() {
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        
        guard let audioEngine, let recognitionRequest else {
            delegate?.errorMessage("Audio Engine not found.")
            return
        }
        
        #if !os(macOS)
        setupAudioSessionForRecording()
        #endif
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            delegate?.errorMessage("Audio Engine won't start.")
            return
        }
        
        inputComplete = false
        recognitionTask?.cancel()
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self, !Task.isCancelled, error == nil else { return }
            if let result {
                let bestTranscription = result.bestTranscription.formattedString
                if !bestTranscription.isEmpty, !inputComplete {
                    self.transcription = bestTranscription
                    
                    self.timer?.invalidate()
                    self.timer = Timer.scheduledTimer(timeInterval: 2,
                                                      target: self,
                                                      selector: #selector(self.didFinishTalking),
                                                      userInfo: nil,
                                                      repeats: false)
                }
            }
        }
    }
    
    #if !os(macOS)
    private func setupAudioSessionForRecording() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .default, options: .duckOthers)
        } catch {
            delegate?.errorMessage("Can't activate Audio Session.")
        }
    }
    #endif
    
    @objc private func didFinishTalking() {
        if !inputComplete {
            Task { @MainActor in
                stopListening()
                self.delegate?.didDetectSentence(transcription)
            }
        }
    }
    
    func stopListening() {
        
        inputComplete = true
        
        timer?.invalidate()
        timer = nil
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        if let audioEngine, audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
    }
}
