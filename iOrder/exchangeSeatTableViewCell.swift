//
//  exchangeSeatTableViewCell.swift
//  iOrder2
//
//  Created by 山尾 守 on 2017/01/13.
//  Copyright © 2017年 山尾守. All rights reserved.
//

import UIKit

class exchangeSeatTableViewCell: UITableViewCell {

    @IBOutlet weak var exchangeCellSeat: UILabel!
    @IBOutlet weak var exchangeCellHolder: UILabel!
    @IBOutlet weak var exchangeCellName: UILabel!
    @IBOutlet weak var exchangeCellKana: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
