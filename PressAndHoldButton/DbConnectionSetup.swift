//
//  DbConnectionSetup.swift
//  PressAndHoldButton
//
//  Created by Jason A Faas on 11/27/19.
//  Copyright © 2019 Jason A Faas. All rights reserved.
//

import Foundation

import SQLite

class DbConnectionSetup {
    
    init() {
        
    }
    
    func setupConnection() -> Connection {
        let connection: Connection = self.createDatabaseConnection()
        self.createDatabaseTable(connection)
        
        return connection
    }
    
    func createDatabaseConnection() -> Connection {
        do {
            let importSqlFileName = "first.sqlite3"
            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let clientsFileUrl = documentsURL.appendingPathComponent(importSqlFileName)
            let fromDocumentsurl = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
            let finalDatabaseURL = fromDocumentsurl.first!.appendingPathComponent(importSqlFileName)
            deleteFirstSqliteIfExistsToReset(fileManager, finalDatabaseURL)
            copyDatabaseToDevice(finalDatabaseURL, importSqlFileName, fileManager)
            
            return try Connection(clientsFileUrl.path)
        } catch {
            print("Function: \(#function):\(#line), Error: \(error)")
            print("DB Setup Error")
            exit(0)
        }
    }
        
    func createDatabaseTable(_ sqliteConnection: Connection) {
        do {
            print("Attempting to Drop RESULT Table")
            try sqliteConnection.run(DbResult.table.drop())
        } catch {
            print("Function: \(#function):\(#line), Error: \(error)")
        }
        
        do {
            let createTable = DbResult.getCreateTable()
            try sqliteConnection.run(createTable)
            print("Created RESULT Table")
        } catch {
            print("DID NOT CREATE RESULT TABLE")
            print("Function: \(#function):\(#line), Error: \(error)")
        }
    }
    
    fileprivate func copyDatabaseToDevice(_ finalDatabaseURL: URL, _ importSqlFileName: String, _ fileManager: FileManager) {
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
    }
    
    fileprivate func deleteFirstSqliteIfExistsToReset(_ fileManager: FileManager, _ finalDatabaseURL: URL) {
        do {
            try fileManager.removeItem(at: finalDatabaseURL)
        } catch {
            print("No database to remove on device")
        }
    }
}
