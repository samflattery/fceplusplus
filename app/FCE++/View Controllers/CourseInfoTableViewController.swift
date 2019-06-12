//
//  CourseInfoTableViewController.swift
//  FCE++
//
//  Created by Sam Flattery on 6/7/19.
//  Copyright © 2019 Sam Flattery. All rights reserved.
//

import UIKit

class CourseInfoTableViewController: UITableViewController, UITextFieldDelegate {
    
    @IBAction func segmentControlValueChanged(_ sender: Any) {
        tableView.reloadData()
    }
    
    var course: Course!
    var instructorInfo: [[String]]! = []
    var courseInfo: [String]!
    var comments: [Comment]?
    var courseComments: Comment?
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    
    @IBOutlet weak var postButton: UIBarButtonItem!
    @IBAction func postButtonPressed(_ sender: Any) {
    }
    
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
        
        comments = appDelegate.comments
        if let comments = comments {
            courseComments = Comments.getCommentsForCourse(comments, for: course.number)
        } else {
            courseComments = nil
        }
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
                return comments.comments.count + 1
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
                newCommentCell.comments = comments
                newCommentCell.courseTitle = course.number
                return newCommentCell
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath)
                let textField = cell.viewWithTag(100) as! UITextView
                textField.text = courseComments?.comments[indexPath.row-1]
            }
        }
        return cell
    }
 
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    
    
    //MARK:- Text Field Methods
    
    

}
