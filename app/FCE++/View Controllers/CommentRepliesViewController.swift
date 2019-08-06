//
//  CommentRepliesViewController.swift
//  FCE++
//
//  Created by Sam Flattery on 6/18/19.
//  Copyright © 2019 Sam Flattery. All rights reserved.
//

import UIKit
import Parse
import SVProgressHUD

typealias CommentReplies = [[String: Any]]

protocol CommentRepliesViewControllerDelegate {
    func updateCourseInfoObject(toObject object: PFObject)
}

class CommentRepliesViewController: UITableViewController, NewReplyTableViewCellDelegate, GuestCommentCellDelegate {

    // passed down from CourseInfoTableViewController in segue
    var commentObj: PFObject! // the object that the comment belongs to, will be updated on
                                // new reply
    var commentIndex: Int!
    
    // taken from the commentObj
    var commentReplies: CommentReplies!
    var comment: CourseComment!
    
    let refreshController = UIRefreshControl()
    
    var isLoadingNewReply = false // true if the comments are being loaded in the background
    var cellHeights: [IndexPath : CGFloat] = [:] // a dictionary of cell heights to avoid jumpy table
    
    var isEditingReply : Bool = false
    var editingIndex : Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        extendedLayoutIncludesOpaqueBars = true
        
        tableView.refreshControl = refreshController
        refreshControl?.addTarget(self, action: #selector(refreshComments), for: .valueChanged)
        
        var cellNib = UINib(nibName: "NewReply", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "NewReply")
        
        cellNib = UINib(nibName: "CommentCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "CommentCell")
        
        cellNib = UINib(nibName: "LoadingCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "LoadingCell")
        
        cellNib = UINib(nibName: "GuestComment", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "GuestComment")
        
        setFieldsFromObject(commentObj)

    }
    
    @objc func refreshComments() { // needs to be objc for the refreshControl
        // called when post clicked or when pulled to refresh
        let reachability = Reachability()!
        if reachability.connection == .none {
            if let rC = self.refreshControl {
                // if there's no internet but there is a refresh bar, end the refreshing
                rC.endRefreshing()
            }
            return
        }
        self.commentObj?.fetchInBackground(block: { (object: PFObject?, error: Error?) in
            // fetch new comments in the background and update the comment array
            if let object = object {
                // there is a chance that someone posted a new comment since the last refresh,
                // in which case, the indices would have shifted and we must find the new index
                let objComments = (object["comments"]) as! CourseComments
                let newComments = objComments[self.commentIndex]
                
                // time posted and andrewID are likely going to be a unique identifier
                let newTimePosted = newComments["timePosted"] as! String
                let oldTimePosted = self.comment["timePosted"] as! String
                let oldID = newComments["andrewID"] as! String
                let newID = self.comment["andrewID"] as! String
                if newTimePosted != oldTimePosted || oldID != newID {
                    // a new comment must have been added which misaligned the index
                    for i in 0..<objComments.count {
                        // find the comment that is supposed to be displayed
                        let comment = objComments[i]
                        let commentTime = comment["timePosted"] as! String
                        let commentID = comment["andrewID"] as! String
                        if commentTime == oldTimePosted && commentID == newID {
                            // set the new index of that comment
                            self.commentIndex = i
                        }
                    }
                }
                self.commentObj = object
                self.setFieldsFromObject(object)
            }
            self.refreshControl?.endRefreshing()
            self.tableView.reloadData()
        })
    }
    
    func setFieldsFromObject(_ commentObj: PFObject) {
        let allComments = commentObj["comments"]! as! NSArray // the commentObj is a dictonary with
        // keys "comments" and "courseNumber"
        self.comment = (allComments[commentIndex] as! CourseComment) // just get the comment that was tapped on
        self.commentReplies = (self.comment["replies"] as! CommentReplies) // get replies of that comment
    }
    
    //MARK:- TableViewDelegates
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // save the height of each cell in the dictionary for faster calculations
        // makes the table transitions smoother
        cellHeights[indexPath] = cell.frame.size.height
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath] ?? 70.0
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3 // the comment itself, the new comment cell, and the replies
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 || section == 1 {
            return 1
        } else {
            return commentReplies.count
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 && PFUser.current() != nil {
            return 200
        } else if indexPath.section == 2 && isEditingReply && indexPath.row == editingIndex {
            return 200
        } else {
            return UITableView.automaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return "Leave a reply!"
        } else if section == 2 {
            return "Replies"
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if PFUser.current() == nil && indexPath.section == 1 {
            showLoginScreen()
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 2 {
            if PFUser.current() == nil {
                return false
            } else if isEditingReply && indexPath.row == editingIndex {
                return false
            } else if (commentReplies[indexPath.row]["andrewID"] as! String) == PFUser.current()!.username {
                return true
            }
        }
        return false
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        var editActions : [UITableViewRowAction]? = nil
        if indexPath.section == 2 {
            if (commentReplies[indexPath.row]["andrewID"] as! String) == PFUser.current()?.username {
                let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
                    let alert = UIAlertController(title: "Are you sure?", message: "Are you sure you want to delete this reply?", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { _ in
                        //Cancel Action
                    }))
                    alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (_) in
                        // fetch, rewrite and save object
                        // update local fields from new object and delete cell
                        SVProgressHUD.show(withStatus: "Deleting...")
                        self.commentObj?.fetchInBackground { (object: PFObject?, error: Error?) in
                            // have to fetch in case someone made a new comment in the meantime
                            if let object = object { // if it succeeds to fetch any updates
                                var comments = object["comments"] as! [[String : Any]] // the current comments
                                var replies = comments[self.commentIndex]["replies"] as! [[String : Any]]
                                replies.remove(at: indexPath.row)
                                comments[self.commentIndex]["replies"] = replies
                                
                                object["comments"] = comments
                                // delete the reply and rewrite the old comments
                                
                                object.saveInBackground(block: { (success: Bool, error: Error?) in
                                    if success {
                                        SVProgressHUD.showSuccess(withStatus: "Deleted")
                                        SVProgressHUD.dismiss(withDelay: 1)
                                        
                                        // update the courseComments with the new comments
                                        self.setFieldsFromObject(object)
    
                                        self.cellHeights.removeValue(forKey: indexPath)
                                        
                                        // shift the heights of each IndexPath after the deleted cell
                                        // to the one before it as the table will be shifted up one cell
                                        for height in self.cellHeights where height.key.section == 2 {
                                            let i = height.key
                                            if i.row > indexPath.row {
                                                self.cellHeights[i] = self.cellHeights[IndexPath(item: i.row-1, section: 1)]
                                            }
                                        }
                                        
                                        self.tableView.beginUpdates()
                                        self.tableView.deleteRows(at: [indexPath], with: .fade)
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
                    }))
                    
                    self.present(alert, animated: true, completion: nil)
                }
                let editAction = UITableViewRowAction(style: .normal, title: "Edit") { (action, indexPath) in
                    print("edit")
                    if self.isEditingReply {
                        print("should reload")
                        self.isEditingReply = false
                        self.tableView.reloadRows(at: [IndexPath(item: self.editingIndex, section: 2)], with: .fade)
                        self.editingIndex = nil
                    }
                    self.isEditingReply = true
                    self.editingIndex = indexPath.row
                    self.tableView.reloadRows(at: [indexPath], with: .bottom)
                    self.tableView.scrollToRow(at: indexPath, at: .none, animated: true)
                    self.tableView.reloadData()
                }
                editActions = [deleteAction, editAction]
            }
        }
        return editActions
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let i = indexPath.row
        let j = indexPath.section
        
        if j == 0 { // display the comment itself
            let commentCell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as! CommentCell
            commentCell.accessoryType = .none // removes disclosure indicator
            commentCell.isUserInteractionEnabled = false
            commentCell.headerLabel.text = comment["header"] as? String
            commentCell.commentLabel.text = comment["commentText"] as? String
            commentCell.dateLabel.text = comment["timePosted"] as? String
            if comment["anonymous"] as! Bool {
                commentCell.andrewIDLabel.text = "Anonymous"
            } else {
                commentCell.andrewIDLabel.text = comment["andrewID"] as? String
            }
            return commentCell
        } else if j == 1 { // the new comment cell
            if PFUser.current() != nil {
                let newReplyCell = tableView.dequeueReusableCell(withIdentifier: "NewReply", for: indexPath) as! NewReplyTableViewCell
                newReplyCell.delegate = self
                return newReplyCell
            } else {
                let guestCell = tableView.dequeueReusableCell(withIdentifier: "GuestComment", for: indexPath) as! GuestCommentCell
                guestCell.delegate = self
                return guestCell
            }
        } else { // display the replies
            if i == 0 && isLoadingNewReply {
                let loadingCell = tableView.dequeueReusableCell(withIdentifier: "LoadingCell", for: indexPath) as! LoadingCell
                loadingCell.spinner.startAnimating()
                return loadingCell
            }
            else if isEditingReply && i == editingIndex {
                let newReplyCell = tableView.dequeueReusableCell(withIdentifier: "NewReply", for: indexPath) as! NewReplyTableViewCell
                newReplyCell.delegate = self
                newReplyCell.editingIndex = i
                newReplyCell.replyText = (commentReplies[i]["replyText"] as! String)
                newReplyCell.setupEditing(isAnonymous: commentReplies[i]["anonymous"] as! Bool)
                return newReplyCell
            }
            else {
                let indexRow = isLoadingNewReply ? i - 1 : i
                let replyCell = tableView.dequeueReusableCell(withIdentifier: "ReplyCell", for: indexPath) as! CommentReplyCell
                let commentReply = commentReplies[indexRow]
                replyCell.replyLabel.text = commentReply["replyText"] as? String
                replyCell.dateLabel.text = commentReply["timePosted"] as? String
                if commentReply["anonymous"] as! Bool {
                    replyCell.andrewIDLabel.text = "Anonymous"
                } else {
                    replyCell.andrewIDLabel.text = commentReply["andrewID"] as? String
                }
                return replyCell
            }
        }
    }
    
    //MARK:- NewReplyTableViewCellDelegate
    func didStartReplying() {
        isLoadingNewReply = true
        tableView.reloadData()
    }
    
    func didPostReply(withData data: [String : Any], wasEdited edited: Bool, toIndex index: Int) {
        if edited {
            // edited loading cell?
        } else {
            isLoadingNewReply = true
            tableView.reloadData()
        }
        commentObj.fetchInBackground { (object: PFObject?, error: Error?) in
            if let object = object {
                var comments = (object["comments"] as! CourseComments)
                var currComment = comments[self.commentIndex]
                var replies = currComment["replies"] as! CommentReplies
                
                if !edited {
                    replies.insert(data, at: 0)
                } else {
                    replies[index] = data
                }
                currComment["replies"] = replies
                comments[self.commentIndex] = currComment
                object["comments"] = comments
                object.saveInBackground(block: { (success: Bool, error: Error?) in
                    if success {
                        if !edited {
                            self.isLoadingNewReply = false
                        }
                        self.setFieldsFromObject(object)
                        if edited {
                            self.isEditingReply = false
                            self.editingIndex = nil
                            self.tableView.reloadRows(at: [IndexPath(item: index, section: 2)], with: .fade)
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
    
    func didCancelReply(atIndex index: Int) {
        self.isEditingReply = false
        self.editingIndex = nil
        self.tableView.reloadRows(at: [IndexPath(item: index, section: 2)], with: .fade)
    }

    //MARK:- GuestCommentCellDelegate
    func showLoginScreen() {
        // called when the guest pressed 'login to comment'
        // instantiate a new signupscreen and push it to navigation stack
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "SignUpScreen") as! SignUpViewController
        vc.hasComeFromGuest = true
        navigationController?.pushViewController(vc, animated: true)
    }

} // end of class

class CommentReplyCell: UITableViewCell {

    @IBOutlet weak var replyLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var andrewIDLabel: UILabel!
    
}

class LoadingCell: UITableViewCell {
    @IBOutlet weak var spinner: UIActivityIndicatorView!
}
