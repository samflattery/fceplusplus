//
//  TimeManager.swift
//  FCE++
//
//  Created by Sam Flattery on 8/12/19.
//  Copyright © 2019 Sam Flattery. All rights reserved.
//

import Foundation
import TimeIntervals

class TimeManager {
    
    var timeDiff : TimeInterval
    var timeDiffInSeconds : Interval<Second>

    init(withTimeOfPosting time : String) {
        
        let postedTime = TimeInterval(time)!
        
        let date = Date()
        let currentTime = date.timeIntervalSince1970
        
        timeDiff = currentTime - postedTime
        timeDiffInSeconds = timeDiff.seconds
        
    }
    
    func getString() -> String {
        let t = timeDiffInSeconds
        
        if t.converted(to: Minute.self) < 1.minutes {
            return "A few seconds ago"
        } else if t.converted(to: Hour.self) < 1.hours {
            return addSuffix("minute", toString: String(Int(t.converted(to:
                Minute.self).value.rounded(.up))))
        } else if t.converted(to: Day.self) < 1.days {
            return addSuffix("hour", toString: String(Int(t.converted(to:
                Hour.self).value.rounded(.up))))
        } else if t.converted(to: Week.self) < 1.weeks {
            return addSuffix("day", toString: String(Int(t.converted(to:
                Day.self).value.rounded(.up))))
        } else if t.converted(to: Month.self) < 1.months {
            return addSuffix("week", toString: String(Int(t.converted(to: Week.self).value.rounded(.up))))
        } else if t.converted(to: Year.self) < 1.years {
            return addSuffix("month", toString:String(Int(t.converted(to:
                Month.self).value.rounded(.up))))
        } else {
            return addSuffix("year", toString:String(Int(t.converted(to:
                Year.self).value.rounded(.up))))
        }
    }
    
    private func addSuffix(_ suffix: String, toString s: String) -> String {
        if s == "1" {
            return s + " " + suffix + " ago"
        } else {
            return s + " " + suffix + "s ago"
        }
    }
    
}


public enum Week : TimeUnit {
    public static var toTimeIntervalRatio: Double {
        return 604800
    }
}

public enum Month : TimeUnit {
    public static var toTimeIntervalRatio: Double {
        return 2628000
    }
}

public enum Year : TimeUnit {
    public static var toTimeIntervalRatio: Double {
        return 31540000
    }
}


extension Interval {
    
    public var inWeeks: Interval<Week> {
        return converted()
    }
    
    public var inMonths: Interval<Month> {
        return converted()
    }
    
    public var inYears: Interval<Year> {
        return converted()
    }
}

extension Double {
    public var weeks: Interval<Week> {
        return Interval<Week>(self)
    }
    
    public var months: Interval<Month> {
        return Interval<Month>(self)
    }
    
    public var years: Interval<Year> {
        return Interval<Year>(self)
    }
}

extension Int {
    public var weeks: Interval<Week> {
        return Interval<Week>(Double(self))
    }
    
    public var months: Interval<Month> {
        return Interval<Month>(Double(self))
    }
    
    public var years: Interval<Year> {
        return Interval<Year>(Double(self))
    }
}

