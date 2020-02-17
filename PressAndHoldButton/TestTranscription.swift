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
    
    init(_ transcription: Transcription) {
        self.cut = transcription
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
    
    func testFeedbackTextForA() {
        let expected = ""
        let extractedExpr: String = self.cut.getFeedbackTextFromGrade(SpeakingGrade.A)
        assert(expected == extractedExpr, extractedExpr)
    }
    
    func testFeedbackTextForB() {
        let expected = ""
        assert(expected == self.cut.getFeedbackTextFromGrade(SpeakingGrade.B))
    }
    
    func testFeedbackTextForC() {
        let expected = ""
        assert(expected == self.cut.getFeedbackTextFromGrade(SpeakingGrade.C))
    }
    
    func testFeedbackTextForD() {
        let expected = ""
        assert(expected == self.cut.getFeedbackTextFromGrade(SpeakingGrade.D))
    }
    
    func testFeedbackTextForF() {
        let expected = ""
        assert(expected == self.cut.getFeedbackTextFromGrade(SpeakingGrade.F))
    }
    
}
