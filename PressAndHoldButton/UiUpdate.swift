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
    var toPronouncePinyin: UILabel
    var buttonTextUpdate: UIButton
    var skipThis: UIButton
    var pinyinToggleButton: UIButton
    
    var pinyinOn = false
    
    var pinyinToggleText: [Bool: String] = [true: "Turn On Pinyin",
                                            false: "True Off Pinyin", ]
    
    init(feedbackLabel: UILabel,
        toPronounceHanzi: UILabel,
        toPronouncePinyin: UILabel,
        buttonTextUpdate: UIButton,
        skipThis: UIButton,
        pinyinToggleButton: UIButton) {
        self.feedbackLabel = feedbackLabel
        self.toPronounceHanzi = toPronounceHanzi
        self.toPronouncePinyin = toPronouncePinyin
        self.buttonTextUpdate = buttonTextUpdate
        self.skipThis = skipThis
        self.pinyinToggleButton = pinyinToggleButton
    }
    
    func pinyinOff() {
        if self.pinyinOn {
            self.pinyinToggle()
        }
    }
    
    func pinyinToggle() {
        self.pinyinOn = !self.pinyinOn
        self.pinyinToggleButton.setTitle(self.pinyinToggleText[!self.pinyinOn], for: .normal)
        self.toPronouncePinyin.isHidden = !self.pinyinOn
    }

    func updateUiWithTranslation(_ dbTranslation: DbTranslation) {
        self._setHanziField(dbTranslation.getHanzi())
        self._setPinyinField(dbTranslation.getPinyin())
    }
    
    func _setHanziField(_ hanzi: String) {
        self.toPronounceHanzi.text = hanzi
    }
    
    func _setPinyinField(_ pinyin: String) {
        self.toPronouncePinyin.isHidden = !self.pinyinOn
        self.toPronouncePinyin.text = pinyin
    }
    
    func updateQuizScreenWithQuizInfo(quizInfo: DbTranslation) {
        if quizInfo.getLanguageToDisplay() == "Mandarin-Simplified" {
            self.toPronounceHanzi.text = quizInfo.getHanzi()
            self.toPronouncePinyin.text = quizInfo.getPinyin()
        } else {
            self.toPronounceHanzi.text = quizInfo.getEnglish()
            self.toPronouncePinyin.text = quizInfo.getPinyin()
        }
    }
    
    func updateFeedbackText(_ feedback: String) {
        self.feedbackLabel.text = feedback
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
    
    func disableRecording() {
        self.buttonTextUpdate.isEnabled = false
    }
    
    func enableRecording() {
        self.buttonTextUpdate.isEnabled = true
    }
}
