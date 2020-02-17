//
//  DbTables.swift
//  PressAndHoldButton
//
//  Created by Jason A Faas on 12/22/19.
//  Copyright © 2019 Jason A Faas. All rights reserved.
//

import Foundation

import SQLite

class DbTranslation {
    
    static let tableName: String = "translations"
    static let hskTableName: String = "hsk"
    static let hskTable: Table = Table(hskTableName)
    
    var tTableName = ""
    var blanksDb: [DbTranslation] = []
    
    static let id = Expression<Int>("id")
    static let blanks = Expression<String>("Blanks")
    static let hanzi = Expression<String>("Hanzi")
    static let pinyin = Expression<String>("Pinyin")
    static let pinyin2nd = Expression<String>("2nd_Pinyin")
    static let english = Expression<String>("English")
    static let difficulty = Expression<Int>("Auto_Level")
    static let difficultyManual = Expression<Int>("Manual_Level")
    static let fk_parent = Expression<Int>("fk_parent")
    
    var tempHanzi:String = "Error Hanzi"
    var tempPinyin:String = "Error Pinyin"
    var tempEnglish:String = "Error English"
    var tempBlanks:String = "Error Blanks"
    
    init() {
    }
    
    init(hanzi: String, pinyin: String, english: String, blanks: String) {
        self.tempHanzi = hanzi
        self.tempPinyin = pinyin
        self.tempEnglish = english
        self.tempBlanks = blanks
    }
    
    func verifyAll() throws {
        throw "Base DbTranslation is not very good"
    }
    
    func getId() -> Int {
        return -1
    }
    
    func getHanzi() -> String {
        return tempHanzi
    }
    
    func getPinyin() -> String {
        return tempPinyin
    }
    
    func get2ndPinyin() -> String {
        return tempPinyin
    }
    
    func getBlanks() -> String {
        return tempBlanks
    }
    
    func getEnglish() -> String {
        return tempEnglish
    }
    
    func setHanzi(_ temp: String) {
        self.tempHanzi = temp
    }
    
    func setBlanks(_ temp: String) {
        self.tempBlanks = temp
    }
    
    func setPinyin(_ temp: String) {
        self.tempPinyin = temp
    }
    
    func setEnglish(_ temp: String) {
        self.tempEnglish = temp
    }
    
    func getDifficulty() -> Int {
        return -1
    }
    
    func getBlanksDb() -> [DbTranslation] {
        return blanksDb
    }
    
    func saveSubQI(_ what: DbTranslation) {
        blanksDb.append(what)
    }
    
    func getTTableName() -> String {
        return self.tTableName
    }
    
    func getLanguageToDisplay() -> String { // TODO Enum
        return LanguageDisplayed.MandarinSimplified.rawValue
    }
    
    static func getStandardSelect(table: Table) -> [SQLite.Expressible] {
        var returnList: [SQLite.Expressible] = []
        
        returnList.append(table[id])
        returnList.append(blanks)
        returnList.append(hanzi)
        returnList.append(pinyin)
        returnList.append(pinyin2nd)
        returnList.append(english)
        returnList.append(difficulty)
        returnList.append(fk_parent)
        
        return returnList
    }
    
}

class SpecificDbTranslation : DbTranslation {
    
    var intElements: Array<Expression<Int>>!
    var stringElements: Array<Expression<String>>!
    
    let dbRow: Row!
    let displayLanguage: String!
        
    init(dbRow: Row,
         displayLanguage: String,
         tTableName: String) {
        
        
        self.dbRow = dbRow
        self.displayLanguage = displayLanguage
        
        super.init()
        
        self.tTableName = tTableName
        
        // TODO populate these dynamically
        intElements = [SpecificDbTranslation.id, SpecificDbTranslation.difficulty]
        stringElements = [SpecificDbTranslation.hanzi, SpecificDbTranslation.pinyin, SpecificDbTranslation.english]
        
        
        
        self.tempHanzi = self.dbRow[SpecificDbTranslation.hanzi]
        self.tempPinyin = self.dbRow[SpecificDbTranslation.pinyin]
        self.tempEnglish = self.dbRow[SpecificDbTranslation.english]
        self.tempBlanks = self.dbRow[SpecificDbTranslation.blanks]
    }
    
    override func verifyAll() throws {
        for intElement in self.intElements {
            if self.dbRow[intElement] < 0 {
                throw "bad int element \(intElement)"
            }
        }
        for stringElement in self.stringElements {
            if self.dbRow[stringElement].count <= 0 {
                throw "bad string element \(stringElement)"
            }
        }
    }
    
    override func getId() -> Int {
        self.dbRow[SpecificDbTranslation.id]
    }
    
    override func getDifficulty() -> Int {
        self.dbRow[SpecificDbTranslation.difficulty]
    }
    
    override func get2ndPinyin() -> String {
        self.dbRow[SpecificDbTranslation.pinyin2nd]
    }
    
    override func getLanguageToDisplay() -> String { // TODO Enum
        return self.displayLanguage
    }
}

