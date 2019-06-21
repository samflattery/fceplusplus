//
//  GuestCommentTableViewCell.swift
//  FCE++
//
//  Created by Sam Flattery on 6/21/19.
//  Copyright © 2019 Sam Flattery. All rights reserved.
//

import UIKit

protocol GuestCommentCellDelegate {
    func loginPressed()
}

class GuestCommentCell: UITableViewCell {
    
    var delegate: GuestCommentCellDelegate!
    
    @IBAction func loginPressed(_ sender: Any) {
        delegate.loginPressed()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
