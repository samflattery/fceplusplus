//
//  ViewController.swift
//  FCE++
//
//  Created by Sam Flattery on 6/6/19.
//  Copyright © 2019 Sam Flattery. All rights reserved.
//

import UIKit
import Parse
import SVProgressHUD
import RSSelectionMenu
import TimeIntervals

struct CommentsToShow {
    // need the comments to be shown on the table
    var comments: CourseComments!
    
    // array of comment objects to be passed to CommentReplyViewController
    var objects: [PFObject]!
    
    // the first element of the tuple is the index of the selected object in the object array
    // the second element is the index of the selected comment in that course's comments
    var indexes: [(Int, Int)]!
    
    init() {
        comments = []
        objects = []
        indexes = []
    }
}

class SearchTableViewController: UITableViewController, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate, InfoPageViewControllerDelegate, GuestCommentCellDelegate, CommentRepliesViewControllerDelegate {
    
    var courses: [Course]! // the array of courses taken from output.json
    var filteredCourses = [Course]() // the courses filtered by search term to be shown to the user
    var highlightedCourses: [String]? // the user's highlighted course numbers
    
    var commentsToShow: CommentsToShow?
    var isLoadingComments = false
    var noCommentsToShow = false
    var failedToLoad = false // if Parse fails to load comments, show a footer
    
    let searchController = UISearchController(searchResultsController: nil)
    let refreshController = UIRefreshControl()
    
    var cellHeights = [IndexPath : CGFloat]() // a dictionary of cell heights to avoid jumpy table
    
    var isSearching: Bool { // is the user currently typing a search
        return searchController.isActive && !(searchController.searchBar.text?.isEmpty ?? true)
    }
    
    var infoBarButtonItem: UIBarButtonItem! // the info button to be put in the navigation bar
    var sortBarButtonItem: UIBarButtonItem! // the sort button for nav bar
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        courses = appDelegate.courses // the AppDelegate loads the courses upon launching
        configureSearchController() // setup the search controller
        configureBarButtons()
        
        self.hideKeyboardWhenTappedAround()
        
        extendedLayoutIncludesOpaqueBars = true
        
