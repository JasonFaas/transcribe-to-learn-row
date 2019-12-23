//
//  FillInBlanks.swift
//  PressAndHoldButton
//
//  Created by Jason A Faas on 12/22/19.
//  Copyright © 2019 Jason A Faas. All rights reserved.
//

import Foundation

class FillInBlanks {
    
    let transcription: DbTranslation!
    let blanksDictionary: Dictionary<Int, DbTranslation> = [:]
    
    init(translation: DbTranslation) {
        self.translation = translation
    }
    
    func processBlanks() {
        // TODO: Identify blanks
        
        // TODO: call setHanzi
        
        // TODO: call setPinyin
        
        // TODO: call setEnglish
    }
    
    func updateDbTranslation() {
        
    }
    
    func set
    
    func runUnitTests() {
        let translation = DbTranslation()
        translation.setEnglish("I am {1:number:21-41} years old")
        translation.setPinyin("wǒ jīnnián {1:number:21-41} suì")
        translation.setHanzi("我今年{1:number:21-41}岁")
        
        test_fib = FillInBlanks(translation: translation)
        test_fib.processBlanks()
        test_fib.updateDbTranslation()
        assert translation.getEnglish() == "I am 33 years old"
        assert translation.getHanzi() == "wǒ jīnnián 33 suì"
        assert translation.getPinyin() == "我今年33岁"
        
    }
}
