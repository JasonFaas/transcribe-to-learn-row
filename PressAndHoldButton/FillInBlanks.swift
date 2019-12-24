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
    var blanksDictionary: Dictionary<Int, Dictionary<String, String>> = [:]
    
    init(dbTranslation: DbTranslation) {
        self.dbTranslation = dbTranslation
    }
    
    func fillBlanks(phrase: String, howTo: String) -> String {
        
        var newPhrase: Substring = phrase[phrase.startIndex..<phrase.endIndex]
        while newPhrase.contains("{") {
            let openIndex: String.Index = newPhrase.firstIndex(of: "{")!
            let closeIndex: String.Index = newPhrase.firstIndex(of: "}")!
            let closePlusOne = newPhrase.index(closeIndex, offsetBy: 1)
            let json: String = String(newPhrase[openIndex...closeIndex])
            
            let refDict: Dictionary<String, String> = getRefDict(json)
            let refStr: String! = refDict["ref"]
            
            let what = blanksDictionary[Int(refStr)!]
            let toFillIn: String! = what![howTo]
            
            newPhrase = newPhrase[..<openIndex] + toFillIn + newPhrase[closePlusOne...]
        }
        
        print(String(newPhrase))
        return String(newPhrase)
    }
    
    func processBlanks() {
        // TODO: Identify blanks
        self.populateBlanksDictionary()
        
        // TODO: call setHanzi
        var blanksFilledIn = self.fillBlanks(phrase: dbTranslation.getHanzi(),
                                             howTo: "hanzi")
        dbTranslation.setHanzi(blanksFilledIn)
        
        // TODO: call setPinyin
        blanksFilledIn = self.fillBlanks(phrase: dbTranslation.getPinyin(),
                                             howTo: "pinyin")
        dbTranslation.setPinyin(blanksFilledIn)
        
        // TODO: call setEnglish
        blanksFilledIn = self.fillBlanks(phrase: dbTranslation.getEnglish(),
                                             howTo: "english")
        dbTranslation.setEnglish(blanksFilledIn)
    }
    
    func updateDbTranslation() {
        
    }
    
    func getDictionaryParts(_ stringParts: String) -> [String] {
        
        var returnList: [String] = []
        
        var newPhrase: Substring = stringParts[stringParts.startIndex..<stringParts.endIndex]
        while newPhrase.contains("{") {
            let openIndex: String.Index = newPhrase.firstIndex(of: "{")!
            let closeIndex: String.Index = newPhrase.firstIndex(of: "}")!
            let closePlusOne = newPhrase.index(closeIndex, offsetBy: 1)
            let json: String = String(newPhrase[openIndex...closeIndex])
            returnList.append(json)
            
            newPhrase = newPhrase[closePlusOne...]
        }
        
        return returnList
    }
    
    func populateBlanksDictionary() {
        let blankParts: [String] = self.getDictionaryParts(self.dbTranslation.getHanzi())
        
        for what in blankParts {
            print(what)
            let refDict: Dictionary<String, String> = getRefDict(what)
            let refVal: String! = refDict["ref"]
            
            
            let refType: String! = refDict["type"]
            if refType == "int" {
                let minString: String! = refDict["min"]
                let minVal: Int! = Int(minString)
                let maxString: String! = refDict["max"]
                let maxVal: Int! = Int(maxString)
                
                let resultVal: String = String(Int.random(in: minVal...maxVal))
                
                self.blanksDictionary[Int(refVal)!] = ["hanzi": resultVal,
                                                       "pinyin": resultVal,
                                                       "english": resultVal]
            } else {
                getRandomRowFromSpecified(refType) //TODO: How to get this?
                
                let resultVal: String = "Type Error"
                self.blanksDictionary[Int(refVal)!] = ["hanzi": resultVal,
                "pinyin": resultVal,
                "english": resultVal]
            }
        }
    }
    
    func getBlanksDictionary() -> Dictionary<Int, Dictionary<String, String>> {
        return self.blanksDictionary
    }
    
    func getRefDict(_ refDict: String) -> Dictionary<String, String> {
        var refWithQuotes = refDict.replacingOccurrences(of: "(\\w+)", with: "\"$1\"", options: .regularExpression)
        
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
        self.testBlanksToJsonNumber()
        self.testBlanksToJsonInDatabase()
        self.testBlanksToJsonInDatabaseFk()
        self.testPopulateBlanksDictNumber()
    }
    
    func testJsonBlankToDict() {
        let test_fib = FillInBlanks(dbTranslation: DbTranslation())
        
        let individualDict: Dictionary<String, String> = test_fib.getRefDict("{ref:1,type:int,min:21,max:22}")
        
        assert(individualDict["ref"] == "1")
        assert(individualDict["type"] == "int")
        assert(individualDict["min"] == "21")
        assert(individualDict["max"] == "22")
    }
    
    func testBlanksToJsonNumber() {
        let dbTranslation = DbTranslation()
        dbTranslation.setHanzi("我今年{ref:1,type:int,min:21,max:22}岁{ref:2,type:int,min:1950,max:1950}WHAT")
        let test_fib = FillInBlanks(dbTranslation: dbTranslation)
        test_fib.populateBlanksDictionary()
        let blanksDict: Dictionary<Int, Dictionary<String, String>> = test_fib.getBlanksDictionary()
        
        assert(blanksDict[1]?["hanzi"] == "21" || blanksDict[1]?["english"] == "22")
        assert(blanksDict[2]?["pinyin"] == "1950")
    }
    
    func testBlanksToJsonInDatabase() {
        let dbTranslation = DbTranslation()
        dbTranslation.setHanzi("{ref:1,type:country_person_name}")
        let test_fib = FillInBlanks(dbTranslation: dbTranslation)
        test_fib.populateBlanksDictionary()
        let blanksDict: Dictionary<Int, Dictionary<String, String>> = test_fib.getBlanksDictionary()
        
        print(blanksDict[1]?["hanzi"])
        assert(blanksDict[1]?["hanzi"] == "中国人" || blanksDict[1]?["english"] == "American")
    }
    
    func testBlanksToJsonInDatabaseFk() {
        let dbTranslation = DbTranslation()
        dbTranslation.setHanzi("{ref:1,type:food_type}{ref:2,type:food,fk_ref:1}")
        let test_fib = FillInBlanks(dbTranslation: dbTranslation)
        test_fib.populateBlanksDictionary()
        let blanksDict: Dictionary<Int, Dictionary<String, String>> = test_fib.getBlanksDictionary()
        
        if blanksDict[1]?["hanzi"] == "水果" {
            assert(blanksDict[2]?["hanzi"] == "苹果" || blanksDict[2]?["english"] == "banana")
        } else if blanksDict[1]?["english"] == "vegetable" {
            assert(blanksDict[2]?["hanzi"] == "西红柿" || blanksDict[2]?["english"] == "corn")
        } else {
            assert(false)
        }
        
    }
    
    func testPopulateBlanksDictNumber() {
        let hanzi = "我今年{ref:1,type:int,min:33,max:33}岁"
        let pinyin = "wǒ jīnnián {ref:1,type:int,min:33,max:33} suì"
        let english = "I am {ref:1,type:int,min:33,max:33} years old"
        let testTranslation = DbTranslation(hanzi: hanzi,
                                        pinyin: pinyin,
                                        english: english)
        let test_fib = FillInBlanks(dbTranslation: testTranslation)
        test_fib.processBlanks()

        print(testTranslation.getEnglish())
        assert(testTranslation.getEnglish() == "I am 33 years old")
        assert(testTranslation.getPinyin() == "wǒ jīnnián 33 suì")
        assert(testTranslation.getHanzi() == "我今年33岁")
    }
}
