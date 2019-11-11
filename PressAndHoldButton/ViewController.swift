//
//  ViewController.swift
//  PressAndHoldButton
//
//  Created by Jason A Faas on 8/10/19.
//  Copyright © 2019 Jason A Faas. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController {

    @IBOutlet weak var toPronounce: UILabel!
    @IBOutlet weak var generalCommentLabel: UILabel!
    @IBOutlet weak var buttonTextUpdate: UIButton!
    @IBOutlet weak var skipThis: UIButton!
    @IBOutlet weak var buttonPinyinToggle: UIButton!
    @IBOutlet weak var toPronouncePinyin: UILabel!
    
    //TODO review all these variables to see if they are actually needed
    var translationValue = 0
    var paragraphValue = 0
    var toPronounceCharacters = ""
    var pronouncedSoFar = ""
    
    var translation: RecordingForTranslation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.translation = RecordingForTranslation(
            feedbackLabel: self.generalCommentLabel,
            toPronounceHanzi: self.toPronounce,
            toPronouncePinyin: self.toPronouncePinyin,
            buttonTextUpdate: self.buttonTextUpdate,
            skipThis: self.skipThis,
            pinyinToggleButton: self.buttonPinyinToggle
        )
        
        do {
            try translation.runUnitTests()
        } catch {
            print("Function: \(#file):\(#line), Error: \(error)")
            exit(1)
        }
        
        self.translation.setupRecordingSession()
    }
    
    @IBAction func pinyinToggle(_ sender: Any) {
        self.translation.pinyinToggle()
    }
    
    @IBAction func skipThisPress(_ sender: Any) {
        self.translation.skipThisPress()
    }
    
    @IBAction func releaseOutside(_ sender: Any) {
        released()
    }
    
    @IBAction func pressAndHoldBbutton(_ sender: UIButton) {
        released()
    }
    
    func released() {
        self.translation.fullFinishRecording()
    }
    
    @IBAction func release(_ sender: Any) {
        self.translation.fullStartRecording()
    }
    
//    func getToPronounce() -> (String, String) {
//
//        let nextParagraph = self.fullTranslations[self.translationValue % self.fullTranslations.count].simplifiedChar
//
//        let pinyinStr = self.fullTranslations[self.translationValue % self.fullTranslations.count].pinyinChar
//        if !nextParagraph.contains("。") {
//            self.toPronounceCharacters = nextParagraph
//            return (nextParagraph, pinyinStr)
//        } else {
//            var sentences:[Substring] = nextParagraph.split(separator: "。")
//            var pinyinSentences:[Substring] = pinyinStr.split(separator: ".")
//            let sentence = removeExtraFromString(String(sentences[self.paragraphValue]))
//            let pinyin = removeExtraFromString(String(pinyinSentences[self.paragraphValue]))
//
//            self.toPronounceCharacters = sentence
//            return (sentence, pinyin)
//        }
//    }
    
//    func removeExtraNewlineForComparrison(_ str: String) -> String {
//        let retStr = str.replacingOccurrences(of: "\n", with: "")
//        return retStr
//    }
//        func removeExtraFromString(_ str: String) -> String {
//            var retStr = str.replacingOccurrences(of: ".", with: "\n")
//        retStr = retStr.replacingOccurrences(of: "。", with: "\n")
//        retStr = retStr.replacingOccurrences(of: ",", with: "\n")
//        retStr = retStr.replacingOccurrences(of: "，", with: "\n")
//
//        return retStr
//    }
    
}
