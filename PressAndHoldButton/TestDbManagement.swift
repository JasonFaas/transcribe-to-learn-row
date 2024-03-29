//
//  TestDbManagement.swift
//  PressAndHoldButton
//
//  Created by Jason A Faas on 1/25/20.
//  Copyright © 2020 Jason A Faas. All rights reserved.
//

import Foundation

import SQLite

class TestDbManagement {
    
    let dbm: DatabaseManagement!
    
    init(_ dbm: DatabaseManagement) {
        self.dbm = dbm
    }
    
    func runUnitTests() throws {
        print("Testing DbManagement")
        
        self.testBadRefVal()
        self.testGetDictionaryPartsReturnedOrdered()
        
        self.testJsonBlankToDict()
        self.testBlanksToJsonNumber()
        self.testBlanksToJsonInDatabase()
        self.testBlanksToJsonInDatabaseFk()
        self.testPopulateBlanksDictNumber()
        self.testSpecificAndCompareCountry()
        self.testConvertHanziToLogSpokenSimpleNumerals()
        self.testConvertHanziToLogSpokenAdvancedNumerals()
        self.testConvertHanziToLogSpokenPunctuation()
        self.testBadHskEntries()
        
        print("Testing testGetResultNoDueDate")
        try self.testGetResultNoDueDate()
        
        print("Testing testGetEasiest")
        try self.testGetEasiest()
        
        print("All DbManagement Tests PASSED")
    }
    
    func testBadHskEntries() {
        assert(0 == self.dbm.countFromSqlStatement("SELECT count(*) FROM hsk where English IS NULL"))
    }
    
    func testConvertHanziToLogSpokenSimpleNumerals() {
        let actual = self.dbm.convertHanziToLogSpoken("你好 1")
        let expected = "你好 一"
        assert(actual == expected, actual)
    }
    
    func testConvertHanziToLogSpokenAdvancedNumerals() {
        var actual = self.dbm.convertHanziToLogSpoken("你好 12")
        var expected = "你好 一十二"
        assert(actual == expected)
        
        actual = self.dbm.convertHanziToLogSpoken("你好 134")
        expected = "你好 一百三十四"
        assert(actual == expected)
        
        actual = self.dbm.convertHanziToLogSpoken("你好 1,567")
        expected = "你好 一千五百六十七"
        assert(actual == expected)
        
        actual = self.dbm.convertHanziToLogSpoken("你好 29,087")
        expected = "你好 二万九千零百八十七"
        assert(actual == expected, actual)
        
        //TODO: Numbers beyond 99,999
        actual = self.dbm.convertHanziToLogSpoken("你好 190,087")
        expected = "你好 190087"
        assert(actual == expected)
    }
    
    func testConvertHanziToLogSpokenPunctuation() {
        let actual = self.dbm.convertHanziToLogSpoken("你,好。 1 ？")
        let expected = "你好 一"
        assert(actual == expected, ":\(actual):")
    }
    
    func testGetResultNoDueDate() throws {
        // Add Jason Faas to Results database with due date of 5 minutes in past
        let commonTableName = "common_name"
        let jasonFaasTranslation: DbTranslation = try self.dbm.getSpecificRow(tTableName: commonTableName,
                                                                              englishVal: "Jason Faas")
        self.dbm.createResultDbTableIfNotExists(tTableName: commonTableName)
        
        let dispLang = LanguageDisplayed.English.rawValue
        let newEnglishInsert: Insert = DbResult
            .getInsert(tableName: commonTableName + DbResult.nameSuffix,
                       fk: jasonFaasTranslation.getId(),
                       letterGrade: SpeakingGrade.New,
                       languageDisplayed: dispLang,
                       pronunciationHelp: "Off",
                       languagePronounced: "Mandarin",
                       minutesUntil: -60 * 2)
        
        try self.dbm.dbConn.run(newEnglishInsert)
        // Look up by due date
        
        let actual_v1 = try self.dbm.getTranslationByResultDueDate(tTableName: commonTableName, dueDateDelimiter: Date(), dispLang: dispLang)
        assert(actual_v1.getEnglish() == "Jason Faas")
        assert(actual_v1.getEnglish() == jasonFaasTranslation.getEnglish())
        
        
        // Add Jason Faas to Results database with due date of 10 years into future
        let minutesUntil = 60*24*365*10
        let englishUpdate = DbResult.getUpdate(tableName: commonTableName + DbResult.nameSuffix,
        fk: jasonFaasTranslation.getId(),
        langDisp: LanguageDisplayed.English.rawValue,
        letterGrade: SpeakingGrade.C,
        pronunciationHelp: "Off",
        minutesUntil: minutesUntil)
        
        try self.dbm.dbConn.run(englishUpdate)
        // Look up by any time
        
        let actual_v2 = try self.dbm.getTranslationByResultDueDate(tTableName: commonTableName, dueDateDelimiter: nil, dispLang: dispLang)
        assert(actual_v2.getEnglish() == jasonFaasTranslation.getEnglish())
    }
    
