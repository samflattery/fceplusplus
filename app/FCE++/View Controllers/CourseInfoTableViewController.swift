//
//  CourseInfoTableViewController.swift
//  FCE++
//
//  Created by Sam Flattery on 6/7/19.
//  Copyright © 2019 Sam Flattery. All rights reserved.
//

import UIKit
import Parse
import SVProgressHUD

typealias CourseComments = [[String: Any]] // comments are stored as a list of dictionaries

class CourseInfoTableViewController: UITableViewController, UITextFieldDelegate, NewCommentViewControllerDelegate {
    
    var query: PFQuery<PFObject>? // the currently active comment query
    var reachability: Reachability! // the user's internet status
    
    var course: Course!  // the course being displayed
    var instructorInfo = [[String]]()  // the instructors json in the form of an array
                                         // for table indexing
    var courseInfo: [String]!  // as above but with the course information
    
    var courseComments: CourseComments?  // the list of comments to be displayed,
                                         // can be nil if unable to load
    var commentObj: PFObject?  // the comments as an object to be passed to the newComment cell
    
    var hasLoadedComments = false // have the comments already been loaded in the background?
    var failedToLoad = false  // the user has no internet, show them the failed to load cell
    var hasPostedComment = false  // if the user posts a new comment, show loading cell
    
    @IBOutlet weak var segmentControl: UISegmentedControl!
    let refreshController = UIRefreshControl()
    
