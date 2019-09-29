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
            for row in try translationsDatabase.prepare("SELECT * FROM sqlite_master WHERE type='table'") {
                print(row[1])
            }
                        
        } catch {
            print(error)
            print("DB Setup Error")
            exit(0)
        }
    }
    
    func getRandomRowFromTranslations() throws -> DbTranslation {
        do {
            
            let random_int = Int.random(in: 1 ..< 6)
            print(random_int)
            let extractedExpr: Table = translationsTable.filter(Expression<Int>("generated_id") < random_int)
            
            for translation in try self.translationsDatabase.prepare(extractedExpr) {
                let dbTranslation = DbTranslation(dbRow: translation)
                try dbTranslation.verifyAll()
                
                print("Jason")
                print(dbTranslation.getHanzi())
            }
            print("End")
            
            for translation in try self.translationsDatabase.prepare(translationsTable) {
                let dbTranslation = DbTranslation(dbRow: translation)
                try dbTranslation.verifyAll()
                
                return dbTranslation
            }
        } catch {
            print(error.localizedDescription)
            throw "Random row failure"
        }
        throw "No row failure"
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
    
    
    
    func logResult(letterGrade: String, hanzi: String, pinyinOn: Bool) {
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
}

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}


typealias TranslationWhat = (
    id: Int64?,
    hanzi: String?,
    pinyin: String?,
    english: String?,
    difficulty: Int64?
)

class TranslationOrmStyle {
    static let TABLE_NAME = "Teams"
    
    static let table = Table(TABLE_NAME)
    
    static let id = Expression<Int64>("generated_id")
    static let hanzi = Expression<String>("Hanzi")
    static let pinyin = Expression<String>("Pinyin")
    static let english = Expression<String>("English")
    static let difficulty = Expression<Int64>("Difficulty")
    
    
    typealias T = TranslationWhat
    
    
    static func find(input_id: Int64) throws -> T? {
//        guard let DB = SQLiteDataStore.sharedInstance.BBDB else {
//            throw DataAccessError.Datastore_Connection_Error
//        }
        let query = table.filter(id == input_id)
        print("A")
        
        //TODO: Duplicate setups of connecting to database. Remove one when it is known that this is working
        let importSqlFileName = "first.sqlite3"
        print("B")
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        print("C")
        let clientsFileUrl = documentsURL.appendingPathComponent(importSqlFileName)
        
        // TODO: put this creation somewhere else. Very slow
        let translationsDatabase = try Connection(clientsFileUrl.path)
        print("D")
        let items = try translationsDatabase.prepare(query)
        print("E")
        for item in items {
            print("F")
            return TranslationWhat(id: item[id], hanzi: item[hanzi], pinyin: item[pinyin], english: item[english], difficulty: item[difficulty])
        }
       print("G")
        return nil
       
    }
}


class DbTranslation {
    
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
    
    func verifyAll() throws {
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
    
    func getId() -> Int {
        self.dbRow[self.id]
    }
    
    func getHanzi() -> String {
        self.dbRow[self.hanzi]
    }
    
    func getPinyin() -> String {
        self.dbRow[self.pinyin]
    }
    
    func getEnglish() -> String {
        self.dbRow[self.english]
    }
    
    func getDifficulty() -> Int {
        self.dbRow[self.difficulty]
    }
    
    
}
