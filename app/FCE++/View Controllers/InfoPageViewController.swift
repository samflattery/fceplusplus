//
//  InfoPageViewController.swift
//  FCE++
//
//  Created by Sam Flattery on 6/20/19.
//  Copyright © 2019 Sam Flattery. All rights reserved.
//

import UIKit
import Parse
import RSSelectionMenu
import SVProgressHUD

protocol InfoPageViewControllerDelegate {
    func highlightedCoursesWillChange() // called before changes are saved
    func highlightedCoursesDidChange(to newCourses: [String]) // called after changes are saved
}

class InfoPageViewController: UIViewController {
    
    // needs to be changed to a login button when there is no user
    @IBOutlet weak var logoutButton: UIButton!
    // needs to be hidden when there is no user
    @IBOutlet weak var highlightedCoursesButton: UIButton!
    @IBOutlet weak var highlightedCoursesUnderline: UIView!
    
    
    var highlightedCourses: [String]! // the user's current highlighted courses
    var courses: [Course]! // all of the courses to populate selection menu with
    var newHighlightedCourses = [String]() // the user's new highlighted courses
    var delegate: InfoPageViewControllerDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        extendedLayoutIncludesOpaqueBars = true
        
        if PFUser.current() == nil {
            // if there is no user, hide the courses button and set logout to login
            highlightedCoursesButton.isHidden = true
            highlightedCoursesUnderline.isHidden = true
            logoutButton.setTitle("Login", for: .normal)
        } else {
            highlightedCoursesButton.isHidden = false
            highlightedCoursesUnderline.isHidden = false
            logoutButton.setTitle("Logout", for: .normal)
        }
        
    }
    
    @IBAction func logoutPressed(_ sender: Any) {
        if PFUser.current() != nil {
            
            SVProgressHUD.show()
            PFUser.logOutInBackground { (error: Error?) in
                if let error = error {
                    SVProgressHUD.dismiss()
                    SVProgressHUD.showError(withStatus: error.localizedDescription)
                    SVProgressHUD.dismiss(withDelay: 1)
                } else {
                    SVProgressHUD.dismiss()
                    self.performSegue(withIdentifier: "Logout", sender: nil)
                }
            }
            
        } else {
            performSegue(withIdentifier: "Login", sender: nil)
        }
    }

    @IBAction func showCourses(_ sender: Any) {
        let defaultSelectedCourses = getDefaults()

        // sort the data so that the already selected courses are first
        var sortedCourses = courses.sorted { (first, second) -> Bool in
            
            func containsCourse(course: Course) -> Bool {
                return defaultSelectedCourses.contains(where: { (elem : Course) -> Bool in
                    return elem == course
                })
            }
  
            switch (containsCourse(course: first), containsCourse(course: second)){
            case (true, true):
                return first.number < second.number
            case (false, true):
                return false
            case (true, false):
                return true
            case (false, false):
                return first.number < second.number
            }
        }
        
        // setup the selection menu
        let selectionMenu = RSSelectionMenu(selectionStyle: .multiple, dataSource: sortedCourses, cellType: .subTitle) { (cell, element: Course, indexPath) in
            
            cell.textLabel?.attributedText = NSAttributedString(string: element.number, attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 166/255, green: 25/255, blue: 46/255, alpha: 1), NSAttributedString.Key.font: UIFont(name: "IowanOldSt OSF BT", size: 22)!])
            cell.detailTextLabel?.attributedText = NSAttributedString(string: element.name ?? "No name available", attributes: [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: UIFont(name: "IowanOldStyleW01-Roman", size: 12)!])
            
        }
        
        selectionMenu.cellSelectionStyle = .checkbox // checkbox or tickmark
        
        selectionMenu.setSelectedItems(items: defaultSelectedCourses) { (course, index, isSelected, selectedItems) in
            return // set the current courses to be selected by default
        }
        
        selectionMenu.onDismiss = { selectedItems in
            // selected items is the array of courses that are selected in the menu
            for course in selectedItems {
                // selected courses is the array of course numbers to be stored in the cloud
                self.newHighlightedCourses.append(course.number)
            }
            // save the new courses and tell user that they have been saved
            
            if Set(self.highlightedCourses!) == Set(self.newHighlightedCourses) {
                // if no changes were made, do nothing
                // made into set so order irrelevant
                self.newHighlightedCourses = []
                return
            }
            
            self.highlightedCourses = self.newHighlightedCourses.sorted(by: { (first, second) -> Bool in
                first < second
            })
            self.newHighlightedCourses = []

            self.delegate.highlightedCoursesWillChange() // reloads the comments table
            
            let user = PFUser.current()! // there will always be a current user on this page
            user["highlightedCourses"] = self.highlightedCourses
            SVProgressHUD.show()
            user.saveInBackground(block: { (success: Bool, error: Error?) in
                SVProgressHUD.dismiss()
                if success {
                    SVProgressHUD.showSuccess(withStatus: "Updated!")
                    SVProgressHUD.dismiss(withDelay: 1)
                    self.delegate.highlightedCoursesDidChange(to: self.highlightedCourses)
                } else if let error = error {
                    SVProgressHUD.showError(withStatus: error.localizedDescription)
                } else {
                    SVProgressHUD.showError(withStatus: "Failed to update")
                }
            })
        }

        selectionMenu.showSearchBar { (searchTerm) -> ([Course]) in
            if let _ = Int(searchTerm) { // if it's a number
                if searchTerm.count > 2 && searchTerm.firstIndex(of: "-") == nil {
                    // if it's in the form xxxxx then convert to xx-xxx
                    let firstTwoIndex = searchTerm.index(searchTerm.startIndex, offsetBy: 2)
                    let hyphenatedSearchTerm = searchTerm[..<firstTwoIndex] + "-" + searchTerm[firstTwoIndex...]
                    return self.courses.filter { $0.number.contains(hyphenatedSearchTerm) }
                } else { // just filter by course number
                    return self.courses.filter { $0.number.contains(searchTerm) }
                }
            } else { // if it's not a number, filter by course name
                return self.courses.filter { $0.number.contains(searchTerm) ||
                    ($0.name?.lowercased().contains(searchTerm.lowercased()) ?? false)
                }
            }

        }
        selectionMenu.show(style: .actionSheet(title: nil, action: "Done", height: nil), from: self)
    }
    
    func getDefaults() -> [Course] {
        var defaults = [Course]()
        for course in courses {
            if self.highlightedCourses.contains(course.number) {
                defaults.append(course)
            }
        }
        return defaults
    }

}
 
