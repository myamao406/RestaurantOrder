//
//  menuTableViewCell.swift
//  iOrder
//
//  Created by 山尾守 on 2016/07/08.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit

class menuTableViewCell: UITableViewCell {

    @IBOutlet weak var category: UIView!
    @IBOutlet weak var menuName: UILabel!
    @IBOutlet weak var categoryLine: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
//        print("333",select_cell_color)
        self.categoryLine.backgroundColor = select_cell_color
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)        
//        print("111",select_cell_color)
        self.categoryLine.backgroundColor = select_cell_color
        
    }
    
}
