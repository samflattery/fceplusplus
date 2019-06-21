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

class CommentRepliesViewController: UITableViewController, NewReplyTableViewCellDelegate, GuestCommentCellDelegate {

    // passed down from CourseInfoTableViewController in segue
    var commentObj: PFObject! // the object that the comment belongs to, will be updated on
                                // new reply
    var commentIndex: Int!
    
    // taken from the commentObj
    var commentReplies: CommentReplies!
    var comment: CourseComment!
    
    var isLoadingComment = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    
    func setFieldsFromObject(_ commentObj: PFObject) {
        let allComments = commentObj["comments"]! as! NSArray // the commentObj is a dictonary with
        // keys "comments" and "courseNumber"
        self.comment = (allComments[commentIndex] as! CourseComment) // just get the comment that was tapped on
        self.commentReplies = (self.comment["replies"] as! CommentReplies) // get replies of that comment
    }
    
    //MARK:- Table View Delegates
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
            loginPressed()
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 { // display the comment itself
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
        } else if indexPath.section == 1 { // the new comment cell
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
            
            if indexPath.row == 0 && isLoadingComment {
                let loadingCell = tableView.dequeueReusableCell(withIdentifier: "LoadingCell", for: indexPath) as! LoadingCell
                loadingCell.spinner.startAnimating()
                return loadingCell
            }
            
            let indexRow = isLoadingComment ? indexPath.row - 1 : indexPath.row
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
    
    //MARK:- NewReplyTableViewCellDelegate
    func didStartReplying() {
        isLoadingComment = true
        tableView.reloadData()
    }
    
    func didPostReply(withData data: [String : Any]) {
//        var comment = comments[indexOfComment] // gets the single comment in the array of comments that
        // was replied to
        // get the old replies from the single comment
        isLoadingComment = true
        tableView.reloadData()
        commentObj.fetchInBackground { (object: PFObject?, error: Error?) in
            if let object = object {
                var comments = (object["comments"] as! CourseComments)
                var currComment = comments[self.commentIndex]
                var replies = currComment["replies"] as! CommentReplies
                replies.insert(data, at: 0)
                currComment["replies"] = replies
                comments[self.commentIndex] = currComment
                object["comments"] = comments
                object.saveInBackground(block: { (success: Bool, error: Error?) in
                    if success {
                        self.isLoadingComment = false
                        self.setFieldsFromObject(object)
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

class CommentReplyCell: UITableViewCell {

    @IBOutlet weak var replyLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var andrewIDLabel: UILabel!
    
}

class LoadingCell: UITableViewCell {
    @IBOutlet weak var spinner: UIActivityIndicatorView!
}
