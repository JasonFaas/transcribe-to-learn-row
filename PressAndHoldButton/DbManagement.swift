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
        let translationCount = self.getRowsInTable(table: Table(DbTranslation.tableName))
        if translationCount <= 0 {
            print("\n\nWOW BIG ERROR, NO DB PROBABLY\n\n")
        }
        print("\t\(translationCount) Translations")
        print("\t\(self.getRowsInTable(table: Table(DbTranslation.tableName + DbResult.nameSuffix))) Results")
    }
    
    func printYourStatement(_ sqlStmt: String) {
        do {
        let count = try dbConn.scalar("SELECT count(*) FROM hsk") as! Int64
        print("JAF \(count)")
        
        let stmt = try dbConn.prepare("SELECT id, Hanzi FROM hsk")
        for row in stmt {
            for (index, name) in stmt.columnNames.enumerated() {
                print("JAF_2 \(name):\(row[index]!)")
                // id: Optional(1), email: Optional("alice@mac.com")
            }
        }
        } catch {
            print("Function: \(#function):\(#line), Error: \(error)")
        }
        
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
    
    func printAllLogWordsTable() {
        do {
            let count = try dbConn.scalar("SELECT count(*) FROM Log_Words") as! Int64
            print("JAF Log_Words \(count)")
            
            for logResultsRow in try self.dbConn.prepare(DbLogWords.table.order(DbLogWords.hsk_fk.asc)) {
//                print("\(logResultsRow[DbLogWords.id])")
                print("\(logResultsRow[DbLogWords.hsk_fk] ?? -1)")
                print("\t\(logResultsRow[DbLogWords.count])")
//                print("\t\(logResultsRow[DbLogWords.date_updated])")
//                print("\t\(logResultsRow[DbLogWords.date_created])")
            }
        } catch {
            print("Why is there nothing to print???")
        }
    }
    
    func getNextPhrase(tTableName: String, idExclude: Int = -1, fk_ref: Int = -1, excludeEnglishVal: String = "", dispLang: String) -> DbTranslation {
        var dbTranslation: DbTranslation!
        
        do {
            dbTranslation = try self.getTranslationByResultDueDate(tTableName: tTableName, tIdExclude: idExclude, t_to_t_fkRef: fk_ref, excludeEnglishVal: excludeEnglishVal, dueDateDelimiter: Date(), dispLang: dispLang)
        } catch {
            do {
                dbTranslation = try self.getEasiestUnansweredTranslation(tTableName: tTableName, tIdExclude: idExclude, t_to_t_fkRef: fk_ref, excludeEnglishVal: excludeEnglishVal, dispLang: dispLang)
            } catch {
                do {
                    dbTranslation = try self.getTranslationByResultDueDate(tTableName: tTableName, tIdExclude: idExclude, t_to_t_fkRef: fk_ref, excludeEnglishVal: excludeEnglishVal, dueDateDelimiter: nil, dispLang: dispLang)
                } catch {
                    return DbTranslation()
                }
            }
        }
        
        self.updateBlanks(dbTranslation)
        
        return dbTranslation
    }
    
    // TODO: Verify if no DB
    func getTranslationByResultDueDate(tTableName: String,
                                       tIdExclude: Int = -1,
                                       t_to_t_fkRef: Int = -1,
                                       excludeEnglishVal: String = "",
                                       dueDateDelimiter: Date!,
                                       dispLang: String) throws -> DbTranslation {
        let tTable: Table = Table(tTableName)
        let rTable = Table(tTableName + DbResult.nameSuffix)
        
        var allSelect = DbTranslation.getStandardSelect(table: tTable)
        allSelect.append(rTable[DbResult.language_displayed])
        
        var newSelectResult = tTable
            .filter(tTable[DbTranslation.id] != tIdExclude)
            .filter(tTable[DbTranslation.english] != excludeEnglishVal)
            .join(rTable, on: tTable[DbTranslation.id] == rTable[DbResult.translation_fk])
            .select(allSelect)
            .filter(rTable[DbResult.language_displayed] == dispLang)
//        .select(tTable[DbTranslation.id], tTable[DbTranslation.blanks])
            
        if dueDateDelimiter != nil {
            newSelectResult = newSelectResult.filter(rTable[DbResult.due_date] < dueDateDelimiter)
        }
            
        if t_to_t_fkRef != -1 {
            newSelectResult = newSelectResult.filter(tTable[DbTranslation.fk_parent] == t_to_t_fkRef)
        }
        
        newSelectResult = newSelectResult.order(rTable[DbResult.due_date].asc)
        
        let translationRow: Row! = try self.dbConn.pluck(newSelectResult)
        
        if translationRow == nil {
//            print("Function: \(#function):\(#line), Error: stuff not found...print more vars")
            throw "DbTranslation row not found in getTranslationForOldestDueByNowResult"
        }
        return SpecificDbTranslation(dbRow: translationRow,
                                     displayLanguage: translationRow[DbResult.language_displayed])
    }
    
    // TODO: Verify if no DB
    func getCountDueTotal(tTableName: String, hoursFromNow: Int = 0) -> Int {
        var returnCount: Int = 0
        do {
            returnCount += try self.getResultDueAfterMarginCount(rTableName: tTableName + DbResult.nameSuffix,
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
    func getResultDueAfterMarginCount(rTableName: String, hoursFromNow: Int = 10) throws -> Int {
        let futureDate: Date = DateMath.getDateHoursFromNow(minutesAhead: hoursFromNow * 60)
        
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
            answered_values.append(result_row[DbResult.translation_fk] ?? -1)
        }
        
        let extractedExpr: Table = Table(tTableName)
            .filter(!answered_values.contains(DbTranslation.id))
        
        return try self.dbConn.scalar(extractedExpr.count)
    }
        
    func createResultDbTableIfNotExists(tTableName: String) {
        do {
            try self.dbConn.run(DbResult.tableCreationString(tTableName: tTableName))
//            print("DB :: Created \(tTableName)\(DbResult.nameSuffix) Table or it already existed")
        } catch {
            print("DB Error :: DID NOT CREATE RESULT TABLE")
            print("Function: \(#function):\(#line), Error: \(error)")
        }
    }
    
    func getEasiestUnansweredTranslation(tTableName: String,
                                         tIdExclude: Int = -1,
                                         t_to_t_fkRef: Int = -1,
                                         excludeEnglishVal: String = "",
                                         dispLang: String) throws -> DbTranslation {
        
        do {
            self.createResultDbTableIfNotExists(tTableName: tTableName)
            let tTable: Table = Table(tTableName)
            let rTable = Table(tTableName + DbResult.nameSuffix)
            
            var selectTranslation = tTable.select(DbTranslation.getStandardSelect(table: tTable))
                .filter(tTable[DbTranslation.id] != tIdExclude)
                .join(JoinType.leftOuter, rTable, on: tTable[DbTranslation.id] == rTable[DbResult.translation_fk])
                .filter(tTable[DbTranslation.english] != excludeEnglishVal)
                .filter(rTable[DbResult.translation_fk] == nil)
            
            
            if t_to_t_fkRef != -1 {
                selectTranslation = selectTranslation.filter(tTable[DbTranslation.fk_parent] == t_to_t_fkRef)
            }
            
            selectTranslation = selectTranslation.order(tTable[DbTranslation.difficulty].asc)
            
            let translationRow: Row! = try self.dbConn.pluck(selectTranslation)
            if translationRow == nil {
                throw "Function: \(#function):\(#line) :: Unique database \"\(tTableName)\" not found with lots of variables"
            }
            
            // TODO: Make this 50/50 whether english or mandarin-simplified is returned, will have to update logging default paradigm
            return SpecificDbTranslation(dbRow: translationRow,
                                         displayLanguage: dispLang)
        } catch {
            print("Function: \(#function):\(#line), Error: \(error) - \(tTableName) \(tIdExclude) \(t_to_t_fkRef) \(excludeEnglishVal)")
            throw error
        }
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
    func getRowsInTranslationTableWithDifficulty(_ table: Table, _ difficulty: Int) -> Int {
        do {
            let tableDiffFilterCount = table
            .filter(DbTranslation.difficulty == difficulty * 10)
            .count
            return try self.dbConn.scalar(tableDiffFilterCount)
        } catch {
            print("Function: \(#function):\(#line), Error: \(error)")
            return 0
        }
    }
     
    // TODO: Verify if no DB
    func getLogRowsCountWithDifficulty(_ difficulty: Int) -> Int {
        do {
            let lTable: Table = DbLogWords.table
            let tTable: Table = DbTranslation.hskTable
            let tableDiffFilterCount = lTable
                .join(tTable, on: lTable[DbLogWords.hsk_fk] == tTable[DbTranslation.id])
                .filter(DbTranslation.difficulty == difficulty * 10)
                .count
            return try self.dbConn.scalar(tableDiffFilterCount)
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
    
    func getHskIdFromHanzi(_ hanzi: String) throws -> Int {
        let hskRow: Row! = try self.dbConn.pluck(DbTranslation.hskTable.select(DbTranslation.id).filter(DbTranslation.hanzi == hanzi))
        if hskRow == nil {
            throw "Hanzi does not exist \(hanzi)"
        } else {
            let hskId = hskRow[DbTranslation.id]
            return hskId
        }
    }
    
    func insertNewHskAndLogSpokenWord(hanziWord: String, pinyinWord: String) {
        // ELSE   Create new HSK_8 reference and log group
        do {
            let hskInsert = DbTranslation.hskTable.insert(DbTranslation.hanzi <- hanziWord,
                                                          DbTranslation.pinyin <- pinyinWord,
                                                          DbTranslation.difficulty <- 80)
            let insertId = try self.dbConn.run(hskInsert)
            print("HSK not found for \(hanziWord)")
            try self.logWordsSpoken(hskWordId: Int(insertId))
        } catch {
            print("Function: \(#function):\(#line), Error: \(error) - HSK_8 failed \(hanziWord)")
        }
    }
    
    func logSpokenProgressChars(hanziWord: String, pinyinWord: String) {
        do {
            // ELIF   ALL chars have an hsk reference, then they all get in individually
            var hskIds: [Int] = []
            for idx in 0..<hanziWord.count {
                let hanziChar = hanziWord[idx]
                hskIds.append(try self.getHskIdFromHanzi(hanziChar))
            }
            
            for hskId in hskIds {
                try self.logWordsSpoken(hskWordId: hskId)
            }
        } catch {
            insertNewHskAndLogSpokenWord(hanziWord: hanziWord, pinyinWord: pinyinWord)
        }
    }
    
    func logSpokenProgressWords(hanzi: String, pinyinBackup: String) {

        let hanziWords: [String] = hanzi.components(separatedBy: " ")
        let pinyinWords: [String] = pinyinBackup.components(separatedBy: " ")
        for idx in 0..<hanziWords.count {
            let hanziWord = hanziWords[idx]
            do {
                let hskId = try self.getHskIdFromHanzi(hanziWord)
                try self.logWordsSpoken(hskWordId: hskId)
            } catch {
                logSpokenProgressChars(hanziWord: hanziWord, pinyinWord: pinyinWords[idx])
            }
        }
    }
    
    func logSpokenProgressWhole(_ quizInfo: DbTranslation) {
        let hanziToLogSpoken = self.convertHanziToLogSpoken(quizInfo.getHanzi())
        
        do {
            let hskId = try self.getHskIdFromHanzi(hanziToLogSpoken)
            try self.logWordsSpoken(hskWordId: hskId)
        } catch {
            logSpokenProgressWords(hanzi: hanziToLogSpoken, pinyinBackup: quizInfo.getPinyin())
        }
    }
    
    func convertHanziToLogSpoken(_ hanzi: String) -> String {
        let words: [String] = hanzi.components(separatedBy: " ")
        
        var returnWords: [String] = []
        
        for word in words {
            print("ABC \(word)")
            let withoutPunc = word.withoutPunctuationAndSpaces()
            if withoutPunc.isArabicNumeral() {
                returnWords.append(withoutPunc.toRoughHanziNumeral())
            } else {
                returnWords.append(withoutPunc)
            }
        }
        
        //TODO: Use existing removal of puncuation method. Consider moving that to string class
        
        //TODO: Write this, remove puncuation and arabic numerals
        
        let returnString: String = returnWords.joined(separator: " ")
        let returnStringNoDs = returnString.replacingOccurrences(of: "  ", with: " ")
        let returnStringNoExtraWs = returnStringNoDs.trimmingCharacters(in: .whitespacesAndNewlines)
        return returnStringNoExtraWs
    }
    
    // TODO: Verify if no DB
    func logResult(letterGrade: String,
                   quizInfo: DbTranslation,
                   pinyinOn: Bool,
                   attempts: Int) {
        let languageDisplayed = quizInfo.getLanguageToDisplay() // or english
        let languagePronounced = "Mandarin" // always
        let pronunciationHelp = pinyinOn ? "On" : "Off"

        // Logging words that were spoken
        if letterGrade == "B" || letterGrade == "A" {
            logSpokenProgressWhole(quizInfo)
        }
        
        // Logging Result Rows
        let resultTableName = DbTranslation.tableName + DbResult.nameSuffix
        do {
            let resultRow: DbResult = try self.getResultRow(resultTableName: resultTableName,
                                                            languageDisplayed: languageDisplayed,
                                                            translationId: quizInfo.getId())
            let newDueDate: Date = DateMath.getUpdatedDueDate(newGrade: letterGrade,
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
                let newOtherLanguage = languageDisplayed == LanguageDisplayed.English.rawValue ? LanguageDisplayed.MandarinSimplified.rawValue : LanguageDisplayed.English.rawValue
                
                let answeredInsert: Insert = DbResult
                    .getInsert(tableName: resultTableName,
                               fk: quizInfo.getId(),
                               due_date: DateMath.getNewDueDate(grade: letterGrade),
                               letterGrade: letterGrade,
                               languageDisplayed: languageDisplayed,
                               pronunciationHelp: pronunciationHelp,
                               languagePronounced: languagePronounced)
                
                let otherLangInsert: Insert = DbResult
                    .getInsert(tableName: resultTableName,
                               fk: quizInfo.getId(),
                               due_date: DateMath.getNewDueDate(grade: "5"),
                               letterGrade: "C",
                               languageDisplayed: newOtherLanguage,
                               pronunciationHelp: "Off",
                               languagePronounced: languagePronounced)
                
                try self.dbConn.run(answeredInsert)
                try self.dbConn.run(otherLangInsert)
            } catch {
                print("Function: \(#function):\(#line), Error: \(error) - Insert failed")
            }
        }
    }
    
    // TODO: Verify if no DB
    func getHskPinyins(_ transcription: String) -> [String] {
        let transcriptionQuery = DbTranslation.hskTable.filter(DbTranslation.hanzi == transcription)
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
    
    func logWordsSpoken(hskWordId: Int) throws {
        let count: Int!
        do {
            count = try self.dbConn.scalar(DbLogWords.table
                .filter(DbLogWords.hsk_fk == hskWordId)
                .count)
        } catch {
            count = 0
            try self.dbConn.run(DbLogWords.tableCreationString())
        }
         
        if count == 0 {
            try self.dbConn.run(DbLogWords.getInsert(hskWordId: hskWordId))
        } else {
            try self.dbConn.run(DbLogWords.getUpdate(hskWordId: hskWordId))
        }
    }
    
    // TODO: Verify if no DB
    func getLogWordsAnswered(hskLevel: Int, answered: Bool) throws -> [String] {
        let tTable = DbTranslation.hskTable
        let lwTable = DbLogWords.table
        var statement = tTable
        
        if hskLevel <= 60 {
            statement = statement.filter(DbTranslation.difficulty == hskLevel)
        } else {
            statement = statement.filter(DbTranslation.difficulty >= hskLevel)
        }
            
            
        if answered {
            statement = statement.join(lwTable, on: tTable[DbTranslation.id] == lwTable[DbLogWords.hsk_fk])
                
            
        } else {
            statement = statement
            
            
            
            .join(JoinType.leftOuter, lwTable, on: tTable[DbTranslation.id] == lwTable[DbLogWords.hsk_fk])
            .filter(lwTable[DbLogWords.hsk_fk] == nil)
        }
        
        
        var loggedValues:[String] = []
        for tRow in try self.dbConn.prepare(statement) {
            let value = tRow[DbTranslation.hanzi]
            
            loggedValues.append(value)
        }
        
        return loggedValues
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
