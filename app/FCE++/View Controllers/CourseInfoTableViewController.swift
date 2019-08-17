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
import Cosmos

typealias CourseComments = [[String: Any]] // comments are stored as a list of dictionaries
typealias CourseComment = [String: Any]

class CourseInfoTableViewController: UITableViewController, UITextFieldDelegate, NewCommentCellDelegate, GuestCommentCellDelegate, CommentRepliesViewControllerDelegate {
    
    var query: PFQuery<PFObject>? // the currently active comment query
    var reachability: Reachability! // the user's internet status
    
    var course: Course!  // the course being displayed
    var instructorInfo = [[String]]()  // the instructors json in the form of an array
                                         // for table indexing
    var courseInfo: [String]!  // as above but with the course information
    
    var courseComments: CourseComments?  // the list of comments to be displayed,
                                         // can be nil if unable to load
    var commentObj: PFObject?  // the comments as an object to be passed to the newComment cell
    
    var commentsHaveLoaded = false
    var failedToLoad = false  // the user has no internet, show them the failed to load cell
    var isLoadingNewComment = false  // if the user posts a new comment, show loading cell
    
    var isEditingComment = false  // if the user is editing a comment, show the new comment cell
    var editingIndex : Int!
    var isLoadingEditedComment = false
    var noCommentsToDisplay = false
    
    var cellHeights = [IndexPath : CGFloat]() // a dictionary of cell heights to avoid jumpy table
    
    @IBOutlet weak var segmentControl: UISegmentedControl!
    let refreshController = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        registerNibs()
        self.hideKeyboardWhenTappedAround()
        extendedLayoutIncludesOpaqueBars = true
                
        self.failedToLoad = false
        tableView.estimatedRowHeight = 60
    
        // get info as lists instead of dictionaries
        courseInfo = getCourseData(course)
        for instructor in course.instructors {
            instructorInfo.append(getInstructorData(instructor))
        }
        
