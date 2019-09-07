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
                                pinyinChar: "Hěn gāoxìng rènshì nǐ",
                                englishChar: "hengaoxingrenshini",
                                englishTranslation: "Nice to meet you"),
                TranslationInfo(simplifiedChar: "生日快乐",
                                pinyinChar: "Shēngrì kuàilè",
                                englishChar: "shengrikuaile",
                                englishTranslation: "Happy Birthday"),
                TranslationInfo(simplifiedChar: "我对海鲜过敏",
                                pinyinChar: "Wǒ duì hǎixiān guòmǐn",
                                englishChar: "Wǒ duì hǎixiān guòmǐn",
                                englishTranslation: "I am allergic to seafood"),
                TranslationInfo(simplifiedChar: "祝你生日快乐",
                                pinyinChar: "Zhù nǐ shēng rì kuài lè",
                                englishChar: "",
                                englishTranslation: "Happy Birthday to you"),
                TranslationInfo(simplifiedChar: "我有一头小毛驴，我从来也不骑。有一天我心血来潮，骑着去赶集。我手里拿着小皮鞭，心里正得意。不知怎么哗啦啦啦摔了我一身泥。",
                                pinyinChar: "Wǒ yǒu yī tóu xiǎo máolǘ，wǒ cónglái yě bù qí. Yǒu yī tiān wǒ xīnxuèláicháo，qí zhe qù gǎnjí. Wǒ shǒulǐ názhe xiǎo píbiān，xīnli zhēng déyì. Bùzhī zěnme hulálálá shuāi le wǒ yī shēn ní.",
                                englishChar: "",
                                englishTranslation: "I have a little donkey, I'd never tried to ride. One day on a whim, I rode him into the market. I had a little whip, I was feeling very proud of myself. I don't know how, whoosh! I was thrown into the mud!"),
        ]
    }
}

enum TranscribtionError: Error {
    case durationTooLong(duration: Int)
    case whatGenericException
}
