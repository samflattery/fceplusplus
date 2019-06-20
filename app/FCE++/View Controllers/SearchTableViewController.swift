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

class SearchTableViewController: UITableViewController, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate {
    
    var courses: [Course]! // the array of courses taken from output.json
    var filteredCourses = [Course]() // the filtered courses to be shown to the user
    var favouriteCourses: [String]?
    var commentsToShow: CourseComments? // holds the first three comments of favourited courses
    
    let searchController = UISearchController(searchResultsController: nil)
    
    var isSearching: Bool { // is the user currently typing a search
        return searchController.isActive && !(searchController.searchBar.text?.isEmpty ?? true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        courses = appDelegate.courses // the AppDelegate loads the courses upon launching
        tableView.reloadData()
        configureSearchController()
        
        if let user = PFUser.current() {
            //if someone is signed in, get their favourite courses
            favouriteCourses = (user["courses"] as! [String])
        }
        
        getComments()
        
        let cellNib = UINib(nibName: "StartScreen", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "StartScreen")
        definesPresentationContext = true
    }
    
    func configureSearchController() {
        // setting up the searchcontroller delegate
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.titleView = searchController.searchBar // put it in the navigation bar
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "Course name, instructor or keyword!"
        searchController.searchBar.sizeToFit()
    }
    
    func getComments() {
        let query = PFQuery(className:"Comments")
        query.whereKey("courseNumber", containedIn: favouriteCourses!)
        
//            reachability = Reachability()!
//            if reachability.connection == .none && !query!.hasCachedResult {
//                tableView.reloadData()
//                failedToLoad = true
//                SVProgressHUD.showError(withStatus: "No internet connection")
//                SVProgressHUD.dismiss(withDelay: 1)
//                courseComments = nil
//                commentObj = nil
//                return
//            }
        SVProgressHUD.show()
        
        query.cachePolicy = .networkElseCache // first try network to get up to date, then cache
        query.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            if let error = error {
                // failed to get comments for some reason
                SVProgressHUD.dismiss()
                SVProgressHUD.showError(withStatus: error.localizedDescription)
                SVProgressHUD.dismiss(withDelay: 1)
                print(error)
            } else if let objects = objects {
                // found objects
                SVProgressHUD.dismiss()
                self.commentsToShow = []
                for object in objects { // each object is a course and its comments
                    let courseComments = object["comments"] as! CourseComments
                    let firstThreeComments = Array(courseComments.prefix(3)) // :CourseComments
                    self.commentsToShow! += firstThreeComments
                }
                self.tableView.reloadData()
            } else {
                SVProgressHUD.dismiss()
                SVProgressHUD.showError(withStatus: "Failed to load comments")
                SVProgressHUD.dismiss(withDelay: 1)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "CourseInfo" {
            // send the course that is pressed on to the CourseInfo view
            let controller = segue.destination as! CourseInfoTableViewController
            controller.course = sender as? Course
        }
    }

    //MARK:- Table View Delegates
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !isSearching {
            if let comments = commentsToShow { // if there are comments, show them
                return comments.count
            } else {
                return 1 // a cell that redirects to login
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
            return "Comments for you"
        }
        return "Search results"
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if !isSearching {
            if commentsToShow != nil {
                return UITableView.automaticDimension
            }
            return tableView.bounds.height - 50 // custom height for the homepage to fill screen
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if !isSearching {
            
            if commentsToShow != nil { // show the comment preview cells
                let i = indexPath.row
                let cell = tableView.dequeueReusableCell(withIdentifier: "CommentPreview", for: indexPath) as! CommentPreviewCell
                cell.headerLabel.text = commentsToShow?[i]["header"] as? String
                cell.courseNumberLabel.text = commentsToShow?[i]["courseNumber"] as? String
                cell.commentLabel.text = commentsToShow?[i]["commentText"] as? String
                return cell
            }
            
            // show a default cell to prompt the user to login
            // THIS NEEDS TO BE CHANGED *******
            let cell = tableView.dequeueReusableCell(withIdentifier: "StartScreen", for: indexPath)
            return cell
            
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "CourseCell", for: indexPath)
        let cellInfo = filteredCourses[indexPath.row]
        cell.textLabel!.text = cellInfo.number
        if let name = cellInfo.name {
            cell.detailTextLabel!.text = name
        } else {
            cell.detailTextLabel!.text = "No name available"
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isSearching {
            let course = filteredCourses[indexPath.row]
            performSegue(withIdentifier: "CourseInfo", sender: course)
        } else {
            // perform the segue to the comment replies
        }
    }
    
    //MARK:- Search Delegates
    func updateSearchResults(for searchController: UISearchController) {
        // called every time the search text is changed
        filterContentForSearchText(searchController.searchBar.text!)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder() // cancel the keyboard
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    func filterContentForSearchText(_ searchTerm: String){
        filteredCourses = courses.filter { ( course : Course) -> Bool in
            if let _ = Int(searchTerm) { // if it's a number
                if searchTerm.count > 2 && searchTerm.firstIndex(of: "-") == nil {
                    // if it's in the form xxxxx then convert to xx-xxx
                    let firstTwoIndex = searchTerm.index(searchTerm.startIndex, offsetBy: 2)
                    return course.number.contains(searchTerm[..<firstTwoIndex] + "-" + searchTerm[firstTwoIndex...])
                }
            }
            var hasInstructor = false
                for instructor in course.instructors {
                    if instructor.name.lowercased().contains(searchTerm.lowercased()) {
                        // if any of the instructors match then the course has that instructor
                        hasInstructor = true
                        break
                    }
                }
            // filters by number, instructor, description and name
            return course.number.contains(searchTerm) || hasInstructor || (course.desc?.lowercased().contains(searchTerm.lowercased()) ?? false) ||
                (course.name?.lowercased().contains(searchTerm.lowercased()) ?? false)
        }
        tableView.reloadData()
    }
}

class CommentPreviewCell: UITableViewCell {
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var courseNumberLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    
}
