//
//  StringSanitizer.swift
//  AICompanion
//
//  Created by Ajarbyurns on 16/08/25.
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
            .replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return output
    }
    
    func postSanitize(_ input: String) -> String {
        var result = ""
        
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = input
        tokenizer.setLanguage(NLLanguage(rawValue: "en"))
        
        tokenizer.enumerateTokens(in: input.startIndex..<input.endIndex) { range, _ in
            let token = String(input[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            if token.isEmpty {
                result += " "
            } else if let number = Double(token.replacingOccurrences(of: ",", with: "")) {
                if let spelled = numberFormatter.string(from: NSNumber(value: number)) {
                    result += " " + spelled
                } else {
                    result += " " + token
                }
            } else if token.count == 1, let ch = token.first, keepSet.contains(ch) {
                result += token
            } else if let symbol = symbolWords[token] {
                result += " \(symbol)"
            } else if token.rangeOfCharacter(from: CharacterSet.letters) != nil {
                result += " \(token)"
            }
            
            return true
        }
        let collapsed = result
            .replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return collapsed
    }
}