        let cellNib = UINib(nibName: "LoadingCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "LoadingCell")
        
        
        if let user = PFUser.current() {
            //if someone is signed in, get their favourite courses
            highlightedCourses = (user["highlightedCourses"] as! [String])
            getCommentsToDisplay(toReload: true)
        }

        definesPresentationContext = true

        tableView.refreshControl = refreshController
        refreshControl?.addTarget(self, action: #selector(getCommentsForRefreshController), for: .valueChanged)
    }
    
    func configureSearchController() {
        // setting up the SearchController delegate
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.titleView = searchController.searchBar // put it in the navigation bar
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "Course name, instructor or keyword!"
        
        // want the cancel button to be white but the cursor to be blue
        setTextFieldTintColor(to: UIColor.blue, for: searchController.searchBar)

        searchController.searchBar.sizeToFit()
    }
    
    func setTextFieldTintColor(to color: UIColor, for view: UIView) {
        // set tint color for all subviews in searchBar that are of type UITextField
        if view is UITextField {
            view.tintColor = color
        }
        for subview in view.subviews {
            setTextFieldTintColor(to: color, for: subview)
        }
    }
    
    
    func configureBarButtons() {
        // Create the info button
        let infoButton = UIButton(type: .infoLight)
        infoButton.addTarget(self, action: #selector(showInfoScreen), for: .touchUpInside)
        // Create a bar button item using the info button as its custom view
        
        let button: UIButton = UIButton(type: .custom)
        //set image for button
        button.setImage(UIImage(named: "resized40"), for: .normal)
        //add function for button
        button.addTarget(self, action: #selector(showCourseSorter), for: .touchUpInside)
        //set frame
        button.frame = CGRect(x: 0, y: 0, width: 22, height: 22)
        
        sortBarButtonItem = UIBarButtonItem(customView: button)
        
        infoBarButtonItem = UIBarButtonItem(customView: infoButton)
        navigationItem.leftBarButtonItem = infoBarButtonItem
    }
    
    @objc func showCourseSorter() {
        // show a popup  when the sort bar button is pressed that allows user to
        // sort the courses by number, name, least and most hours per week
        let sortOptions = ["By Course Number (default)", "By Course Name", "Increasing Hours per Week", "Decreasing Hours per Week"]
        
        let selectionMenu = RSSelectionMenu(selectionStyle: .single, dataSource: sortOptions, cellType: .basic) { (cell, element: String, indexPath) in
            
            cell.textLabel!.attributedText = NSAttributedString(string: "\(element)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: UIFont(name: "IowanOldStyleW01-Roman", size: 18)!])
        }
        
        selectionMenu.cellSelectionStyle = .checkbox
        
        selectionMenu.onDismiss = { selectedItems in
            if selectedItems.count == 0 {
                return
            }
            switch selectedItems[0] {
            case "By Course Number (default)":
                self.filteredCourses = sortCoursesByNumber(self.filteredCourses, number: self.searchController.searchBar.text!)
            case "By Course Name":
                self.filteredCourses.sort(by: {
                    switch ($0.name == nil, $1.name == nil){
                    // 4 cases: neither have names, both have names,
                    // or one has name and other doesn't
                    // prioritize having a name
                    case (true, true):
                        return $0.number < $1.number
                    case (false, true):
                        return false
                    case (true, false):
                        return true
                    case (false, false):
                        return $0.name! < $1.name!
                    }
                })
            case "Increasing Hours per Week":
                self.filteredCourses.sort(by: { $0.hours < $1.hours })
            case "Decreasing Hours per Week":
                self.filteredCourses.sort(by: { $0.hours > $1.hours })
            default:
                break
            }
            self.tableView.reloadData()
        }

        selectionMenu.show(style: .alert(title: "Sort by", action: "Cancel", height: nil), from: self)

        return
    }
    
    @objc func showInfoScreen() {
        performSegue(withIdentifier: "ShowInfo", sender: nil)
    }
    
    @objc func getCommentsForRefreshController() {
        getCommentsToDisplay(toReload: true)
    }
    
    func getCommentsToDisplay(toReload reload: Bool) {
        let query = PFQuery(className: "Comments")
        // get all objects where the course name is in the user's favourite courses
        query.whereKey("courseNumber", containedIn: highlightedCourses!)
        
        let reachability = Reachability()!
        if reachability.connection == .none && !query.hasCachedResult {
            commentsToShow = nil
            self.failedToLoad = true
            tableView.reloadData()
            SVProgressHUD.showError(withStatus: "Could not display comments. Pull to refresh to try again")
            SVProgressHUD.dismiss(withDelay: 1)
            return
        }
        
        if reload {
            // if new highlightedCourses have been selected, the table view will have already
            // reloaded to get a loading cell before this point, so no need to do it again
            isLoadingComments = true
            tableView.reloadData()
        }
        
        query.cachePolicy = .networkElseCache // first try network to get up to date, then cache
//        query.cachePolicy = .networkOnly // first try network to get up to date, then cache

        query.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            self.isLoadingComments = false
            self.refreshControl?.endRefreshing()
            if let objects = objects {
                // found objects
                self.commentsToShow = CommentsToShow() // initialize a new struct
                
                /* when performing the segue to CommentReplyViewController, we need to pass the
                 object and the index of the comment that was pressed on in that object
                 
                 it was not possible to loop through using for i in 0..<objects.count because some
                 of the objects are empty and thus this gave indexing errors
                 
                 the end results is as follows:
                 objects = [Object0, Object1, Object2, ...]
                 comments = [Comment0.0, Comment0.1, Comment1.0, Comment2.0, ...]
                 indexes = [(0,0), (0,1), (1,0), (2,0), ...]
                 
                 the indices line up with the comments and show the relative index of the object to
                 which the comment belongs, and the comment's index in that object's comment array
 
                */
                var objectIndex = -1 // the index of the object in the object array
                
                for object in objects {
                    let courseComments = object["comments"] as! CourseComments
                    if courseComments.count == 0 {
                        continue // if there are no comments in the object, don't add anything
                    }
                    objectIndex += 1
            
                    self.commentsToShow!.objects.append(object) // add each object
                    let firstThreeComments: CourseComments = Array(courseComments.prefix(3))
                    for j in 0..<firstThreeComments.count {
                        // append the indices for each comment
                        self.commentsToShow!.indexes.append((objectIndex, j))
                    }
                    self.commentsToShow!.comments += firstThreeComments
                }
                if self.commentsToShow!.comments.count == 0 {
                    self.noCommentsToShow = true
                } else {
                    self.noCommentsToShow = false
                }
            } else if let error = error {
                // failed to get comments for some reason
                self.failedToLoad = true
                SVProgressHUD.showError(withStatus: error.localizedDescription)
                SVProgressHUD.dismiss(withDelay: 1)
            } else {
                self.failedToLoad = true
                SVProgressHUD.showError(withStatus: "Failed to load comments")
                SVProgressHUD.dismiss(withDelay: 1)
            }
            self.tableView.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "CourseInfo" {
            // send the course that is pressed on to the CourseInfo view
            let controller = segue.destination as! CourseInfoTableViewController
            controller.course = sender as? Course
        } else if segue.identifier == "ShowRepliesFromHome" {
            let controller = segue.destination as! CommentRepliesViewController
            let senderIndex = sender as! Int // the index of the comment in global array
            
            // get the relevant object index and the index of the comment in that object
            let commentIndices = commentsToShow!.indexes[senderIndex]
            let objectIndex = commentIndices.0
            let commentIndex = commentIndices.1
            
            controller.commentObj = commentsToShow!.objects[objectIndex]
            controller.commentIndex = commentIndex
            controller.indexOfGlobalComment = senderIndex
            controller.commentsToShowIndices = commentIndices
            controller.cameFromSearch = true
            controller.delegate = self
        } else if segue.identifier == "ShowInfo" {
            let controller = segue.destination as! InfoPageViewController
            controller.highlightedCourses = self.highlightedCourses
            controller.courses = self.courses
            controller.delegate = self
        }
    }

    //MARK:- Table View Delegates
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // save the height of each cell in the dictionary for faster calculations
        // makes the table transitions smoother
        cellHeights[indexPath] = cell.frame.size.height
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath] ?? 50.0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !isSearching {
            if isLoadingComments {
                // if the comments are being loaded, just display one loading cell
                return 1
            } else if let comments = commentsToShow {
                // if there are comments, show them
                if noCommentsToShow {
                    return 0
                } else {
                    return comments.comments.count
                }
            } else if PFUser.current() == nil {
                return 1 // a cell that redirects to login
            } else {
                return 0 // failed to load, show the footer
            }
        } else {
            return filteredCourses.count // the number of search results
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if !isSearching {
            if PFUser.current() == nil {
                return nil
            } else {
                return "Comments for you"
            }
        }
        return "Search results"
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if !isSearching {
            if noCommentsToShow {
                return "Click the info icon in the top left to add some courses.  The most recent comments from these courses will be displayed here!"
            } else if failedToLoad {
                return "Failed to load comments. Pull to refresh to try again"
            }
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if !isSearching {
            
            if isLoadingComments {
                // if new comments are being loaded, display the comment loading cell
                let loadingCell = tableView.dequeueReusableCell(withIdentifier: "LoadingCell", for: indexPath) as! LoadingCell
                loadingCell.spinner.startAnimating()
                return loadingCell
            }
            
            if commentsToShow != nil {
                // show the comment preview cells
                let i = indexPath.row
                let commentCell = tableView.dequeueReusableCell(withIdentifier: "CommentPreview", for: indexPath) as! CommentPreviewCell
                commentCell.headerLabel.text = commentsToShow?.comments[i]["header"] as? String
                commentCell.courseNumberLabel.text = commentsToShow?.comments[i]["courseNumber"] as? String
                commentCell.commentLabel.text = commentsToShow?.comments[i]["commentText"] as? String
                
                let timeManager = TimeManager(withTimeOfPosting: commentsToShow?.comments[i]["timePosted"] as! String)
                commentCell.dateLabel.text = timeManager.getString()
                
                return commentCell
            }

            // show a default cell to prompt the user to login
            let loginCell = tableView.dequeueReusableCell(withIdentifier: "LoginCell", for: indexPath) as! GuestCommentCell
            loginCell.delegate = self
            return loginCell
        } else {
            // Show the search result cells
            let searchResultCell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath) as! SearchResultCell
            let cellInfo = filteredCourses[indexPath.row]
            searchResultCell.numberLabel.text = cellInfo.number
            if let name = cellInfo.name {
                searchResultCell.nameLabel.text = name
            } else {
                searchResultCell.nameLabel.text = "No name available"
            }
            searchResultCell.hoursLabel.text = "FCE Hours: \(String(format: "%.1f", cellInfo.hours))"
            return searchResultCell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isSearching {
            let course = filteredCourses[indexPath.row]
            performSegue(withIdentifier: "CourseInfo", sender: course)
        } else {
            if PFUser.current() == nil {
                // if the guest wants to login, return them to login screen
                showLoginScreen()
            } else {
                // perform the segue to the comment replies
                if commentsToShow != nil {
                    performSegue(withIdentifier: "ShowRepliesFromHome", sender: indexPath.row)
                }
            }
        }
    }
    
    //MARK:- Search Delegates
    func updateSearchResults(for searchController: UISearchController) {
        if !isSearching {
            // if the user is not searching, show the info button
            // and enable the refresh controller
            navigationItem.leftBarButtonItem = infoBarButtonItem
            tableView.refreshControl = refreshController
        } else {
            // show the sort button and disable refresh controller
            navigationItem.leftBarButtonItem = sortBarButtonItem
            tableView.refreshControl = nil
        }
        // called every time the search text is changed
        filterContentForSearchText(searchController.searchBar.text!)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder() // cancel the keyboard
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    func filterContentForSearchText(_ searchTerm: String) {
        if isCourseNumber(searchTerm) {
            filteredCourses = resultsForSearch(self.courses, number: searchTerm)
        } else {
            filteredCourses = courses.filter { (course : Course) -> Bool in
                var hasInstructor = false
                    for instructor in course.instructors {
                        if instructor.name.lowercased().contains(searchTerm.lowercased()) {
                            // if any of the instructors match then the course has that instructor
                            hasInstructor = true
                            break
                        }
                    }
                // filters by number, instructor, description and name
                return hasInstructor || (course.desc?.lowercased().contains(searchTerm.lowercased()) ?? false) ||
                    (course.name?.lowercased().contains(searchTerm.lowercased()) ?? false)
            }
        }
        tableView.reloadData()
    }
    
    //MARK:- InfoPageViewControllerDelegate
    
    func highlightedCoursesWillChange() {
        self.isLoadingComments = true
        tableView.reloadData()
    }
    
    func highlightedCoursesDidChange(to newCourses: [String]) {
        self.highlightedCourses = newCourses
        getCommentsToDisplay(toReload: false)
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
        self.commentsToShow?.objects[indices.0] = object
        self.commentsToShow?.comments[index] = (object["comments"] as! CourseComments)[indices.1]
        tableView.reloadData()
    }
    
}

class CommentPreviewCell: UITableViewCell {
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var courseNumberLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
}

class SearchResultCell: UITableViewCell {
    
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var hoursLabel: UILabel!
    
}
