//
//  DateMath.swift
//  PressAndHoldButton
//
//  Created by Jason A Faas on 2/2/20.
//  Copyright © 2020 Jason A Faas. All rights reserved.
//

import Foundation

class DateMath {
    
    static func getNewDueDate(grade: String) -> Date {
        
        let generalDateAdding: [String: Int] = [
            "A": 60 * 24,
            "B": 60 * 4,
            "C": 60 * 1,
            "D": 60 / 4,
            "F": 60 / 16,
        ]
        
        let minutesAhead: Int = generalDateAdding[grade, default: Int(grade) ?? 1]
        let dueDate: Date = self.getDateHoursFromNow(minutesAhead: minutesAhead)
        
        return dueDate
    }
    
    static func getDateHoursFromNow(minutesAhead: Int) -> Date {
        let now: Date = Date()
        let calendar: Calendar = Calendar.current
        
        let interval: DateComponents = DateComponents(calendar: calendar, timeZone: nil, era: nil, year: nil, month: nil, day: nil, hour: nil, minute: minutesAhead, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
        let dueDate: Date = calendar.date(byAdding: interval, to: now)!
        return dueDate
    }
    
    static func getUpdatedDueDate(newGrade: String,
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
}
