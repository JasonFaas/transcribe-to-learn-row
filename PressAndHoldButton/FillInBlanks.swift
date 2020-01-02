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
//        print(phrase)
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
        
//        print(String(newPhrase))
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
//            print(what)
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
//                        print("VAL: \(fk_ref)")
                        
                        let whatWhat: Dictionary<String, String>! = self.blanksDictionary[Int(fk_ref)!]
                        let fk_str: String! = whatWhat["db_id"]
                        let fk_val: Int! = Int(fk_str)
                        
                        reference = try self.dbm.getRandomRowFromSpecified(database: refType, fk_ref: fk_val)
                    } else {
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
    
}
