//
//  FillInBlanks.swift
//  PressAndHoldButton
//
//  Created by Jason A Faas on 12/22/19.
//  Copyright © 2019 Jason A Faas. All rights reserved.
//

import Foundation

class FillInBlanks {
    
    let dbTranslation: DbTranslation!
    let blanksDictionary: Dictionary<Int, DbTranslation> = [:]
    
    init(dbTranslation: DbTranslation) {
        self.dbTranslation = dbTranslation
    }
    
    func processBlanks() {
        // TODO: Identify blanks
//        populateBlanksDictionary()
        
        // TODO: call setHanzi
        
        // TODO: call setPinyin
        
        // TODO: call setEnglish
    }
    
    func updateDbTranslation() {
        
    }
    
    func runUnitTests() {
        self.testBlanksToJson()
        self.testPopulateBlanksDictNumber()
        self.testPopulateBlanksDictFromDb()
        self.testPopulateBlanksDictFromDbNested()
        self.testFillInBlanksFromDict()
    }
    
    func testBlanksToJson() {
        assert(false)
    }
    
    func testPopulateBlanksDictFromDb() {
        assert(false)
    }
    
    func testPopulateBlanksDictFromDbNested() {
        assert(false)
    }
    
    func testFillInBlanksFromDict() {
        assert(false)
    }
    
    func testPopulateBlanksDictNumber() {
        assert(false)
//        let translation = DbTranslation()
//        translation.setHanzi("我今年{ref:1,type:int,min:21-41}岁{ref:2,type:int,min:1950,max:1999}")
//        test_fib = FillInBlanks(translation: translation)
//        test_fib.populateBlanksDictionary()
//
//        let testDict: Dictionary<Int, DbTranslation> = test_fib.getBlanksDictionary()
//        assert testDict['1'] ==
//        assert translation.getEnglish() == "I am 33 years old"
//        assert translation.getHanzi() == "wǒ jīnnián 33 suì"
//        assert translation.getPinyin() == "我今年33岁"
    }
}
