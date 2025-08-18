//
//  ListenerDirector.swift
//  AICompanion
//
//  Created by Barry Juans on 17/08/25.
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
        speechRecognizer = SFSpeechRecognizer(locale: .init(identifier: "en-US"))
    }
    
    func requestAuthorization(completion: (()->Void)? = nil) {
        let status = AVAudioApplication.shared.recordPermission
        
        switch status {
        case .undetermined:
            delegate?.errorMessage("Microphone access denied.")
        case .denied:
            delegate?.errorMessage("Microphone access denied.")
        case .granted:
            SFSpeechRecognizer.requestAuthorization { authStatus in
                DispatchQueue.main.async { [weak self] in
                    switch authStatus {
                    case .authorized:
                        completion?()
                    case .denied, .restricted, .notDetermined:
                        self?.delegate?.errorMessage("Speech recognition not authorized")
                    @unknown default:
                        self?.delegate?.errorMessage("Unknown authorization status")
                    }
                }
            }
        @unknown default:
            delegate?.errorMessage("Microphone access denied.")
        }
    }
    
    func startListening() {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        
        guard let audioEngine, let recognitionRequest else {
            delegate?.errorMessage("Audio Engine or Recognition Request is nil")
            return
        }
        
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
            delegate?.errorMessage("Audio Engine won't start")
            return
        }
        
        inputComplete = false
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
    
    @objc private func didFinishTalking() {
        if !inputComplete {
            self.stopListening()
            self.delegate?.didDetectSentence(transcription)
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
