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
                
                self.updateBlanks(dbTranslation)
                
                return dbTranslation
            }
        } catch {
            print("Function: \(#function):\(#line), Error: \(error)")
        }
        
        return DbTranslation()
    }
    
    func updateBlanks(_ dbTranslation: DbTranslation) {
        var hanziTemp = dbTranslation.getHanzi().replacingOccurrences(of: " ", with: "")
        let numberBlank: String  = "{number:"
//        if let numberIndex = hanziTemp.index(of: numberBlank) {
//
//        }
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
            let newDate: Date = self.getNewDueDate(grade: letterGrade)
            let quizSpecific = DbResult.table.filter(DbResult.translation_fk == quizInfo.getId()).filter(DbResult.language_displayed == languageDisplayed)
            
            if try self.sqliteConnection.run(quizSpecific.update(DbResult.due_date <- newDate, DbResult.last_grade <- letterGrade)) > 0 {
                print("updated row")
            } else {
                try self.sqliteConnection.run(
                DbResult.table.insert(
                                DbResult.translation_fk <- quizInfo.getId(),
                                DbResult.difficulty <- quizInfo.getDifficulty(),
                                DbResult.due_date <- newDate, // TODO: This may need to be fixed
                                DbResult.last_grade <- letterGrade,
                                DbResult.language_displayed <- languageDisplayed, // TODO: use enum
                                DbResult.like <- true // TODO: use enum
                            ))
                
                print("New row created")
            }
        } catch {
            print("update failed: \(error)")
        }
    }
    
    func getNewDueDate(grade: String) -> Date {

        let generalDateAdding: [String: Int] = [
            "A": 60,
            "B": 30,
            "C": 15,
            "D": 5,
            "F": 1,
        ]
        let now: Date = Date()
        let calendar: Calendar = Calendar.current
        let minutesAhead: Int = generalDateAdding[grade, default: 1]
        let interval: DateComponents = DateComponents(calendar: calendar, timeZone: nil, era: nil, year: nil, month: nil, day: nil, hour: nil, minute: minutesAhead, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
        let dueDate: Date = calendar.date(byAdding: interval, to: now) ?? Date()
        
        return dueDate
    }
    
    func replaceBlanks(_ phrase: String) throws -> String {
        
        var newPhrase: Substring = phrase[phrase.startIndex..<phrase.endIndex]
        while newPhrase.contains("{") {
            let openIndex: String.Index = newPhrase.firstIndex(of: "{")!
            let closeIndex: String.Index = newPhrase.firstIndex(of: "}")!
            
            let blankStartIndex = newPhrase.index(openIndex, offsetBy: 1)
            let blankPhrase = newPhrase[blankStartIndex..<closeIndex]
            assert(blankPhrase == "int:[33,33]", String(newPhrase[blankStartIndex..<closeIndex]))
            if blankPhrase.contains(":") {
                let colonIndex: String.Index = newPhrase.firstIndex(of: ":")!
                if blankPhrase[..<colonIndex] == "int" {
                    let intRangeStartIndex = blankPhrase.index(colonIndex, offsetBy: 1)
                    
//                    newPhrase.replaceSubrange(openIndex...closeIndex, with: randomFromIntRange(blankPhrase[intRangeStartIndex...]))
                    let replacement: String = self.randomFromIntRange(blankPhrase[intRangeStartIndex...])
                    newPhrase.replaceSubrange(openIndex...closeIndex, with: replacement)
                } else {
                    throw "Terrible Exception, what could it be?"
                }
            } else {
                throw "Terrible Exception, populate more"
            }
            
//            newPhrase = newPhrase.prefix(upTo: openIndex) + "33" + newPhrase.suffix(from: closeIndex)
            
//            var stars = "***XYZ***"
//            if let xyzRange = stars.range(of: "XYZ") {
//              stars.replaceSubrange(xyzRange, with: "ABC") // "***ABC***"
//            }
            
            
            
            
        }
        
        return String(newPhrase)
    }
    
    func randomFromIntRange(_ intRange: Substring) -> String {
        assert(intRange == "[33,33]", String(intRange))
        
        return "33"
        
    }
    
    func runUnitTests() throws {
        let firstNumberBlank: String = "what{int:[33,33]}how"
        let firstResponse = try self.replaceBlanks(firstNumberBlank)
        let noBlankPhrase: String = "what what"
        let secondResponse = try self.replaceBlanks(noBlankPhrase)
        assert(firstResponse == "what33how", firstResponse)
        assert(secondResponse == noBlankPhrase)
        
        
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
        print("\tFK:   \(dbRow[DbResult.translation_fk])")
        print("\tDiff: \(dbRow[DbResult.difficulty])")
        print("\tDue:  \(dbRow[DbResult.due_date])")
        print("\tGrade:\(dbRow[DbResult.last_grade])")
        print("\tLang: \(dbRow[DbResult.language_displayed])")
        print("\tLike: \(dbRow[DbResult.like])")
    }
    
    init() {
        
    }
}
