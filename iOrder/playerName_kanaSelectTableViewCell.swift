//
//  playerName+kanaSelectTableViewCellTableViewCell.swift
//  iOrder2
//
//  Created by 山尾 守 on 2016/12/06.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit

class playerName_kanaSelectTableViewCell: UITableViewCell {

    @IBOutlet weak var holderNoLabel: UILabel!
    @IBOutlet weak var playerNameLabel: UILabel!
    @IBOutlet weak var playerNameKanaLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
