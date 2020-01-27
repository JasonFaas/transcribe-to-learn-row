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
    let dbConn: Connection!
    
    init() {
        let dbSetup: DbConnectionSetup = DbConnectionSetup()
        
        // ENABLE ONLY IF WANTING TO RESET DATABASE
        // TODO: Regularlly turn this to true to verify it still works
        let copyNewDb: Bool = true
        let deleteResultDb: Bool = false
        
        self.dbConn = dbSetup.setupConnection(copyNewDb: copyNewDb,
                                              deleteResultsDb: deleteResultDb)
        print("Row Count:")
        print("\t\(self.getRowsInTable(table: Table(DbTranslation.tableName))) Translations")
        print("\t\(self.getRowsInTable(table: Table(DbTranslation.tableName + DbResult.nameSuffix))) Results")
    }
    
    func printAllResultsTable(rTableName: String = DbTranslation.tableName + DbResult.nameSuffix) {
        do {
            for result_row in try self.dbConn.prepare(Table(rTableName)) {
                let dbResult = DbResult(dbRow: result_row)
                dbResult.printInfo()
            }
        } catch {
            print("Why is there nothing to print???")
        }
    }
    
    func getNextPhrase(tTableName: String, idExclude: Int = -1, fk_ref: Int = -1, excludeEnglishVal: String = "") -> DbTranslation {
        var dbTranslation: DbTranslation!
        
        do {
            dbTranslation = try self.getOldestDueNowTranslation(tTableName: tTableName, tIdExclude: idExclude, t_to_t_fkRef: fk_ref, excludeEnglishVal: excludeEnglishVal)
        } catch {
            do {
                dbTranslation = self.getEasiestUnansweredTranslation(tTableName: tTableName, tIdExclude: idExclude, t_to_t_fkRef: fk_ref, excludeEnglishVal: excludeEnglishVal)
            } catch {
                dbTranslation = self.getDueSoonestTranslation(tTableName: tTableName, tIdExclude: idExclude, t_to_t_fkRef: fk_ref, excludeEnglishVal: excludeEnglishVal)
            }
        }
        
        self.updateBlanks(dbTranslation)
        
        return dbTranslation
    }
    
    // TODO: Verify if no DB
    func getOldestDueNowTranslation(tTableName: String,
                                    tIdExclude: Int = -1,
                                    t_to_t_fkRef: Int = -1,
                                    excludeEnglishVal: String = "") throws -> DbTranslation {
        let tTable: Table = Table(tTableName)
        let rTable = Table(tTableName + "Result")
        var selectResult = rTable
            .select(DbResult.translation_fk, DbResult.language_displayed)
            .filter(DbResult.due_date < Date())
            .filter(DbResult.translation_fk != tIdExclude)
            
        if t_to_t_fkRef != -1 || excludeEnglishVal != "" {
            selectResult = selectResult.join(tTable, on: tTable[DbTranslation.id] == rTable[DbResult.translation_fk])
            
            if t_to_t_fkRef != -1 {
                selectResult = selectResult.filter(tTable[DbTranslation.fk_parent] == t_to_t_fkRef)
            }
            if excludeEnglishVal != "" {
                selectResult = selectResult.filter(tTable[DbTranslation.english] != excludeEnglishVal)
            }
        }
        
        selectResult = selectResult.order(DbResult.due_date.asc)
        
        let resultRow: Row! = try self.dbConn.pluck(selectResult)
        
        if resultRow == nil {
            throw "DbResult row not found in getTranslationForOldestDueByNowResult"
        }
        let dbResult = DbResult(dbRow: resultRow)
        
        let selectTranslation = Table(tTableName).filter(DbTranslation.id == dbResult.getTranslationFk())
        
        let translationRow: Row! = try self.dbConn.pluck(selectTranslation)
        if translationRow == nil {
            throw "DbTranslation row not found in getTranslationForOldestDueByNowResult"
        }
        
        return SpecificDbTranslation(dbRow: translationRow,
                                     displayLanguage: dbResult.getLanguageDisplayed())
    }
    
    // TODO: Verify if no DB
    func getCountDueTotal(tTableName: String, hoursFromNow: Int = 0) -> Int {
        var returnCount: Int = 0
        do {
            returnCount += try self.getDueNowCount(rTableName: tTableName + DbResult.nameSuffix,
                                                   hoursFromNow: hoursFromNow)
            if hoursFromNow == 0 {
                returnCount += try self.getUnansweredCount(tTableName: tTableName)
            } else {
                returnCount += try self.getUnansweredCount(tTableName: tTableName) * 2
            }
        } catch {
            print("Function: \(#function):\(#line), Error: \(error)")
        }
        
        return returnCount
    }
    
    // TODO: Verify if no DB
    func getDueNowCount(rTableName: String, hoursFromNow: Int = 10) throws -> Int {
        let futureDate: Date = self.getDateHoursFromNow(minutesAhead: hoursFromNow * 60)
        
        let selectResult = Table(rTableName).select(DbResult.translation_fk,
                                             DbResult.language_displayed)
        .filter(DbResult.due_date < futureDate)
        
        return try self.dbConn.scalar(selectResult.count)
    }
    
    // TODO: Verify if no DB
    func getUnansweredCount(tTableName: String) throws -> Int {
        let select_fk_keys = Table(tTableName + DbResult.nameSuffix)
            .select(DbResult.translation_fk, DbResult.language_displayed)
        
        var answered_values:Array<Int> = []
        for result_row in try self.dbConn.prepare(select_fk_keys) {
            answered_values.append(result_row[DbResult.translation_fk])
        }
        
        let extractedExpr: Table = Table(tTableName)
            .filter(!answered_values.contains(DbTranslation.id))
        
        return try self.dbConn.scalar(extractedExpr.count)
    }
        
    func createResultDbTableIfNotExists(tTableName: String) {
        do {
            try self.dbConn.run(DbResult.tableCreationString(tTableName: tTableName))
            print("\tDB :: Created \(tTableName)\(DbResult.nameSuffix) Table or it already existed")
        } catch {
            print("\tDB Error :: DID NOT CREATE RESULT TABLE")
            print("Function: \(#function):\(#line), Error: \(error)")
        }
    }
    
    func getEasiestUnansweredTranslation(tTableName: String,
                                         tIdExclude: Int = -1,
                                         t_to_t_fkRef: Int = -1,
                                         excludeEnglishVal: String = "") -> DbTranslation {
        do {
            self.createResultDbTableIfNotExists(tTableName: tTableName)
            let tTable: Table = Table(tTableName)
            let rTable = Table(tTableName + "Result")
            
            var selectTranslation = tTable.filter(DbTranslation.id != tIdExclude)
                .filter(DbTranslation.english != excludeEnglishVal)
                .join(JoinType.leftOuter, rTable, on: tTable[DbTranslation.id] == rTable[DbResult.translation_fk])
            
            if t_to_t_fkRef != -1 {
                selectTranslation = selectTranslation.filter(DbTranslation.fk_parent == t_to_t_fkRef)
            }
            
            selectTranslation = selectTranslation.order(DbTranslation.difficulty.asc)
            
            let translationRow: Row! = try self.dbConn.pluck(selectTranslation)
            if translationRow == nil {
                throw "Function: \(#function):\(#line) :: Unique database \"\(tTableName)\" not found with lots of variables"
            }
            
            // TODO: Make this 50/50 whether english or mandarin-simplified is returned, will have to update logging default paradigm
            return SpecificDbTranslation(dbRow: translationRow,
                                         displayLanguage: "Mandarin-Simplified")
        } catch {
            print("Function: \(#function):\(#line), Error: \(error)")
        }
        
        return DbTranslation()
    }
    
    // TODO: Verify if no DB
    func updateBlanks(_ dbTranslation: DbTranslation) {
        let what = FillInBlanks(dbTranslation: dbTranslation, dbm: self)
        what.processBlanks()
    }
    
    // TODO: Verify if no DB
    func getSpecificRow(tTableName: String, englishVal: String) throws -> DbTranslation {
        let selectTranslation = Table(tTableName).filter(DbTranslation.english == englishVal)
        
        let translationRow: Row! = try self.dbConn.pluck(selectTranslation)
        if translationRow == nil {
            throw "Unique database \"\(tTableName)\" with specific english value not found \(englishVal)"
        }
        
        return SpecificDbTranslation(dbRow: translationRow,
                                     displayLanguage: "none")
    }
    
    // TODO: Verify if no DB
    // TODO: Get rid of the random row usage
    func getRandomRowFromSpecified(tTableName: String, fk_ref: Int, excludeEnglishVal: String) throws -> DbTranslation {
        var selectTranslation = Table(tTableName)
        
        if fk_ref >= 1 {
            selectTranslation = selectTranslation.filter(DbTranslation.fk_parent == fk_ref)
        } else if excludeEnglishVal != "" {
            selectTranslation = selectTranslation.filter(DbTranslation.english != excludeEnglishVal)
        }
        
        selectTranslation = selectTranslation.order(Expression<Int>.random())
//        selectTranslation = selectTranslation.order(DbTranslation.fk_parent.desc)
        
        let translationRow: Row! = try self.dbConn.pluck(selectTranslation)
        if translationRow == nil {
            throw "Unique database \"\(tTableName)\" not found with exclude englishVal :\(excludeEnglishVal): and fk :\(fk_ref):"
        }
        
        return SpecificDbTranslation(dbRow: translationRow,
                                     displayLanguage: "none")
        
    }
    
    // TODO: Verify if no DB
    func getRowsInTable(table: Table) -> Int {
        do {
            return try self.dbConn.scalar(table.count)
        } catch {
            print("Function: \(#function):\(#line), Error: \(error)")
            return 0
        }
    }
    
    // TODO: Verify if no DB
    func getResultRow(resultTableName: String, languageDisplayed: String, translationId: Int) throws -> DbResult {
        let extractedExpr: Table = Table(resultTableName)
            .filter(DbResult.translation_fk == translationId)
            .filter(DbResult.language_displayed == languageDisplayed)
        
        let what: Row! = try self.dbConn.pluck(extractedExpr)
        if what == nil {
            throw "DbResult row not found"
        }
        
        return DbResult(dbRow: what)
    }
    
    // TODO: Verify if no DB
    func logResult(letterGrade: String,
                   quizInfo: DbTranslation,
                   pinyinOn: Bool,
                   attempts: Int) {
        let languageDisplayed = quizInfo.getLanguageToDisplay() // or english
        let languagePronounced = "Mandarin" // always
        var pronunciationHelp = "Off"
        if pinyinOn {
            pronunciationHelp = "On"
        }

        let resultTableName = DbTranslation.tableName + DbResult.nameSuffix
        do {
            let resultRow: DbResult = try self.getResultRow(resultTableName: resultTableName,
                                                            languageDisplayed: languageDisplayed,
                                                            translationId: quizInfo.getId())
            let newDueDate: Date = self.getUpdatedDueDate(newGrade: letterGrade,
                                                          lastGrade: resultRow.getLastGrade(),
                                                          lastDate: resultRow.getLastUpdatedDate())
            let update: Update = DbResult.getUpdate(tableName: resultTableName,
                                                    fk: quizInfo.getId(),
                                                    langDisp: languageDisplayed,
                                                    newDueDate: newDueDate,
                                                    letterGrade: letterGrade,
                                                    pronunciationHelp: pronunciationHelp)
            
            try self.dbConn.run(update)
            
        } catch {
            do {
                
                let firstMandarinInsert: Insert = DbResult
                    .getInsert(tableName: resultTableName,
                               fk: quizInfo.getId(),
                               due_date: self.getNewDueDate(grade: letterGrade),
                               letterGrade: letterGrade,
                               languageDisplayed: languageDisplayed,
                               pronunciationHelp: pronunciationHelp,
                               languagePronounced: languagePronounced)
                
                let newEnglishInsert: Insert = DbResult
                    .getInsert(tableName: resultTableName,
                               fk: quizInfo.getId(),
                               due_date: self.getNewDueDate(grade: "5"),
                               letterGrade: "C",
                               languageDisplayed: "English",
                               pronunciationHelp: "Off",
                               languagePronounced: languagePronounced)
                
                try self.dbConn.run(firstMandarinInsert)
                try self.dbConn.run(newEnglishInsert)
            } catch {
                print("Function: \(#function):\(#line), Error: \(error) - Insert failed")
            }
        }
    }
    
    // TODO: Verify if no DB
    func getNewDueDate(grade: String) -> Date {
        
        let generalDateAdding: [String: Int] = [
            "A": 60 * 24,
            "B": 60 * 4,
            "C": 60 * 1,
            "D": 60 / 4,
            "F": 60 / 16,
        ]
        
        let minutesAhead: Int = generalDateAdding[grade, default: Int(grade) ?? 1]
        let dueDate: Date = self.getDateHoursFromNow(minutesAhead: minutesAhead)
        
        return dueDate
    }
    
    // TODO: Verify if no DB
    func getDateHoursFromNow(minutesAhead: Int) -> Date {
        let now: Date = Date()
        let calendar: Calendar = Calendar.current
        
        let interval: DateComponents = DateComponents(calendar: calendar, timeZone: nil, era: nil, year: nil, month: nil, day: nil, hour: nil, minute: minutesAhead, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
        let dueDate: Date = calendar.date(byAdding: interval, to: now)!
        return dueDate
    }
    
    // TODO: Verify if no DB
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
    
    // TODO: Verify if no DB
    func contentInsideBracket(_ input: Substring, _ openIndex: String.Index, _ closeIndex: String.Index) -> Substring{
        let startOffByOne = input.index(openIndex, offsetBy: 1)
        return input[startOffByOne..<closeIndex]
    }
    
    // TODO: Verify if no DB
    func getHskPinyins(_ transcription: String) -> [String] {
        let transcriptionQuery = Table("hsk").filter(DbTranslation.hanzi == transcription)
        let transcriptionRow: Row!
        do {
            transcriptionRow = try self.dbConn.pluck(transcriptionQuery)
            if transcriptionRow == nil {
                return []
            }
        } catch {
            print("Function: \(#function):\(#line), Error: \(error) :: HSK error for \(transcription)")
            return []
        }
        
        let transcriptionTranslation = SpecificDbTranslation(dbRow: transcriptionRow,
                                                             displayLanguage: "")
        
        var transcriptionPinyins = [transcriptionTranslation.getPinyin(),]
        if transcriptionTranslation.get2ndPinyin().count > 0 {
            transcriptionPinyins.append(transcriptionTranslation.get2ndPinyin())
        }
        return transcriptionPinyins
    }
    
    // TODO: Verify if no DB
    func arePinyinSame(_ transcription: String,
                       _ expected: String) -> Bool {
        let transcriptionPinyins = getHskPinyins(transcription)
        let expectedPinyins = getHskPinyins(expected)
        
        let mySet = Set(transcriptionPinyins + expectedPinyins)
        return mySet.count < transcriptionPinyins.count + expectedPinyins.count
    }
    
}