    func testGetEasiest() throws {
        do {
            let expected = try self.dbm.getEasiestUnansweredTranslation(tTableName: "city_name", dispLang: LanguageDisplayed.English.rawValue)
            assert(expected.getEnglish() == "Beijing" || expected.getEnglish() == "Xi'an")
        } catch {
            print("Function: \(#function):\(#line), Error: \(error)")
            assert(5 == 4)
        }
    }
    
    func testJsonBlankToDict() {
        let test_fib = FillInBlanks(dbTranslation: DbTranslation(),
                                    dbm: self.dbm,
                                    testRandomMode: true)
        
        let individualDict: Dictionary<String, String> = test_fib.getRefDict("{ref:1,type:int,min:21,max:22}")
        
        assert(individualDict["ref"] == "1")
        assert(individualDict["type"] == "int")
        assert(individualDict["min"] == "21")
        assert(individualDict["max"] == "22")
    }
    
    func testBlanksToJsonNumber() {
        let dbTranslation = DbTranslation()
        dbTranslation.setBlanks("我今年{ref:1,type:int,min:21,max:22}岁{ref:2,type:int,min:1950,max:1950}WHAT")
        let test_fib = FillInBlanks(dbTranslation: dbTranslation,
                                    dbm: self.dbm,
                                    testRandomMode: true)
        test_fib.populateBlanksDictionary()
        let blanksDict: Dictionary<Int, Dictionary<String, String>> = test_fib.getBlanksDictionary()
        
        assert(blanksDict[1]?["hanzi"] == "21" || blanksDict[1]?["english"] == "22")
        assert(blanksDict[2]?["pinyin"] == "1950")
    }
    
    func testBlanksToJsonInDatabase() {
        var trueCount = 0
        for _ in 1...100 {
            let dbTranslation = DbTranslation()
            dbTranslation.setBlanks("{ref:1,type:country_person_name}")
            let test_fib = FillInBlanks(dbTranslation: dbTranslation,
                                        dbm: self.dbm,
                                        testRandomMode: true)
            test_fib.populateBlanksDictionary()
            let blanksDict: Dictionary<Int, Dictionary<String, String>> = test_fib.getBlanksDictionary()
            
            if blanksDict[1]?["hanzi"] == "中国 人" || blanksDict[1]?["english"] == "American" {
                trueCount += 1
                if trueCount > 2 {
                    break
                }
            }
        }
        assert(trueCount > 1)
        assert(trueCount < 90)
    }
    
    func testBlanksToJsonInDatabaseFk() {
        var complex_fruit_once = false
        var simple_fruit_once = false
        var not_fruit_once = false
        let simple_fruit_list: [String] = ["苹果", "香蕉", "火龙果", "黑莓"]
        for _ in 1...200 {
            let dbTranslation = DbTranslation()
            dbTranslation.setBlanks("{ref:1,type:food_type}{ref:2,type:food,fk_ref:1}")
            let test_fib = FillInBlanks(dbTranslation: dbTranslation,
                                        dbm: self.dbm,
                                        testRandomMode: true)
            test_fib.populateBlanksDictionary()
            let blanksDict: Dictionary<Int, Dictionary<String, String>> = test_fib.getBlanksDictionary()
            
            
            
            let food_type: String? = blanksDict[1]?["hanzi"]
            let food_specific: String? = blanksDict[2]?["hanzi"]
            if food_type == "水果" {
                if simple_fruit_list.contains(food_specific!) {
                    simple_fruit_once = true
                } else {
                    complex_fruit_once = true
                }
                
            } else {
                not_fruit_once = true
            }
        }
        assert(complex_fruit_once)
        assert(simple_fruit_once)
        assert(not_fruit_once)
        
    }
    
