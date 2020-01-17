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
}
