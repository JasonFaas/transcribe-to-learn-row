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

    // TODO: ENABLE ONLY IF WANTING TO RESET DATABASE
    // TODO: Regularlly turn this to true to verify it still works
    let deleteExistingAndCopyNew: Bool = true
    
    init() {
        
    }
    
    func setupConnection() -> Connection {

        let importSqlFileName: String = "first.sqlite3"
        let fileManager: FileManager = FileManager.default
        
        let fromDocumentsurl: Array<URL> = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let finalDatabaseURL: URL = fromDocumentsurl.first!.appendingPathComponent(importSqlFileName)
        
        // TODO: If database does not exist, copy database over
        if deleteExistingAndCopyNew {
            self.dropTranslationDb(finalDatabaseURL, fileManager)
        }
        
        self.copyDatabaseToDevice(finalDatabaseURL, importSqlFileName, fileManager)
        
        let connection: Connection = self.createDatabaseConnection(importSqlFileName, fileManager)
        
        if deleteExistingAndCopyNew {
            self.dropDbResultTable(connection)
        }
        self.createResultDbTableIfNotExists(connection)
        
        return connection
    }
    
    func dropTranslationDb(_ finalDatabaseURL: URL, _ fileManager: FileManager) {
        do {
            try fileManager.removeItem(at: finalDatabaseURL)
        } catch {
            print("No database to remove on device")
            print("Function: \(#function):\(#line), Error: \(error)")
            print("Not exiting, but think about it?")
        }
    }
    
    func createDatabaseConnection(_ importSqlFileName: String, _ fileManager: FileManager) -> Connection {
        let documentsURL: URL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        do {
            let clientsFileUrl = documentsURL.appendingPathComponent(importSqlFileName)
            return try Connection(clientsFileUrl.path)
        } catch {
            print("Function: \(#function):\(#line), Error: \(error)")
            print("DB Setup Error")
            exit(0)
        }
    }
        
    func dropDbResultTable(_ sqliteConnection: Connection) {
        do {
            try sqliteConnection.run(DbResult.table.drop())
            print("DB :: Dropped RESULT Table")
        } catch {
            print("Function: \(#function):\(#line), Error: \(error)")
        }
    }
        
    func createResultDbTableIfNotExists(_ sqliteConnection: Connection) {
        do {
            try sqliteConnection.run(DbResult.tableCreationString())
            print("DB :: Created RESULT Table or it already existed")
        } catch {
            print("DB Error :: DID NOT CREATE RESULT TABLE")
            print("Function: \(#function):\(#line), Error: \(error)")
        }
    }
    
    fileprivate func copyDatabaseToDevice(_ finalDatabaseURL: URL, _ importSqlFileName: String, _ fileManager: FileManager) {
        if !((try? finalDatabaseURL.checkResourceIsReachable()) ?? false) {
            print("DB :: does not exist in documents folder")
            let finalDocumentsURL = Bundle.main.resourceURL?.appendingPathComponent(importSqlFileName)
            do {
                try fileManager.copyItem(atPath: (finalDocumentsURL?.path)!, toPath: finalDatabaseURL.path)
                print("DB :: copied over")
            } catch let error as NSError {
                print("DB Error :: Couldn't copy file to final location! Error:\(error.description)")
            }
        } else {
            print("DB Error :: Database file found at path: \(finalDatabaseURL.path)")
        }
    }
}
