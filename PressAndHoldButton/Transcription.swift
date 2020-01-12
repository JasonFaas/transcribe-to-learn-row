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
    
    let letterGradeMap: Dictionary<Int, String> = [
        0: "A",
        -1: "B",
        -2: "C",
        -3: "D",
    ]
    
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
        
        if self.isTranscriptionCorrect(self.lastTranscription, self.currentTranslation.getHanzi()) {
            self.correctPronunciation()
        } else {
            self.updateUi.enableSkip()
        }
    }
    
    func isTranscriptionCorrect(_ transcription: String, _ expected: String) -> Bool {
        let expectedClean: String = self.cleanUpTranscribed(expected)
        
        if expectedClean.count != transcription.count {
            return false
        } else if transcription == expectedClean {
            return true
        }
        
        for i in 0 ..< transcription.count {
            print("\(transcription[i]) \(expectedClean[i])")
            if transcription[i] != expectedClean[i]
                && !self.dbm.charactersPrimaryPinyinSame(transcription[i],
                                                         expectedClean[i]) {
                    return false
            }
        }
        
        return transcription == expectedClean
    }
    
    func correctPronunciation() {
        self.updateUi.updateFeedbackText("Great Pronunciation:\n\(self.currentTranslation.getHanzi())\n\(self.currentTranslation.getPinyin())\n\(self.currentTranslation.getEnglish())")
        
        var letterGradeNum = 0
        
        if self.attempts > 8 {
            letterGradeNum -= 3
        } else if self.attempts > 4 {
            letterGradeNum -= 2
        } else if self.attempts > 1 {
            letterGradeNum -= 1
        }
        
        if self.updateUi.getPinyinOn() {
            letterGradeNum -= 1
        }
        
        let letterGrade = self.letterGradeMap[letterGradeNum, default: "F"]
            
        self.dbm.logResult(letterGrade: letterGrade,
                           quizInfo: self.currentTranslation,
                           pinyinOn: self.updateUi.pinyinOn,
                           attempts: attempts)
        
        self.advanceToNextPhrase()
    }
    
    func skipCurrentPhrase(grade: String) {
        self.dbm.logResult(letterGrade: grade,
                           quizInfo: self.currentTranslation,
                           pinyinOn: self.updateUi.pinyinOn,
                           attempts: attempts)
        
        if grade == "F" {
            self.updateUi.updateFeedbackText("I know you'll get it next time")
        } else {
            self.updateUi.updateFeedbackText("I know you'll get it next time\n\(self.currentTranslation.getHanzi())\n\(self.currentTranslation.getPinyin())\n\(self.currentTranslation.getEnglish())")
        }
        
        
        
        self.advanceToNextPhrase()
    }

    func advanceToNextPhrase() {
        self.updateUi.disableSkip()
        self.updateUi.pinyinOff()
        self.lastTranscription = ""
        
        self.currentTranslation = self.dbm.getNextPhrase(self.currentTranslation.getId())
                
        self.updateUi.updateQuizScreenWithQuizInfo(quizInfo: self.currentTranslation)
        
        let dueNow: String = "Now\t\(self.dbm.getCountDueTotal())"
        let dueOneHour: String = "1 hour\t\(self.dbm.getCountDueTotal(hoursFromNow: 1))"
        let dueOneDay: String = "1 day\t\(self.dbm.getCountDueTotal(hoursFromNow: 24))"
        self.updateUi.updatePhraseProgress("Due\n\(dueNow)\n\(dueOneHour)\n\(dueOneDay)")
    }
    
    func getCurrentTranslation() -> DbTranslation {
        return currentTranslation
    }
    
    func getCurrentTranscription() -> String {
        return lastTranscription
    }
    
    func runUnitTests() throws {
        try self.dbm.runUnitTests()
        
        assert(!self.isTranscriptionCorrect("他受什么", "她说什么"))
        assert(self.isTranscriptionCorrect("他说什么", "她说什么"))
        assert(self.isTranscriptionCorrect("她们对于过敏", "他们对鱼过敏"))
    }
}
