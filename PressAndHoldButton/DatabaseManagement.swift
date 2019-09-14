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
    var database: Connection!
    
    // Example
    let resultsTable = Table("Results")
    let id = Expression<Int>("id")
    
    let phrase = Expression<String>("phrase")
    let lastGrade = Expression<String>("lastGrade")
    let pinyinDisplayed = Expression<Bool>("pinyinDisplayed")
    
    init() {
        
    }
    
    
    func createDatabaseConnection() {
        
        do {
            let documentDirecotry = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true)
            let fileUrl = documentDirecotry.appendingPathComponent("results").appendingPathExtension("sqlite3")
            
            self.database = try Connection(fileUrl.path)
            
            
        } catch {
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
            try self.database.run(resultsTable.drop())
        } catch {
            print(error)
        }
        
        do {
            print("Creating Table")
            try self.database.run(createTable)
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
            let count = try self.database.scalar(currentInTable)
            let currentPhraseinDatabase: Bool = count != 0
            
            if currentPhraseinDatabase {
                let insertResult = self.resultsTable.insert(self.phrase <- hanzi,
                                                            self.lastGrade <- letterGrade,
                                                            self.pinyinDisplayed <- pinyinOn)
                try self.database.run(insertResult)
            } else {
                let updateResult = currentPhraseResult.update(self.lastGrade <- letterGrade,
                                                              self.pinyinDisplayed <- pinyinOn)
                try self.database.run(updateResult)
            }
            
            print("\t\(hanzi)")
            print("\t\(letterGrade)")
        } catch {
            print(error)
        }
    }
}
