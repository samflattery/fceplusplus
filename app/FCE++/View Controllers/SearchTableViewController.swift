//
//  ViewController.swift
//  FCE++
//
//  Created by Sam Flattery on 6/6/19.
//  Copyright © 2019 Sam Flattery. All rights reserved.
//

import UIKit

class SearchTableViewController: UITableViewController, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate {
    
    var courses: [Course]!
    var filteredCourses = [Course]()
    let searchController = UISearchController(searchResultsController: nil)
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var isSearching: Bool {
        return searchController.isActive && !(searchController.searchBar.text?.isEmpty ?? true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        courses = appDelegate.courses
        tableView.reloadData()
        configureSearchController()
        let cellNib = UINib(nibName: "StartScreen", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "StartScreen")
        definesPresentationContext = true
    }
    
    func configureSearchController() {
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.titleView = searchController.searchBar
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "Course name, instructor or keyword!"
        searchController.searchBar.sizeToFit()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "CourseInfo" {
            let controller = segue.destination as! CourseInfoTableViewController
            controller.course = sender as? Course
        }
    }

    //MARK:- Table View Delegates
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !isSearching {
            return 1
        } else {
            return filteredCourses.count
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if !isSearching {
            return tableView.bounds.height - 50
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if !isSearching {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StartScreen", for: indexPath)
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "Course Cell", for: indexPath)
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
        if isSearching{
            let course = filteredCourses[indexPath.row]
            performSegue(withIdentifier: "CourseInfo", sender: course)
        }
    }
    
    //MARK:- Search Delegates
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    func filterContentForSearchText(_ searchTerm: String){
        filteredCourses = courses.filter { ( course : Course) -> Bool in
            //convert XXXXX to XX-XXX
            if let _ = Int(searchTerm) {
                if searchTerm.count > 2 {
                    if searchTerm.firstIndex(of: "-") == nil {
                        let firstTwoIndex = searchTerm.index(searchTerm.startIndex, offsetBy: 2)
                        return course.number.contains(searchTerm[..<firstTwoIndex] + "-" + searchTerm[firstTwoIndex...])
                    }
                }
            }
            var hasInstructor = false
                for instructor in course.instructors {
                    if instructor.name.lowercased().contains(searchTerm.lowercased()) {
                        hasInstructor = true
                        break
                    }
                }
            return course.number.contains(searchTerm) || hasInstructor || (course.desc?.lowercased().contains(searchTerm.lowercased()) ?? false) ||
                (course.name?.lowercased().contains(searchTerm.lowercased()) ?? false)
        }
        tableView.reloadData()
    }

  
}
