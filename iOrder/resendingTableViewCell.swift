//
//  resendingTableViewCell.swift
//  iOrder2
//
//  Created by 山尾 守 on 2016/11/29.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit

class resendingTableViewCell: UITableViewCell {

    @IBOutlet weak var resend_kbnLabel: UILabel!
    @IBOutlet weak var resend_timeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
