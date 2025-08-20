//
//  AudioPlayer.swift
//  AICompanion
//
//  Created by Barry Juans on 09/08/25.
//
import AVFoundation

protocol AudioDirectorDelegate: AnyObject {
    func foundError(_ text: String)
    func willStartTalking(_ text: String, _ duration: Double)
    func didFinishPlayingAllBuffers()
}

class AudioDirector {
    private var audioEngine: AVAudioEngine
    private var playerNode: AVAudioPlayerNode
    private var audioFormat: AVAudioFormat
    
    private let sampleRate: Double
    private let channels: UInt32
    
    private var playAudioTask: Task<Void, Never>?
    weak var delegate: AudioDirectorDelegate?
            
    init(sampleRate: Double = 24000, channels: UInt32 = 1) {
        self.sampleRate = sampleRate
        self.channels = channels

        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        audioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                    sampleRate: sampleRate,
                                    channels: channels,
                                    interleaved: false)!
    
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: audioFormat)
        audioEngine.connect(audioEngine.mainMixerNode, to: audioEngine.outputNode, format: audioFormat)
    }

    func startAudio() {
        guard !audioEngine.isRunning else {
            return
        }
        
        do {
            try audioEngine.start()
        } catch {
            delegate?.foundError("Error starting audio engine: \(error.localizedDescription)")
        }
    }
    
    func waitAndPlayAudio(_ coordinator: DataCoordinator<(String, [Float])>) {
        playAudioTask?.cancel()
        playAudioTask = Task {
            for await (text, frames) in coordinator.buffer {
                guard !Task.isCancelled else { return }
                if let pcmBuffer = await getPCMBuffer(samples: frames) {
                    await playAudio(text: text,
                                    duration: Double(frames.count)/sampleRate,
                                    pcmBuffer: pcmBuffer)
                }
            }
            Task { @MainActor in
                stop()
                delegate?.didFinishPlayingAllBuffers()
            }
        }
    }
    
    private func getPCMBuffer(samples: [Float]) async -> AVAudioPCMBuffer? {
        guard !samples.isEmpty else { return nil }
        let frameCapacity = AVAudioFrameCount(samples.count)
        guard let pcmBuffer = AVAudioPCMBuffer(
            pcmFormat: self.audioFormat,
            frameCapacity: frameCapacity) else {
            Task { @MainActor in
                delegate?.foundError("Failed to create AVAudioPCMBuffer.")
            }
            return nil
        }

        if let channelData = pcmBuffer.floatChannelData {
            samples.withUnsafeBufferPointer { sampleBuffer in
                if let address = sampleBuffer.baseAddress {
                    channelData[0].initialize(from: address, count: samples.count)
                }
            }
        } else {
            Task { @MainActor in
                delegate?.foundError("Failed to access pcm buffer data.")
            }
            return nil
        }
        
        pcmBuffer.frameLength = frameCapacity
        
        return pcmBuffer
    }
    
    private func playAudio(text: String,
                           duration: Double,
                           pcmBuffer: AVAudioPCMBuffer,
                           delay: Double = 0.25) async {

        guard audioEngine.isRunning else { return }
        
        Task { @MainActor in
            delegate?.willStartTalking(text, duration)
        }
        
        let lastRenderTime = playerNode.lastRenderTime
        var startTime: AVAudioTime? = nil

        if let lastRenderTime,
           let playerTime = playerNode.playerTime(forNodeTime: lastRenderTime) {
            let previousAudioEndTimeInSamples = playerTime.sampleTime
            let delayInSamples = AVAudioFramePosition(delay * sampleRate)
            let newAudioStartTimeInSamples = previousAudioEndTimeInSamples + delayInSamples
            startTime = AVAudioTime(sampleTime: newAudioStartTimeInSamples, atRate: sampleRate)
        }
        
        if !playerNode.isPlaying {
            playerNode.play()
        }
        
        await withCheckedContinuation { continuation in
            self.playerNode.scheduleBuffer(pcmBuffer, at: startTime, options: .interrupts, completionHandler: {
                continuation.resume()
            })
        }
    }

    func stop() {
        playAudioTask?.cancel()
        if playerNode.isPlaying {
            self.playerNode.stop()
        }
        if audioEngine.isRunning {
            audioEngine.stop()
        }
    }
}
