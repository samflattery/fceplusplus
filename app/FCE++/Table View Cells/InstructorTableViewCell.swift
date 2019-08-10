//
//  InstructorTableViewCell.swift
//  FCE++
//
//  Created by Sam Flattery on 8/9/19.
//  Copyright © 2019 Sam Flattery. All rights reserved.
//

import UIKit
import Cosmos

class InstructorTableViewCell: UITableViewCell {
    
    @IBOutlet weak var instructorLabel: UILabel!
    @IBOutlet weak var hoursLabel: UILabel!
    @IBOutlet weak var ratingStars: CosmosView!
    @IBOutlet weak var ratingLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }


}
