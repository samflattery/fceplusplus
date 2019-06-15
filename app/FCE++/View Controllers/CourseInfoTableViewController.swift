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

typealias courseComment = [[String: Any]]

class CourseInfoTableViewController: UITableViewController, UITextFieldDelegate {
    
    var query: PFQuery<PFObject>?
    var reachability: Reachability!
    
    var course: Course!
    var instructorInfo: [[String]] = []
    var courseInfo: [String]!
    var courseComments: courseComment?
    var commentObj: PFObject?
    var button: UIButton?
    
    var hasLoadedComments = false
    var failedToLoad = false
    var hasPostedComment = false
    
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    let refreshController = UIRefreshControl()
    
    @IBAction func segmentControlValueChanged(_ sender: Any) {
        SVProgressHUD.dismiss()
        if segmentControl.selectedSegmentIndex == 2 {
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
                tableView.refreshControl = refreshController
                refreshControl?.addTarget(self, action: #selector(refreshComments), for: .valueChanged)
                
                tableView.reloadData()
                query!.cachePolicy = .networkElseCache
                query!.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
                    if let error = error {
                        // Log details of the failure
                        SVProgressHUD.dismiss()
                        SVProgressHUD.showError(withStatus: "Failed to load comments.")
                        SVProgressHUD.dismiss(withDelay: 2)
                        print("failed in segment value changed", error.localizedDescription)
                    } else if let objects = objects {
                        // Do something with the found objects
                        self.hasLoadedComments = true
                        for object in objects {
                            self.courseComments = (object["comments"] as! courseComment)
                            self.commentObj = object
                            let newCommentCell = self.view.viewWithTag(1001) as? NewCommentTableViewCell
                            newCommentCell?.commentObj = object
                            SVProgressHUD.dismiss()
                            self.tableView.reloadData()
                        }
                    }
                }
            } else {
                tableView.reloadData()
            }
        } else {
            tableView.reloadData()
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.failedToLoad = false
        self.hasLoadedComments = false
        tableView.estimatedRowHeight = 60
        
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
        
        courseInfo = getCourseData(course)
        for instructor in course.instructors {
            instructorInfo.append(getInstructorData(instructor))
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        query?.cancel()
        SVProgressHUD.dismiss()
    }
    
    @objc func postClicked() {
        hasPostedComment = true
        tableView.reloadData()
        refreshComments()
    }
    
    @objc func refreshComments() {
        reachability = Reachability()!
        if reachability.connection == .none {
            if let rC = self.refreshControl {
                rC.endRefreshing()
            }
            return
        }
        self.commentObj?.fetchInBackground(block: { (object: PFObject?, error: Error?) in
            self.courseComments = (object?["comments"] as! courseComment)
            self.refreshControl?.endRefreshing()
            if self.hasPostedComment {
                self.hasPostedComment = false
            }
            self.tableView.reloadData()
        })
    }
    
    @objc func showLoginScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "SignUpScreen") as! SignUpViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if segmentControl.selectedSegmentIndex == 2 && indexPath.row == 0 && PFUser.current() != nil {
            return 200
        } else {
            return UITableView.automaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if PFUser.current() == nil && indexPath.row == 0 {
            showLoginScreen()
        }
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        if segmentControl.selectedSegmentIndex == 1 {
            return instructorInfo.count
        } else {
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmentControl.selectedSegmentIndex == 0 {
            return 9
        } else if segmentControl.selectedSegmentIndex == 1 {
            return 11
        } else {
            if let comments = courseComments {
                if hasPostedComment {
                    return comments.count + 2
                }
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
        
        if failedToLoad && segmentControl.selectedSegmentIndex == 2 {
            return tableView.dequeueReusableCell(withIdentifier: "FailedToLoad", for: indexPath)
        }
        
        if segmentControl.selectedSegmentIndex == 0 {
            if i == 6 {
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
        } else if segmentControl.selectedSegmentIndex == 1 {
            cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.textLabel!.text = instructorTitles[i]
            cell.detailTextLabel!.text = instructorInfo[j][i]
        } else {
            if i == 0 && PFUser.current() != nil {
                let newCommentCell = tableView.dequeueReusableCell(withIdentifier: "NewComment", for: indexPath) as! NewCommentTableViewCell
                newCommentCell.courseNumber = course.number
                newCommentCell.commentObj = commentObj
                let button = self.view.viewWithTag(120) as! UIButton
                button.addTarget(self, action: #selector(postClicked), for: .touchUpInside)
                return newCommentCell
            } else if i == 0 && PFUser.current() == nil {
                let guestCommentCell = tableView.dequeueReusableCell(withIdentifier: "GuestComment", for: indexPath)
                let button = guestCommentCell.viewWithTag(65) as! UIButton
                button.addTarget(self, action: #selector(showLoginScreen), for: .touchUpInside)
                return guestCommentCell
            } else if i == 1 && hasPostedComment {
                cell = tableView.dequeueReusableCell(withIdentifier: "LoadingCell", for: indexPath)
                let activitySpinner = cell.viewWithTag(121) as! UIActivityIndicatorView
                activitySpinner.startAnimating()
            } else {
                let indexRow = hasPostedComment ? indexPath.row - 2 : indexPath.row - 1
                cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath)
                if let commentInfo = courseComments?[indexRow] {
                    let commentTextView = cell.viewWithTag(100) as! UITextView
                    commentTextView.text = commentInfo["commentText"] as? String
                    let dateLabel = cell.viewWithTag(175) as! UILabel
                    dateLabel.text = commentInfo["timePosted"] as? String
                    let andrewIDLabel = cell.viewWithTag(150) as! UILabel
                    if commentInfo["anonymous"] as! Bool {
                        andrewIDLabel.text = "Anonymous"
                    } else {
                        andrewIDLabel.text = commentInfo["andrewID"] as? String
                    }
                }
            }
        }
        return cell
    }


}
