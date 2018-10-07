//
//  selectMenuTableViewCell.swift
//  iOrder2
//
//  Created by 山尾 守 on 2017/01/17.
//  Copyright © 2017年 山尾守. All rights reserved.
//

import UIKit

class selectMenuTableViewCell: UITableViewCell {

    @IBOutlet weak var selectMenuLabel: UILabel!
    @IBOutlet weak var tankaButton: UIButton!
    @IBOutlet weak var selectMenuDitailText: UITextField!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
