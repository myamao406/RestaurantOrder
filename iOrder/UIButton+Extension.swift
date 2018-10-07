//
//  UIButton+Extension.swift
//  iOrder2
//
//  Created by 山尾 守 on 2016/12/21.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable

class ExpansionButton: UIButton {
    
//    @IBInspectable var insets:UIEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
    
    internal var insets: UIEdgeInsets = UIEdgeInsets.zero
    
    @IBInspectable internal var insetsTop: CGFloat {
        get { return insets.top }
        set { insets = UIEdgeInsets(top: newValue,
                                           left: insets.left,
                                           bottom: insets.bottom,
                                           right: insets.right) }
    }
    
    @IBInspectable internal var insetsLeft: CGFloat {
        get { return insets.left }
        set { insets = UIEdgeInsets(top: insets.top,
                                           left: newValue,
                                           bottom: insets.bottom,
                                           right: insets.right) }
    }
    
    @IBInspectable internal var insetsBottom: CGFloat {
        get { return insets.bottom }
        set { insets = UIEdgeInsets(top: insets.top,
                                           left: insets.left,
                                           bottom: newValue,
                                           right: insets.right) }
    }
    
    @IBInspectable internal var insetsRight: CGFloat {
        get { return insets.right }
        set { insets = UIEdgeInsets(top: insets.top,
                                           left: insets.left,
                                           bottom: insets.bottom,
                                           right: newValue) }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        var rect = bounds
        rect.origin.x -= insets.left
        rect.origin.y -= insets.top
        rect.size.width += insets.left + insets.right
        rect.size.height += insets.top + insets.bottom
        
        // 拡大したViewサイズがタップ領域に含まれているかどうかを返します
        return rect.contains(point)
    }
}
