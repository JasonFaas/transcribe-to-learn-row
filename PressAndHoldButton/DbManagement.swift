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
        print("\t\(self.getRowsInTable(table: DbTranslation.table)) Translations")
        print("\t\(self.getRowsInTable(table: DbResult.table)) Results")
    }
    
    func printAllResultsTable() {
        do {
            for result_row in try self.dbConn.prepare(DbResult.table) {
                let dbResult = DbResult(dbRow: result_row)
                dbResult.printInfo()
            }
        } catch {
            print("Why is there nothing to print???")
        }
    }
    
    func getTranslationForOldestDueByNowResult() throws -> DbTranslation {
        let selectResult = DbResult.table.select(DbResult.translation_fk, DbResult.language_displayed)
            .filter(DbResult.due_date < Date())
            .order(DbResult.due_date.asc)
        
        let resultRow: Row! = try self.dbConn.pluck(selectResult)
        
        if resultRow == nil {
            throw "DbResult row not found in getTranslationForOldestDueByNowResult"
        }
        let dbResult = DbResult(dbRow: resultRow)
        
        let selectTranslation = DbTranslation
            .table
            .filter(DbTranslation.id == dbResult.getTranslationFk())
        
        let translationRow: Row! = try self.dbConn.pluck(selectTranslation)
        if translationRow == nil {
            throw "DbTranslation row not found in getTranslationForOldestDueByNowResult"
        }
        
        return SpecificDbTranslation(dbRow: translationRow,
                                     displayLanguage: dbResult.getLanguageDisplayed())
    }
    
    func getNextPhrase(_ rowToNotGet: Int) -> DbTranslation {
        var dbTranslation: DbTranslation!
        
        do {
            dbTranslation = try self.getTranslationForOldestDueByNowResult()
        } catch {
            dbTranslation = self.getEasiestUnansweredRowFromTranslations(rowToNotGet)
        }
        
        self.updateBlanks(dbTranslation)
        
        return dbTranslation
    }
        
    func getEasiestUnansweredRowFromTranslations(_ rowToNotGet: Int) -> DbTranslation {
        do {
            let select_fk_keys = DbResult.table
                .select(DbResult.translation_fk, DbResult.language_displayed)
//                .filter(DbResult.last_grade == "A")
            var answered_values:Array<Int> = [rowToNotGet]
            for result_row in try self.dbConn.prepare(select_fk_keys) {
                answered_values.append(result_row[DbResult.translation_fk])
            }
            
            let extractedExpr: Table = DbTranslation.table
                .filter(!answered_values.contains(DbTranslation.id))
                .order(DbTranslation.difficulty.asc)
            
            for translation in try self.dbConn.prepare(extractedExpr) {
                let dbTranslation = SpecificDbTranslation(dbRow: translation,
                                                          displayLanguage: "Mandarin-Simplified")
                try dbTranslation.verifyAll()
                
                return dbTranslation
            }
        } catch {
            print("Function: \(#function):\(#line), Error: \(error)")
        }
        
        return DbTranslation()
    }
    
    func updateBlanks(_ dbTranslation: DbTranslation) {
        let what = FillInBlanks(dbTranslation: dbTranslation, dbm: self)
        what.processBlanks()
    }
    
    func getSpecificRow(database: String, englishVal: String) throws -> DbTranslation {
        let selectTranslation = Table(database).filter(DbTranslation.english == englishVal)
        
        let translationRow: Row! = try self.dbConn.pluck(selectTranslation)
        if translationRow == nil {
            throw "Unique database \"\(database)\" with specific english value not found \(englishVal)"
        }
        
        return SpecificDbTranslation(dbRow: translationRow,
                                     displayLanguage: "none")
    }

    // TODO: Get rid of the random row usage
    func getRandomRowFromSpecified(database: String, fk_ref: Int = -1, excludeEnglishVal: String = "") throws -> DbTranslation {
         
        var whereHelper: String = ""
        if fk_ref >= 1 {
            whereHelper = "where fk_parent = \(fk_ref) "
        } else if excludeEnglishVal != "" {
            whereHelper = "where \(DbTranslation.english.template) != \"\(excludeEnglishVal)\" "
        }
        
        let random_int: Int64 = try self.dbConn.scalar("SELECT * FROM \(database) \(whereHelper)ORDER BY RANDOM() LIMIT 1;") as! Int64

        let selectTranslation = Table(database).filter(DbTranslation.id == Int(random_int))
    
        let translationRow: Row! = try self.dbConn.pluck(selectTranslation)
        if translationRow == nil {
            throw "Unique database \"\(database)\" not found \(random_int) \(fk_ref)"
        }
        
        return SpecificDbTranslation(dbRow: translationRow,
                                     displayLanguage: "none")
    
    }
    
    func getRowsInTable(table: Table) -> Int {
        do {
            return try self.dbConn.scalar(table.count)
        } catch {
            print("Function: \(#function):\(#line), Error: \(error)")
            return -1
        }
    }
    
    func getRandomRowFromTranslations(_ rowToNotGet: Int) -> DbTranslation {
        do {
            let random_int: Int64 = try self.dbConn.scalar("SELECT * FROM Translations where id != \(rowToNotGet) ORDER BY RANDOM() LIMIT 1;") as! Int64
                        
            let extractedExpr: Table = DbTranslation.table.filter(DbTranslation.id == Int(random_int))
            
            for translation in try self.dbConn.prepare(extractedExpr) {
                let dbTranslation = SpecificDbTranslation(dbRow: translation,
                                                          displayLanguage: "Mandarin-Simplified")
                try dbTranslation.verifyAll()
                
                return dbTranslation
            }
        } catch {
            print("Function: \(#function):\(#line), Error: \(error)")
        }
        
        return DbTranslation()
    }
    
    func getResultRow(languageDisplayed: String, translationId: Int) throws -> DbResult {
    
        let extractedExpr: Table = DbResult.table
            .filter(DbResult.translation_fk == translationId)
            .filter(DbResult.language_displayed == languageDisplayed)
        
        let what: Row! = try self.dbConn.pluck(extractedExpr)
        if what == nil {
            throw "DbResult row not found"
        }
        return DbResult(dbRow: what)
    
    }
    
    func logResult(letterGrade: String,
                   quizInfo: DbTranslation,
                   pinyinOn: Bool,
                   attempts: Int) {
        print("Logging:")
        
        let languageDisplayed = quizInfo.getLanguageToDisplay() // or english
        let languagePronounced = "Mandarin" // always
        var pronunciationHelp = "Off"
        if pinyinOn {
            pronunciationHelp = "On"
        }
        
        do {
            let resultRow: DbResult = try self.getResultRow(languageDisplayed: languageDisplayed,
                                                            translationId: quizInfo.getId())
            let newDueDate: Date = self.getUpdatedDueDate(newGrade: letterGrade,
                                                          lastGrade: resultRow.getLastGrade(),
                                                          lastDate: resultRow.getLastUpdatedDate())

            let update: Update = DbResult.getUpdate(fk: quizInfo.getId(),
                                                   langDisp: languageDisplayed,
                                                   newDueDate: newDueDate,
                                                   letterGrade: letterGrade,
                                                   pronunciationHelp: pronunciationHelp,
                                                   difficulty: quizInfo.getDifficulty())
            
            try self.dbConn.run(update)
            
            print("Row Updated")
        } catch {
            do {
                
                let firstMandarinInsert: Insert = DbResult
                    .getInsert(fk: quizInfo.getId(),
                               difficulty: quizInfo.getDifficulty(),
                               due_date: self.getNewDueDate(grade: letterGrade),
                               letterGrade: letterGrade,
                               languageDisplayed: languageDisplayed,
                               pronunciationHelp: pronunciationHelp,
                               languagePronounced: languagePronounced)
                
                let newEnglishInsert: Insert = DbResult
                    .getInsert(fk: quizInfo.getId(),
                               difficulty: quizInfo.getDifficulty(),
                               due_date: self.getNewDueDate(grade: "5"),
                               letterGrade: "C",
                               languageDisplayed: "English",
                               pronunciationHelp: "Off",
                               languagePronounced: languagePronounced)
                
                try self.dbConn.run(firstMandarinInsert)
                try self.dbConn.run(newEnglishInsert)
            
                print("Now rows created for DbResult Mandarin and English")
            } catch {
                print("update failed: \(error)")
            }
        }
        
        self.printAllResultsTable()
    }
    
    func getNewDueDate(grade: String) -> Date {

        let generalDateAdding: [String: Int] = [
            "A": 60 * 24,
            "B": 60 * 4,
            "C": 60 * 1,
            "D": 60 / 4,
            "F": 60 / 16,
        ]
        let now: Date = Date()
        let calendar: Calendar = Calendar.current
        let minutesAhead: Int = generalDateAdding[grade, default: Int(grade) ?? 1]
        let interval: DateComponents = DateComponents(calendar: calendar, timeZone: nil, era: nil, year: nil, month: nil, day: nil, hour: nil, minute: minutesAhead, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
        let dueDate: Date = calendar.date(byAdding: interval, to: now)!
        
        return dueDate
    }
    
    func getUpdatedDueDate(newGrade: String,
                           lastGrade: String,
                           lastDate: Date) -> Date {

        let generalDateAdding: [String: Float] = [
            "A": 2.0,
            "B": 1.0,
            "C": 0.5,
            "D": 0.25,
            "F": 0.125,
        ]
        let now: Date = Date()
        let calendar: Calendar = Calendar.current
        let dateComponents = calendar.dateComponents([Calendar.Component.second],
                                                     from: lastDate,
                                                     to: now)
        let seconds: Int = Int(Float(dateComponents.second!) * generalDateAdding[newGrade, default: 0.01])
        
        let interval: DateComponents = DateComponents(calendar: calendar, timeZone: nil, era: nil, year: nil, month: nil, day: nil, hour: nil, minute: nil, second: seconds, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
        let dueDate: Date = calendar.date(byAdding: interval, to: now)!
        
        return dueDate
    }
    
    func contentInsideBracket(_ input: Substring, _ openIndex: String.Index, _ closeIndex: String.Index) -> Substring{
        let startOffByOne = input.index(openIndex, offsetBy: 1)
        return input[startOffByOne..<closeIndex]
    }
    
    func runUnitTests() throws {
        
        self.testBadRefVal()
        self.testGetDictionaryPartsReturnedOrdered()
        
        self.testJsonBlankToDict()
        self.testBlanksToJsonNumber()
        self.testBlanksToJsonInDatabase()
        self.testBlanksToJsonInDatabaseFk()
        self.testPopulateBlanksDictNumber()
        self.testSpecificAndCompareCountry()
    }
    
    
    func testJsonBlankToDict() {
        let test_fib = FillInBlanks(dbTranslation: DbTranslation(),
                                    dbm: self)
        
        let individualDict: Dictionary<String, String> = test_fib.getRefDict("{ref:1,type:int,min:21,max:22}")
        
        assert(individualDict["ref"] == "1")
        assert(individualDict["type"] == "int")
        assert(individualDict["min"] == "21")
        assert(individualDict["max"] == "22")
    }
    
    func testBlanksToJsonNumber() {
        let dbTranslation = DbTranslation()
        dbTranslation.setBlanks("我今年{ref:1,type:int,min:21,max:22}岁{ref:2,type:int,min:1950,max:1950}WHAT")
        let test_fib = FillInBlanks(dbTranslation: dbTranslation,
        dbm: self)
        test_fib.populateBlanksDictionary()
        let blanksDict: Dictionary<Int, Dictionary<String, String>> = test_fib.getBlanksDictionary()
        
        assert(blanksDict[1]?["hanzi"] == "21" || blanksDict[1]?["english"] == "22")
        assert(blanksDict[2]?["pinyin"] == "1950")
    }
    
    func testBlanksToJsonInDatabase() {
        var trueCount = 0
        for i in 1...100 {
            let dbTranslation = DbTranslation()
            dbTranslation.setBlanks("{ref:1,type:country_person_name}")
            let test_fib = FillInBlanks(dbTranslation: dbTranslation,
            dbm: self)
            test_fib.populateBlanksDictionary()
            let blanksDict: Dictionary<Int, Dictionary<String, String>> = test_fib.getBlanksDictionary()
            
            if blanksDict[1]?["hanzi"] == "中国 人" || blanksDict[1]?["english"] == "American" {
                trueCount += 1
                if trueCount > 2 {
                    break
                }
            }
        }
        assert(trueCount > 1)
    }
    
    func testBlanksToJsonInDatabaseFk() {
        var fruit_once = false
        for i in 1...20 {
            let dbTranslation = DbTranslation()
            dbTranslation.setBlanks("{ref:1,type:food_type}{ref:2,type:food,fk_ref:1}")
            let test_fib = FillInBlanks(dbTranslation: dbTranslation,
            dbm: self)
            test_fib.populateBlanksDictionary()
            let blanksDict: Dictionary<Int, Dictionary<String, String>> = test_fib.getBlanksDictionary()
            
            let current_fruit_list: [String] = ["苹果", "香蕉", "火龙果", "黑莓", "蓝莓", "樱桃", "葡萄", "柠檬", "芒果", "橙子", "桃", "李", "菠萝", "草莓", "西瓜"]
            
            let food_type: String? = blanksDict[1]?["hanzi"]
            let food_specific: String? = blanksDict[2]?["hanzi"]
            if food_type == "水果" {
                assert(current_fruit_list.contains(food_specific!), food_specific!)
                fruit_once = true
            }
        }
        assert(fruit_once)
        
    }
    
    func testPopulateBlanksDictNumber() {
        let hanzi = "我今年{ref:1,type:int,min:33,max:33}岁"
        let pinyin = "wǒ jīnnián {ref:1,type:int,min:33,max:33} suì"
        let english = "I am {ref:1,type:int,min:33,max:33} years old"
        let blanks = "{ref:1,type:int,min:33,max:33}"
        let testTranslation = DbTranslation(hanzi: hanzi,
                                        pinyin: pinyin,
                                        english: english,
                                        blanks: blanks)
        let test_fib = FillInBlanks(dbTranslation: testTranslation,
        dbm: self)
        test_fib.processBlanks()

        assert(testTranslation.getEnglish() == "I am 33 years old", testTranslation.getEnglish())
        assert(testTranslation.getPinyin() == "wǒ jīnnián 33 suì")
        assert(testTranslation.getHanzi() == "我今年33岁")
    }
    
    func testGetDictionaryPartsReturnedOrdered() {
        let ref_1 = "{ref:1}"
        let ref_2 = "{ref:2}"
        let ref_3 = "{ref:5}"
        let ref_4 = "{ref:3}"
        let ref_5 = "{ref:4}"
        
        let testTranslantion = DbTranslation(hanzi: "",
                                            pinyin: "",
                                            english: "",
                                            blanks: "")
        
        let test_fib = FillInBlanks(dbTranslation: testTranslantion, dbm: self)
        
        let decodeString = "\(ref_1) \(ref_2) \(ref_3) \(ref_4) \(ref_5) "
        let blankParts: [String] = test_fib.getDictionaryParts(decodeString)
        for i in 1...5 {
            assert(blankParts[i - 1].contains("ref:\(i)"))
        }
    }
    
    func testSpecificAndCompareCountry() {
        let ref_1 = "{ref:1,type:country_name,specific:Russia}"
        let ref_2 = "{ref:2,type:country_name,ref_not:1}"
        let ref_3 = "{ref:5,type:eval,left:3,right:4,sign:<,true:comparison_adjectives.bigger,false:comparison_adjectives.smaller}"
        let ref_4 = "{ref:3,type:country_size_km2,fk_ref:1,display:empty}"
        let ref_5 = "{ref:4,type:country_size_km2,fk_ref:2,display:empty}"
         
        let testTranslantion = DbTranslation(hanzi: "",
                                            pinyin: "",
                                            english: "",
                                            blanks: "\(ref_1) \(ref_2) \(ref_3) \(ref_4) \(ref_5) ")
        
        let test_fib = FillInBlanks(dbTranslation: testTranslantion, dbm: self)
        for i in 1...200 {
            test_fib.populateBlanksDictionary()
            let blanksDict: Dictionary<Int, Dictionary<String, String>> = test_fib.getBlanksDictionary()
                        
            assert(blanksDict[1]?["english"] == "Russia")
            assert(blanksDict[2]?["english"] != "Russia")
            assert((blanksDict[2]?["hanzi"]?.count)! > 1)
            assert(Int((blanksDict[3]?["hanzi"])!) == 17098)
            assert(Int((blanksDict[4]?["hanzi"])!)! < 17098)
            assert(Int((blanksDict[4]?["hanzi"])!)! > 2)
            assert(blanksDict[5]?["hanzi"] != "smaller")
        }
        
    }
    
    func testBadRefVal() {
        let ref_1 = "{ref:t,type:what}"
        
        let testTranslantion = DbTranslation(hanzi: "",
                                            pinyin: "",
                                            english: "",
                                            blanks: ref_1)
        
        let test_fib = FillInBlanks(dbTranslation: testTranslantion, dbm: self)
        test_fib.populateBlanksDictionary()
        let blanksDict: Dictionary<Int, Dictionary<String, String>> = test_fib.getBlanksDictionary()
        
        assert(blanksDict.count == 0)
    }
}

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}
