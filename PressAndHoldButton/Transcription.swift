//
//  Translation.swift
//  PressAndHoldButton
//
//  Created by Jason A Faas on 11/27/19.
//  Copyright © 2019 Jason A Faas. All rights reserved.
//

import UIKit
import Foundation

class Transcription {
    
    var updateUi: UiUpdate
    
    let sayAgainHTRButton: UIButton
    let sayInZwHTRButton: UIButton
    
    var lastTranscription: String = ""
    
    var currentTranslation: DbTranslation
    var previousTranslation: DbTranslation
    var attempts = 0
    
    
    var dbm: DatabaseManagement
    
    var langPref: [String:Bool]
    
    var pinyinDefaultOn: Bool
    
    // TODO: This should probably go away?
    let letterGradeMap: Dictionary<Int, SpeakingGrade> = [
        0: SpeakingGrade.A,
        -1: SpeakingGrade.B,
        -2: SpeakingGrade.C,
        -3: SpeakingGrade.D,
    ]
    
    init(updateUi: UiUpdate,
         quickStartDbmHold: DatabaseManagement!,
         quickStartNextLangDispHold: String!,
         sayAgainHTRButton: UIButton,
         sayInZwHTRButton: UIButton) {
        self.updateUi = updateUi
        
        self.sayAgainHTRButton = sayAgainHTRButton
        self.sayInZwHTRButton = sayInZwHTRButton
        
        if quickStartDbmHold == nil {
            self.dbm = DatabaseManagement()
        } else {
            self.dbm = quickStartDbmHold
        }
        
        self.langPref = [
            DbSettings.settingEnglish: dbm.getSetting(DbSettings.settingEnglish),
            DbSettings.settingMandarinSimplified: dbm.getSetting(DbSettings.settingMandarinSimplified),
        ]
        
        self.pinyinDefaultOn = dbm.getSetting(DbSettings.settingPinyinDefaultOn)
        if !pinyinDefaultOn {
            self.updateUi.pinyinOff()
        } else {
            self.updateUi.pinyinToOn()
        }
        
        self.currentTranslation = self.dbm.getNextPhrase(
            tTableName: DbTranslation.tableName,
            dispLang: Transcription.getLangToDisplayNext(
                currLangDisp: nil,
                quickStartNextLangDispHold: quickStartNextLangDispHold,
                langPref: langPref
            )
        )
        self.previousTranslation = self.currentTranslation
        self.updateUi.updateQuizScreenWithQuizInfo(quizInfo: currentTranslation)
    }
    
    func mostRecentTranscription(_ transcribed: String) {
        self.lastTranscription = transcribed
        self.updateUi.updateFeedbackText("Listening... \n\(self.lastTranscription)")
    }
    
    func gradeTranscription(logResult: Bool) {
        self.attempts += 1
        
        if self.isTranscriptionCorrect(
            transcription: self.lastTranscription,
            expected: self.currentTranslation.getHanzi()) {
            print("Function: \(#function):\(#line) Corret")
            self.correctPronunciation(logResult: logResult)
        } else {
            print("Function: \(#function):\(#line) Incorrect")
            self.updateUi.enableSkip()
        }
    }
    
    func isTranscriptionCorrect(transcription: String, expected: String) -> Bool {
        var expectedClean: String = expected.withoutPunctuationAndSpaces()
        var transcriptionClean: String = transcription.withoutPunctuationAndSpaces()
        
        expectedClean = expectedClean.timeColocialToRomanNumeralInPlace()
        transcriptionClean = transcriptionClean.timeColocialToRomanNumeralInPlace()
        
        let areLengthsDifferent: Bool = expectedClean.count != transcriptionClean.count
        if areLengthsDifferent {
            return false
        }
        let areStringsSame: Bool = transcriptionClean == expectedClean
        if areStringsSame {
            return true
        }
        
        let arePinyinEqual = arePinyinSame(transcriptionClean: transcriptionClean, expectedClean: expectedClean)
        return arePinyinEqual
    }
    
