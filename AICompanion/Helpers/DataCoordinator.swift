//
//  DataCoordinator.swift
//  AICompanion
//
//  Created by Barry Juans on 10/08/25.
//
import Foundation

class DataCoordinator {
    
    let buffer: AsyncStream<(String, [Float])>
    private var continuation: AsyncStream<(String, [Float])>.Continuation?
    var isFinished = false
    
    init() {
        var localContinuation: AsyncStream<(String, [Float])>.Continuation?
        buffer = AsyncStream { continuation in
            localContinuation = continuation
        }
        continuation = localContinuation
    }

    func addData(_ item: (String, [Float])) {
        continuation?.yield(item)
    }
    
    func finish() {
        isFinished = true
        continuation?.finish()
    }
}
