//
//  SwiftSyllables.swift
//  AICompanion
//
//  Created by Ajarbyurns on 13/08/25.
//


import Foundation

class SwiftSyllables {

    private var syllableDict: [String: Int] = [:]
    private var ipaDict: [String: String] = [:]
    private var addSyllables: [NSRegularExpression] = []
    private var subSyllables: [NSRegularExpression] = []
      
    private let vowels: Set<Character> = ["a", "e", "i", "o", "u", "y"]
            
    private enum SyllableCounterError: Error {
        case badRegex(String)
        case missingExceptionsDataAsset
        case badExceptionsData(String)
    }
    
    init() {
        configureSyllableDict()
        configureIPADict()
        do {
          try populateAddSyllables()
          try populateSubSyllables()
        }
        catch SyllableCounterError.badRegex(let pattern) {
          print("Bad Regex pattern: \(pattern)")
        }
        catch SyllableCounterError.missingExceptionsDataAsset {
          print("Missing exceptions dataset.")
        }
        catch SyllableCounterError.badExceptionsData(let info) {
          print("Problem parsing exceptions dataset: \(info)")
        }
        catch {
          print("An unexpected error occured while initializing the syllable counter.")
        }
    }

    fileprivate func validWords(_ text: String, scheme: String) -> [String] {
        let options = UInt(NSLinguisticTagger.Options.omitWhitespace.rawValue | NSLinguisticTagger.Options.omitPunctuation.rawValue | NSLinguisticTagger.Options.omitOther.rawValue)
        let taggerOptions : NSLinguisticTagger.Options = NSLinguisticTagger.Options(rawValue: options)
        let tagger = NSLinguisticTagger(tagSchemes: NSLinguisticTagger.availableTagSchemes(forLanguage: "en"),
            options: Int(options))
        tagger.string = text

        var validWords: [String] = []
        tagger.enumerateTags(in: NSMakeRange(0, text.count), scheme:NSLinguisticTagScheme(rawValue: scheme), options: taggerOptions) {
            tag, tokenRange, _, _ in let string = (text as NSString).substring(with: tokenRange)
            if tag == NSLinguisticTag.word {
                if let firstChar = string.first {
                    if firstChar != "\'" {
                        validWords.append(string)
                    }
                }
            }
        }
        return validWords
    }

    fileprivate func configureSyllableDict() {
        if self.syllableDict.count == 0 {
            let fileName : String = "cmudict"
            if let fileURL = Bundle.main.path(forResource: fileName, ofType: nil) {
                let data : NSMutableData? = NSMutableData.init(contentsOfFile: fileURL)
                if let foundData = data {
                    let unarchiver : NSKeyedUnarchiver = NSKeyedUnarchiver.init(forReadingWith: foundData as Data)
                    let dict : Any? = unarchiver.decodeObject(forKey: fileName)
                    unarchiver.finishDecoding()
                    if let processedDict = dict as? [String : Int] {
                        for (key, value) in processedDict {
                            syllableDict[key.lowercased()] = value
                        }
                    }
                }
            } else {
                print("Error: '\(fileName)' not found in main bundle.")
            }
        }
    }
    
    func configureIPADict() {
        if self.ipaDict.count == 0 {
            let fileName : String = "lexicon-us-en"
            if let filepath = Bundle.main.path(forResource: fileName, ofType: "txt") {
                do {
                    let content = try String(contentsOfFile: filepath, encoding: .utf8)

                    let lines = content.components(separatedBy: .newlines)

                    var loadedCount = 0
                    for line in lines {
                        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

                        guard !trimmedLine.isEmpty && !trimmedLine.hasPrefix("#") else { continue }

                        let components = trimmedLine.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)

                        if components.count == 2 {
                            let word = String(components[0]).lowercased()
                            let ipaTranscription = String(components[1]).replacingOccurrences(of: " ", with: "")
                            ipaDict[word] = ipaTranscription
                            loadedCount += 1
                        } else {
                            print("Warning: Skipping malformed line in file: '\(trimmedLine)'")
                        }
                    }
                } catch {
                    print("Error reading or parsing file: \(error)")
                }
            } else {
                print("Error: '\(fileName)' not found in main bundle.")
            }
        }
    }

    func getPhonemesAndSyllables(_ string: String) -> [(String, Int)] {
        guard !syllableDict.isEmpty else { return [] }

        var result: [(String, Int)] = []
        var sanitizedString = string
        if string.contains("'") {
            sanitizedString = sanitizedString.replacingOccurrences(of: "'", with: "")
        }
        if string.contains("’") {
            sanitizedString = sanitizedString.replacingOccurrences(of: "’", with: "")
        }
        let taggedWords : [String] = self.validWords(sanitizedString, scheme: convertFromNSLinguisticTagScheme(NSLinguisticTagScheme.tokenType))
        for word : String in taggedWords {
            let lowerCase = word.lowercased()
            var counter = 0
            if let syllables = syllableDict[lowerCase] {
                counter = syllables
            } else {
                counter = count(word: lowerCase)
            }
            let ipaString = ipaDict[lowerCase] ?? lowerCase
            result.append((ipaString, counter))
        }
        return result
    }
    
    private func populateAddSyllables() throws {
        try addSyllables = buildRegexes(forPatterns: [
          "ia", "riet", "dien", "iu", "io", "ii",
          "[aeiouy]bl$", "mbl$", "tl$", "sl$", "[aeiou]{3}",
          "^mc", "ism$", "(.)(?!\\1)([aeiouy])\\2l$", "[^l]llien", "^coad.",
          "^coag.", "^coal.", "^coax.", "(.)(?!\\1)[gq]ua(.)(?!\\2)[aeiou]", "dnt$",
          "thm$", "ier$", "iest$", "[^aeiou][aeiouy]ing$"])
    }
  
    private func populateSubSyllables() throws {
        try subSyllables = buildRegexes(forPatterns: [
          "cial", "cian", "tia", "cius", "cious",
          "gui", "ion", "iou", "sia$", ".ely$",
          "ves$", "geous$", "gious$", "[^aeiou]eful$", ".red$"])
    }
  
    private func buildRegexes(forPatterns patterns: [String]) throws -> [NSRegularExpression] {
        return try patterns.map { pattern -> NSRegularExpression in
          do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .anchorsMatchLines])
            return regex
          }
          catch {
            throw SyllableCounterError.badRegex(pattern)
          }
        }
    }
    
    private func count(word: String) -> Int {
        if word.count <= 1 {
          return word.count
        }
        
        var mutatedWord = word.lowercased(with: Locale(identifier: "en_US")).trimmingCharacters(in: .punctuationCharacters)
        
        if mutatedWord.last == "e" {
          mutatedWord = String(mutatedWord.dropLast())
        }
        
        var count = 0
        var previousIsVowel = false
        
        for character in mutatedWord {
          let isVowel = vowels.contains(character)
          if isVowel && !previousIsVowel {
            count += 1
          }
          previousIsVowel = isVowel
        }
        
        for pattern in addSyllables {
          let matches = pattern.matches(in: mutatedWord, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSRange(location: 0, length: mutatedWord.count))
          if !matches.isEmpty {
            count += 1
          }
        }
        
        for pattern in subSyllables {
          let matches = pattern.matches(in: mutatedWord, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSRange(location: 0, length: mutatedWord.count))
          if !matches.isEmpty {
            count -= 1
          }
        }
        
        return (count > 0) ? count : 1
    }
}

fileprivate func convertFromNSLinguisticTagScheme(_ input: NSLinguisticTagScheme) -> String {
	return input.rawValue
}
