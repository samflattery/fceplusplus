//
//  JSONInfo.swift
//  FCE++
//
//  Created by Sam Flattery on 6/6/19.
//  Copyright © 2019 Sam Flattery. All rights reserved.
//

import Foundation
import RSSelectionMenu

struct reqObj: Decodable {
    let invert: Bool?
    let reqsList: [[String]]?
}

struct Instructor: Decodable {
    let name: String
    let hours: Double
    let interest: Double
    let requirements: Double
    let objectives: Double
    let feedback: Double
    let importance: Double
    let matter: Double
    let respect: Double
    let teachingRate: Double
    let courseRate: Double
    
    enum CodingKeys: String, CodingKey {
        case name = "Instructor name"
        case hours = "Hours per week"
        case interest = "Interest in student learning"
        case requirements = "Clearly explain course requirements"
        case objectives = "Clear learning objectives & goals"
        case feedback = "Instructor provides feedback to students to improve"
        case importance = "Demonstrate importance of subject matter"
        case matter = "Explains subject matter of course"
        case respect = "Show respect for all students"
        case teachingRate = "Overall teaching rate"
        case courseRate = "Overall course rate"
    }
}

struct Course: Decodable, UniquePropertyDelegate, Equatable {
    
    let number: String
    let hours: Double
    let rate: Double
    let name: String?
    let department: String?
    let units: Double?
    let desc: String?
    let prereqs: String?
    let prereqsObj: reqObj?
    let coreqs: String?
    let coreqsObj: reqObj?
    let instructors: [Instructor]
    
    enum CodingKeys: String, CodingKey {
        case number, name, department, units
        case desc, prereqs, coreqs, instructors
        case hours = "hours per week"
        case rate = "overall course rate"
        case prereqsObj = "prereqs_obj"
        case coreqsObj = "coreqs_obj"
    }
    
    func getUniquePropertyName() -> String {
        return "number"
    }
    
    static func == (lhs: Course, rhs: Course) -> Bool {
        return lhs.number == rhs.number
    }
}

func getCourseData(_ course: Course) -> [String] {
    //returns the dictionary of a course as an array for table indexing
    var data = [String]()
    let none = "Not available"
    for i in 0..<9 {
        switch i {
        case 0:
            data.append(course.number)
        case 1:
            data.append(String(format: "%.1f", course.hours))
        case 2:
            data.append(String(format: "%.1f", course.rate))
        case 3:
            data.append(course.name ?? none)
        case 4:
            data.append(course.department ?? none)
        case 5:
            data.append(course.units == nil ? none : String(format: "%.1f", course.units!))
        case 6:
            data.append(course.desc ?? none)
        case 7:
            data.append(course.prereqs ?? none)
        case 8:
            data.append(course.coreqs ?? none)
        default:
            print("error")
        }
    }
    return data
}

func getInstructorData(_ instructor: Instructor) -> [String] {
    //returns the dictionary of an instuctor as an array for table indexing
    var data = [String]()
    for i in 0..<11 {
        switch i {
        case 0:
            data.append(instructor.name)
        case 1:
            data.append(String(format: "%.1f", instructor.hours))
        case 2:
            data.append(String(format: "%.1f", instructor.interest))
        case 3:
            data.append(String(format: "%.1f", instructor.requirements))
        case 4:
            data.append(String(format: "%.1f", instructor.objectives))
        case 5:
            data.append(String(format: "%.1f", instructor.feedback))
        case 6:
            data.append(String(format: "%.1f", instructor.importance))
        case 7:
            data.append(String(format: "%.1f", instructor.matter))
        case 8:
            data.append(String(format: "%.1f", instructor.respect))
        case 9:
            data.append(String(format: "%.1f", instructor.teachingRate))
        case 10:
            data.append(String(format: "%.1f", instructor.courseRate))
        default:
            print("error")
        }
    }
    return data
}

public var instructorTitles = ["Instructor Name", "Average hours per week", "Interest in student learning", "Clearly explains course requirements", "Clear learning objectives and goals", "Instructor provides feedback to students to improve", "Demonstrates importance of subject matter", "Explains subject matter of course", "Shows respect for all students", "Overall teaching rate", "Overall course rate"]

public var infoTitles = ["Course Number", "Average Hours Per Week", "Overall Course Rate", "Course Name", "Department", "Units", "Description", "Prereqs", "Coreqs"]
