//
//  UIViewController+Extention.swift
//  iOrder2
//
//  Created by 山尾 守 on 2017/03/29.
//  Copyright © 2017年 山尾守. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    
    func exclusiveAllTouches() {
        self.applyAllViews { $0.isExclusiveTouch = true }
    }
    
    func applyAllViews(_ apply: (UIView) -> ()) {
        apply(self.view)
        self.applyAllSubviews(self.view, apply: apply)
    }
    
    fileprivate func applyAllSubviews(_ view: UIView, apply: (UIView) -> ()) {
        let subviews = view.subviews as [UIView]
        _ = subviews.map { (view: UIView) -> () in 
            apply(view)
            self.applyAllSubviews(view, apply: apply)
        }
    }
}
