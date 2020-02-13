//
//  StringHelper.swift
//  PressAndHoldButton
//
//  Created by Jason A Faas on 1/16/20.
//  Copyright © 2020 Jason A Faas. All rights reserved.
//

import Foundation


extension String: LocalizedError {
    public var errorDescription: String? { return self }

    var length: Int {
      return count
    }

    subscript (i: Int) -> String {
      return self[i ..< i + 1]
    }

    func substring(fromIndex: Int) -> String {
      return self[min(fromIndex, length) ..< length]
    }

    func substring(toIndex: Int) -> String {
      return self[0 ..< max(0, toIndex)]
    }

    subscript (r: Range<Int>) -> String {
      let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                          upper: min(length, max(0, r.upperBound))))
      let start = index(startIndex, offsetBy: range.lowerBound)
      let end = index(start, offsetBy: range.upperBound - range.lowerBound)
      return String(self[start ..< end])
    }
    
    func withoutPunctuationAndSpaces() -> String {
        var returnMe = String(self)
        let charsToRemove = [",", "。", "！", "？", " ", "，", ";"]
        
        for charToRemove in charsToRemove {
            returnMe = returnMe.replacingOccurrences(of: charToRemove, with: "")
        }
        
        return returnMe
    }
    
    func isArabicNumeral() -> Bool {
        if self.count > 5 {
            return false
        }
        
        let arabicNumerals: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
        
        for character in self {
            if !arabicNumerals.contains(Int(String(character)) ?? -1) {
                return false
            }
        }
        
        return true
    }
    
    func toRoughHanziNumeral() -> String {
        let numeralMap: [String: String] = [
            "0": "零",
            "1": "一",
            "2": "二",
            "3": "三",
            "4": "四",
            "5": "五",
            "6": "六",
            "7": "七",
            "8": "八",
            "9": "九",
        ]
        
        let digitsMap: [Int: String] = [
            0: "",
            1: "十",
            2: "百",
            3: "千",
            4: "万",
        ]
        
        var returnHanzi: String = ""
        for i in stride(from: 0, to: self.count, by:1) {
            let what: String = String(self[self.count - 1 - i])
            returnHanzi = (numeralMap[what] ?? "") + (digitsMap[i] ?? "") + returnHanzi
        }
        return returnHanzi
    }
}
