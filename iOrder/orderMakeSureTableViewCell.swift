//
//  orderMakeSureTableViewCell.swift
//  iOrder
//
//  Created by 山尾守 on 2016/07/15.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit

class orderMakeSureTableViewCell: UITableViewCell {

    @IBOutlet weak var setButton: UIButton!
    @IBOutlet weak var orderNameLabel: UILabel!
    @IBOutlet weak var orderCountLabel: UILabel!
    @IBOutlet weak var orderAddButton: UIButton!
    @IBOutlet weak var handWrightButton: UIButton!
    @IBOutlet weak var subOrderImage: UIImageView!
    @IBOutlet weak var subOrderNameLabel: UILabel!
    @IBOutlet weak var orderName2Label: UILabel!
    @IBOutlet weak var orderNameKanaLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
}
