//
//  cancelOrderSelectTableViewCell.swift
//  iOrder2
//
//  Created by 山尾 守 on 2016/09/27.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit

class cancelOrderSelectTableViewCell: UITableViewCell {

    @IBOutlet weak var setButton: ExpansionButton!
    @IBOutlet weak var orderNameLabel: UILabel!
    @IBOutlet weak var orderCountLabel: UILabel!
    @IBOutlet weak var orderMin: UILabel!
    @IBOutlet weak var orderSeat: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
