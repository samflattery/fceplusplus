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
typealias CourseComment = [String: Any]

class CourseInfoTableViewController: UITableViewController, UITextFieldDelegate, NewCommentViewControllerDelegate, GuestCommentCellDelegate {

    var query: PFQuery<PFObject>? // the currently active comment query
    var reachability: Reachability! // the user's internet status
    
    var course: Course!  // the course being displayed
    var instructorInfo = [[String]]()  // the instructors json in the form of an array
                                         // for table indexing
    var courseInfo: [String]!  // as above but with the course information
    
    var courseComments: CourseComments?  // the list of comments to be displayed,
                                         // can be nil if unable to load
    var commentObj: PFObject?  // the comments as an object to be passed to the newComment cell
    
    var hasDownloadedComments = false // have the comments already been loaded in the background?
    var failedToLoad = false  // the user has no internet, show them the failed to load cell
    var isLoadingComment = false  // if the user posts a new comment, show loading cell
    
    @IBOutlet weak var segmentControl: UISegmentedControl!
    let refreshController = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.failedToLoad = false
        self.hasDownloadedComments = false
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
            if !hasDownloadedComments {
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
                        self.hasDownloadedComments = true
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
            let controller = segue.destination as! NewCommentViewController
            controller.commentObj = commentObj
            controller.courseNumber = course.number
            controller.delegate = self
        } else if segue.identifier == "ShowReplies" {
            let controller = segue.destination as! CommentRepliesViewController
            controller.commentObj = commentObj
            let commentIndex = sender as! Int
            controller.commentIndex = commentIndex
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // cancel any queries running in background and dismiss any progress huds
        query?.cancel()
        SVProgressHUD.dismiss()
    }
    
    @objc func refreshComments() { // needs to be objc for the refreshControl
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
            if self.isLoadingComment {
                self.isLoadingComment = false
            }
            self.tableView.reloadData()
        })
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if segmentControl.selectedSegmentIndex == 2 {
            if PFUser.current() == nil && indexPath.row == 0 {
                // take the guest back to login screen
                loginPressed()
            } else if PFUser.current() != nil && indexPath.row == 0 {
                performSegue(withIdentifier: "NewComment", sender: nil)
            } else {
                performSegue(withIdentifier: "ShowReplies", sender: indexPath.row - 1)
                // the create new comment cell is first so it must be offset by one
            }
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
                if isLoadingComment {
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
//        var cell: UITableViewCell!
        let i = indexPath.row
        let j = indexPath.section
        
        if failedToLoad && segmentControl.selectedSegmentIndex == 2 {
            // only display the failed to load cell
            let failedToLoadCell = tableView.dequeueReusableCell(withIdentifier: "FailedToLoad", for: indexPath)
            return failedToLoadCell
        }

        if segmentControl.selectedSegmentIndex == 0 {
            // the course information segment's cells
            if i == 6 {
                // the description cell is different
                let descriptionCell = tableView.dequeueReusableCell(withIdentifier: "DescriptionCell", for: indexPath)
                let textLabel = descriptionCell.viewWithTag(15) as! UILabel
                textLabel.text = infoTitles[i]
                let detailLabel = descriptionCell.viewWithTag(16) as! UILabel
                detailLabel.text = courseInfo[i]
                return descriptionCell
            } else {
                // just a normal course info cell
                let infoCell = tableView.dequeueReusableCell(withIdentifier: "InfoCell", for: indexPath)
                infoCell.textLabel!.text = infoTitles[i] // the title of the info field
                infoCell.detailTextLabel!.text = courseInfo[i] // the info itself
                return infoCell
            }
        }
        else if segmentControl.selectedSegmentIndex == 1 {
            // the instructor segment's cells
            let instructorCell = tableView.dequeueReusableCell(withIdentifier: "InfoCell", for: indexPath)
            instructorCell.textLabel!.text = instructorTitles[i] // title of instructor field
            instructorCell.detailTextLabel!.text = instructorInfo[j][i] // the instructor info
            return instructorCell
        }
        else {
            // the comment segment's cells
            if i == 0 && PFUser.current() != nil {
                // show the new comment cell as the first cell
                let newCommentCell = tableView.dequeueReusableCell(withIdentifier: "CreatePost", for: indexPath)
                return newCommentCell

            }
            else if i == 0 && PFUser.current() == nil {
                // if there is no user, display the cell with the login button
                let guestCommentCell = tableView.dequeueReusableCell(withIdentifier: "GuestComment", for: indexPath) as! GuestCommentCell
                guestCommentCell.delegate = self
                return guestCommentCell
            }
            else if i == 1 && isLoadingComment {
                // if the user posted a new comment, display the loading cell
                let loadingCell = tableView.dequeueReusableCell(withIdentifier: "LoadingCell", for: indexPath) as! LoadingCell
                loadingCell.spinner.startAnimating()
                return loadingCell
            }
            else {
                // display comments
                // if the user has just posted a comment, there is a temporary cell with a loading
                // spinner, so in this case each cell must be shifted forward by one to fit this
                let indexRow = isLoadingComment ? indexPath.row - 2 : indexPath.row - 1
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
    } // end of cellForIndexAt
    
    //MARK:- NewCommentViewControllerDelegate
    func didPostComment(withData data: [String : Any]) {
        isLoadingComment = true
        tableView.reloadData() // display loading cell
        commentObj?.fetchInBackground { (object: PFObject?, error: Error?) in
            if let object = object { // if it succeeds to fetch any updates
                var comments = object["comments"] as! [[String : Any]] // the current comments
                // insert the new comment at the beginning and rewrite the old comments
                comments.insert(data, at: 0)
                object["comments"] = comments
                
                object.saveInBackground(block: { (success: Bool, error: Error?) in
                    if success {
                        self.isLoadingComment = false // remove the loading cell
                        // update the courseComments with the new comments
                        self.courseComments = (object["comments"] as! CourseComments)
                        self.tableView.reloadData()
                    } else if let error = error {
                        SVProgressHUD.showError(withStatus: error.localizedDescription)
                        SVProgressHUD.dismiss(withDelay: 1)
                    } else {
                        SVProgressHUD.showError(withStatus: "Something went wrong")
                        SVProgressHUD.dismiss(withDelay: 1)
                    }
                })
            } else if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
                SVProgressHUD.dismiss(withDelay: 1.5)
            } else {
                SVProgressHUD.showError(withStatus: "Something went wrong")
                SVProgressHUD.dismiss(withDelay: 1)
            }
        }
    }
    
    //MARK:- GuestCommentCellDelegate
    func loginPressed() {
        // called when the guest pressed 'login to comment'
        // instantiate a new signupscreen and push it to navigation stack
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "SignUpScreen") as! SignUpViewController
        vc.hasComeFromGuest = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
} // end of class

class CommentCell: UITableViewCell { // the cell that displays a comment
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var andrewIDLabel: UILabel!
    
}
