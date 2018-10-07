//
//  configSegmentedControlTableViewCell.swift
//  iOrder
//
//  Created by 山尾守 on 2016/07/25.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit

class configSegmentedControlTableViewCell: UITableViewCell {

    @IBOutlet weak var configSegmentedImage: UIImageView!
    @IBOutlet weak var configSegmentedLabel: UILabel!
    @IBOutlet weak var configSegmentedSegmented: UISegmentedControl!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
