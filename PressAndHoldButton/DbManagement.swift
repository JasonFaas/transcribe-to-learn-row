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
            .filter(DbTranslation.id == dbResult.getTranslationFk())
        
        let translationRow: Row! = try self.sqliteConnection.pluck(selectTranslation)
        if translationRow == nil {
            throw "DbTranslation row not found in getTranslationForOldestDueByNowResult"
        }
        
        return SpecificDbTranslation(dbRow: translationRow,
                                     displayLanguage: dbResult.getLanguageDisplayed())
    }
    
    func getNextPhrase(_ rowToNotGet: Int) -> DbTranslation {
        var dbTranslation: DbTranslation!
        
        do {
            dbTranslation = try self.getTranslationForOldestDueByNowResult()
        } catch {
            dbTranslation = self.getEasiestUnansweredRowFromTranslations(rowToNotGet)
        }
        
        self.updateBlanks(dbTranslation)
        
        return dbTranslation
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
                .filter(!answered_values.contains(DbTranslation.id))
                .order(DbTranslation.difficulty.asc)
            
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
    
    func updateBlanks(_ dbTranslation: DbTranslation) {
        let what = FillInBlanks(dbTranslation: dbTranslation, dbm: self)
        what.processBlanks()
    }
    
    func getRandomRowFromSpecified(database: String, fk_ref: Int) throws -> DbTranslation {
         
        print("a")
        var fk_helper: String = ""
        if fk_ref >= 1 {
            fk_helper = "where fk_parent = \(fk_ref) "
        }
        
        let random_int: Int64 = try self.sqliteConnection.scalar("SELECT * FROM \(database) \(fk_helper)ORDER BY RANDOM() LIMIT 1;") as! Int64

        print("b")
        var selectTranslation = Table(database).filter(DbTranslation.id == Int(random_int))
    
        
        print("d")
        let translationRow: Row! = try self.sqliteConnection.pluck(selectTranslation)
        print("e")
        if translationRow == nil {
            throw "Unique database \"\(database)\" not found \(random_int) \(fk_ref)"
        }
        
        print("f")
        return SpecificDbTranslation(dbRow: translationRow,
                                     displayLanguage: "none")
    
    }
    
    func getRandomRowFromTranslations(_ rowToNotGet: Int) -> DbTranslation {
        do {
            let random_int: Int64 = try self.sqliteConnection.scalar("SELECT * FROM Translations where id != \(rowToNotGet) ORDER BY RANDOM() LIMIT 1;") as! Int64
                        
            let extractedExpr: Table = DbTranslation.table.filter(DbTranslation.id == Int(random_int))
            
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

            let update: Update = DbResult.getUpdate(fk: quizInfo.getId(),
                                                   langDisp: languageDisplayed,
                                                   newDueDate: newDueDate,
                                                   letterGrade: letterGrade,
                                                   pronunciationHelp: pronunciationHelp)
            
            try self.sqliteConnection.run(update)
            
            print("Row Updated")
        } catch {
            do {
                
                let firstMandarinInsert: Insert = DbResult
                    .getInsert(fk: quizInfo.getId(),
                               difficulty: quizInfo.getDifficulty(),
                               due_date: self.getNewDueDate(grade: letterGrade),
                               letterGrade: letterGrade,
                               languageDisplayed: languageDisplayed,
                               pronunciationHelp: pronunciationHelp,
                               languagePronounced: languagePronounced)
                
                let newEnglishInsert: Insert = DbResult
                    .getInsert(fk: quizInfo.getId(),
                               difficulty: quizInfo.getDifficulty(),
                               due_date: self.getNewDueDate(grade: "5"),
                               letterGrade: "C",
                               languageDisplayed: "English",
                               pronunciationHelp: "Off",
                               languagePronounced: languagePronounced)
                
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
        let fib = FillInBlanks(dbTranslation: DbTranslation(), dbm: self)
        fib.runUnitTests()
        
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