    override func viewDidLoad() {
        print("viewDidLoad")
        super.viewDidLoad()
        self.failedToLoad = false
        self.hasLoadedComments = false
        tableView.estimatedRowHeight = 60
        
        //Register all of the cell nibs
        var cellNib = UINib(nibName: "NewComment", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "NewComment")
        
        cellNib = UINib(nibName: "CommentCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "CommentCell")
        
        cellNib = UINib(nibName: "DescriptionCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "DescriptionCell")
        
        cellNib = UINib(nibName: "GuestComment", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "GuestComment")
        
        cellNib = UINib(nibName: "FailedToLoad", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "FailedToLoad")
        
        cellNib = UINib(nibName: "LoadingCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "LoadingCell")
        
        // get info as lists instead of dictionaries
        courseInfo = getCourseData(course)
        for instructor in course.instructors {
            instructorInfo.append(getInstructorData(instructor))
        }
    }
    
    @IBAction func segmentControlValueChanged(_ sender: Any) {
        SVProgressHUD.dismiss() // if the user leaves comments when loading, dismiss
        tableView.refreshControl = nil // remove the pull to refresh
        if segmentControl.selectedSegmentIndex == 2 { // comments segment
            tableView.refreshControl = refreshController
            refreshControl?.addTarget(self, action: #selector(refreshComments), for: .valueChanged)
            if !hasLoadedComments {
                query = PFQuery(className:"Comments")
                query!.whereKey("courseNumber", equalTo: course.number)
                
                reachability = Reachability()!
                if reachability.connection == .none && !query!.hasCachedResult {
                    tableView.reloadData()
                    failedToLoad = true
                    SVProgressHUD.showError(withStatus: "No internet connection")
                    SVProgressHUD.dismiss(withDelay: 1)
                    courseComments = nil
                    commentObj = nil
                    return
                }
                SVProgressHUD.show()
                
                tableView.reloadData()
                query!.cachePolicy = .networkElseCache // first try network to get up to date, then cache
                query!.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
                    if let error = error {
                        // failed to get comments for some reason
                        SVProgressHUD.dismiss()
                        self.courseComments = nil
                        self.commentObj = nil
                        SVProgressHUD.showError(withStatus: "Failed to load comments.")
                        SVProgressHUD.dismiss(withDelay: 1)
                        print("failed in segment value changed", error.localizedDescription)
                    } else if let objects = objects {
                        // found objects
                        self.hasLoadedComments = true
                        let object = objects[0] // should only return one object
                        self.courseComments = (object["comments"] as! CourseComments)
                        self.commentObj = object
                        SVProgressHUD.dismiss()
                        self.tableView.reloadData()
                    }
                }
            } else {
                tableView.reloadData() // if the comments are already loaded, just reload table
            }
        } else {
            tableView.reloadData() // if it isn't the comment segment, just reload table
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "NewComment" {
            let vc = segue.destination as! NewCommentViewController
            vc.commentObj = commentObj
            vc.courseNumber = course.number
            vc.delegate = self
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // cancel any queries running in background and dismiss any progress huds
        query?.cancel()
        SVProgressHUD.dismiss()
    }
    
    @objc func postClicked() {
        // called when the post new comment button has been pressed
        hasPostedComment = true
        tableView.reloadData() // reload to get loading comment
        refreshComments()
    }
    
    @objc func refreshComments() {
        // called when post clicked or when pulled to refresh
        reachability = Reachability()!
        if reachability.connection == .none {
            if let rC = self.refreshControl {
                // if there's no internet but there is a refresh bar, end the refreshing
                rC.endRefreshing()
            }
            return
        }
        self.commentObj?.fetchInBackground(block: { (object: PFObject?, error: Error?) in
            // fetch new comments in the background and update the comment array
            self.courseComments = (object?["comments"] as! CourseComments)
            self.refreshControl?.endRefreshing()
            if self.hasPostedComment {
                self.hasPostedComment = false
            }
            self.tableView.reloadData()
        })
    }
    
    @objc func showLoginScreen() {
        // called when the guest pressed 'login to comment'
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "SignUpScreen") as! SignUpViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if PFUser.current() == nil && indexPath.row == 0 {
            // take the guest back to login screen
            showLoginScreen()
        }
        else if PFUser.current() != nil && indexPath.row == 0 {
            performSegue(withIdentifier: "NewComment", sender: nil)
        }
    }

    //MARK: - Table view delegates
    override func numberOfSections(in tableView: UITableView) -> Int {
        if segmentControl.selectedSegmentIndex == 1 {
            // one segment for each instructor
            return instructorInfo.count
        } else {
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmentControl.selectedSegmentIndex == 0 {
            return 9 // one for each piece of course info
        } else if segmentControl.selectedSegmentIndex == 1 {
            return 11 // one for each piece of instructor info
        } else {
            if let comments = courseComments {
                if hasPostedComment {
                    return comments.count + 2 // 2 extra for new comment and loading comment cells
                }
                return comments.count + 1
            } else {
                return 1 // failed to load cell
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if segmentControl.selectedSegmentIndex == 1 {
            return instructorInfo[section][0]
        }
        return super.tableView(tableView, titleForHeaderInSection: section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        let i = indexPath.row
        let j = indexPath.section
        
        if failedToLoad && segmentControl.selectedSegmentIndex == 2 {
            // only display the failed to load cell
            return tableView.dequeueReusableCell(withIdentifier: "FailedToLoad", for: indexPath)
        }
        
        if segmentControl.selectedSegmentIndex == 0 {
            if i == 6 {
                // the description cell is different
                cell = tableView.dequeueReusableCell(withIdentifier: "DescriptionCell", for: indexPath)
                let textLabel = cell.viewWithTag(15) as! UILabel
                textLabel.text = infoTitles[i]
                let detailLabel = cell.viewWithTag(16) as! UILabel
                detailLabel.text = courseInfo[i]
                return cell
            }
            cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.textLabel!.text = infoTitles[i]
            cell.detailTextLabel!.text = courseInfo[i]
        }
        else if segmentControl.selectedSegmentIndex == 1 {
            // instructor cells
            cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.textLabel!.text = instructorTitles[i]
            cell.detailTextLabel!.text = instructorInfo[j][i]
        }
        else {
            if i == 0 && PFUser.current() != nil {
                let newCommentCell = tableView.dequeueReusableCell(withIdentifier: "CreatePost", for: indexPath)
                return newCommentCell

            }
            else if i == 0 && PFUser.current() == nil {
                // if there is no user, display the cell with the login button
                let guestCommentCell = tableView.dequeueReusableCell(withIdentifier: "GuestComment", for: indexPath)
                let button = guestCommentCell.viewWithTag(65) as! UIButton
                button.addTarget(self, action: #selector(showLoginScreen), for: .touchUpInside)
                return guestCommentCell
            }
            else if i == 1 && hasPostedComment {
                // if the user posted a new comment, display the loading cell
                cell = tableView.dequeueReusableCell(withIdentifier: "LoadingCell", for: indexPath)
                let activitySpinner = cell.viewWithTag(121) as! UIActivityIndicatorView
                activitySpinner.startAnimating()
            }
            else {
                // display comments
                // if the user has just posted a comment, there is a temporary cell with a loading
                // spinner, so in this case each cell must be shifted forward by one to fit this
                let indexRow = hasPostedComment ? indexPath.row - 2 : indexPath.row - 1
                let commentCell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as! CommentCell
                if let commentInfo = courseComments?[indexRow] {
                    commentCell.headerLabel.text = commentInfo["header"] as? String
                    commentCell.commentLabel.text = commentInfo["commentText"] as? String
                    commentCell.dateLabel.text = commentInfo["timePosted"] as? String
                    if commentInfo["anonymous"] as! Bool {
                        commentCell.andrewIDLabel.text = "Anonymous"
                    } else {
                        commentCell.andrewIDLabel.text = commentInfo["andrewID"] as? String
                    }
                }
                return commentCell
            }
        }
        return cell
    } // end of cellForIndexAt
    
    //MARK:- NewCommentViewControllerDelegate
    func didPostComment(_ commentData: [String : Any]) {
        print("didPostComment")
        hasPostedComment = true
        tableView.reloadData() // reload to get loading comment
        refreshComments()
    }
  
    
} // end of class

class CommentCell: UITableViewCell {
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var andrewIDLabel: UILabel!
    
}
