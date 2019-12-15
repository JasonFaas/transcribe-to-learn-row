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
    
    func getTranslationForOldestDueByNowResult() throws -> DbTranslation {
        let selectResult = DbResult.table.select(DbResult.translation_fk, DbResult.language_displayed)
            .filter(DbResult.due_date < Date())
            .order(DbResult.due_date.asc)
        
        let resultRow: Row! = try self.sqliteConnection.pluck(selectResult)
        
        if resultRow == nil {
            throw "DbResult row not found in getTranslationForOldestDueByNowResult"
        }
        let dbResult = DbResult(dbRow: resultRow)
        
        let selectTranslation = DbTranslation
            .table
            .filter(DbTranslation.static_id == dbResult.getTranslationFk())
        
        let translationRow: Row! = try self.sqliteConnection.pluck(selectTranslation)
        if translationRow == nil {
            throw "DbTranslation row not found in getTranslationForOldestDueByNowResult"
        }
        
        return SpecificDbTranslation(dbRow: translationRow,
                                     displayLanguage: dbResult.getLanguageDisplayed())
    }
    
    func getNextPhrase(_ rowToNotGet: Int) -> DbTranslation {
        do {
            return try self.getTranslationForOldestDueByNowResult()
        } catch {
            return self.getEasiestUnansweredRowFromTranslations(rowToNotGet)
        }
    }
        
    func getEasiestUnansweredRowFromTranslations(_ rowToNotGet: Int) -> DbTranslation {
        do {
            let select_fk_keys = DbResult.table
                .select(DbResult.translation_fk, DbResult.language_displayed)
//                .filter(DbResult.last_grade == "A")
            var answered_values:Array<Int> = [rowToNotGet]
            for result_row in try self.sqliteConnection.prepare(select_fk_keys) {
                answered_values.append(result_row[DbResult.translation_fk])
            }
            
            let extractedExpr: Table = DbTranslation.table
                .filter(!answered_values.contains(DbTranslation.static_id))
                .order(SpecificDbTranslation.difficulty.asc)
            
            for translation in try self.sqliteConnection.prepare(extractedExpr) {
                let dbTranslation = SpecificDbTranslation(dbRow: translation,
                                                          displayLanguage: "Mandarin-Simplified")
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
        do {
            var hanziTemp = dbTranslation.getHanzi().replacingOccurrences(of: " ", with: "")
            try dbTranslation.setHanzi(self.replaceBlanks(hanziTemp))
        } catch {
            print("Update Blanks failed: \(error)")
        }
    }
    
    func getRandomRowFromTranslations(_ rowToNotGet: Int) -> DbTranslation {
        do {
            let random_int: Int64 = try self.sqliteConnection.scalar("SELECT * FROM Translations where id != \(rowToNotGet) ORDER BY RANDOM() LIMIT 1;") as! Int64
                        
            let extractedExpr: Table = DbTranslation.table.filter(DbTranslation.static_id == Int(random_int))
            
            for translation in try self.sqliteConnection.prepare(extractedExpr) {
                let dbTranslation = SpecificDbTranslation(dbRow: translation,
                                                          displayLanguage: "Mandarin-Simplified")
                try dbTranslation.verifyAll()
                
                return dbTranslation
            }
        } catch {
            print("Function: \(#function):\(#line), Error: \(error)")
        }
        
        return DbTranslation()
    }
    
    func getResultRow(languageDisplayed: String, translationId: Int) throws -> DbResult {
    
        let extractedExpr: Table = DbResult.table
            .filter(DbResult.translation_fk == translationId)
            .filter(DbResult.language_displayed == languageDisplayed)
        
        let what: Row! = try self.sqliteConnection.pluck(extractedExpr)
        if what == nil {
            throw "DbResult row not found"
        }
        return DbResult(dbRow: what)
    
    }
    
    func logResult(letterGrade: String,
                   quizInfo: DbTranslation,
                   pinyinOn: Bool,
                   attempts: Int) {
        print("Logging:")
        
        let languageDisplayed = quizInfo.getLanguageToDisplay() // or english
        let languagePronounced = "Mandarin" // always
        var pronunciationHelp = "Off"
        if pinyinOn {
            pronunciationHelp = "On"
        }
        
        do {
            let resultRow: DbResult = try self.getResultRow(languageDisplayed: languageDisplayed,
                                                            translationId: quizInfo.getId())
            let newDueDate: Date = self.getUpdatedDueDate(newGrade: letterGrade,
                                                          lastGrade: resultRow.getLastGrade(),
                                                          lastDate: resultRow.getLastUpdatedDate())

            // TODO: extract to DbResult
            let quizSpecific = DbResult.table
                .filter(DbResult.translation_fk == quizInfo.getId())
                .filter(DbResult.language_displayed == languageDisplayed)
            var whatwhat: Update = quizSpecific.update(DbResult.due_date <- newDueDate,
            DbResult.last_grade <- letterGrade,
            DbResult.pronunciation_help <- pronunciationHelp,
            DbResult.last_updated_date <- Date())
            try self.sqliteConnection.run(whatwhat)
            
            print("Row Updated")
        } catch {
            do {
                let newDate: Date = self.getNewDueDate(grade: letterGrade)
                
                // TODO: extract to DbResult
                let firstMandarinInsert: Insert = DbResult.table.insert(
                    DbResult.translation_fk <- quizInfo.getId(),
                    DbResult.difficulty <- quizInfo.getDifficulty(),
                    DbResult.due_date <- newDate, // TODO: This may need to be fixed
                    DbResult.last_grade <- letterGrade,
                    DbResult.language_displayed <- languageDisplayed, // TODO: use enum
                    DbResult.like <- true, // TODO: use enum
                    DbResult.pronunciation_help <- pronunciationHelp,
                    DbResult.language_pronounced <- languagePronounced,
                    DbResult.last_updated_date <- Date()
                )
                
                let newEnglishInsert: Insert = DbResult.table.insert(
                    DbResult.translation_fk <- quizInfo.getId(),
                    DbResult.difficulty <- quizInfo.getDifficulty(),
                    DbResult.due_date <- self.getNewDueDate(grade: "5"),
                    DbResult.last_grade <- "C",
                    DbResult.language_displayed <- "English", // TODO: use enum
                    DbResult.like <- true, // TODO: use enum
                    DbResult.pronunciation_help <- "Off", // TODO: use enum
                    DbResult.language_pronounced <- languagePronounced,
                    DbResult.last_updated_date <- Date()
                )
                
                try self.sqliteConnection.run(firstMandarinInsert)
                try self.sqliteConnection.run(newEnglishInsert)
            
                print("Now rows created for DbResult Mandarin and English")
            } catch {
                print("update failed: \(error)")
            }
        }
        
        self.printAllResultsTable()
    }
    
    func getNewDueDate(grade: String) -> Date {

        let generalDateAdding: [String: Int] = [
            "A": 240,
            "B": 120,
            "C": 60,
            "D": 30,
            "F": 10,
        ]
        let now: Date = Date()
        let calendar: Calendar = Calendar.current
        let minutesAhead: Int = generalDateAdding[grade, default: Int(grade) ?? 1]
        let interval: DateComponents = DateComponents(calendar: calendar, timeZone: nil, era: nil, year: nil, month: nil, day: nil, hour: nil, minute: minutesAhead, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
        let dueDate: Date = calendar.date(byAdding: interval, to: now)!
        
        return dueDate
    }
    
    func getUpdatedDueDate(newGrade: String,
                           lastGrade: String,
                           lastDate: Date) -> Date {

        let generalDateAdding: [String: Float] = [
            "A": 2.0,
            "B": 1.0,
            "C": 0.5,
            "D": 0.25,
            "F": 0.125,
        ]
        let now: Date = Date()
        let calendar: Calendar = Calendar.current
        let dateComponents = calendar.dateComponents([Calendar.Component.second],
                                                     from: lastDate,
                                                     to: now)
        let seconds: Int = Int(Float(dateComponents.second!) * generalDateAdding[newGrade, default: 0.01])
        
        let interval: DateComponents = DateComponents(calendar: calendar, timeZone: nil, era: nil, year: nil, month: nil, day: nil, hour: nil, minute: nil, second: seconds, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
        let dueDate: Date = calendar.date(byAdding: interval, to: now)!
        
        return dueDate
    }
    
    func contentInsideBracket(_ input: Substring, _ openIndex: String.Index, _ closeIndex: String.Index) -> Substring{
        let startOffByOne = input.index(openIndex, offsetBy: 1)
        return input[startOffByOne..<closeIndex]
    }
    
    func replaceBlanks(_ phrase: String) throws -> String {
        
        print(phrase)
        
        var newPhrase: Substring = phrase[phrase.startIndex..<phrase.endIndex]
        while newPhrase.contains("{") {
            let openIndex: String.Index = newPhrase.firstIndex(of: "{")!
            let closeIndex: String.Index = newPhrase.firstIndex(of: "}")!
            let closePlusOne = newPhrase.index(closeIndex, offsetBy: 1)
            
            let contentInsideBracket = self.contentInsideBracket(newPhrase, openIndex, closeIndex)
            
            if contentInsideBracket.contains(":") {
                let colonIndex: String.Index = newPhrase.firstIndex(of: ":")!
                if contentInsideBracket[..<colonIndex] == "number" {
                    let intRangeStartIndex = contentInsideBracket.index(colonIndex, offsetBy: 1)
                    
                    let replacement: String = self.randomFromIntRange(contentInsideBracket[intRangeStartIndex...])
                    newPhrase = newPhrase[..<openIndex] + replacement + newPhrase[closePlusOne...]
                } else {
                    throw "Terrible Exception, what could it be?"
                }
            } else {
                throw "Terrible Exception, populate more"
            }
        }
        
        print(String(newPhrase))
        return String(newPhrase)
    }
    
    func randomFromIntRange(_ intRange: Substring) -> String {
        return "33"
//        let vals: Array<Substring> = intRange.split(separator: "-")
//
//        return String(Int.random(in: Int(String(vals[0]))!...Int(String(vals[1]))!))
    }
    
    func runUnitTests() throws {
        let firstNumberBlank: String = "what{number:33-33}how"
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
    
    func setHanzi(_ tempHanzi: String) {
        
    }
    
    func getLanguageToDisplay() -> String { // TODO Enum
        return "Mandarin"
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
    let displayLanguage: String!
    
    var tempHanzi = ""
        
    init(dbRow: Row, displayLanguage: String) {
        self.dbRow = dbRow
        self.displayLanguage = displayLanguage
        
        // TODO populate these dynamically
        intElements = [SpecificDbTranslation.id, SpecificDbTranslation.difficulty]
        stringElements = [SpecificDbTranslation.hanzi, SpecificDbTranslation.pinyin, SpecificDbTranslation.english]
        
        self.tempHanzi = self.dbRow[SpecificDbTranslation.hanzi]
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
        self.tempHanzi
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
    
    override func setHanzi(_ tempHanzi: String) {
        self.tempHanzi = tempHanzi
    }
    
    override func getLanguageToDisplay() -> String { // TODO Enum
        return self.displayLanguage
    }
}


class DbResult {
    
    //TODO: Duplicate removal
    static let table = Table("Results")
    
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
            
            t.foreignKey(DbResult.translation_fk, references: DbTranslation.table, DbTranslation.static_id)
        }
    }
}
