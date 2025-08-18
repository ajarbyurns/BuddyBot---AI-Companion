//
//  StringSanitizer.swift
//  AICompanion
//
//  Created by Barry Juans on 16/08/25.
//
import Foundation
import NaturalLanguage

class StringSanitizer {
    
    let symbolWords: [String: String] = [
            "@": "at", "#": "hashtag", "$": "dollar", "%": "percent",
            "&": "and", "*": "star", "+": "plus", "-": "minus",
            "=": "equals", "/": "slash", "\\": "backslash",
            ":": "colon", ";": "semicolon", "(": "left parenthesis",
            ")": "right parenthesis", "[": "left bracket",
            "]": "right bracket", "{": "left brace", "}": "right brace",
            "<": "less than", ">": "greater than", "|": "pipe",
            "^": "caret", "_": "underscore", "~": "approximately",
            "`": "backtick"
        ]
    
    let keepSet: Set<Character> = [",", ".", "!", "?", "\"", "'", " "]
    
    let numberFormatter = NumberFormatter()
    
    init() {
        numberFormatter.numberStyle = .spellOut
        numberFormatter.locale = Locale(identifier: "en_US")
    }
    
    func preSanitize(_ input: String) -> String {
        let normalized = input.precomposedStringWithCanonicalMapping
        let filteredScalars = normalized.unicodeScalars.filter { scalar in
            let category = scalar.properties.generalCategory
            return category != .control || scalar == "\n" || scalar == "\t" || scalar == " "
        }
        
        let output = String(String.UnicodeScalarView(filteredScalars))
            .replacingOccurrences(of: "\\s{2,}", with: ". ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return output
    }
    
    func postSanitize(_ input: String) -> String {
        var result = ""
        
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = input
        tokenizer.setLanguage(NLLanguage(rawValue: "en"))
        
        tokenizer.enumerateTokens(in: input.startIndex..<input.endIndex) { range, _ in
            let token = String(input[range])
            
            if let number = Double(token.replacingOccurrences(of: ",", with: "")) {
                if let spelled = numberFormatter.string(from: NSNumber(value: number)) {
                    result += " " + spelled
                } else {
                    result += " " + token
                }
            } else if token.rangeOfCharacter(from: CharacterSet.letters) != nil {
                result += " " + token
            } else if keepSet.contains(token) {
                result += token
            } else if token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                result += " "
            } else {
                if let symbol = symbolWords[token] {
                    result += " \(symbol)"
                } else {
                    result += ", "
                }
            }
            return true
        }
        let collapsed = result.replacingOccurrences(of: "\\s{2,}", with: ". ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return collapsed
    }
}
