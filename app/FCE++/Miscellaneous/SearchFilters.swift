//
//  SearchFilters.swift
//  FCE++
//
//  Created by Sam Flattery on 8/17/19.
//  Copyright © 2019 Sam Flattery. All rights reserved.
//

import Foundation

func isCourseNumber(_ string: String) -> Bool {
    // returns true if a string is an integer or is in the form
    // X-Y where x is a <=2 digit integer and Y is a <=3 digit integer

    if let _ = Int(string) {
        if string.count > 5 {
            return false
        }
        return true
    }
    
    if string.count > 6 {
        return false
    }
    
    if let index = string.firstIndex(of: "-") {
        let firstHalf = string[..<index]
        if firstHalf.count > 2 {
            return false
        }
        let secondHalf = string[string.index(after: index)...]
        if secondHalf.count > 3 {
            return false
        }
        if firstHalf == "" || Int(firstHalf) != nil {
            if secondHalf == "" || Int(secondHalf) != nil {
                return true
            }
        }
    }
    return false
}

func reformattedNumber(_ number: String) -> String {
    if let _ = Int(number) { // if it's a number
        if number.count > 2 && number.firstIndex(of: "-") == nil {
            // if it's in the form xxxxx then convert to xx-xxx
            let firstTwoIndex = number.index(number.startIndex, offsetBy: 2)
            return number[..<firstTwoIndex] + "-" + number[firstTwoIndex...]
        }
    }
    return number
}

func courseContainsNumber(_ course: Course, number num: String) -> Bool {
    return course.number.contains(num)
}

func sortCoursesByNumber( _ courses: inout [Course], number num: String) {
    
    // will always be <= 5 by isCourseNumber and reformattedNumber
    let searchLength = num.count
    
    courses.sort(by : {
        switch ($0.number.prefix(searchLength).contains(num), $1.number.prefix(searchLength).contains(num)) {
            /*
             4 cases: neither start with the search term, both start with the
             search term, or one does and other doesn't
             prioritize starting with the term, then sort the ending bit
             */
        case (true, true):
            return $0.number < $1.number
        case (false, true):
            return false
        case (true, false):
            return true
        case (false, false):
            return $0.number < $1.number
        }
    }
    )
}

