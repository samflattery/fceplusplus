//
//  CourseInfoTableViewController.swift
//  FCE++
//
//  Created by Sam Flattery on 6/7/19.
//  Copyright © 2019 Sam Flattery. All rights reserved.
//

import UIKit
import Parse

typealias courseComment = [[String: Any]]

class CourseInfoTableViewController: UITableViewController, UITextFieldDelegate {
    
    @IBAction func segmentControlValueChanged(_ sender: Any) {
        
        let query = PFQuery(className:"Comments")
        query.whereKey("courseNumber", equalTo: course.number)
        query.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            if let error = error {
                // Log details of the failure
                print(error.localizedDescription)
            } else if let objects = objects {
                // Do something with the found objects
                for object in objects {
                    self.courseComments = (object["comments"] as! courseComment)
                    self.commentObj = object
                    let newCommentCell = self.view.viewWithTag(1001) as? NewCommentTableViewCell
                    newCommentCell?.commentObj = object
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    var course: Course!
    var instructorInfo: [[String]] = []
    var courseInfo: [String]!
    var courseComments: courseComment?
    var commentObj: PFObject?
    var button: UIButton?
    
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 60
//        tableView.rowHeight = UITableView.automaticDimension
        
        var cellNib = UINib(nibName: "NewComment", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "NewComment")
        
        cellNib = UINib(nibName: "CommentCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "CommentCell")
        
        courseInfo = getCourseData(course)
        for instructor in course.instructors {
            instructorInfo.append(getInstructorData(instructor))
        }
        
    }
    
    @objc func refreshComments() {
        print("pressed button")
        self.commentObj?.fetchInBackground(block: { (object: PFObject?, error: Error?) in
            self.courseComments = object?["comments"] as! courseComment
            self.tableView.reloadData()
        })
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if segmentControl.selectedSegmentIndex == 2 && indexPath.row == 0 {
            return 150
        } else {
            return UITableView.automaticDimension
        }
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        if segmentControl.selectedSegmentIndex == 1{
            return instructorInfo.count
        } else {
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if segmentControl.selectedSegmentIndex == 0 {
            return 9
        } else if segmentControl.selectedSegmentIndex == 1 {
            return 11
        } else {
            if let comments = courseComments {
                print(comments.count + 1)
                return comments.count + 1
            } else {
                return 1
            }
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        let i = indexPath.row
        let j = indexPath.section
        
        if segmentControl.selectedSegmentIndex == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.textLabel!.text = infoTitles[i]
            cell.detailTextLabel!.text = courseInfo[i]
        } else if segmentControl.selectedSegmentIndex == 1 {
            cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.textLabel!.text = instructorTitles[i]
            cell.detailTextLabel!.text = instructorInfo[j][i]
        } else {
            if i == 0 {
                let newCommentCell = tableView.dequeueReusableCell(withIdentifier: "NewComment", for: indexPath) as! NewCommentTableViewCell
//                newCommentCell.comments = comments
                newCommentCell.courseNumber = course.number
                newCommentCell.commentObj = commentObj
                let button = self.view.viewWithTag(120) as! UIButton
                button.addTarget(self, action: #selector(refreshComments), for: .touchUpInside)
                return newCommentCell
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath)
                if let commentInfo = courseComments?[indexPath.row - 1] {
                    let commentTextView = cell.viewWithTag(100) as! UITextView
                    commentTextView.text = commentInfo["commentText"] as? String
                    let dateLabel = cell.viewWithTag(175) as! UILabel
                    dateLabel.text = commentInfo["timePosted"] as? String
                    let posterLabel = cell.viewWithTag(150) as! UILabel
                    posterLabel.text = commentInfo["poster"] as? String
                }
            }
        }
        return cell
    }

}