    func testPopulateBlanksDictNumber() {
        let hanzi = "我今年{ref:1}岁"
        let pinyin = "wǒ jīnnián {ref:1} suì"
        let english = "I am {ref:1} years old"
        let blanks = "{ref:1,type:int,min:33,max:33}"
        let testTranslation = DbTranslation(hanzi: hanzi,
                                            pinyin: pinyin,
                                            english: english,
                                            blanks: blanks)
        let test_fib = FillInBlanks(dbTranslation: testTranslation,
                                    dbm: self.dbm,
                                    testRandomMode: true)
        test_fib.processBlanks()
        
        assert(testTranslation.getEnglish() == "I am 33 years old", testTranslation.getEnglish())
        assert(testTranslation.getPinyin() == "wǒ jīnnián 33 suì")
        assert(testTranslation.getHanzi() == "我今年33岁")
    }
    
    func testGetDictionaryPartsReturnedOrdered() {
        let ref_1 = "{ref:1}"
        let ref_2 = "{ref:2}"
        let ref_3 = "{ref:5}"
        let ref_4 = "{ref:3}"
        let ref_5 = "{ref:4}"
        
        let testTranslantion = DbTranslation(hanzi: "",
                                             pinyin: "",
                                             english: "",
                                             blanks: "")
        
        let test_fib = FillInBlanks(dbTranslation: testTranslantion,
                                    dbm: self.dbm,
                                    testRandomMode: true)
        
        let decodeString = "\(ref_1) \(ref_2) \(ref_3) \(ref_4) \(ref_5) "
        let blankParts: [String] = test_fib.getDictionaryParts(decodeString)
        for i in 1...5 {
            assert(blankParts[i - 1].contains("ref:\(i)"))
        }
    }
    
    func testSpecificAndCompareCountry() {
        let ref_1 = "{ref:1,type:country_name,specific:Russia}"
        let ref_2 = "{ref:2,type:country_name,ref_not:1}"
        let ref_3 = "{ref:5,type:eval,left:3,right:4,sign:<,true:comparison_adjectives.bigger,false:comparison_adjectives.smaller}"
        let ref_4 = "{ref:3,type:country_size_km2,fk_ref:1}"
        let ref_5 = "{ref:4,type:country_size_km2,fk_ref:2}"
        
        let testTranslantion = DbTranslation(hanzi: "",
                                             pinyin: "",
                                             english: "",
                                             blanks: "\(ref_1) \(ref_2) \(ref_3) \(ref_4) \(ref_5) ")
        
        let test_fib = FillInBlanks(dbTranslation: testTranslantion,
                                    dbm: self.dbm,
                                    testRandomMode: true)
        for _ in 1...200 {
            test_fib.populateBlanksDictionary()
            let blanksDict: Dictionary<Int, Dictionary<String, String>> = test_fib.getBlanksDictionary()
            
            assert(blanksDict[1]?["english"] == "Russia")
            assert(blanksDict[2]?["english"] != "Russia")
            assert((blanksDict[2]?["hanzi"]?.count)! > 1)
            assert(Int((blanksDict[3]?["hanzi"])!) == 17098)
            assert(Int((blanksDict[4]?["hanzi"])!)! < 17098)
            assert(Int((blanksDict[4]?["hanzi"])!)! > 2)
            assert(blanksDict[5]?["hanzi"] != "smaller")
        }
        
    }
    
    func testBadRefVal() {
        let ref_1 = "{ref:t,type:what}"
        
        let testTranslantion = DbTranslation(hanzi: "",
                                             pinyin: "",
                                             english: "",
                                             blanks: ref_1)
        
        let test_fib = FillInBlanks(dbTranslation: testTranslantion,
                                    dbm: self.dbm,
                                    testRandomMode: true)
        test_fib.populateBlanksDictionary()
        let blanksDict: Dictionary<Int, Dictionary<String, String>> = test_fib.getBlanksDictionary()
        
        assert(blanksDict.count == 0)
    }
}
