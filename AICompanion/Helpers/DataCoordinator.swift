//
//  DataCoordinator.swift
//  AICompanion
//
//  Created by Ajarbyurns on 10/08/25.
//
import Foundation

class DataCoordinator<T> {
    
    let buffer: AsyncStream<T>
    private var continuation: AsyncStream<T>.Continuation?
    var isFinished = false
    
    init() {
        var localContinuation: AsyncStream<T>.Continuation?
        buffer = AsyncStream { continuation in
            localContinuation = continuation
        }
        continuation = localContinuation
    }

    func addData(_ item: T) {
        continuation?.yield(item)
    }
    
    func finish() {
        isFinished = true
        continuation?.finish()
    }
}
