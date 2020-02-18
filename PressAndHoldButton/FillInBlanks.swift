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
    let testRandomMode: Bool!
    var blanksDictionary: Dictionary<Int, Dictionary<String, String>> = [:]
    
    init(dbTranslation: DbTranslation, dbm: DatabaseManagement, testRandomMode: Bool = false) {
        self.dbTranslation = dbTranslation
        self.dbm = dbm
        self.testRandomMode = testRandomMode
    }
    
    func fillBlanks(phrase: String, howTo: String) -> String {
        var newPhrase: Substring = phrase[phrase.startIndex..<phrase.endIndex]
        while newPhrase.contains("{") {
            let openIndex: String.Index = newPhrase.firstIndex(of: "{")!
            let closeIndex: String.Index = newPhrase.firstIndex(of: "}")!
            let closePlusOne = newPhrase.index(closeIndex, offsetBy: 1)
            let json: String = String(newPhrase[openIndex...closeIndex])
            
            let refDict: Dictionary<String, String> = getRefDict(json)
            let refStr: String = refDict["ref", default: "-1"]
            
            let what: Dictionary<String, String> = blanksDictionary[Int(refStr) ?? -1, default: [:]]

            if let toFillIn: String = what[howTo] {
                newPhrase = newPhrase[..<openIndex] + toFillIn + newPhrase[closePlusOne...]
            } else {
                print("processing: \(blanksDictionary)")
                print("Bad error during \(json)")
                break
            }
            
        }
        
        return String(newPhrase)
    }
    
    func processBlanks() {
        self.populateBlanksDictionary()
        
        var blanksFilledIn = self.fillBlanks(phrase: dbTranslation.getHanzi(),
                                             howTo: "hanzi")
        dbTranslation.setHanzi(blanksFilledIn)
        
        blanksFilledIn = self.fillBlanks(phrase: dbTranslation.getPinyin(),
                                         howTo: "pinyin")
        dbTranslation.setPinyin(blanksFilledIn)
        
        blanksFilledIn = self.fillBlanks(phrase: dbTranslation.getEnglish(),
                                         howTo: "english")
        dbTranslation.setEnglish(blanksFilledIn)
    }
    
    func updateDbTranslation() {
        
    }
    
    func getDictionaryParts(_ stringParts: String) -> [String] {
        
        var returnList: [String] = []
        var returnListEmpty: [String] = []
        
        var newPhrase: Substring = stringParts[stringParts.startIndex..<stringParts.endIndex]
        while newPhrase.contains("{") {
            let openIndex: String.Index = newPhrase.firstIndex(of: "{")!
            let closeIndex: String.Index = newPhrase.firstIndex(of: "}")!
            let closePlusOne = newPhrase.index(closeIndex, offsetBy: 1)
            let json: String = String(newPhrase[openIndex...closeIndex])
            returnList.append(json)
            returnListEmpty.append("")
            
            newPhrase = newPhrase[closePlusOne...]
        }
        
        for i in 0..<returnList.count {
            let refDict: Dictionary<String, String> = self.getRefDict(returnList[i])
            
            let refValInt: Int = Int(refDict["ref"] ?? "-1") ?? -1
            
            if refValInt >= 0 {
                returnListEmpty[refValInt - 1] = returnList[i]
            }
        }
        
        return returnListEmpty
    }
    
    func getIntResultVal(_ refDict: Dictionary<String, String>) -> Int {
        let minString: String! = refDict["min"]
        let minVal: Int! = Int(minString)
        let maxString: String! = refDict["max"]
        let maxVal: Int! = Int(maxString)
        
        return Int.random(in: minVal...maxVal)
    }
    
    func populateBlanksDictionary() {
        let blankParts: [String] = self.getDictionaryParts(self.dbTranslation.getBlanks())
        
        for refString in blankParts {
            let refDict: Dictionary<String, String> = getRefDict(refString)
            
            let refValInt: Int = Int(refDict["ref"] ?? "-1") ?? -1
            if refValInt < 0 {
                continue
            }
            
            if let refType: String = refDict["type"] {
                if refType == "int" {
                    let resultVal = String(self.getIntResultVal(refDict))
                    
                    self.blanksDictionary[refValInt] = [
                        "hanzi": resultVal,
                        "pinyin": resultVal,
                        "english": resultVal,
                        "tableName": refType,
                        "db_id":"-1",
                    ]
                } else {
                    do {
                        let reference:DbTranslation!
                        
                        if refType == "eval", let evalLeft = refDict["left"], let evalRight = refDict["right"], let evalSign = refDict["sign"] {
                            
                            let leftVal:String = self.blanksDictionary[Int(evalLeft)!]!["hanzi"]!
                            let rightVal:String = self.blanksDictionary[Int(evalRight)!]!["hanzi"]!
                                                        
                            let result: Bool!
                            if evalSign == "<" {
                                result = Int(leftVal)! < Int(rightVal)!
                            } else if evalSign == ">" {
                                result = Int(leftVal)! > Int(rightVal)!
                            } else {
                                result = false
                            }
                            
                            let resultStr: String! = refDict[String(result)]
                            
                            let resultArr = resultStr.components(separatedBy: ".")
                            
                            reference = try self.dbm.getSpecificRow(tTableName: resultArr[0], englishVal: resultArr[1])
                        } else if let specificRow: String = refDict["specific"] {
                            reference = try self.dbm.getSpecificRow(tTableName: refType, englishVal: specificRow)
                        } else {
                            let fk_blank: String = refDict["fk_ref", default: "-1"]
                            let whatWhat: Dictionary<String, String> = self.blanksDictionary[Int(fk_blank) ?? -1, default: [:]]
                            let fk_str: String! = whatWhat["db_id", default: "-1"]
                            let fk_val = Int(fk_str) ?? -1
                            
                            let excludedRef: String = refDict["ref_not", default: "-1"]
                            let exRow = self.blanksDictionary[Int(excludedRef) ?? -1, default: [:]]
                            let excludedEnglishVal: String = exRow["english", default: ""]
                            
                            reference = try self.getTranslationForBlank(tTableName: refType,
                                                                    fk_ref: fk_val,
                                                                    excludeEnglishVal: excludedEnglishVal)
                        }
                        
                        self.dbTranslation.saveSubQI(reference)
                        
                        self.blanksDictionary[refValInt] = [
                            "hanzi": reference.getHanzi(),
                            "pinyin": reference.getPinyin(),
                            "english": reference.getEnglish(),
                            "tableName": refType,
                            "db_id":String(reference.getId()),
                        ]
                    } catch {
                        print("Function: \(#function):\(#line), Error: \(error) :: \(blanksDictionary)")
                        
                        let resultVal: String = "Lookup Error"
                        self.blanksDictionary[refValInt] = ["hanzi": resultVal,
                                                            "pinyin": resultVal,
                                                            "english": resultVal,
                                                            "tableName": refType,
                                                            "db_id": refType,]
                    }
                }
            }
        }
    }
    
    func getTranslationForBlank(tTableName: String,
        fk_ref: Int,
        excludeEnglishVal: String) throws -> DbTranslation {
        if self.testRandomMode {
            return try self.dbm.getRandomRowFromSpecified(tTableName: tTableName,
                                                          fk_ref: fk_ref,
                                                          excludeEnglishVal: excludeEnglishVal)
        } else {
            return self.dbm.getNextPhrase(tTableName: tTableName,
                                              idExclude: -1,
                                              fk_ref: fk_ref,
                                              excludeEnglishVal: excludeEnglishVal,
                                              dispLang: self.dbTranslation.getLanguageToDisplay())
        }
        
    }
    
    func getBlanksDictionary() -> Dictionary<Int, Dictionary<String, String>> {
        return self.blanksDictionary
    }
    
    func getRefDict(_ refDict: String) -> Dictionary<String, String> {
        let refWithCommans = refDict.replacingOccurrences(of: ";", with: ",")
        
        var refWithQuotes: String = ""
        for char in refWithCommans {
            if char == "}" || char == ":" || char == "," {
                refWithQuotes.append("\"")
            }
            
            refWithQuotes.append("\(char)")
            
            if char == "{" || char == ":" || char == "," {
                refWithQuotes.append("\"")
            }
        }
        
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
