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
        
        assert(self.cut.isTranscriptionCorrect("什么", "什么"))
        assert(!self.cut.isTranscriptionCorrect("他受什么", "她说什么"))
        assert(self.cut.isTranscriptionCorrect("他说什么", "她说什么"))
        assert(self.cut.isTranscriptionCorrect("她们对于过敏", "他们对鱼过敏"))
    }
    
}
