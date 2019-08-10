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
            logoutButton.setTitle("Login", for: .normal)
        } else {
            highlightedCoursesButton.isHidden = false
            logoutButton.setTitle("Logout", for: .normal)
        }
        
        setupButtons()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Logout" {
          
        }
    }
    
    func setupButtons() {
        // put a line under the two buttons
        let logoutBottomLine = CALayer()
        logoutBottomLine.frame = CGRect.init(x: 0, y: logoutButton.frame.size.height - 1, width: logoutButton.frame.size.width - 5, height: 2)
        logoutBottomLine.backgroundColor = UIColor.white.cgColor
        
        let changeButtonBottomLine = CALayer()
        changeButtonBottomLine.frame = CGRect.init(x: 0, y: highlightedCoursesButton.frame.size.height - 1, width: highlightedCoursesButton.frame.size.width - 5, height: 2)
        changeButtonBottomLine.backgroundColor = UIColor.white.cgColor
        
        logoutButton.layer.addSublayer(logoutBottomLine)
        highlightedCoursesButton.layer.addSublayer(changeButtonBottomLine)

        
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
        // setup the selection menu
        let selectionMenu = RSSelectionMenu(selectionStyle: .multiple, dataSource: courses, cellType: .subTitle) { (cell, element: Course, indexPath) in

            // populate it with the course information
            cell.textLabel?.text = element.number
            cell.detailTextLabel?.text = element.name
        }
        
        let defaultSelectedCourses = getDefaults()

        selectionMenu.cellSelectionStyle = .checkbox // checkbox or tickmark
        
        selectionMenu.setSelectedItems(items: defaultSelectedCourses) { (course, index, isSelected, selectedItems) in
            return // set the current courses to be selected by default
        }
        
        selectionMenu.onDismiss = {selectedItems in
            // selected items is the array of courses that are selected in the menu
            for course in selectedItems {
                // selected courses is the array of course numbers to be stored in the cloud
                self.newHighlightedCourses.append(course.number)
            }
            // save the new courses and tell user that they have been saved
            
            if self.highlightedCourses == self.newHighlightedCourses {
                // if no changes were made, do nothing
                return
            }
            
            self.delegate.highlightedCoursesWillChange() // reloads the comments table
            
            let user = PFUser.current()! // there will always be a current user on this page
            user["highlightedCourses"] = self.newHighlightedCourses
            SVProgressHUD.show()
            user.saveInBackground(block: { (success: Bool, error: Error?) in
                SVProgressHUD.dismiss()
                if success {
                    SVProgressHUD.showSuccess(withStatus: "Updated!")
                    SVProgressHUD.dismiss(withDelay: 1)
                    self.delegate.highlightedCoursesDidChange(to: self.newHighlightedCourses)
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
                return self.courses.filter { $0.name?.lowercased().contains(searchTerm.lowercased()) ?? false }
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
 
