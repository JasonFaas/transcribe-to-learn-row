//
//  DatabaseManagement.swift
//  PressAndHoldButton
//
//  Created by Jason A Faas on 9/14/19.
//  Copyright © 2019 Jason A Faas. All rights reserved.
//

import Foundation

import SQLite

class DatabaseManagement {
    var sqliteConnection: Connection!
    
    init() {
        sqliteConnection = DbConnectionSetup().setupConnection()
    }
    
    func printAllResultsTable() {
        do {
            for result_row in try self.sqliteConnection.prepare(DbResult.table) {
                let dbResult = DbResult(dbRow: result_row)
                dbResult.printInfo()
            }
        } catch {
            print("Why is there nothing to print???")
        }
    }
        
    func getEasiestUnansweredRowFromTranslations(_ rowToNotGet: Int) -> DbTranslation {
        do {
            let select_fk_keys = DbResult.table.select(DbResult.translation_fk).filter(DbResult.last_grade == "A")
            var answered_values:Array<Int> = [rowToNotGet]
            for result_row in try self.sqliteConnection.prepare(select_fk_keys) {
                answered_values.append(result_row[DbResult.translation_fk])
            }
            
            let extractedExpr: Table = DbTranslation.table.filter(!answered_values.contains(DbTranslation.static_id)).order(SpecificDbTranslation.difficulty.asc)
            
            for translation in try self.sqliteConnection.prepare(extractedExpr) {
                let dbTranslation = SpecificDbTranslation(dbRow: translation)
                try dbTranslation.verifyAll()
                
                return dbTranslation
            }
        } catch {
            print("Function: \(#function):\(#line), Error: \(error)")
        }
        
        return DbTranslation()
    }
    
    func getRandomRowFromTranslations(_ rowToNotGet: Int) -> DbTranslation {
        do {
            let random_int: Int64 = try self.sqliteConnection.scalar("SELECT * FROM Translations where id != \(rowToNotGet) ORDER BY RANDOM() LIMIT 1;") as! Int64
                        
            let extractedExpr: Table = DbTranslation.table.filter(DbTranslation.static_id == Int(random_int))
            
            for translation in try self.sqliteConnection.prepare(extractedExpr) {
                let dbTranslation = SpecificDbTranslation(dbRow: translation)
                try dbTranslation.verifyAll()
                
                return dbTranslation
            }
        } catch {
            print("Function: \(#function):\(#line), Error: \(error)")
        }
        
        return DbTranslation()
    }
    
    func logResult(letterGrade: String, quizInfo: DbTranslation, pinyinOn: Bool) {
        print("Logging:")
        
        var languageDisplayed = "Mandarin"
        if pinyinOn {
            languageDisplayed = "\(languageDisplayed)-Pinyin"
        } else {
            languageDisplayed = "\(languageDisplayed)-Simplified"
        }
        do {
            try self.sqliteConnection.run(DbResult().getInsert(translation: quizInfo, grade: letterGrade, languageDisplayed: languageDisplayed))
        } catch {
            print("Logging failed")
            print("Function: \(#function):\(#line), Error: \(error)")
        }
        
        // let pinyinOn = self.pinyinOn
//        let currentHanzi = self.fullTranslations[self.translationValue % self.fullTranslations.count].simplifiedChar
//        do {
//            let currentPhraseResult = resultsTable.filter(self.phrase == hanzi)
//            let currentInTable = currentPhraseResult.count
//            let count = try self.resultsDatabase.scalar(currentInTable)
//            let currentPhraseinDatabase: Bool = count != 0
//
//            if currentPhraseinDatabase {
//                let insertResult = self.resultsTable.insert(self.phrase <- hanzi,
//                                                            self.lastGrade <- letterGrade,
//                                                            self.pinyinDisplayed <- pinyinOn)
//                try self.resultsDatabase.run(insertResult)
//            } else {
//                let updateResult = currentPhraseResult.update(self.lastGrade <- letterGrade,
//                                                              self.pinyinDisplayed <- pinyinOn)
//                try self.resultsDatabase.run(updateResult)
//            }
//
//            print("\t\(hanzi)")
//            print("\t\(letterGrade)")
//        } catch {
//            print("Function: \(#function):\(#line), Error: \(error)")
//        }
    }
    
    func runUnitTests() throws {
        let firstRandom: DbTranslation = self.getEasiestUnansweredRowFromTranslations(-1)
        let secondRandom: DbTranslation = self.getRandomRowFromTranslations(firstRandom.getId())
        
        print("Testing random ids \(firstRandom.getId()) \(secondRandom.getId())")
        assert(firstRandom.getId() != secondRandom.getId())
        
        try firstRandom.verifyAll()
        try secondRandom.verifyAll()
        
        print("Test of 1st random database request:\(firstRandom.getHanzi()):")
    }
    
}

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

