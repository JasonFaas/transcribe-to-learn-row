//
//  UiUpdate.swift
//  PressAndHoldButton
//
//  Created by Jason A Faas on 11/27/19.
//  Copyright © 2019 Jason A Faas. All rights reserved.
//

import Foundation
import UIKit

class UiUpdate {
    
    var feedbackLabel: UILabel
    var toPronounceHanzi: UILabel
    var dueProgress: UILabel
    var toPronouncePinyin: UILabel
    var sayInZwHTRButton: UIButton
    var sayAgainHTRButton: UIButton
    var skipThis: UIButton
    var pinyinToggleButton: UIButton
    
    var pinyinOn = false
    
    var pinyinToggleText: [Bool: String] = [true: "Turn On Pinyin",
                                            false: "Turn Off Pinyin", ]
    
    init(feedbackLabel: UILabel,
        toPronounceHanzi: UILabel,
        toPronouncePinyin: UILabel,
        sayInZwHTRButton: UIButton,
        skipThis: UIButton,
        pinyinToggleButton: UIButton,
        dueProgress: UILabel,
        sayAgainHTRButton: UIButton) {
        self.feedbackLabel = feedbackLabel
        self.toPronounceHanzi = toPronounceHanzi
        self.toPronouncePinyin = toPronouncePinyin
        self.sayInZwHTRButton = sayInZwHTRButton
        self.sayAgainHTRButton = sayAgainHTRButton
        self.skipThis = skipThis
        self.pinyinToggleButton = pinyinToggleButton
        self.dueProgress = dueProgress
    }
    
    func getPinyinOn() -> Bool {
        return self.pinyinOn
    }
    
    func pinyinOff() {
        if self.pinyinOn {
            self.pinyinToggle()
        }
    }
    
    func pinyinToOn() {
        if !self.pinyinOn {
            self.pinyinToggle()
        }
    }
    
    func pinyinToggle() {
        self.pinyinOn = !self.pinyinOn
        self.pinyinToggleButton.setTitle(self.pinyinToggleText[!self.pinyinOn], for: .normal)
        self.toPronouncePinyin.isHidden = !self.pinyinOn
    }
    
    func _setHanziField(_ hanzi: String) {
        self.toPronounceHanzi.text = hanzi
    }
    
    func _setPinyinField(_ pinyin: String) {
        self.toPronouncePinyin.isHidden = !self.pinyinOn
        self.toPronouncePinyin.text = pinyin
    }
    
    func updateQuizScreenWithQuizInfo(quizInfo: DbTranslation) {
        _setPinyinField(quizInfo.getPinyin())
        
        _setHanziField("\(quizInfo.getHanzi())\n\(quizInfo.getEnglish())")
        
        // TODO: Consider just one language, for now both
//        if quizInfo.getLanguageToDisplay() == LanguageDisplayed.MandarinSimplified.rawValue {
//            _setHanziField(quizInfo.getHanzi())
//        } else {
//            _setHanziField(quizInfo.getEnglish())
//        }
    }
    
    func updateFeedbackText(_ feedback: String) {
        self.feedbackLabel.text = feedback
    }
    
    func updatePhraseProgress(_ phraseProgress: String) {
        self.dueProgress.text = phraseProgress
    }
    
    func addToFeedbackText(_ feedback: String) {
        self.updateFeedbackText("\(String(self.feedbackLabel.text ?? "hello"))\(feedback)")
    }
    
    func disableSkip() {
        self.skipThis.isEnabled = false
    }
    
    func enableSkip() {
        self.skipThis.isEnabled = true
    }
    
    func disableRecordingButtons() {
        self.sayInZwHTRButton.isEnabled = false
        self.sayAgainHTRButton.isEnabled = false
    }
    
    func enableRecording(_ sender: UIButton) {
        sender.isEnabled = true
    }
}
