//
//  DateMath.swift
//  PressAndHoldButton
//
//  Created by Jason A Faas on 2/2/20.
//  Copyright © 2020 Jason A Faas. All rights reserved.
//

import Foundation

class DateMath {
    
    static func getNewMinutesUntil(grade: SpeakingGrade) -> Int {
        
        let generalDateAdding: [SpeakingGrade: Int] = [
            SpeakingGrade.A: 60 * 48,
            SpeakingGrade.B: 60 * 24,
            SpeakingGrade.C: 60 * 12,
            SpeakingGrade.D: 60 * 4,
            SpeakingGrade.F: 60 * 1,
            SpeakingGrade.New: 60 * 8,
        ]
        
        let minutesAhead: Int = generalDateAdding[grade, default: 5]
        return minutesAhead
    }
    
    static func getDateFromNow(minutesAhead: Int) -> Date {
        let now: Date = Date()
        let calendar: Calendar = Calendar.current
        
        let interval: DateComponents = DateComponents(calendar: calendar, timeZone: nil, era: nil, year: nil, month: nil, day: nil, hour: nil, minute: minutesAhead, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
        let dueDate: Date = calendar.date(byAdding: interval, to: now)!
        return dueDate
    }
    
    static func getUpdatedMinutesReturn(newGrade: SpeakingGrade, lastMinutesReturn: Int)  -> Int {
        let generalDateAdding: [SpeakingGrade: Float] = [
            SpeakingGrade.A: 4.0,
            SpeakingGrade.B: 2.0,
            SpeakingGrade.C: 1.0,
            SpeakingGrade.D: 0.5,
            SpeakingGrade.F: 0.25,
            SpeakingGrade.New: 1.0,
        ]
        
        return Int(Float(lastMinutesReturn) * generalDateAdding[newGrade, default: 0.01])
    }
}
