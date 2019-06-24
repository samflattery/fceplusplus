//
//  CourseInfoTableViewCell.swift
//  FCE++
//
//  Created by Sam Flattery on 6/24/19.
//  Copyright © 2019 Sam Flattery. All rights reserved.
//

import UIKit

class CourseInfoTableViewCell: UITableViewCell {
    
    @IBOutlet weak var courseRateLabel: UILabel!
    @IBOutlet weak var courseRateDetailsLabel: UILabel!
    
    @IBOutlet weak var coreqLabel: UILabel!
    @IBOutlet weak var coreqDetailsLabel: UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        
        courseRateLabel.leftAnchor.constraint(equalTo: self.contentView.centerXAnchor, constant: 0).isActive = true
        courseRateDetailsLabel.leftAnchor.constraint(equalTo: self.contentView.centerXAnchor, constant: 0).isActive = true
        coreqLabel.leftAnchor.constraint(equalTo: self.contentView.centerXAnchor, constant: 0).isActive = true
        coreqDetailsLabel.leftAnchor.constraint(equalTo: self.contentView.centerXAnchor, constant: 0).isActive = true
        
        
    }


}
