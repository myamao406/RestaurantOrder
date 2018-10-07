//
//  UIImageView+ForScrollView.swift
//  iOrder2
//
//  Created by 山尾 守 on 2016/12/08.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import Foundation
import UIKit

let noDisableVerticalScrollTag = 836913
let noDisableHorizontalScrollTag = 836914

extension UIImageView {

    fileprivate func setAlpha(_ alpha: CGFloat) {

        if self.superview!.tag == noDisableVerticalScrollTag {
            if alpha == 0 && self.autoresizingMask ==  UIViewAutoresizing.flexibleLeftMargin {
                if self.frame.size.width < 10 && self.frame.size.height > self.frame.size.width {
                    let sc = self.superview as! UIScrollView
                    if sc.frame.size.height < sc.contentSize.height {
                        return
                    }
                }
            }
        }
        if self.superview!.tag == noDisableHorizontalScrollTag {
            if alpha == 0 && self.autoresizingMask == UIViewAutoresizing.flexibleTopMargin {
                if self.frame.size.height < 10 && self.frame.size.height < self.frame.size.width {
                    let sc = self.superview as! UIScrollView
                    if sc.frame.size.width < sc.contentSize.width {
                        return
                    }
                }
            }
        }
//        super.setAlpha(alpha)
    }
}
