//
//  Extensions.swift
//  AICompanion
//
//  Created by Barry Juans on 06/08/25.
//
import Foundation
import SwiftUI

extension NSTextView {
    open override var frame: CGRect {
        didSet {
            backgroundColor = .clear
            drawsBackground = true
        }

    }
}
