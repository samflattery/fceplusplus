//
//  SelectCoursesViewController.swift
//  FCE++
//
//  Created by Sam Flattery on 8/11/19.
//  Copyright © 2019 Sam Flattery. All rights reserved.
//

import UIKit
import Parse
import RSSelectionMenu
import SVProgressHUD

class SelectCoursesViewController: UIViewController {
    
    var courses: [Course]!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "CancelledSignUp", sender: nil)
    }
    
    @IBAction func selectCoursesButtonPressed(_ sender: Any) {
        let selectionMenu = RSSelectionMenu(selectionStyle: .multiple, dataSource: courses, cellType: .subTitle) { (cell, element: Course, indexPath) in
            
            // populate it with the course information
            cell.textLabel?.attributedText = NSAttributedString(string: element.number, attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 166/255, green: 25/255, blue: 46/255, alpha: 1), NSAttributedString.Key.font: UIFont(name: "IowanOldSt OSF BT", size: 22)!])
            cell.detailTextLabel?.attributedText = NSAttributedString(string: element.name ?? "No name available", attributes: [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: UIFont(name: "IowanOldStyleW01-Roman", size: 12)!])
        }
        
        selectionMenu.cellSelectionStyle = .checkbox // checkbox or tickmark
        
        selectionMenu.onDismiss = { [weak self] selectedItems in
            // selected items is the array of courses that are selected in the menu
            var selectedCourses = [String]()
            for course in selectedItems {
                // selected courses is the array of course numbers to be stored in the cloud
                selectedCourses.append(course.number)
            }
            self?.setUserCourses(selectedCourses)
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
    
    func setUserCourses(_ courses: [String]) {
        let user = PFUser.current()! // there will always be a current user on this page
        user["highlightedCourses"] = courses
        user["firstLogin"] = false
        SVProgressHUD.show()
        user.saveInBackground(block: { (success: Bool, error: Error?) in
            SVProgressHUD.dismiss()
            if success {
                SVProgressHUD.showSuccess(withStatus: "Saved!")
                self.performSegue(withIdentifier: "SelectedCourses", sender: nil)
            } else if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            } else {
                SVProgressHUD.showError(withStatus: "Failed to update")
            }
            SVProgressHUD.dismiss(withDelay: 1)
        })
    }
    
    

}
