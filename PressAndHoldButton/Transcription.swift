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
    
    var dbm: DatabaseManagement
    
    init(updateUi: UiUpdate) {
        self.updateUi = updateUi
        
        self.dbm = DatabaseManagement()
        self.currentTranslation = self.dbm.getEasiestUnansweredRowFromTranslations(-1)
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
        if self.lastTranscription == self.cleanUpTranscribed(self.currentTranslation.getHanzi()) {
            self.perfectResult()
        } else {
            self.updateUi.enableSkip()
        }
    }
    
    func perfectResult() {
        self.updateUi.updateFeedbackText("Great Pronunciation:\n\(self.currentTranslation.getHanzi())")
        
        self.advanceToNextPhrase(letterGrade: "A")
        
        self.updateUi.disableSkip()
        self.dbm.printAllResultsTable()
    }
    
    func skipCurrentPhrase() {
        
        self.advanceToNextPhrase(letterGrade: "F")
        self.updateUi.updateFeedbackText("I know you'll get it next time")
    }

    func advanceToNextPhrase(letterGrade: String) {
        // log info
        self.dbm.logResult(letterGrade: letterGrade,
                           quizInfo: self.currentTranslation,
                           pinyinOn: self.updateUi.pinyinOn)
        
        self.currentTranslation = self.dbm.getEasiestUnansweredRowFromTranslations(self.currentTranslation.getId())
        
        self.updateUi.updateQuizScreenWithQuizInfo(quizInfo: self.currentTranslation)
        
        self.dbm.printAllResultsTable()
    }
    
    func runUnitTests() throws {
        try self.dbm.runUnitTests()
    }
}
