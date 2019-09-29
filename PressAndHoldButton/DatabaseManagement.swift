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
    var resultsDatabase: Connection!
    
    // First import
    
    let translationsTable = Table("Translations")
    
    
    
    // Example
    let resultsTable = Table("Results")
    let id = Expression<Int>("id")
    
    let phrase = Expression<String>("phrase")
    let lastGrade = Expression<String>("lastGrade")
    let pinyinDisplayed = Expression<Bool>("pinyinDisplayed")
    
    var translationsDatabase: Connection!
    
    init() {
        self.createDatabaseConnection()
        self.createDatabaseTable()
    }
    
    
    func createDatabaseConnection() {
        
        do {
            let documentDirectory = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true)
            
            //TODO: Remove code for results database
            let fileUrl = documentDirectory.appendingPathComponent("results").appendingPathExtension("sqlite3")
            self.resultsDatabase = try Connection(fileUrl.path)
            print("Original db working")
            
            
            let importSqlFileName = "first.sqlite3"
            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let clientsFileUrl = documentsURL.appendingPathComponent(importSqlFileName)
            let fromDocumentsurl = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
            let finalDatabaseURL = fromDocumentsurl.first!.appendingPathComponent(importSqlFileName)
            do {
                try fileManager.removeItem(at: finalDatabaseURL)
            } catch {
                print("No database to remove on device")
            }
            
            if !((try? finalDatabaseURL.checkResourceIsReachable()) ?? false) {
                print("DB does not exist in documents folder")
                let finalDocumentsURL = Bundle.main.resourceURL?.appendingPathComponent(importSqlFileName)
                do {
                    try fileManager.copyItem(atPath: (finalDocumentsURL?.path)!, toPath: finalDatabaseURL.path)
                } catch let error as NSError {
                    print("Couldn't copy file to final location! Error:\(error.description)")
                }
            } else {
                print("Database file found at path: \(finalDatabaseURL.path)")
            }
            
            self.translationsDatabase = try Connection(clientsFileUrl.path)
                                    
        } catch {
            print(error)
            print("DB Setup Error")
            exit(0)
        }
    }
    
    func getRandomRowFromTranslations() -> DbTranslation {
        do {
            
            let rows: Int64 = try self.translationsDatabase.scalar("SELECT count(*) FROM Translations") as! Int64
            let random_int = Int.random(in: 1 ..< Int(rows))
            
            let extractedExpr: Table = translationsTable.filter(Expression<Int>("generated_id") == random_int)
            
            for translation in try self.translationsDatabase.prepare(extractedExpr) {
                let dbTranslation = SpecificDbTranslation(dbRow: translation)
                try dbTranslation.verifyAll()
                
                return dbTranslation
            }
            
        } catch {
            print(error.localizedDescription)
            print("Random row failure")
            
            return DbTranslation()
        }
        print("No row failure")
        return DbTranslation()
    }
    
    func createDatabaseTable() {
        
        let createTable = self.resultsTable.create { (table) in
            table.column(self.id, primaryKey: true)
            table.column(self.lastGrade)
            table.column(self.phrase, unique: true)
            table.column(self.pinyinDisplayed)
        }
        
        do {
            print("Dropping Table")
            try self.resultsDatabase.run(resultsTable.drop())
        } catch {
            print(error)
        }
        
        do {
            print("Creating Table")
            try self.resultsDatabase.run(createTable)
            print("Created Table")
        } catch {
            print("DID NOT CREATE TABLE")
            print(error)
        }
    }
    
    
    
    func logResult(letterGrade: String, quizInfo: DbTranslation, pinyinOn: Bool) {
        print("Logging:")
        
        // let pinyinOn = self.pinyinOn
//        let currentHanzi = self.fullTranslations[self.translationValue % self.fullTranslations.count].simplifiedChar
        do {
            let currentPhraseResult = resultsTable.filter(self.phrase == hanzi)
            let currentInTable = currentPhraseResult.count
            let count = try self.resultsDatabase.scalar(currentInTable)
            let currentPhraseinDatabase: Bool = count != 0
            
            if currentPhraseinDatabase {
                let insertResult = self.resultsTable.insert(self.phrase <- hanzi,
                                                            self.lastGrade <- letterGrade,
                                                            self.pinyinDisplayed <- pinyinOn)
                try self.resultsDatabase.run(insertResult)
            } else {
                let updateResult = currentPhraseResult.update(self.lastGrade <- letterGrade,
                                                              self.pinyinDisplayed <- pinyinOn)
                try self.resultsDatabase.run(updateResult)
            }
            
            print("\t\(hanzi)")
            print("\t\(letterGrade)")
        } catch {
            print(error)
        }
    }
    
    func insertRowIntoResults(dbResult: DbResult) {
        
        
        self.translationsDatabase.run(dbResult.getInsert())
    }
}

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

