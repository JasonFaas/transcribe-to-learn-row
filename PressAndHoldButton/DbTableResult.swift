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
    
    static let nameSuffix = "_results"
    
    static let id = Expression<Int>("id")
    static let translation_fk = Expression<Int?>("translation")
    static let due_date = Expression<Date>("due_date")
    static let last_updated_date = Expression<Date>("last_updated_date")
    static let last_grade: Expression<String> = Expression<String>("last_grade")
    static let minutes_until: Expression<Int> = Expression<Int>("minutes_until")
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
        self.dbRow[DbResult.translation_fk] ?? -1
    }
    
    func getDueDate() -> Date {
        self.dbRow[DbResult.due_date]
    }
    
    func getLastUpdatedDate() -> Date {
        self.dbRow[DbResult.last_updated_date]
    }
    
    func getLastGrade() -> SpeakingGrade {
        return SpeakingGrade(rawValue: self.dbRow[DbResult.last_grade])!
    }
    
    func getLanguageDisplayed() -> String {
        self.dbRow[DbResult.language_displayed]
    }
    
    func getMinutesUntil() -> Int {
        self.dbRow[DbResult.minutes_until]
    }
    
    func printInfo() {
        print(dbRow[DbResult.id])
        print("\tFK:       \(dbRow[DbResult.translation_fk])")
        print("\tDue:      \(dbRow[DbResult.due_date])")
        print("\tUpdated:  \(dbRow[DbResult.last_updated_date])")
        print("\tGrade:    \(dbRow[DbResult.last_grade])")
        print("\tLangDisp: \(dbRow[DbResult.language_displayed])")
        print("\tLangPron: \(dbRow[DbResult.language_pronounced])")
        print("\tPronHelp: \(dbRow[DbResult.pronunciation_help])")
        print("\tMinUntil: \(dbRow[DbResult.minutes_until])")
        print("\tLike:     \(dbRow[DbResult.like])")
    }
    
    init() {
        
    }
    
    static func tableCreationString(tTableName: String) -> String {
        return Table(tTableName + DbResult.nameSuffix).create(ifNotExists: true) { t in
            t.column(DbResult.id, primaryKey: true)
            t.column(DbResult.translation_fk)
            t.column(DbResult.due_date)
            t.column(DbResult.last_updated_date)
            t.column(DbResult.last_grade)
            t.column(DbResult.minutes_until)
            t.column(DbResult.language_displayed)
            t.column(DbResult.language_pronounced)
            t.column(DbResult.pronunciation_help)
            t.column(DbResult.like)
            
            t.foreignKey(DbResult.translation_fk, references: Table(tTableName), DbTranslation.id)
        }
    }
    
    static func getUpdate(tableName: String,
                          fk: Int,
                          langDisp: String,
                          letterGrade: SpeakingGrade,
                          pronunciationHelp: String,
                          minutesUntil: Int) -> Update {
        let quizSpecific = Table(tableName)
            .filter(DbResult.translation_fk == fk)
            .filter(DbResult.language_displayed == langDisp)
        let whatwhat: Update = quizSpecific.update(
            DbResult.due_date <- DateMath.getDateFromNow(minutesAhead: minutesUntil),
            DbResult.last_grade <- letterGrade.rawValue,
            DbResult.pronunciation_help <- pronunciationHelp,
            DbResult.last_updated_date <- Date(),
            DbResult.minutes_until <- minutesUntil
        )
        return whatwhat
    }
    
    static func getInsert(tableName: String,
                          fk: Int,
                          letterGrade: SpeakingGrade,
                          languageDisplayed: String,
                          pronunciationHelp: String,
                          languagePronounced: String,
                          minutesUntil: Int) -> Insert {

        return Table(tableName).insert(
            DbResult.translation_fk <- fk,
            DbResult.due_date <- DateMath.getDateFromNow(minutesAhead: minutesUntil),
            DbResult.last_grade <- letterGrade.rawValue,
            DbResult.language_displayed <- languageDisplayed, // TODO: use enum
            DbResult.like <- true, // TODO: use enum
            DbResult.pronunciation_help <- pronunciationHelp,
            DbResult.language_pronounced <- languagePronounced,
            DbResult.last_updated_date <- Date(),
            DbResult.minutes_until <- minutesUntil
        )
    }
}

enum LanguageDisplayed: String {
    case English="English"
    case MandarinSimplified="Mandarin-Simplified"
}

enum SpeakingGrade: String {
    case A="A"
    case B="B"
    case C="C"
    case D="D"
    case F="F"
    case New="New"
}
