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
    
    func testCurrentTranslation(_ letterGrade: SpeakingGrade) -> String {
        return "对不起\nduìbùqǐ\nI'm sorry\nGrade: \(letterGrade.rawValue)\nScheduled: 2005-05-30 11:30 -0700"
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
        
        self.testFeedbackTextForA()
        self.testFeedbackTextForB()
        self.testFeedbackTextForC()
        self.testFeedbackTextForD()
        self.testFeedbackTextForF()
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
    
    func testFeedbackTextForA() {
        cut.currentTranslation = self.testDbTranslation
        let expected = "Perfect Pronunciation\n\(self.testCurrentTranslation(SpeakingGrade.A))"
        
        let extractedExpr: String = self.cut.getFeedbackTextFromGrade(SpeakingGrade.A, [getTestDate()]) // TODO: Have to hardcode this
        
        assert(expected == extractedExpr, extractedExpr)
    }
    
    func testFeedbackTextForB() {
        cut.currentTranslation = self.testDbTranslation
        let expected = "Great Pronunciation\n\(self.testCurrentTranslation(SpeakingGrade.B))"
        
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
        let expected = "Good Pronunciation\n\(self.testCurrentTranslation(SpeakingGrade.C))"
        
        let extractedExpr: String = self.cut.getFeedbackTextFromGrade(SpeakingGrade.C, [getTestDate()]) // TODO: Have to hardcode this
        assert(expected == extractedExpr, extractedExpr)
    }
    
    func testFeedbackTextForD() {
        
        cut.currentTranslation = self.testDbTranslation
        let expected = "You'll get it next time\n\(self.testCurrentTranslation(SpeakingGrade.D))"
        
        let extractedExpr: String = self.cut.getFeedbackTextFromGrade(SpeakingGrade.D, [getTestDate()]) // TODO: Have to hardcode this
        assert(expected == extractedExpr, extractedExpr)
    }
    
    func testFeedbackTextForF() {
        
        cut.currentTranslation = self.testDbTranslation
        let expected = "Keep practicing\n\(self.testCurrentTranslation(SpeakingGrade.F))"
        
        let extractedExpr: String = self.cut.getFeedbackTextFromGrade(SpeakingGrade.F, [getTestDate()]) // TODO: Have to hardcode this
        assert(expected == extractedExpr, extractedExpr)
    }
    
}
