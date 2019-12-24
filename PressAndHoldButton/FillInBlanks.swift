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
    let dbm: DatabaseManagement!
    var blanksDictionary: Dictionary<Int, Dictionary<String, String>> = [:]
    
    init(dbTranslation: DbTranslation, dbm: DatabaseManagement) {
        self.dbTranslation = dbTranslation
        self.dbm = dbm
    }
    
    func fillBlanks(phrase: String, howTo: String) -> String {
        print(phrase)
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
                
                self.blanksDictionary[Int(refVal)!] = [
                    "hanzi": resultVal,
                    "pinyin": resultVal,
                    "english": resultVal,
                    "tableName": refType,
                    "db_id":"-1",
                ]
            } else {
                do {
                    let reference:DbTranslation!
                    if let fk_ref = refDict["fk_ref"] {
                        print("VAL: \(fk_ref)")
                        
                        let whatWhat: Dictionary<String, String>! = self.blanksDictionary[Int(fk_ref)!]
                        let fk_str: String! = whatWhat["db_id"]
                        let fk_val: Int! = Int(fk_str)
                        
                        
                        print("TRYING HERE")
                        reference = try self.dbm.getRandomRowFromSpecified(database: refType, fk_ref: fk_val)
                    } else {
                        print("STILL TRYING")
                        reference = try self.dbm.getRandomRowFromSpecified(database: refType, fk_ref: -1)
                    }
                    
                    self.blanksDictionary[Int(refVal)!] = [
                        "hanzi": reference.getHanzi(),
                        "pinyin": reference.getPinyin(),
                        "english": reference.getEnglish(),
                        "tableName": refType,
                        "db_id":String(reference.getId()),
                    ]
                } catch {
                    print("Function: \(#function):\(#line), Error: \(error)")
                    
                    let resultVal: String = "Lookup Error"
                    self.blanksDictionary[Int(refVal)!] = ["hanzi": resultVal,
                                                           "pinyin": resultVal,
                                                           "english": resultVal,
                                                           "tableName": refType,
                                                           "db_id": refType,]
                }
            }
        }
    }
    
    func getBlanksDictionary() -> Dictionary<Int, Dictionary<String, String>> {
        return self.blanksDictionary
    }
    
    func getRefDict(_ refDict: String) -> Dictionary<String, String> {
        var refWithCommans = refDict.replacingOccurrences(of: ";", with: ",")
        var refWithQuotes = refWithCommans.replacingOccurrences(of: "(\\w+)", with: "\"$1\"", options: .regularExpression)
        
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
        let test_fib = FillInBlanks(dbTranslation: DbTranslation(),
                                    dbm: self.dbm)
        
        let individualDict: Dictionary<String, String> = test_fib.getRefDict("{ref:1,type:int,min:21,max:22}")
        
        assert(individualDict["ref"] == "1")
        assert(individualDict["type"] == "int")
        assert(individualDict["min"] == "21")
        assert(individualDict["max"] == "22")
    }
    
    func testBlanksToJsonNumber() {
        let dbTranslation = DbTranslation()
        dbTranslation.setHanzi("我今年{ref:1,type:int,min:21,max:22}岁{ref:2,type:int,min:1950,max:1950}WHAT")
        let test_fib = FillInBlanks(dbTranslation: dbTranslation,
        dbm: self.dbm)
        test_fib.populateBlanksDictionary()
        let blanksDict: Dictionary<Int, Dictionary<String, String>> = test_fib.getBlanksDictionary()
        
        assert(blanksDict[1]?["hanzi"] == "21" || blanksDict[1]?["english"] == "22")
        assert(blanksDict[2]?["pinyin"] == "1950")
    }
    
    func testBlanksToJsonInDatabase() {
        for i in 1...10 {
            let dbTranslation = DbTranslation()
            dbTranslation.setHanzi("{ref:1,type:country_person_name}")
            let test_fib = FillInBlanks(dbTranslation: dbTranslation,
            dbm: self.dbm)
            test_fib.populateBlanksDictionary()
            let blanksDict: Dictionary<Int, Dictionary<String, String>> = test_fib.getBlanksDictionary()
            
            print(blanksDict[1]?["hanzi"])
            assert(blanksDict[1]?["hanzi"] == "中国 人" || blanksDict[1]?["english"] == "American")
        }
    }
    
    func testBlanksToJsonInDatabaseFk() {
        for i in 1...10 {
            let dbTranslation = DbTranslation()
            dbTranslation.setHanzi("{ref:1,type:food_type}{ref:2,type:food,fk_ref:1}")
            let test_fib = FillInBlanks(dbTranslation: dbTranslation,
            dbm: self.dbm)
            test_fib.populateBlanksDictionary()
            let blanksDict: Dictionary<Int, Dictionary<String, String>> = test_fib.getBlanksDictionary()
            
            print("Testing!")
            print(blanksDict[1]?["english"])
            print(blanksDict[2]?["english"])
            if blanksDict[1]?["hanzi"] == "水果" {
                assert(blanksDict[2]?["hanzi"] == "苹果" || blanksDict[2]?["english"] == "banana" ||
                    blanksDict[2]?["pinyin"] == "huǒlóng guǒ")
            } else if blanksDict[1]?["english"] == "vegetable" {
                assert(blanksDict[2]?["hanzi"] == "西红柿" || blanksDict[2]?["english"] == "corn")
            } else {
                assert(false)
            }
        }
        
    }
    
    func testPopulateBlanksDictNumber() {
        let hanzi = "我今年{ref:1,type:int,min:33,max:33}岁"
        let pinyin = "wǒ jīnnián {ref:1,type:int,min:33,max:33} suì"
        let english = "I am {ref:1,type:int,min:33,max:33} years old"
        let testTranslation = DbTranslation(hanzi: hanzi,
                                        pinyin: pinyin,
                                        english: english)
        let test_fib = FillInBlanks(dbTranslation: testTranslation,
        dbm: self.dbm)
        test_fib.processBlanks()

        print(testTranslation.getEnglish())
        assert(testTranslation.getEnglish() == "I am 33 years old")
        assert(testTranslation.getPinyin() == "wǒ jīnnián 33 suì")
        assert(testTranslation.getHanzi() == "我今年33岁")
    }
}
