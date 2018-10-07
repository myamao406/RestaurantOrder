//
//  DemoLabel.swift
//  iOrder2
//
//  Created by 山尾 守 on 2016/10/28.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import Foundation
import UIKit

open class DemoLabel {
    
    struct Instance{
        static var demoLabel = UILabel()
    }
    
    class func Show(_ view:UIView){
        
        Instance.demoLabel.transform = CGAffineTransform.identity
        Instance.demoLabel.frame = CGRect(x: -47*size_scale, y: 20*size_scale, width: 201*size_scale, height: 33*size_scale)
        Instance.demoLabel.alpha = 0.7
        Instance.demoLabel.font = UIFont(name: "YuGo-Bold",size: CGFloat(20*size_scale))
        Instance.demoLabel.textAlignment = .center
            
        // デモラベルを斜めにする
        Instance.demoLabel.transform = Instance.demoLabel.transform.rotated(by: CGFloat(-2 * M_1_PI))
        
        
        view.addSubview(Instance.demoLabel)
            
        // 一番手前にする
        view.bringSubview(toFront: Instance.demoLabel)
        
    }
        
    
    class func modeChange(){
        switch demo_mode {
        case 1:
            Instance.demoLabel.isHidden = false
            Instance.demoLabel.backgroundColor =  UIColor.yellow
            Instance.demoLabel.textColor = iOrder_blackColor
            Instance.demoLabel.text = demo_label.0
            
        case 2:
            Instance.demoLabel.isHidden = false
            Instance.demoLabel.backgroundColor = UIColor.red
            Instance.demoLabel.textColor = UIColor.white
            Instance.demoLabel.text = demo_label.1
            
        default:
            Instance.demoLabel.isHidden = true
        }
    }
    
}
