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
    
    let fileManager: FileManager!
    init() {
        self.fileManager = FileManager.default
    }
    
    func setupConnection(copyNewDb: Bool, deleteResultsDb: Bool) -> Connection {
        print("Setting up DbConn")
        let dbFileName: String = "first.sqlite3"

        let dbUrlPhone: URL = self.fileManager.urls(for: .documentDirectory, in: .userDomainMask)
                                         .first!
                                         .appendingPathComponent(dbFileName)
        let dbUrlXcode = Bundle.main.resourceURL?.appendingPathComponent(dbFileName)
        
        let isDbOnPhone: Bool = fileManager.fileExists(atPath: dbUrlPhone.path)
        
        
        var dbOnPhoneCreationDate: Date = Date()
        var dbOnXcodeCreationDate: Date = Date()
        
        do {
            if isDbOnPhone {
                let dbPhoneAttrs = try FileManager.default.attributesOfItem(atPath: dbUrlPhone.path) as NSDictionary
                dbOnPhoneCreationDate = dbPhoneAttrs.fileCreationDate()!
                print("Db on Phone Creation Date \(dbOnPhoneCreationDate)")
            }
            let dbXcodeAttrs = try FileManager.default.attributesOfItem(atPath: dbUrlXcode!.path) as NSDictionary
            dbOnXcodeCreationDate = dbXcodeAttrs.fileCreationDate()!
            print("Db on Xcode Creation Date \(dbOnXcodeCreationDate)")
        } catch {
            dbOnPhoneCreationDate = Date()
            sleep(1)
            dbOnXcodeCreationDate = Date()
            print("Just trying to get file details")
        }
        
        let dbCreationDatesSame: Bool = dbOnPhoneCreationDate == dbOnXcodeCreationDate
        
        if !isDbOnPhone || !dbCreationDatesSame || copyNewDb {
            if isDbOnPhone {
                self.removeSqlliteFile(dbUrlPhone)
            }
            self.copyDatabaseToDevice(dbUrlPhone, dbFileName)
        }
        
        let connection = self.createDatabaseConnection(dbFileName)
        
        if deleteResultsDb {
            self.dropTable(sqlConn: connection, tableToDrop: Table(DbTranslation.tableName + DbResult.nameSuffix))
        }
        
        return connection
    }
    
    func removeSqlliteFile(_ dbUrl: URL) {
        do {
            try self.fileManager.removeItem(at: dbUrl)
        } catch {
            print("Function: \(#function):\(#line), Error: \(error)...\nNo database to remove on device")
            exit(0)
        }
    }
    
    func createDatabaseConnection(_ importSqlFileName: String) -> Connection {
        let documentsURL: URL = self.fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        do {
            let clientsFileUrl = documentsURL.appendingPathComponent(importSqlFileName)
            return try Connection(clientsFileUrl.path)
        } catch {
            print("Function: \(#function):\(#line), Error: \(error)...\nDB Setup Error")
            exit(0)
        }
    }
        
    func dropTable(sqlConn: Connection, tableToDrop: Table) {
        do {
            try sqlConn.run(tableToDrop.drop())
            print("\tDB :: Dropped a table")
        } catch {
            print("Function: \(#function):\(#line), Error: \(error)")
        }
    }
    
    fileprivate func copyDatabaseToDevice(_ dbUrl: URL, _ importSqlFileName: String) {
        if !((try? dbUrl.checkResourceIsReachable()) ?? false) {
            print("\tDB :: does not exist in documents folder")
            let finalDocumentsURL = Bundle.main.resourceURL?.appendingPathComponent(importSqlFileName)
            do {
                try self.fileManager.copyItem(atPath: (finalDocumentsURL?.path)!, toPath: dbUrl.path)
                print("\tDB :: copied over")
            } catch let error as NSError {
                print("\tDB Error :: Couldn't copy file to final location! Error:\(error.description)")
            }
        } else {
            print("\tDB Error :: Database file found at path: \(dbUrl.path)")
        }
    }
}
