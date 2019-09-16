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
    let hanzi = Expression<String>("Hanzi")
    let pinyin = Expression<String>("Pinyin")
    let english = Expression<String>("English")
    let difficulty = Expression<Int>("Difficulty")
    
    // Example
    let resultsTable = Table("Results")
    let id = Expression<Int>("id")
    
    let phrase = Expression<String>("phrase")
    let lastGrade = Expression<String>("lastGrade")
    let pinyinDisplayed = Expression<Bool>("pinyinDisplayed")
    
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
            
            let translationsDatabase = try Connection(clientsFileUrl.path)
            for row in try translationsDatabase.prepare("SELECT * FROM sqlite_master WHERE type='table'") {
                print(row[1])
            }
            
            print("Near")
            
            for translation in try translationsDatabase.prepare(translationsTable) {
                print(translation[self.hanzi])
                print(translation[self.english])
                print(translation[self.pinyin])
                print(translation[self.difficulty])
                print("")
            }
            
            print("Far?")
            
        } catch {
            print(error)
            print("DB Setup Error")
            exit(0)
        }
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


class Clients {
    let id: Int64?
    var col1: String
    var col2: String
    
    init(id: Int64, col1: String, col2: String) {
        self.id = id
        self.col1 = col1
        self.col2 = col2
    }
}
