//
//  HTMLTtest.swift
//  FCE++
//
//  Created by Sam Flattery on 6/8/19.
//  Copyright © 2019 Sam Flattery. All rights reserved.
//

import Foundation

struct Comment : Codable {
    let courseNumber: String
    var comments: [String]
}

class Comments {
    
    static var myjsonURL = "https://api.myjson.com/bins/"
    static var myID = "depeh"

    static func performWebsiteRequest(with url: URL) -> Data? {
        do {
            return try Data(contentsOf: url)
        } catch {
            print("error performing website request")
            return nil
        }
    }

    static func parseComments(data: Data) -> [Comment] {
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([Comment].self, from: data)
        } catch {
            print("JSON Error \(error)")
            return []
        }
    }

    static func addNewComment(_ comments: inout [Comment], toCourse course: String, withText text: String)  {
        if let classIndex = comments.firstIndex(where: { $0.courseNumber == course }) {
            var commentObj = comments[classIndex]
            commentObj.comments.insert(text, at: 0)
            comments[classIndex] = commentObj
        }
        uploadComments(comments)
    }

    static func getComments() -> [Comment]? {
        let url = URL(string: myjsonURL + myID)!
        
        var comments = [Comment]()
    
        if let data = performWebsiteRequest(with: url) {
            comments = parseComments(data: data)
            return comments
        } else {
            print("failed to get data")
            return nil
        }
    }
    
    static func uploadComments(_ comments: [Comment]) {
        
        var arrayToSerialize = [[String: Any]]()
        
        for classObj in comments {
            arrayToSerialize.append(["courseNumber": classObj.courseNumber, "comments": classObj.comments])
        }

        let session = URLSession.shared

        //now create the URLRequest object using the url object
        let url = URL(string: myjsonURL + myID)!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: arrayToSerialize, options: .prettyPrinted)
        } catch let error {
            print(error.localizedDescription)
        }

        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")

        //create dataTask using the session object to send data to the server
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in

            guard error == nil else {
                return
            }

            guard data != nil else {
                return
            }

        })
        task.resume()
    }

    static func getCommentsForCourse(_ comments: [Comment], for course: String) -> Comment {
        let courseComments = comments.first(where: { $0.courseNumber == course })!
        return courseComments
    }

}
