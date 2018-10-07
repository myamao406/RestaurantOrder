//
//  configTableViewCell.swift
//  iOrder
//
//  Created by 山尾守 on 2016/07/25.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit

class configTableViewCell: UITableViewCell {

    @IBOutlet weak var configImage: UIImageView!
    @IBOutlet weak var configLabel1: UILabel!
    @IBOutlet weak var configLabel2: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
