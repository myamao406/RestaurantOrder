//
//  subMenuTableViewCell.swift
//  iOrder
//
//  Created by 山尾守 on 2016/07/12.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit

class subMenuTableViewCell: UITableViewCell {

    @IBOutlet weak var subMenuImage: UIImageView!
    @IBOutlet weak var subMenuName: UILabel!
    @IBOutlet weak var subMenuPrice: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
