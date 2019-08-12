//
//  TranslationInfo.swift
//  PressAndHoldButton
//
//  Created by Jason A Faas on 8/11/19.
//  Copyright © 2019 Jason A Faas. All rights reserved.
//

import Foundation

class TranslationInfo {
    let simplifiedChar:String
    let pinyinChar:String
    let englishChar:String
    let englishTranslation:String
    
    init(simplifiedChar: String,
         pinyinChar: String,
         englishChar: String,
         englishTranslation: String) {
        self.simplifiedChar = simplifiedChar
        self.pinyinChar = pinyinChar
        self.englishChar = englishChar
        self.englishTranslation = englishTranslation
    }
    init() {
        self.simplifiedChar = ""
        self.pinyinChar = ""
        self.englishChar = ""
        self.englishTranslation = ""
    }
    
    func getAllTranslations() -> Array<TranslationInfo> {
        return [TranslationInfo(simplifiedChar: "你好",
                                pinyinChar: "nǐ hǎo",
                                englishChar: "ni hao",
                                englishTranslation: "Hello"),
                TranslationInfo(simplifiedChar: "美国人",
                                pinyinChar: "měiguó rén",
                                englishChar: "meiguo ren",
                                englishTranslation: "American Person"),
                TranslationInfo(simplifiedChar: "没问题",
                                pinyinChar: "méi wèn tí",
                                englishChar: "mei wen ti",
                                englishTranslation: "No problem"),
                TranslationInfo(simplifiedChar: "很高兴认识你",
                                pinyinChar: "",
                                englishChar: "hengaoxingrenshini",
                                englishTranslation: "Nice to meet you"),
                TranslationInfo(simplifiedChar: "生日快乐",
                                pinyinChar: "",
                                englishChar: "shengrikuaile",
                                englishTranslation: "Happy Birthday"),
                TranslationInfo(simplifiedChar: "我对海鲜过敏",
                                pinyinChar: "",
                                englishChar: "Wǒ duì hǎixiān guòmǐn",
                                englishTranslation: "I am allergic to seafood"),
        ]
    }
}

enum TranscribtionError: Error {
    case durationTooLong(duration: Int)
    case whatGenericException
}
