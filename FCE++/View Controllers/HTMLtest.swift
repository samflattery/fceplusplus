//
//  HTMLTtest.swift
//  FCE++
//
//  Created by Sam Flattery on 6/8/19.
//  Copyright © 2019 Sam Flattery. All rights reserved.
//

import Foundation

var myURL = "https://api.myjson.com/bins/"
var myID = "depeh"

struct Comment : Codable {
    let courseNumber: String
    var comments: [String]
}

func performWebsiteRequest(with url: URL) -> Data? {
    do {
        return try Data(contentsOf: url)
    } catch {
        print("error performing website request")
        return nil
    }
}

func parseComments(data: Data) -> [Comment] {
    
    do {
        let decoder = JSONDecoder()
        return try decoder.decode([Comment].self, from: data)
    } catch {
        print("JSON Error \(error)")
        return []
    }
}

func addNewComment(_ comments: inout [Comment], toCourse course: String, withText text: String)  {
    if let classIndex = comments.firstIndex(where: { $0.courseNumber == course }) {
        var commentObj = comments[classIndex]
        commentObj.comments.append(text)
        
        comments[classIndex] = commentObj
    }
}

func getComments() {
    let url = URL(string: myURL + myID)!
    
    var comments = [Comment]()
    
    if let data = performWebsiteRequest(with: url) {
        comments = parseComments(data: data)
    } else {
        print("failed to get data")
    }

//    addNewComment(&comments, toCourse: "15-122", withText: "Great class")
//    addNewComment(&comments, toCourse: "15-122", withText: "Nice")
//    addNewComment(&comments, toCourse: "15-150", withText: "Prof Erdmann is the best")

    var arrayToSerialize = [[String: Any]]()
    
    for classObj in comments {
        arrayToSerialize.append(["courseNumber": classObj.courseNumber, "comments": classObj.comments])
    }

    let session = URLSession.shared

    //now create the URLRequest object using the url object
    var request = URLRequest(url: url)
    request.httpMethod = "PUT" //set http method as POST

    do {
//        let data = try JSONSerialization.data(withJSONObject: arrayToSerialize, options: .prettyPrinted) // first of all convert json to the data
//
//        let convertedString = String(data: data, encoding: String.Encoding.utf8) // the data will be converted to the string
        request.httpBody = try JSONSerialization.data(withJSONObject: arrayToSerialize, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
//        request.httpBody = convertedString!.data(using: .utf8)
//            request.httpBody = testData.data(using: .utf8)
    } catch let error {
        print(error.localizedDescription)
    }

    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Location")
//        request.addValue("application/json", forHTTPHeaderField: "Accept")

    //create dataTask using the session object to send data to the server
    let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in

        guard error == nil else {
            return
        }

        guard data != nil else {
            return
        }
//        let httpResponse = response as? HTTPURLResponse
//        print(httpResponse)

    })
    task.resume()
    
}

func getCommentsForCourse(_ comments: [Comment], for course: String) -> Comment {
    let course = comments.first(where: { $0.courseNumber == course })!
    return course
}
