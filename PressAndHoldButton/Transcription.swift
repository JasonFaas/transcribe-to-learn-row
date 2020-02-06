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
    
    init(updateUi: UiUpdate,
         quickStartDbmHold: DatabaseManagement!,
         quickStartNextLangDispHold: String!) {
        self.updateUi = updateUi
        
        if quickStartDbmHold == nil {
            self.dbm = DatabaseManagement()
        } else {
            self.dbm = quickStartDbmHold
        }
        
        let firstLangDisp: String!
        if quickStartNextLangDispHold == nil {
            firstLangDisp = LanguageDisplayed.MandarinSimplified.rawValue
        } else {
            firstLangDisp = quickStartNextLangDispHold
        }
        
        self.currentTranslation = self.dbm.getNextPhrase(tTableName: DbTranslation.tableName,
                                                         dispLang: firstLangDisp)
        self.updateUi.updateQuizScreenWithQuizInfo(quizInfo: currentTranslation)
    }
    
    func mostRecentTranscription(_ transcribed: String) {
        //TODO: Delete legacy if new lastTranscription paradigm working
//        self.lastTranscription = self.cleanUpTranscribed(transcribed)
        
        self.lastTranscription = transcribed
        self.updateUi.updateFeedbackText("Listening... \n\(self.lastTranscription)")
    }
    
    func gradeTranscription() {
        self.attempts += 1
        
        if self.isTranscriptionCorrect(
            transcription: self.lastTranscription,
            expected: self.currentTranslation.getHanzi()) {
            self.correctPronunciation()
        } else {
            self.updateUi.enableSkip()
        }
    }
    
    func isTranscriptionCorrect(transcription: String, expected: String) -> Bool {
        let expectedClean: String = expected.withoutPunctuationAndSpaces()
        let transcriptionClean: String = transcription.withoutPunctuationAndSpaces()
        
        let areLengthsDifferent: Bool = expectedClean.count != transcriptionClean.count
        if areLengthsDifferent {
            return false
        }
        let areStringsSame: Bool = transcriptionClean == expectedClean
        if areStringsSame {
            return true
        }
        
        for i in 0 ..< transcriptionClean.count {
            if transcriptionClean[i] == expectedClean[i] {
                continue
            } else if !self.dbm.arePinyinSame(transcriptionClean[i],
                                              expectedClean[i]) {
                var charsAreSame: Bool = false
                
                for length in 2...2 {
                    for mod in (-1 * length + 1)...0 {
                        if i+mod < 0 || i+mod+length > transcriptionClean.count {
                            continue
                        }
                        let extraRange: Range<Int> = i+mod..<i+mod+length
                        let transcriptionPinyins: [String] = self.dbm.getHskPinyins(transcriptionClean[extraRange])
                        
                        var expectedPinyins: [String] = self.dbm.getHskPinyins(expectedClean[extraRange])
                        
                        var moreExpectedPinyins: [[String]] = []
                        for i in 0..<length {
                            moreExpectedPinyins.append(self.dbm.getHskPinyins(expectedClean[extraRange][i]))
                        }
                        expectedPinyins += self.putTogetherNestedPinyins(moreExpectedPinyins)
                        
                        

                        let uniqueSet = Set(transcriptionPinyins + expectedPinyins)
                        if uniqueSet.count < transcriptionPinyins.count + expectedPinyins.count {
                            charsAreSame = true
                            break
                        }
                    }
                    if charsAreSame {
                        break
                    }
                }
                if charsAreSame {
                    continue
                }
                
                return false
            }
        }
        
        return true
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
        
        let tTableName = DbTranslation.tableName
        
        self.currentTranslation = self.dbm.getNextPhrase(tTableName: tTableName,
                                                         idExclude: self.currentTranslation.getId(),
                                                         dispLang: currentTranslation.getLanguageToDisplay() == LanguageDisplayed.English.rawValue ? LanguageDisplayed.MandarinSimplified.rawValue : LanguageDisplayed.English.rawValue)
                
        self.updateUi.updateQuizScreenWithQuizInfo(quizInfo: self.currentTranslation)
        
        let dueNow: String = "Now\t\(self.dbm.getCountDueTotal(tTableName: tTableName))"
        let dueOneHour: String = "1 hour\t\(self.dbm.getCountDueTotal(tTableName: tTableName, hoursFromNow: 1))"
        let dueOneDay: String = "1 day\t\(self.dbm.getCountDueTotal(tTableName: tTableName, hoursFromNow: 24))"
        self.updateUi.updatePhraseProgress("Due\n\(dueNow)\n\(dueOneHour)\n\(dueOneDay)")
    }
    
    func getCurrentTranslation() -> DbTranslation {
        return currentTranslation
    }
    
    func getCurrentTranscription() -> String {
        return lastTranscription
    }
    
    func putTogetherNestedPinyins(_ nesting: [[String]], _ startPoint: Int = 0) -> [String] {
        if startPoint + 1 == nesting.count {
            return nesting[startPoint]
        }
            
        var returnList: [String] = []
        for what in nesting[startPoint] {
            let furtherNest:[String] = putTogetherNestedPinyins(nesting, startPoint + 1)
            for how in furtherNest {
                returnList.append(what + how)
            }
        }

        return returnList
    }
    
    func runUnitTests() throws {
        try TestDbManagement(dbm).runUnitTests()
        try TestTranscription(self).runUnitTests()
    }
}
