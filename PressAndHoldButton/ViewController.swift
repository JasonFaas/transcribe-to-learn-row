//
//  ViewController.swift
//  PressAndHoldButton
//
//  Created by Jason A Faas on 8/10/19.
//  Copyright © 2019 Jason A Faas. All rights reserved.
//

import UIKit
import Speech

import PressAndHoldButton

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
    var pinyinOn = true
    var pinyinToggleText: [Bool: String] = [true: "Turn On Pinyin",
                                            false: "True Off Pinyin", ]
    
    var currentTranslation: DbTranslation!
    
    var translation: RecordingForTranslation!
    
    var dbm: DatabaseManagement!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //TODO: Really, no unit tests?
//        if !unitTests() {
//            exit(0)
//        }
        
        // Setup
        self.dbm = DatabaseManagement()
        self.translation = RecordingForTranslation(primaryLabel: self.generalCommentLabel)
        self.translation.setupRecordingSession()
        
        
        // DB testing
        do {
            var testTranslation: DbTranslation = self.dbm.getRandomRowFromTranslations()
            try testTranslation.verifyAll()
            print(testTranslation.getHanzi())
            
            testTranslation = self.dbm.getRandomRowFromTranslations()
            try testTranslation.verifyAll()
            print(testTranslation.getHanzi())
        } catch {
            print(error.localizedDescription)
            exit(33)
        }
        
        self.currentTranslation = self.dbm.getRandomRowFromTranslations()
        
        self.toPronounce.text = self.currentTranslation.getHanzi()
        self.toPronouncePinyin.text = self.currentTranslation.getPinyin()
        
        self.buttonPinyinToggle.setTitle(self.pinyinToggleText[!self.pinyinOn], for: .normal)
        self.toPronouncePinyin.isHidden = !self.pinyinOn
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
    
    @IBAction func pinyinToggle(_ sender: Any) {
        self.pinyinOn = !self.pinyinOn
        self.buttonPinyinToggle.setTitle(self.pinyinToggleText[!self.pinyinOn], for: .normal)
        self.toPronouncePinyin.isHidden = !self.pinyinOn
    }
    
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
    
    @IBAction func skipThisPress(_ sender: Any) {
        self.skipThis.isEnabled = false
        
        self.advanceToNextPhrase(letterGrade: "F")
        self.generalCommentLabel.text = "I know you'll get it next time"
    }
    
    
    @IBAction func releaseOutside(_ sender: Any) {
        released()
    }
    
    @IBAction func pressAndHoldBbutton(_ sender: UIButton) {
        released()
    }
    
    func released() {
        self.buttonTextUpdate.isEnabled = false
        
        generalCommentLabel.text = "\(String(generalCommentLabel.text ?? "hello"))\nProcessing..."
        
        self.translation.finishRecording()
        
        self.translation.playback()
        self.transcribeFile(url: self.translation.getFileURL() as URL)
        
        self.buttonTextUpdate.isEnabled = true
    }

    
    @IBAction func release(_ sender: Any) {
        generalCommentLabel.text = "Listening..."
        
        do {
            try self.translation.startRecording()
        } catch {
            self.translation.finishRecording()
            generalCommentLabel.text = "\(String(generalCommentLabel.text ?? "hello")) Did not record."
        }
    }
    
    func updateQuizScreenWithQuizInfo(quizInfo: DbTranslation) {
        self.toPronounce.text = quizInfo.getHanzi()
        self.toPronouncePinyin.text = quizInfo.getPinyin()
    }
    
    func advanceToNextPhrase(letterGrade: String) {
        // log info
        self.dbm.logResult(letterGrade: letterGrade,
                           quizInfo: self.currentTranslation,
                           pinyinOn: self.pinyinOn)
        
        self.currentTranslation = self.dbm.getRandomRowFromTranslations()
        
        self.updateQuizScreenWithQuizInfo(quizInfo: self.currentTranslation)
        
        

//        let currentParagraph = self.fullTranslations[self.translationValue % self.fullTranslations.count].simplifiedChar
//        let pinyinOn = self.pinyinOn
//        let currentHanzi = self.fullTranslations[self.translationValue % self.fullTranslations.count].simplifiedChar
//        if !currentParagraph.contains("。") {
//
//            self.dbm.logResult(letterGrade: letterGrade,
//                               hanzi: currentHanzi,
//                               pinyinOn: pinyinOn)
//
//            self.translationValue += 1
//        } else {
//            let sentences:[Substring] = currentParagraph.split(separator: "。")
//            self.paragraphValue += 1
//            if sentences.count == self.paragraphValue {
//                self.dbm.logResult(letterGrade: letterGrade,
//                                   hanzi: currentHanzi,
//                                   pinyinOn: pinyinOn)
//
//                self.translationValue += 1
//                self.paragraphValue = 0
//            }
//        }
//
//        let (characters, pinyin) = self.getToPronounce()
//        self.toPronounce.text = characters
//        self.toPronouncePinyin.text = pinyin
//
//        self.pronouncedSoFar = ""
    }
    
    fileprivate func transcribeFile(url: URL) {
        // 1
        //en-US or zh_Hans_CN - https://gist.github.com/jacobbubu/1836273
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh_Hans_CN")) else {
            print("Speech recognition not available for specified locale")
            return
        }
        
        if !recognizer.isAvailable {
            print("Speech recognition not currently available")
            return
        }
        
        // 2
//        updateUIForTranscriptionInProgress()
        let request = SFSpeechURLRecognitionRequest(url: url)
        
        // 3
        recognizer.recognitionTask(with: request) {
            [unowned self] (result, error) in
            guard let result = result else {
                print("There was an error transcribing that file")
                return
            }
            
            // 4
//            if result.isFinal {
//                var transcribed:String = result.bestTranscription.formattedString
//
//                transcribed = transcribed.replacingOccurrences(of: "。", with: "")
//                transcribed = transcribed.replacingOccurrences(of: "！", with: "")
//                transcribed = "\(self.pronouncedSoFar)\(transcribed)"
//
//                let compareString = self.removeExtraNewlineForComparrison(self.toPronounceCharacters)
//                if transcribed == compareString {
//                    self.primaryLabel.text = "Great Pronunciation:\n\(transcribed)"
//                    self.skipThis.isEnabled = false
//
//                    self.advanceToNextPhrase(letterGrade: "A")
//                } else if compareString.contains(transcribed) {
//                    self.pronouncedSoFar = "\(self.pronouncedSoFar)\(transcribed)"
//                        self.primaryLabel.text = "\(String(self.primaryLabel.text ?? "hello")) \nKeep Going: \(self.pronouncedSoFar)"
//                } else {
//                    self.primaryLabel.text = "Try again:\n\(transcribed)"
//                    self.pronouncedSoFar = ""
                    self.skipThis.isEnabled = true
//                }
//
//            }
        }
    }

}

