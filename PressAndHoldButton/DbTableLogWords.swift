//
//  DbTableLogWords.swift
//  PressAndHoldButton
//
//  Created by Jason A Faas on 2/2/20.
//  Copyright © 2020 Jason A Faas. All rights reserved.
//

import Foundation

import SQLite

class DbLogWords {
    
    static let table:Table = Table("Log_Words")
    
    static let id = Expression<Int>("id")
    static let hsk_fk = Expression<Int?>("hsk_fk")
    static let count = Expression<Int>("count")
    static let date_updated = Expression<Date>("date_updated")
    static let date_created = Expression<Date>("date_created")
    
    


    static func tableCreationString() -> String {
        
        return table.create(ifNotExists: true) { t in
            t.column(DbLogWords.id, primaryKey: true)
            t.column(DbLogWords.hsk_fk, unique: true)
            t.column(DbLogWords.count, defaultValue: 1)
            t.column(DbLogWords.date_updated) // TODO: Verify new date in all of them
            t.column(DbLogWords.date_created) // TODO: Verify new date in all of them

            t.foreignKey(DbLogWords.hsk_fk,
                         references: DbTranslation.hskTable, DbTranslation.id)
        }
    }
    
    static func getInsert(hskWordId: Int) -> Insert {
        let this_date = Date()
        let insert = DbLogWords.table.insert(DbLogWords.hsk_fk <- hskWordId,
                                             DbLogWords.date_updated <- this_date,
                                             DbLogWords.date_created <- this_date)
        return insert
    }
    
    static func getUpdate(hskWordId: Int) -> Update {
        let update = DbLogWords.table.filter(DbLogWords.hsk_fk == hskWordId)
                                      .update(DbLogWords.count += 1,
                                              DbLogWords.date_updated <- Date())
        return update
    }
    
}
