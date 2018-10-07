//
//  playerTableViewCell.swift
//  iOrder
//
//  Created by 山尾守 on 2016/06/30.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit

class playerTableViewCell: UITableViewCell {

    @IBOutlet weak var playerCellSeat: UILabel!
    @IBOutlet weak var playerCellSeatImage: UIImageView!
    @IBOutlet weak var playerCellHolder: UILabel!
    @IBOutlet weak var playerCellPrice: UILabel!
//    @IBOutlet weak var playerCellName: UITextField!
    
    @IBOutlet weak var placeholderLabel: UILabel!
    @IBOutlet weak var playerCellName: UILabel!
    @IBOutlet weak var playerCellKana: UILabel!
    @IBOutlet weak var playerCellMessage: UILabel!
    @IBOutlet weak var playerCelltanka: UIButton!
    @IBOutlet weak var playerCellPopUp: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
                
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
//        self.playerCellSeat.backgroundColor = iOrder_blackColor
        self.playerCelltanka.backgroundColor = UIColor(red: 0.6, green: 0.4, blue: 0.6, alpha: 1.0)
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
//        self.playerCellSeat.backgroundColor = iOrder_blackColor
        self.playerCelltanka.backgroundColor = UIColor(red: 0.6, green: 0.4, blue: 0.6, alpha: 1.0)
    }
    
}
