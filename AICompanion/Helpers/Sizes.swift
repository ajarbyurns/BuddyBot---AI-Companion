//
//  Sizes.swift
//  AICompanion
//
//  Created by Ajarbyurns on 25/08/25.
//


import SwiftUI

#if os(macOS)
let textEditorFont: Font = .title2
let progressBarScale: CGFloat = 1
let buttonSize: Font = .largeTitle
let paddingSize: CGFloat = 10
#else
let textEditorFont: Font = .body
let progressBarScale: CGFloat = 1.5
let buttonSize: Font = .title
let paddingSize: CGFloat = 10
#endif