    func arePinyinSame(transcriptionClean: String, expectedClean: String) -> Bool {
        
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
    
    func correctPronunciation(logResult: Bool) {
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
        
        let letterGrade = self.letterGradeMap[letterGradeNum, default: SpeakingGrade.F]
        
        let dates: [Date]
        if logResult {
            dates = self.dbm.logResult(
                letterGrade: letterGrade,
                quizInfo: self.currentTranslation,
                pinyinOn: self.updateUi.pinyinOn,
                attempts: attempts
            )
        } else {
            dates = []
        }
        
        self.updateUi.updateFeedbackText(
            getFeedbackTextFromGrade(letterGrade, dates)
        )
        
        self.advanceToNextPhrase()
    }
    
    func skipCurrentPhrase(grade: SpeakingGrade, logResult: Bool) {
        var dates: [Date] = []
        if logResult {
            dates = self.dbm.logResult(
                letterGrade: grade,
                quizInfo: self.currentTranslation,
                pinyinOn: self.updateUi.pinyinOn,
                attempts: attempts
            )
        }
        
        self.updateUi.updateFeedbackText(getFeedbackTextFromGrade(grade, dates))
        
        self.advanceToNextPhrase()
    }
    
    func getFeedbackTextFromGrade(_ grade: SpeakingGrade, _ dates: [Date]) -> String {
        let translationInfo = "\(self.currentTranslation.getHanzi())\n\(self.currentTranslation.getPinyin())\n\(self.currentTranslation.getEnglish())"
        
        let gradeStuff: String = "Grade: \(grade.rawValue)"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd h:mm a Z"
        dateFormatter.timeZone = NSTimeZone(abbreviation: TimeZone.current.abbreviation() ?? "") as TimeZone?
        
        let dateStuff: String
        if dates.count > 0 {
            let stringDate = dateFormatter.string(from: dates[0])
            dateStuff = "\nScheduled: \(stringDate)"
        } else {
            dateStuff = ""
        }
        
        let gradeToFeedback: [SpeakingGrade: String] = [
            SpeakingGrade.A: "Perfect Pronunciation",
            SpeakingGrade.B: "Great Pronunciation",
            SpeakingGrade.C: "Good Pronunciation",
            SpeakingGrade.D: "You'll get it next time",
            SpeakingGrade.F: "Keep practicing",
            SpeakingGrade.New: "New grade for this",
        ]
        
        let feedback = gradeToFeedback[grade, default: "grade feedback error"]
            
        return "\(feedback)\n\(translationInfo)\n\(gradeStuff)\(dateStuff)"
    }

    static func getLangToDisplayNext(currLangDisp: String?,
                                     quickStartNextLangDispHold: String?,
                                     langPref: [String:Bool]) -> String {
        if !(langPref[DbSettings.settingEnglish] ?? true) {
            return LanguageDisplayed.MandarinSimplified.rawValue
        } else if !(langPref[DbSettings.settingMandarinSimplified] ?? true) {
            return LanguageDisplayed.English.rawValue
        }
        
        if currLangDisp != nil {
            return currLangDisp == LanguageDisplayed.English.rawValue ? LanguageDisplayed.MandarinSimplified.rawValue : LanguageDisplayed.English.rawValue
        } else if quickStartNextLangDispHold != nil {
            return quickStartNextLangDispHold!
        } else {
            return LanguageDisplayed.MandarinSimplified.rawValue
        }
    }
    
    func advanceToNextPhrase() {
        self.updateUi.disableSkip()
        if !pinyinDefaultOn {
            self.updateUi.pinyinOff()
        } else {
            self.updateUi.pinyinToOn()
        }
        self.lastTranscription = ""
        self.attempts = 0
        
        let tTableName = DbTranslation.tableName
        self.previousTranslation = self.currentTranslation
        self.currentTranslation = self.dbm.getNextPhrase(tTableName: tTableName,
                                                         idExclude: self.currentTranslation.getId(),
                                                         dispLang: Transcription.getLangToDisplayNext(currLangDisp: self.currentTranslation.getLanguageToDisplay(), quickStartNextLangDispHold: nil,
                                                                                                      langPref: self.langPref))
                
        self.updateUi.updateQuizScreenWithQuizInfo(quizInfo: self.currentTranslation)
        
        let dueNow: String = "Now\t\(self.dbm.getCountDueTotal(tTableName: tTableName))"
        let dueOneHour: String = "1 hour\t\(self.dbm.getCountDueTotal(tTableName: tTableName, hoursFromNow: 1))"
        let dueOneDay: String = "1 day\t\(self.dbm.getCountDueTotal(tTableName: tTableName, hoursFromNow: 24))"
        self.updateUi.updatePhraseProgress("Due\n\(dueNow)\n\(dueOneHour)\n\(dueOneDay)")

        self.updateUi.enableRecording(self.sayAgainHTRButton)
        self.updateUi.enableRecording(self.sayInZwHTRButton)
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
    
    func updateUiWithPrevious() {
        self.currentTranslation = self.previousTranslation
        self.updateUi.updateQuizScreenWithQuizInfo(quizInfo: self.currentTranslation)
    }
    
    func runUnitTests() throws {
        try TestDbManagement(dbm).runUnitTests()
        try TestTranscription(self).runUnitTests()
    }
}