        getComments()
    }
    
    func registerNibs() {
        //Register all of the cell nibs
        var cellNib = UINib(nibName: "NewComment", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "NewComment")
        
        cellNib = UINib(nibName: "CommentCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "CommentCell")
        
        cellNib = UINib(nibName: "GuestComment", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "GuestComment")
        
        cellNib = UINib(nibName: "FailedToLoad", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "FailedToLoad")
        
        cellNib = UINib(nibName: "LoadingCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "LoadingCell")
        
        cellNib = UINib(nibName: "CourseInfoCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "CourseInfoCell")
        
        cellNib = UINib(nibName: "NewCommentCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "NewCommentCell")
        
        cellNib = UINib(nibName: "InstructorCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "InstructorCell")
    }
    
    func getComments() {
        query = PFQuery(className:"Comments")
        query!.whereKey("courseNumber", equalTo: course.number)
        
        reachability = Reachability()!
        if reachability.connection == .none && !query!.hasCachedResult {
            tableView.reloadData()
            failedToLoad = true
            SVProgressHUD.showError(withStatus: "No internet connection. Cannot load comments")
            SVProgressHUD.dismiss(withDelay: 1)
            courseComments = nil
            commentObj = nil
            return
        }
        
        query!.cachePolicy = .networkElseCache // first try network to get up to date, then cache
        query!.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            if let objects = objects {
                // found objects
                self.commentsHaveLoaded = true
                let object = objects[0] // should only return one object
                self.courseComments = (object["comments"] as! CourseComments)
                if self.courseComments!.count == 0 {
                    self.noCommentsToDisplay = true
                } else {
                    self.noCommentsToDisplay = false
                }
                self.commentObj = object
                if self.segmentControl.selectedSegmentIndex == 2 {
                    self.tableView.reloadData()
                }
            } else if let error = error {
                // failed to get comments for some reason
                self.failedToLoad = true
                self.courseComments = nil
                self.commentObj = nil
                if self.segmentControl.selectedSegmentIndex == 2 {
                    SVProgressHUD.showError(withStatus: error.localizedDescription)
                    SVProgressHUD.dismiss(withDelay: 1)
                }
            } else {
                self.failedToLoad = true
                if self.segmentControl.selectedSegmentIndex == 2 {
                    SVProgressHUD.showError(withStatus: "Failed to load comments")
                    SVProgressHUD.dismiss(withDelay: 1)
                }
            }
        }
    }
    
    @IBAction func segmentControlValueChanged(_ sender: Any) {
        SVProgressHUD.dismiss() // if the user leaves comments when loading, dismiss
        tableView.reloadData()
        if segmentControl.selectedSegmentIndex != 2 {
            tableView.refreshControl = nil // remove the pull to refresh
        } else { // comments segment
            tableView.refreshControl = refreshController
            refreshControl?.addTarget(self, action: #selector(refreshComments), for: .valueChanged)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowReplies" {
            let controller = segue.destination as! CommentRepliesViewController
            controller.commentObj = commentObj
            controller.delegate = self
            let commentIndex = sender as! Int
            controller.commentIndex = commentIndex
        } else if segue.identifier == "ShowInstructorInfo" {
            let controller = segue.destination as! InstructorInfoTableViewController
            let instructorIndex = sender as! Int
            controller.instructor = course.instructors[instructorIndex]
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
            if self.isLoadingNewComment {
                self.isLoadingNewComment = false
            }
            self.tableView.reloadData()
        })
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if segmentControl.selectedSegmentIndex == 2 && indexPath.section == 0 && PFUser.current() == nil {
            return 80
        }
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if segmentControl.selectedSegmentIndex == 1 {
            // show the instructor info
            performSegue(withIdentifier: "ShowInstructorInfo", sender: indexPath.row)
        } else if segmentControl.selectedSegmentIndex == 2 {
            if PFUser.current() == nil && indexPath.section == 0 {
                // take the guest back to login screen
                showLoginScreen()
            } else if PFUser.current() != nil && indexPath.section == 0 {
                return
            } else {
                if failedToLoad {
                    // if the comments have failed to load, tapping the failed to load cell
                    // will refresh the loading
                    getComments()
                    return
                } else if courseComments == nil {
                    // if the comments are loading, tapping the loading cell will do nothing
                    return
                }
                
                if isEditingComment {
                    // can't segue to the comment that is being edited
                    if editingIndex == indexPath.row {
                        return
                    }
                }
                performSegue(withIdentifier: "ShowReplies", sender: indexPath.row)
            }
        }
    }

    //MARK: - TableViewDelegates
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // save the height of each cell in the dictionary for faster calculations
        // makes the table transitions smoother
        if segmentControl.selectedSegmentIndex == 2 {
            cellHeights[indexPath] = cell.frame.size.height
        }
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if segmentControl.selectedSegmentIndex == 2 {
            return cellHeights[indexPath] ?? 70.0
        } else {
            return 70
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if segmentControl.selectedSegmentIndex == 2 {
            return 2
        } else {
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmentControl.selectedSegmentIndex == 0 {
            return 1
        } else if segmentControl.selectedSegmentIndex == 1 {
//            return 11 // one for each piece of instructor info
            return course.instructors.count
        } else {
            if section == 0 {
                return 1
            } else {
                if let comments = courseComments {
                    return isLoadingNewComment ? comments.count + 1 : comments.count
                } else { // there were no comments to show so just show failed to load cell
                    return 1
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if segmentControl.selectedSegmentIndex == 2 && section == 0 && PFUser.current() != nil {
            return "New Comment"
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if segmentControl.selectedSegmentIndex == 2 && section == 1 {
            if noCommentsToDisplay {
                return "This course has no comments so far. Be the first to leave one!"
            }
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let i = indexPath.row
        if segmentControl.selectedSegmentIndex == 2 && indexPath.section == 1 {
            if courseComments == nil || PFUser.current() == nil {
                return false
            } else if isEditingComment && editingIndex == i {
                return false
            } else if isLoadingNewComment && i == 0 {
                return false
            } else if (courseComments?[isLoadingNewComment ? i - 1 : i]["andrewID"] as! String) == PFUser.current()?.username {
                return true
            }
        }
        return false
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        var editActions : [UITableViewRowAction]? = nil
        if segmentControl.selectedSegmentIndex == 2 && indexPath.section == 1 {
            if (courseComments?[indexPath.row]["andrewID"] as! String) == PFUser.current()?.username {
                let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
                    let replies = self.courseComments![indexPath.row]["replies"] as! [[String : Any]]
                    let numReplies = replies.count
                    var alertMessage = ""
                    if numReplies == 0 {
                        alertMessage = "Are you sure you want to delete this comment?"
                    } else {
                        alertMessage = "This comment has \(numReplies) replies that other students may find useful! Consider making the comment anonymous!"
                    }
                    let alert = formattedAlert(titleString: "Are you sure?", messageString: alertMessage)

                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                        //Cancel Action
                    }))
                    alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { (_) in
                        // remove the comment from the indexPath.row of the comment obj array
                        // fetch, rewrite and save the comment obj
                        // refresh the table
                        // manually change the height dictionary
                        self.deleteComment(atIndexPath: indexPath)
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
                let editAction = UITableViewRowAction(style: .normal, title: "Edit") { (action, indexPath) in
                    if self.isEditingComment {
                        self.isEditingComment = false
                        self.tableView.reloadRows(at: [IndexPath(item: self.editingIndex, section: 1)], with: .fade)
                        self.editingIndex = nil
                    }
                    self.isEditingComment = true
                    self.editingIndex = indexPath.row
                    self.tableView.reloadRows(at: [indexPath], with: .bottom)
                    self.tableView.scrollToRow(at: indexPath, at: .none, animated: true)
                }
                editActions = [deleteAction, editAction]
            }
        }
        return editActions
    }
    
    func deleteComment(atIndexPath indexPath: IndexPath) {
        SVProgressHUD.show(withStatus: "Deleting...")
        self.commentObj?.fetchInBackground { (object: PFObject?, error: Error?) in
            // have to fetch in case someone made a new comment in the meantime
            if let object = object { // if it succeeds to fetch any updates
                var comments = object["comments"] as! [[String : Any]] // the current comments
                comments.remove(at: indexPath.row)
                
                object["comments"] = comments
                // delete the comment and rewrite the old comments
                
                object.saveInBackground(block: { (success: Bool, error: Error?) in
                    if success {
                        SVProgressHUD.showSuccess(withStatus: "Deleted")
                        SVProgressHUD.dismiss(withDelay: 1)
                        
                        // update the courseComments with the new comments
                        self.courseComments = (object["comments"] as! CourseComments)
                        self.commentObj = object
                        
                        self.cellHeights.removeValue(forKey: indexPath)
                        
                        // shift the heights of each IndexPath after the deleted cell
                        // to the one before it as the table will be shifted up one cell
                        for height in self.cellHeights where height.key.section != 0 {
                            let i = height.key
                            if i.row > indexPath.row {
                                self.cellHeights[i] = self.cellHeights[IndexPath(item: i.row-1, section: 1)]
                            }
                        }
                        
                        self.tableView.beginUpdates()
                        self.tableView.deleteRows(at: [indexPath], with: .left)
                        self.tableView.endUpdates()
                        
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

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let i = indexPath.row
        let j = indexPath.section
        
        if failedToLoad && segmentControl.selectedSegmentIndex == 2 {
            // only display the failed to load cell
            let failedToLoadCell = tableView.dequeueReusableCell(withIdentifier: "FailedToLoad", for: indexPath)
            return failedToLoadCell
        }

        if segmentControl.selectedSegmentIndex == 0 {
            // the course information segment's cells
            let infoCell = tableView.dequeueReusableCell(withIdentifier: "CourseInfoCell", for: indexPath) as! CourseInfoTableViewCell
            infoCell.numberLabel.text = course.number
            infoCell.nameLabel.text = course.name ?? "No name available"
            infoCell.departmentLabel.text = course.department ?? "No department available"
            if let units = course.units {
                infoCell.unitsLabel.text = "Units: \(String(format: "%.1f", units))"
            } else {
                infoCell.unitsLabel.text = "Units not available"
            }
            infoCell.hoursDetailsLabel.text = String(format: "%.1f", course.hours)
            infoCell.courseRateDetailsLabel.text = String(format: "%.1f", course.rate)
            infoCell.descriptionLabel.text = course.desc ?? "No description available"
            infoCell.prereqsDetailsLabel.text = course.prereqs ?? "None"
            infoCell.coreqDetailsLabel.text = course.coreqs ?? "None"
            return infoCell
        }
        else if segmentControl.selectedSegmentIndex == 1 {
            // the instructor segment's cells
            let instructorCell = tableView.dequeueReusableCell(withIdentifier: "InstructorCell", for: indexPath) as! InstructorTableViewCell
            instructorCell.hasDisclosureIndicator(true)
            instructorCell.instructorLabel.text = course.instructors[i].name
            instructorCell.ratingStars.rating = course.instructors[i].teachingRate
            instructorCell.ratingLabel.text = "(\(String(format: "%.1f", course.instructors[i].teachingRate)))"
            instructorCell.hoursLabel.text = String(format: "%.1f", course.instructors[i].hours)
            return instructorCell
        }
        else {
            if j == 0 { // the first segment is the new comment segment
                if PFUser.current() != nil {
                    // show the new comment cell as the first cell
                    let newCommentCell = tableView.dequeueReusableCell(withIdentifier: "NewCommentCell", for: indexPath) as! NewCommentCell
                    newCommentCell.delegate = self
                    newCommentCell.courseNumber = course.number
                    newCommentCell.isEditingComment = false
                    newCommentCell.setupText()
                    return newCommentCell
                } else {
                    let guestCommentCell = tableView.dequeueReusableCell(withIdentifier: "GuestComment", for: indexPath) as! GuestCommentCell
                    guestCommentCell.delegate = self
                    return guestCommentCell
                }
            }
            else {
                if (i == 0 && isLoadingNewComment) || (isLoadingEditedComment && i == editingIndex) {
                    // if the user posted a new comment, display the loading cell
                    let loadingCell = tableView.dequeueReusableCell(withIdentifier: "LoadingCell", for: indexPath) as! LoadingCell
                    loadingCell.spinner.startAnimating()
                    return loadingCell
                }
                if isEditingComment && i == editingIndex {
                    let editingCell = tableView.dequeueReusableCell(withIdentifier: "NewCommentCell", for: indexPath) as! NewCommentCell
                    editingCell.delegate = self
                    editingCell.isEditingComment = true
                    editingCell.editingCommentIndex = i
                    editingCell.titleField.becomeFirstResponder()
                    editingCell.courseNumber = course.number
                    editingCell.commentText = courseComments![i]["commentText"] as? String
                    editingCell.commentTitle = courseComments![i]["header"] as? String
                    editingCell.wasAnonymous = courseComments![i]["anonymous"] as? Bool
                    editingCell.replies = (courseComments![i]["replies"] as! CommentReplies)
                    editingCell.setupText()
                    return editingCell
                }
                else {
                    if let comments = courseComments {
                        // display comments
                        // if the user has just posted a comment, there is a temporary cell with a loading
                        // spinner, so in this case each cell must be shifted forward by one to fit this
                        let indexRow = isLoadingNewComment ? indexPath.row - 1 : indexPath.row
                        let commentCell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as! CommentCell
                        let commentInfo = comments[indexRow]
                        commentCell.headerLabel.text = commentInfo["header"] as? String
                        commentCell.commentLabel.text = commentInfo["commentText"] as? String
                        
                        let timeManager = TimeManager(withTimeOfPosting: commentInfo["timePosted"] as! String)
                        let dateString = timeManager.getString()
                        
                        commentCell.dateLabel.text = dateString
                        
                        if commentInfo["andrewID"] as? String == PFUser.current()?.username {
                            commentCell.starImage.isHidden = false
                            if commentInfo["anonymous"] as! Bool {
                                commentCell.andrewIDLabel.text = "You (anonymous)"
                            } else {
                                commentCell.andrewIDLabel.text = "You"
                            }
                        } else {
                            commentCell.starImage.isHidden = true
                            if commentInfo["anonymous"] as! Bool {
                                commentCell.andrewIDLabel.text = "Anonymous"
                            } else {
                                commentCell.andrewIDLabel.text = commentInfo["andrewID"] as? String
                            }
                        }
                        return commentCell
                    } else {
                        // the comments haven't loaded
                        let loadingCell = tableView.dequeueReusableCell(withIdentifier: "LoadingCell", for: indexPath) as! LoadingCell
                        loadingCell.spinner.startAnimating()
                        return loadingCell
                    }
                }
            }
        }
    }
    
    //MARK:- NewCommentCellDelegate
    func askToSave(withData data: [String: Any], toIndex index: Int) {
        let alert = formattedAlert(titleString: "Are you sure?", messageString: "Are you sure you want to save these changes?")
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            return
        }))
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { (_) in
            // update the existing comment
            self.didPostComment(withData: data, wasEdited: true, atIndex: index)
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func askToCancel(atIndex index: Int) {
        let alert = formattedAlert(titleString: "Are you sure?", messageString: "Are you sure you want to cancel these changes?")

        alert.addAction(UIAlertAction(title: "Don't Cancel", style: .default, handler: { _ in
            return
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            self.didCancelComment(atIndex: index)
        }))
        present(alert, animated: true, completion: nil)
    }
    
    
    func didPostComment(withData data: [String : Any], wasEdited edited: Bool, atIndex index : Int) {
        if isEditingComment && !edited {
            // if the user tried to post a comment while they were editing another comment
            SVProgressHUD.showError(withStatus: "You cannot post a new comment while editing another")
            SVProgressHUD.dismiss(withDelay: 1)
            return
        }
        
        if edited {
            // TODO - loading cell for updated comment?
        } else {
            isLoadingNewComment = true
            if noCommentsToDisplay {
                noCommentsToDisplay = false
                tableView.reloadData()
            } else {
                tableView.beginUpdates()
                tableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .top)
                tableView.endUpdates()
            }
        }
        commentObj?.fetchInBackground { (object: PFObject?, error: Error?) in
            // have to fetch in case someone made a new comment in the meantime
            if let object = object { // if it succeeds to fetch any updates
                var comments = object["comments"] as! [[String : Any]] // the current comments
                // insert the new comment at the beginning and rewrite the old comments
                if !edited {
                    // if it's a new comment, insert the new comment at the beginning
                    comments.insert(data, at: 0)
                    object["comments"] = comments
                } else {
                    // else just rewrite the old comment at the right index
                    comments[index] = data
                    object["comments"] = comments
                }
                
                object.saveInBackground(block: { (success: Bool, error: Error?) in
                    self.isLoadingNewComment = false // remove the loading cell
                    
                    if success {
                        // update the courseComments with the new comments
                        self.courseComments = (object["comments"] as! CourseComments)
                        if edited {
                            self.isEditingComment = false
                            self.tableView.reloadRows(at: [IndexPath(item: self.editingIndex, section: 1)], with: .fade)
                            self.editingIndex = nil
                        } else {
                            self.tableView.reloadData()
                        }
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
    
    func didCancelComment(atIndex index : Int) {
        self.isEditingComment = false
        self.editingIndex = nil
        self.tableView.reloadRows(at: [IndexPath(item: index, section: 1)], with: .fade)
    }
    
    //MARK:- GuestCommentCellDelegate
    func showLoginScreen() {
        // called when the guest pressed 'login to comment'
        // instantiate a new signupscreen and push it to navigation stack
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "SignUpScreen") as! SignUpViewController
        self.present(vc, animated: true, completion: nil)
    }
    
    //MARK:- CommentRepliesViewControllerDelegate
    func updateCourseInfoObject(toObject object: PFObject, commentIndices indices: (Int, Int)!, commentIndex index: Int!) {
        self.commentObj = object
        self.courseComments = (commentObj!["comments"] as! CourseComments)
        tableView.reloadData()
    }
    
} // end of class

class CommentCell: UITableViewCell { // the cell that displays a comment
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var andrewIDLabel: UILabel!
    @IBOutlet weak var starImage: UIImageView!
    
}

class InfoCell: UITableViewCell {
    
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    
}
