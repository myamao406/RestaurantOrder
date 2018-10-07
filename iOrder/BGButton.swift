//
//  BGButton.swift
//  iOrder2
//
//  Created by 山尾 守 on 2016/10/18.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class BGButton: UIButton {
    
    var gradientLayer: CAGradientLayer?
    
    @IBInspectable var topColor: UIColor = UIColor.white {
        didSet {
            setGradient()
        }
    }
    
    @IBInspectable var bottomColor: UIColor = UIColor.black {
        didSet {
            setGradient()
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            setGradient()
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
            setGradient()
        }
    }
    
    @IBInspectable var borderColor: UIColor = UIColor.clear {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
    
    fileprivate func setGradient() {
        
        gradientLayer?.removeFromSuperlayer()
        
        gradientLayer = CAGradientLayer()
        gradientLayer!.colors = [topColor.cgColor, bottomColor.cgColor]
        gradientLayer!.frame.size = frame.size
        gradientLayer!.frame.origin = CGPoint(x: 0.0,y: 0.0)
        gradientLayer!.cornerRadius = cornerRadius
        gradientLayer!.zPosition = -100
        layer.insertSublayer(gradientLayer!, at: 0)
        layer.masksToBounds = true
        
        imageView?.layer.zPosition = 0
    }
    
}