class DbTranslation {
    
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
    let id = Expression<Int>("generated_id")
    let hanzi = Expression<String>("Hanzi")
    let pinyin = Expression<String>("Pinyin")
    let english = Expression<String>("English")
    let difficulty = Expression<Int>("Difficulty")
    
    var intElements: Array<Expression<Int>>!
    var stringElements: Array<Expression<String>>!
    
    let dbRow: Row!
        
    init(dbRow: Row) {
        self.dbRow = dbRow
        // TODO populate these dynamically
        intElements = [id, difficulty]
        stringElements = [hanzi, pinyin, english]
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
        self.dbRow[self.id]
    }
    
    override func getHanzi() -> String {
        self.dbRow[self.hanzi]
    }
    
    override func getPinyin() -> String {
        self.dbRow[self.pinyin]
    }
    
    override func getEnglish() -> String {
        self.dbRow[self.english]
    }
    
    override func getDifficulty() -> Int {
        self.dbRow[self.difficulty]
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
    let resultsTable = Table("Results")
    
    let dbDict: [String: Any] = [
        "id": Expression<Int>("id"),
        "translation_fk": Expression<Int>("translation"),
        "difficulty": Expression<String>("difficulty"),
        "due_date": Expression<Date>("due_date"),
        "last_grade": Expression<String>("last_grade"),
        "language_displayed": Expression<String>("language_displayed"), //TODO: enum to English, Mandarin-Simplified, or Mandarin-Pinyin
        "like": Expression<Bool>("like")
    ]
    
    let valuesDict: [String: Any] = [:]
    
    var intElements: Array<Expression<Int>>!
    var stringElements: Array<Expression<String>>!
    
    let dbRow: Row!
    
    init(dbRow: Row) {
        
    }
    
    func getInsert(translation: DbTranslation, grade: String, languageDisplayed: String) -> Insert {
        let now: Date = Date()
        let calendar: Calendar = Calendar.current
        let minutesAhead: Int = self.generalDateAdding[grade, default: 1]
        let interval: DateComponents = DateComponents(calendar: calendar, timeZone: nil, era: nil, year: nil, month: nil, day: nil, hour: nil, minute: minutesAhead, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
        let dueDate: Date = calendar.date(byAdding: interval, to: now) ?? <#default value#>
        
        return resultsTable.insert(
            self.dbDict["translation_fk"] as! Expression<Int> <- translation.getId(),
            self.dbDict["difficulty"] as! Expression<Int> <- translation.getDifficulty(),
            self.dbDict["due_date"] as! Expression<Date> <- dueDate, // TODO: This may need to be fixed
            self.dbDict["last_grade"] as! Expression<String> <- "B",
            self.dbDict["language_displayed"] as! Expression<String> <- languageDisplayed, // TODO: use enum
            self.dbDict["like"] as! Expression<Bool> <- true // TODO: use enum
        )
    }
        
//    init(dbRow: Row) {
//        self.dbRow = dbRow
//        // TODO populate these dynamically
//        intElements = [id, difficulty]
//        stringElements = [hanzi, pinyin, english]
//    }
//
//    override func verifyAll() throws {
//        for intElement in self.intElements {
//            if self.dbRow[intElement] < 0 {
//                throw "bad int element \(intElement)"
//            }
//        }
//        for stringElement in self.stringElements {
//            if self.dbRow[stringElement].count <= 0 {
//                throw "bad string element \(stringElement)"
//            }
//        }
//    }
//
//    override func getId() -> Int {
//        self.dbRow[self.id]
//    }
//
//    override func getHanzi() -> String {
//        self.dbRow[self.hanzi]
//    }
//
//    override func getPinyin() -> String {
//        self.dbRow[self.pinyin]
//    }
//
//    override func getEnglish() -> String {
//        self.dbRow[self.english]
//    }
//
//    override func getDifficulty() -> Int {
//        self.dbRow[self.difficulty]
//    }
}
