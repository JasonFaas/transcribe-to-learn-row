//
//  DbTableResult.swift
//  PressAndHoldButton
//
//  Created by Jason A Faas on 1/25/20.
//  Copyright © 2020 Jason A Faas. All rights reserved.
//

import Foundation

import SQLite

class DbResult {
    
    //TODO: Duplicate removal
    static let table: Table = Table("Results")
    
    static let id = Expression<Int>("id")
    static let translation_fk = Expression<Int>("translation") // TODO Change this to translation_fk
    static let difficulty = Expression<Int>("difficulty")
    static let due_date = Expression<Date>("due_date")
    static let last_updated_date = Expression<Date>("last_updated_date")
    static let last_grade: Expression<String> = Expression<String>("last_grade")
    static let language_displayed = Expression<String>("language_displayed") //TODO: enum to English, Mandarin-Simplified, or Mandarin-Pinyin
    static let language_pronounced = Expression<String>("language_pronounced")
    static let like = Expression<Bool>("like")
    static let pronunciation_help = Expression<String>("pronunciation_help")
    
//    let valuesDict: [String: Any] = [:]
//
//    var intElements: Array<Expression<Int>>!
//    var stringElements: Array<Expression<String>>!
    
    var dbRow: Row!
    
    init(dbRow: Row) {
        self.dbRow = dbRow
    }
    
    func getId() -> Int {
        self.dbRow[DbResult.id]
    }
    
    func getTranslationFk() -> Int {
        self.dbRow[DbResult.translation_fk]
    }
    
    func getDueDate() -> Date {
        self.dbRow[DbResult.due_date]
    }
    
    func getLastUpdatedDate() -> Date {
        self.dbRow[DbResult.last_updated_date]
    }
    
    func getLastGrade() -> String {
        self.dbRow[DbResult.last_grade]
    }
    
    func getLanguageDisplayed() -> String {
        self.dbRow[DbResult.language_displayed]
    }
    
    func printInfo() {
        print(dbRow[DbResult.id])
        print("\tFK:       \(dbRow[DbResult.translation_fk])")
        print("\tDiff:     \(dbRow[DbResult.difficulty])")
        print("\tDue:      \(dbRow[DbResult.due_date])")
        print("\tUpdated:  \(dbRow[DbResult.last_updated_date])")
        print("\tGrade:    \(dbRow[DbResult.last_grade])")
        print("\tLangDisp: \(dbRow[DbResult.language_displayed])")
        print("\tLangPron: \(dbRow[DbResult.language_pronounced])")
        print("\tPronHelp: \(dbRow[DbResult.pronunciation_help])")
        print("\tLike:     \(dbRow[DbResult.like])")
    }
    
    init() {
        
    }
    
    static func tableCreationString() -> String {
        return DbResult.table.create(ifNotExists: true) { t in
            t.column(DbResult.id, primaryKey: true)
            t.column(DbResult.translation_fk)
            t.column(DbResult.difficulty)
            t.column(DbResult.due_date)
            t.column(DbResult.last_updated_date)
            t.column(DbResult.last_grade)
            t.column(DbResult.language_displayed)
            t.column(DbResult.language_pronounced)
            t.column(DbResult.pronunciation_help)
            t.column(DbResult.like)
            
            t.foreignKey(DbResult.translation_fk, references: DbTranslation.table, DbTranslation.id)
        }
    }
    
    static func getUpdate(fk: Int,
                          langDisp: String,
                          newDueDate: Date,
                          letterGrade: String,
                          pronunciationHelp: String,
                          difficulty: Int) -> Update {
        let quizSpecific = DbResult.table
            .filter(DbResult.translation_fk == fk)
            .filter(DbResult.language_displayed == langDisp)
        let whatwhat: Update = quizSpecific.update(DbResult.due_date <- newDueDate,
                                                    DbResult.last_grade <- letterGrade,
                                                    DbResult.pronunciation_help <- pronunciationHelp,
                                                    DbResult.last_updated_date <- Date(),
                                                    DbResult.difficulty <- difficulty)
        return whatwhat
    }
    
    static func getInsert(fk: Int,
                          difficulty: Int,
                          due_date: Date,
                          letterGrade: String,
                          languageDisplayed: String,
                          pronunciationHelp: String,
                          languagePronounced: String) -> Insert {

        return DbResult.table.insert(
            DbResult.translation_fk <- fk,
            DbResult.difficulty <- difficulty,
            DbResult.due_date <- due_date,
            DbResult.last_grade <- letterGrade,
            DbResult.language_displayed <- languageDisplayed, // TODO: use enum
            DbResult.like <- true, // TODO: use enum
            DbResult.pronunciation_help <- pronunciationHelp,
            DbResult.language_pronounced <- languagePronounced,
            DbResult.last_updated_date <- Date()
        )
    }
}