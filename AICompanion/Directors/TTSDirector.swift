//
//  SherpaTTS.swift
//  AICompanion
//
//  Created by Barry Juans on 09/08/25.
//
import Foundation

class TTSDirector {
    
    var tts: SherpaOnnxOfflineTtsWrapper?
    
    init(initCompletion: (() -> Void)? = nil) {
        Task {
            let temp = getModelWrapper()
            await MainActor.run {
                tts = temp
                initCompletion?()
            }
        }
    }
    
    func getModelWrapper() -> SherpaOnnxOfflineTtsWrapper? {
        let model = getResource("model", "onnx")
        let voices = getResource("voices", "bin")
        let tokens = getResource("tokens", "txt")
        let lexicon_en = getResource("lexicon-us-en", "txt")
        let lexicon_zh = getResource("lexicon-zh", "txt")
        let lexicon = "\(lexicon_en),\(lexicon_zh)"

        let dataDir = resourceURL(to: "espeak-ng-data")
        let dictDir = resourceURL(to: "dict")
        
        guard !model.isEmpty, !voices.isEmpty, !tokens.isEmpty, !lexicon_en.isEmpty, !lexicon_zh.isEmpty, !dataDir.isEmpty, !dictDir.isEmpty else {
            print("File is empty")
            return nil
        }

        let kokoro = sherpaOnnxOfflineTtsKokoroModelConfig(
            model: model, voices: voices, tokens: tokens, dataDir: dataDir,
            dictDir: dictDir, lexicon: lexicon)
        
        let modelConfig = sherpaOnnxOfflineTtsModelConfig(kokoro: kokoro,
                                                        provider: "coreml")
        var config = sherpaOnnxOfflineTtsConfig(model: modelConfig)

        return SherpaOnnxOfflineTtsWrapper(config: &config)
    }
    
    func resourceURL(to path: String) -> String {
      return URL(string: path, relativeTo: Bundle.main.resourceURL)?.path ?? ""
    }

    func getResource(_ forResource: String, _ ofType: String) -> String {
        if let path = Bundle.main.path(forResource: forResource, ofType: ofType) {
            return path
        } else {
            print("\(forResource).\(ofType) does not exist!\n" + "Remember to change \n"
                  + "  Build Phases -> Copy Bundle Resources\n" + "to add it!")
            return ""
        }
    }
}
