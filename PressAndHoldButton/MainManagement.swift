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
    var sayAgainHTRButton: UIButton
    var sayInZwHTRButton: UIButton
    
    init(feedbackLabel: UILabel,
         toPronounceHanzi: UILabel,
         toPronouncePinyin: UILabel,
         sayInZwHTRButton: UIButton,
         skipThis: UIButton,
         pinyinToggleButton: UIButton,
         dueProgress: UILabel,
         quickStartDbmHold: DatabaseManagement!,
         quickStartNextLangDispHold: String!,
         sayAgainHTRButton: UIButton) {
        self.updateUi = UiUpdate(
            feedbackLabel: feedbackLabel,
            toPronounceHanzi: toPronounceHanzi,
            toPronouncePinyin: toPronouncePinyin,
            sayInZwHTRButton: sayInZwHTRButton,
            skipThis: skipThis,
            pinyinToggleButton: pinyinToggleButton,
            dueProgress: dueProgress,
            sayAgainHTRButton: sayAgainHTRButton
        )
        self.sayAgainHTRButton = sayAgainHTRButton
        self.sayInZwHTRButton = sayInZwHTRButton
        self.transcription = Transcription(updateUi: self.updateUi,
                                           quickStartDbmHold: quickStartDbmHold,
                                           quickStartNextLangDispHold: quickStartNextLangDispHold)
        self.recording = Recording(translation: transcription)
    }
    
    func skipThisPress(grade: SpeakingGrade) {
        self.transcription.skipCurrentPhrase(grade: grade)
        self.updateUi.enableRecording(self.sayAgainHTRButton)
        self.updateUi.enableRecording(self.sayInZwHTRButton)
    }
    
    func pinyinToggle() {
        self.updateUi.pinyinToggle()
    }
    
    func fullStartRecording(_ sender: UIButton) {
        self.updateUi.disableRecordingButtons()
        // TODO: Update Say in Mandarin to previous
        self.updateUi.updateFeedbackText("Listening...")
        
        do {
            try self.recording._startRecording()
        } catch {
            self.recording._finishRecording()
            self.updateUi.addToFeedbackText("\nUnable to transcribe at this time.")

            print("Function: \(#file):\(#line), Error: \(error)")
        }
    }
    
    func fullFinishRecording(_ sender: UIButton) {
        self.updateUi.addToFeedbackText("\nComplete")
        
        self.recording._finishRecording()
        
        self.transcription.gradeTranscription()
        
        self.updateUi.enableRecording(sender)
    }
    
    func getCurrentTranslation() -> DbTranslation {
        return transcription.getCurrentTranslation()
    }
    
    func getCurrentTranscription() -> String {
        return transcription.getCurrentTranscription()
    }
    
    func runUnitTests() throws {
        try self.transcription.runUnitTests()
    }
}
