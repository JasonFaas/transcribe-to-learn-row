//
//  DbSettings.swift
//  Say Again Mandarin
//
//  Created by Jason A Faas on 2/18/20.
//  Copyright © 2020 Jason A Faas. All rights reserved.
//

import Foundation

import SQLite

class DbSettings {
    
    static let table:Table = Table("Settings")
    
    static let settingEnglish: String = "English"
    static let settingMandarinSimplified: String = "Mandarin-Simplified"
    static let settingPinyinDefaultOn: String = "PinyinDefaultOn"
    
    static let defaultSettings: [String:Bool] = [
        DbSettings.settingEnglish:true,
        DbSettings.settingMandarinSimplified:true,
        DbSettings.settingPinyinDefaultOn:true,
    ]
    
    static let id = Expression<Int>("id")
    static let setting_col = Expression<String>("setting")
    static let is_enabled_col = Expression<Bool>("is_enabled")

    static func tableCreationString() -> String {
        return table.create(ifNotExists: true) { t in
            t.column(DbSettings.id, primaryKey: true)
            t.column(DbSettings.setting_col, unique: true)
            t.column(DbSettings.is_enabled_col, defaultValue: false)
        }
    }
    
    static func getInsert(setting: String, val: Bool) -> Insert {
        let insert = DbSettings.table.insert(DbSettings.setting_col <- setting,
                                             DbSettings.is_enabled_col <- val)
        return insert
    }
    
    static func getUpdate(setting: String, val: Bool) -> Update {
        let update = DbSettings.table.filter(DbSettings.setting_col == setting)
                                      .update(DbSettings.is_enabled_col <- val)
        return update
    }
    
}
