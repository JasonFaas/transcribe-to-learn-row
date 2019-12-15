//
//  Translation.swift
//  PressAndHoldButton
//
//  Created by Jason A Faas on 11/27/19.
//  Copyright © 2019 Jason A Faas. All rights reserved.
//

import Foundation

class Transcription {
    
    var updateUi: UiUpdate
    
    var lastTranscription: String = ""
    
    var currentTranslation: DbTranslation
    var attempts = 0
    
    var dbm: DatabaseManagement
    
    init(updateUi: UiUpdate) {
        self.updateUi = updateUi
        
        self.dbm = DatabaseManagement()
        self.currentTranslation = self.dbm.getNextPhrase(-1)
        self.updateUi.updateUiWithTranslation(currentTranslation)
    }
    
    func mostRecentTranscription(_ transcribed: String) {
        self.lastTranscription = self.cleanUpTranscribed(transcribed)
        self.updateUi.updateFeedbackText("Listening... \n\(self.lastTranscription)")
    }
    
    func cleanUpTranscribed(_ transcribed: String) -> String {
        var returnMe = transcribed
        let charsToRemove = ["。", "！", "？", " ", "，"]
        
        for charToRemove in charsToRemove {
            returnMe = returnMe.replacingOccurrences(of: charToRemove, with: "")
        }
        
        return returnMe
    }
    
    func gradeTranscription() {
        self.attempts += 1
        
        if self.lastTranscription == self.cleanUpTranscribed(self.currentTranslation.getHanzi()) {
            self.correctPronunciation()
        } else {
            self.updateUi.enableSkip()
        }
    }
    
    func correctPronunciation() {
        self.updateUi.updateFeedbackText("Great Pronunciation:\n\(self.currentTranslation.getHanzi())")
        
        var letterGrade = "A"
        if self.attempts > 8 {
            letterGrade = "D"
        } else if self.attempts > 4 {
           letterGrade = "C"
        } else if self.attempts > 1 {
          letterGrade = "B"
        }
            
        self.dbm.logResult(letterGrade: letterGrade,
                           quizInfo: self.currentTranslation,
                           pinyinOn: self.updateUi.pinyinOn,
                           attempts: attempts)
        
        self.advanceToNextPhrase()
    }
    
    func skipCurrentPhrase() {
        self.dbm.logResult(letterGrade: "F",
                           quizInfo: self.currentTranslation,
                           pinyinOn: self.updateUi.pinyinOn,
                           attempts: attempts)
        
        self.advanceToNextPhrase()
        self.updateUi.updateFeedbackText("I know you'll get it next time")
    }

    func advanceToNextPhrase() {
        self.updateUi.disableSkip()
        self.updateUi.pinyinOff()
        self.lastTranscription = ""
        
        self.currentTranslation = self.dbm.getNextPhrase(self.currentTranslation.getId())
                
        self.updateUi.updateQuizScreenWithQuizInfo(quizInfo: self.currentTranslation)
    }
    
    func runUnitTests() throws {
        try self.dbm.runUnitTests()
    }
}