class DbTranslation {
    
    static let table = Table("Translations")
    static let static_id = Expression<Int>("id")
    
    func verifyAll() throws {
        throw "Base DbTranslation is not very good"
    }
    
    func getId() -> Int {
        return -1
    }
    
    func getHanzi() -> String {
        return "Error Hanzi"
    }
    
    func getPinyin() -> String {
        return "Error Pinyin"
    }
    
    func getEnglish() -> String {
        return "Error English"
    }
    
    func getDifficulty() -> Int {
        return -1
    }
    
}

class SpecificDbTranslation : DbTranslation {
    static let id = Expression<Int>("id")
    static let hanzi = Expression<String>("Hanzi")
    static let pinyin = Expression<String>("Pinyin")
    static let english = Expression<String>("English")
    static let difficulty = Expression<Int>("Difficulty")
    
    var intElements: Array<Expression<Int>>!
    var stringElements: Array<Expression<String>>!
    
    let dbRow: Row!
        
    init(dbRow: Row) {
        self.dbRow = dbRow
        // TODO populate these dynamically
        intElements = [SpecificDbTranslation.id, SpecificDbTranslation.difficulty]
        stringElements = [SpecificDbTranslation.hanzi, SpecificDbTranslation.pinyin, SpecificDbTranslation.english]
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
    
    override func getHanzi() -> String {
        self.dbRow[SpecificDbTranslation.hanzi]
    }
    
    override func getPinyin() -> String {
        self.dbRow[SpecificDbTranslation.pinyin]
    }
    
    override func getEnglish() -> String {
        self.dbRow[SpecificDbTranslation.english]
    }
    
    override func getDifficulty() -> Int {
        self.dbRow[SpecificDbTranslation.difficulty]
    }
}


class DbResult {
    
    let generalDateAdding: [String: Int] = [
        "A": 60,
        "B": 30,
        "C": 15,
        "D": 5,
        "F": 1,
    ]
    
    //TODO: Duplicate removal
    static let table = Table("Results")
    
    static let id = Expression<Int>("id")
    static let translation_fk = Expression<Int>("translation")
    static let difficulty = Expression<Int>("difficulty")
    static let due_date = Expression<Date>("due_date")
    static let last_grade: Expression<String> = Expression<String>("last_grade")
    static let language_displayed = Expression<String>("language_displayed") //TODO: enum to English, Mandarin-Simplified, or Mandarin-Pinyin
    static let like = Expression<Bool>("like")
    
    let valuesDict: [String: Any] = [:]
    
    var intElements: Array<Expression<Int>>!
    var stringElements: Array<Expression<String>>!
    
    var dbRow: Row!
    
    init(dbRow: Row) {
        // TODO Set this up?
        self.dbRow = dbRow
    }
    
    func printInfo() {
        print(dbRow[DbResult.id])
        print("\t\(dbRow[DbResult.translation_fk])")
        print("\t\(dbRow[DbResult.difficulty])")
        print("\t\(dbRow[DbResult.due_date])")
        print("\t\(dbRow[DbResult.last_grade])")
        print("\t\(dbRow[DbResult.language_displayed])")
        print("\t\(dbRow[DbResult.like])")
    }
    
    init() {
        
    }
    
    func getInsert(translation: DbTranslation,
                   grade: String,
                   languageDisplayed: String) -> Insert { // TODO: Should this be static?
        let now: Date = Date()
        let calendar: Calendar = Calendar.current
        let minutesAhead: Int = self.generalDateAdding[grade, default: 1]
        let interval: DateComponents = DateComponents(calendar: calendar, timeZone: nil, era: nil, year: nil, month: nil, day: nil, hour: nil, minute: minutesAhead, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
        let dueDate: Date = calendar.date(byAdding: interval, to: now) ?? Date()
        
        return DbResult.table.insert(
            DbResult.translation_fk <- translation.getId(),
            DbResult.difficulty <- translation.getDifficulty(),
            DbResult.due_date <- dueDate, // TODO: This may need to be fixed
            DbResult.last_grade <- grade,
            DbResult.language_displayed <- languageDisplayed, // TODO: use enum
            DbResult.like <- true // TODO: use enum
        )
    }
    
    static func getCreateTable() -> String {
        return DbResult.table.create { t in
            t.column(DbResult.id, primaryKey: true)
            t.column(DbResult.translation_fk)
            t.column(DbResult.difficulty)
            t.column(DbResult.due_date)
            t.column(DbResult.last_grade)
            t.column(DbResult.language_displayed)
            t.column(DbResult.like)
            
            t.foreignKey(DbResult.translation_fk, references: DbTranslation.table, DbTranslation.static_id)
        }
    }
}
