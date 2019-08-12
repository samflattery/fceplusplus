//
//  InstructorInfoViewController.swift
//  FCE++
//
//  Created by Sam Flattery on 8/10/19.
//  Copyright © 2019 Sam Flattery. All rights reserved.
//

import UIKit

class InstructorInfoTableViewController: UITableViewController {
    
    var instructor : Instructor!
    var instructorInfo : [String]!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        extendedLayoutIncludesOpaqueBars = true

        instructorInfo = getInstructorData(instructor)
    }
    
    
    
    


}
