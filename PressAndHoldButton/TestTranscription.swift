//
//  TestTranscription.swift
//  PressAndHoldButton
//
//  Created by Jason A Faas on 1/25/20.
//  Copyright © 2020 Jason A Faas. All rights reserved.
//

import Foundation

class TestTranscription {
    
    let cut: Transcription!
    let testDbTranslation: DbTranslation
    
    init(_ transcription: Transcription) {
        self.cut = transcription
        self.testDbTranslation = DbTranslation(hanzi: "对不起", pinyin: "duìbùqǐ", english: "I'm sorry", blanks: "")
    }
    
    func testCurrentTranslation(_ letterGrade: SpeakingGrade, logResult: Bool) -> String {
        if logResult {
            return "对不起\nduìbùqǐ\nI'm sorry\nGrade: \(letterGrade.rawValue)\nScheduled: 2005-05-30 11:30 AM -0700"
        } else {
            return "对不起\nduìbùqǐ\nI'm sorry\nGrade: \(letterGrade.rawValue)"
        }
    }
    
    func runUnitTests() throws {
        print("Testing Transcription")
        
        assert(self.cut.putTogetherNestedPinyins([["a","b"],
                                                  ["c"],
                                                  ["d"]]) == ["acd",
                                                              "bcd"])
        assert(self.cut.putTogetherNestedPinyins([["a","b"],[],["d"]]) == [])
        
        assert(self.cut.isTranscriptionCorrect(transcription: "什么",
                                               expected: "什么"))
        assert(!self.cut.isTranscriptionCorrect(transcription: "他受什么",
                                                expected: "她说什么"))
        assert(self.cut.isTranscriptionCorrect(transcription: "他说什么",
                                               expected: "她说什么"))
        assert(self.cut.isTranscriptionCorrect(transcription: "她们对于过敏",
                                               expected: "他们对鱼过敏"))
        assert(self.cut.isTranscriptionCorrect(transcription: "我有10,502个苹果",
                                               expected: "我有10502个苹果"))
        
        assert(self.cut.isTranscriptionCorrect(transcription: "昨天晚上9:30",
                                               expected: "昨天 晚上 9 点 半"))
        assert(self.cut.isTranscriptionCorrect(transcription: "昨天晚上9:30",
                                               expected: "昨天 晚上 9:30"))
        
        assert(!self.cut.isTranscriptionCorrect(transcription: "他女朋友行李",
        expected: "他女朋友姓李"))
        assert(self.cut.isTranscriptionCorrect(transcription: "新年快乐！",
        expected: "新年 快乐"))
        
        self.testFeedbackTextForA()
        self.testFeedbackTextForB()
        self.testFeedbackTextForC()
        self.testFeedbackTextForD()
        self.testFeedbackTextForF()
        self.testFeedbackTextForSayAgain()
    }
    
    func getTestDate() -> Date {
        var dateComponents = DateComponents()
        dateComponents.year = 2005
        dateComponents.month = 5
        dateComponents.day = 30
        dateComponents.timeZone = TimeZone(abbreviation: "EST") // Japan Standard Time
        dateComponents.hour = 14
        dateComponents.minute = 30

        // Create date from components
        let userCalendar = Calendar.current // user calendar
        return userCalendar.date(from: dateComponents)!
    }
    
    func testFeedbackTextForSayAgain() {
        cut.currentTranslation = self.testDbTranslation
        let expected = "Perfect Pronunciation\n\(self.testCurrentTranslation(SpeakingGrade.A, logResult: false))"
        
        let extractedExpr: String = self.cut.getFeedbackTextFromGrade(SpeakingGrade.A, [])
        
        assert(expected == extractedExpr, extractedExpr)
    }
    
    func testFeedbackTextForA() {
        cut.currentTranslation = self.testDbTranslation
        let expected = "Perfect Pronunciation\n\(self.testCurrentTranslation(SpeakingGrade.A, logResult: true))"
        
        let extractedExpr: String = self.cut.getFeedbackTextFromGrade(SpeakingGrade.A, [getTestDate()])
        
        assert(expected == extractedExpr, extractedExpr)
    }
    
    func testFeedbackTextForB() {
        cut.currentTranslation = self.testDbTranslation
        let expected = "Great Pronunciation\n\(self.testCurrentTranslation(SpeakingGrade.B, logResult: true))"
        
        let extractedExpr: String = self.cut.getFeedbackTextFromGrade(SpeakingGrade.B, [getTestDate()])
        
        print("Function: \(#function):\(#line)")
        print(expected)
        print("Function: \(#function):\(#line)")
        print(extractedExpr)
        print("Function: \(#function):\(#line)")
        
        assert(expected == extractedExpr, extractedExpr)
    }
    
    func testFeedbackTextForC() {
        cut.currentTranslation = self.testDbTranslation
        let expected = "Good Pronunciation\n\(self.testCurrentTranslation(SpeakingGrade.C, logResult: true))"
        
        let extractedExpr: String = self.cut.getFeedbackTextFromGrade(SpeakingGrade.C, [getTestDate()])
        assert(expected == extractedExpr, extractedExpr)
    }
    
    func testFeedbackTextForD() {
        
        cut.currentTranslation = self.testDbTranslation
        let expected = "You'll get it next time\n\(self.testCurrentTranslation(SpeakingGrade.D, logResult: true))"
        
        let extractedExpr: String = self.cut.getFeedbackTextFromGrade(SpeakingGrade.D, [getTestDate()])
        assert(expected == extractedExpr, extractedExpr)
    }
    
    func testFeedbackTextForF() {
        
        cut.currentTranslation = self.testDbTranslation
        let expected = "Keep practicing\n\(self.testCurrentTranslation(SpeakingGrade.F, logResult: true))"
        
        let extractedExpr: String = self.cut.getFeedbackTextFromGrade(SpeakingGrade.F, [getTestDate()])
        assert(expected == extractedExpr, extractedExpr)
    }
    
}
