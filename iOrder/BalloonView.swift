//
//  BalloonView.swift
//  iOrder2
//
//  Created by 山尾 守 on 2016/12/19.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import Foundation
import UIKit

class BalloonView: UIView {
    
    enum EnumArrowDirections {
        case top
        case buttom
        case left
        case right
    }
    
    let triangleSideLength: CGFloat = 18.0
    let triangleHeight: CGFloat = 13.0
    let roundSize: CGFloat = 10.0
    
//    init() {
//        permittedArrowDirections.arrow = EnumArrowDirections.Left
//    }
    
    struct permittedArrowDirections{
        static var arrow = EnumArrowDirections.left
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(UIColor.darkGray.cgColor)
        contextBalloonPath(context!, rect: rect)
    }
    
    func contextBalloonPath(_ context: CGContext, rect: CGRect ) {
        let zero:CGFloat = 0.0

        let size_par : CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 0.5 : 0.7
        
        switch permittedArrowDirections.arrow {
        case .left:
            let triangleRightCorner = (x: triangleHeight, y: (rect.size.height + triangleSideLength) * size_par)
            let triangleBottomCorner = (x: zero, y: rect.size.height * size_par)
            let triangleLeftCorner = (x:  triangleHeight, y: (rect.size.height - triangleSideLength) * size_par)
            // 塗りつぶし
            let rect = CGRect(x: triangleHeight, y: 0, width: rect.size.width - triangleHeight , height: rect.size.height)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: roundSize)
            UIColor.darkGray.setFill()
            path.fill()
            
            context.move(to: CGPoint(x: triangleLeftCorner.x, y: triangleLeftCorner.y))
            context.addLine(to: CGPoint(x: triangleBottomCorner.x, y: triangleBottomCorner.y))
            context.addLine(to: CGPoint(x: triangleRightCorner.x, y: triangleRightCorner.y))
            context.fillPath()
            break;
        case .right:
            let triangleRightCorner = (x: rect.size.width - triangleHeight, y: (rect.size.height + triangleSideLength) * 0.5)
            let triangleBottomCorner = (x:rect.size.width , y: rect.size.height * 0.5)
            let triangleLeftCorner = (x:  rect.size.width - triangleHeight, y: (rect.size.height - triangleSideLength) * 0.5)
            // 塗りつぶし
            let rect = CGRect(x: 0, y: 0, width: rect.size.width - triangleHeight , height: rect.size.height)

            let path = UIBezierPath(roundedRect: rect, cornerRadius: roundSize)
            UIColor.darkGray.setFill()
            path.fill()
            
            context.move(to: CGPoint(x: triangleLeftCorner.x, y: triangleLeftCorner.y))
            context.addLine(to: CGPoint(x: triangleBottomCorner.x, y: triangleBottomCorner.y))
            context.addLine(to: CGPoint(x: triangleRightCorner.x, y: triangleRightCorner.y))
            context.fillPath()
            
            
            break;
            
        default:
            let triangleRightCorner = (x: triangleHeight, y: (rect.size.height + triangleSideLength) * 0.7)
            let triangleBottomCorner = (x: zero, y: rect.size.height * 0.7)
            let triangleLeftCorner = (x:  triangleHeight, y: (rect.size.height - triangleSideLength) * 0.7)
            // 塗りつぶし
            let rect = CGRect(x: triangleHeight, y: 0, width: rect.size.width - triangleHeight , height: rect.size.height)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: roundSize)
            UIColor.darkGray.setFill()
            path.fill()
            
            context.move(to: CGPoint(x: triangleLeftCorner.x, y: triangleLeftCorner.y))
            context.addLine(to: CGPoint(x: triangleBottomCorner.x, y: triangleBottomCorner.y))
            context.addLine(to: CGPoint(x: triangleRightCorner.x, y: triangleRightCorner.y))
            context.fillPath()

            break;
        }
        

        
    }
    
}
