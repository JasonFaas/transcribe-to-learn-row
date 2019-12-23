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
        self.populateBlanksDictionary()
        
        // TODO: call setHanzi
        
        // TODO: call setPinyin
        
        // TODO: call setEnglish
    }
    
    func updateDbTranslation() {
        
    }
    
    func getDictionaryParts(_ stringParts: String) -> [String] {
        
        var returnList: [String] = []
        
        var newPhrase: Substring = stringParts[stringParts.startIndex..<stringParts.endIndex]
        while newPhrase.contains("{") {
            print(String(newPhrase))
            let openIndex: String.Index = newPhrase.firstIndex(of: "{")!
            let closeIndex: String.Index = newPhrase.firstIndex(of: "}")!
            let closePlusOne = newPhrase.index(closeIndex, offsetBy: 1)
            let json: String = String(newPhrase[openIndex...closeIndex])
            returnList.append(json)
            
            newPhrase = newPhrase[closePlusOne...]
            print(String(newPhrase))
        }
        
        return returnList
    }
    
    func populateBlanksDictionary() {
        let blankParts: [String] = self.getDictionaryParts(self.dbTranslation.getHanzi())
    }
    
    func getBlanksDictionary() -> Dictionary<Int, DbTranslation> {
        return self.blanksDictionary
    }
    
    func getRefDict(_ refDict: String) -> Dictionary<String, String> {
        var refWithQuotes = refDict.replacingOccurrences(of: "(\\w+)", with: "\"$1\"", options: .regularExpression)
        print(refWithQuotes)
        
        let empty: Dictionary<String, String> = [:]
        
        if let returnDict = refWithQuotes.data(using: .utf8) {
            do {
                return try (JSONSerialization.jsonObject(with: returnDict, options: []) as? [String: String])!
            } catch {
                print(error.localizedDescription)
            }
        }
        
        return empty
    }
    
    
    
    func runUnitTests() {
        self.testJsonBlankToDict()
        self.testBlanksToJson()
        self.testPopulateBlanksDictNumber()
        self.testPopulateBlanksDictFromDb()
        self.testPopulateBlanksDictFromDbNested()
        self.testFillInBlanksFromDict()
    }
    
    func testJsonBlankToDict() {
        let test_fib = FillInBlanks(dbTranslation: DbTranslation())
        
        let individualDict: Dictionary<String, String> = test_fib.getRefDict("{ref:1,type:int,min:21,max:22}")
        
        assert(individualDict["ref"] == "1")
        assert(individualDict["type"] == "int")
        assert(individualDict["min"] == "21")
        assert(individualDict["max"] == "22")
    }
    
    func testBlanksToJson() {
        let dbTranslation = DbTranslation()
        dbTranslation.setHanzi("我今年{ref:1,type:int,min:21,max:22}岁{ref:2,type:int,min:1950,max:1950}WHAT")
        let test_fib = FillInBlanks(dbTranslation: dbTranslation)
        test_fib.populateBlanksDictionary()
        let blanksDict: Dictionary<Int, DbTranslation> = test_fib.getBlanksDictionary()
        
        assert(blanksDict[1]?.getHanzi() == "21" || blanksDict[1]?.getHanzi() == "22")
        assert(blanksDict[2]?.getPinyin() == "1950")
        
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
