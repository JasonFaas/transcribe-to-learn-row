//
//  Recording.swift
//  PressAndHoldButton
//
//  Created by Jason A Faas on 9/7/19.
//  Copyright © 2019 Jason A Faas. All rights reserved.
//

import Foundation

import UIKit

class MainManagement {
    
    var updateUi: UiUpdate
    var recording: Recording
    var transcription: Transcription
    
    init(feedbackLabel: UILabel,
         toPronounceHanzi: UILabel,
         toPronouncePinyin: UILabel,
         buttonTextUpdate: UIButton,
         skipThis: UIButton,
         pinyinToggleButton: UIButton) {
        self.updateUi = UiUpdate(feedbackLabel: feedbackLabel,
                                 toPronounceHanzi: toPronounceHanzi,
                                 toPronouncePinyin: toPronouncePinyin,
                                 buttonTextUpdate: buttonTextUpdate,
                                 skipThis: skipThis,
                                 pinyinToggleButton: pinyinToggleButton)
        self.transcription = Transcription(updateUi: self.updateUi)
        self.recording = Recording(translation: transcription)
    }
    
    func skipThisPress() {
        self.transcription.skipCurrentPhrase()
        
        self.updateUi.disableSkip()
    }
    
    func pinyinToggle() {
        self.updateUi.pinyinToggle()
    }
    
    func fullStartRecording() {
        self.updateUi.disableRecording()
        self.updateUi.updateFeedbackText("Listening...")
        
        do {
            try self.recording._startRecording()
        } catch {
            self.recording._finishRecording()
            self.updateUi.addToFeedbackText(" Did not record.")

            print("Function: \(#file):\(#line), Error: \(error)")
        }
    }
    
    func fullFinishRecording() {
        self.updateUi.addToFeedbackText("\nComplete")
        
        self.recording._finishRecording()
        
        self.transcription.gradeTranscription()
        
        self.updateUi.enableRecording()
    }
    
    func runUnitTests() throws {
        try self.transcription.runUnitTests()
    }
}
