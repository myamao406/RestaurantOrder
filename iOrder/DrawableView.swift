//
//  DrawableView.swift
//  iOrder
//
//  Created by 山尾守 on 2016/07/13.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


protocol DrawableViewDelegate {
    func onUpdateDrawableView()
    func onFinishSave()
}


protocol DrawableViewPart{
    func drawOnContext(_ context:CGContext)
}


class DrawableView: UIView {

    class Line: DrawableViewPart {
        var points  : [CGPoint]
        var color   : CGColor
        var width   : CGFloat
        
        init(color: CGColor,width:CGFloat){
            self.color = color
            self.width = width
            self.points = []
        }
        
        func drawOnContext(_ context:CGContext){
            UIGraphicsPushContext(context)
            
            context.setStrokeColor(self.color)
            context.setLineWidth(self.width)
            context.setLineCap(CGLineCap.round)
            
            // 2点以上ないと線描画する必要なし
            if self.points.count > 1 {
//                CGContextMoveToPoint(context, points.first!.x, points.first!.y)
                for (index,point) in self.points.enumerated(){
                    if index == 0 {
                        context.move(to: CGPoint(x: point.x, y: point.y))
                    } else {
                        context.addLine(to: CGPoint(x: point.x, y: point.y))
                    }

                }
            } else {
                Dot(line:self).drawOnContext(context)
            }
            context.strokePath()
            
            UIGraphicsPopContext()
        }
        
        // 更新分だけ描画したい時用
        func drawLastlineOnContext(_ context: CGContext){
            if self.points.count > 1 {
                UIGraphicsPushContext(context)
                context.setStrokeColor(self.color)
                context.setLineWidth(self.width)
                context.setLineCap(CGLineCap.round)
            
                let startPoint = self.points[self.points.endIndex-2]
                let endPoint = self.points.last!
                context.move(to: CGPoint(x: startPoint.x, y: startPoint.y))
                context.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
                
                context.strokePath()
                UIGraphicsPopContext()
            } else {
                Dot(line:self).drawOnContext(context)
            }
        }
    }
    
    class Dot: DrawableViewPart {
        var pos     : CGPoint
        var radius  : CGFloat
        var color   : CGColor
        
        init(pos: CGPoint, radius: CGFloat, color: CGColor) {
            self.radius = radius
            self.pos = pos
            self.color = color
        }
        
        init(line: Line) {
            self.pos = line.points.first!
            self.radius = line.width
            self.color = line.color
        }
        
        func drawOnContext(_ context: CGContext) {
            UIGraphicsPushContext(context)
            context.setFillColor(self.color)
            context.addEllipse(in: CGRect(x: pos.x-(radius/2), y: pos.y-(radius/2), width: radius, height: radius))
            context.fillPath()
            UIGraphicsPopContext()
        }
    }
    
    class Image: DrawableViewPart {
        var image: UIImage
        init(image:UIImage){
            self.image = image
        }
        func drawOnContext(_ context: CGContext) {
            UIGraphicsPushContext(context)
            image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))
            UIGraphicsPopContext()
        }
    }
    
    struct DrawableViewSetting {
        var lineColor: CGColor = UIColor.red.cgColor
        var lineWidth: CGFloat = 5
    }
    
    // DrawableViewParts
    var parts: [DrawableViewPart] = []
    // 描画中のLine
    var currentLine: Line? = nil
    // これまでに描画したimage
    fileprivate var currentImage: UIImage? = nil
    // delegate
    var delegate:DrawableViewDelegate? = nil
    
    fileprivate var currentSetting = DrawableViewSetting()
    
    func setLineColor(_ color: CGColor){
        currentSetting.lineColor = color
    }
    
    func setLineWidth(_ width: CGFloat){
        currentSetting.lineWidth = width
    }
    
    // 初期化
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        
        self.parts = [Image(image: UIImage())]
        currentSetting.lineColor = UIColor.red.cgColor
        currentSetting.lineWidth = 5
    }
    
    override init(frame: CGRect){
        super.init(frame: frame)
    }
    
    func undo(){
        if !self.parts.isEmpty {
            self.parts.removeLast()
            requireRedraw()
        }
    }
    
    // タッチされた
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let point = touches.first!.location(in: self)
        currentLine = Line(color: self.currentSetting.lineColor , width: self.currentSetting.lineWidth)
        currentLine?.points.append(point)
        self.setNeedsDisplay()
    }
    
    // タッチが動いた
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let point = touches.first!.location(in: self)
        currentLine?.points.append(point)
        self.setNeedsDisplay()
    }
    
    // タッチが終わった
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if currentLine?.points.count > 1 {
            parts.append(currentLine!)
        } else {
            self.parts.append(Dot(line: currentLine!))
        }
        // 更新フラグON
        isUpdate = true
        currentLine = nil
    }
    
    fileprivate func requireRedraw(){
        self.currentImage = nil
        self.setNeedsDisplay()
    }
    
    // UIImageとして取得
    func getCurrentImage() -> UIImage {
        // nilだったら再度描画させる
        if self.currentImage == nil {
            UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0)
            let context = UIGraphicsGetCurrentContext()
            for part in parts {
                part.drawOnContext(context!)
            }
            if let line = currentLine {
                line.drawOnContext(context!)
            }
            
            self.currentImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        return self.currentImage!
    }
    
    func updateCurrentImage() {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0)
        let imageContext = UIGraphicsGetCurrentContext()
        // 今までのimageを取得して描画
        self.getCurrentImage().draw(in: self.bounds)
        // 追加分を描画
        if let line = currentLine {
            line.drawLastlineOnContext(imageContext!)
        }
        // 更新
        self.currentImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    func clear() {
        if currentLine?.points.count > 1 {
            parts.append(currentLine!)
            currentLine = nil
        }
        self.parts = []
        self.requireRedraw()
    }
    
    fileprivate func getResizedImage(_ image: UIImage, size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        image.draw(in: CGRect(origin: CGPoint.zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage!
    }
    
    func setBackgroundImage(_ image: UIImage) {
        let resizeImage = getResizedImage(image, size: CGSize(width: self.bounds.width, height: self.bounds.height))
        
        let backgroundImage = Image(image: resizeImage)
        
        if let part = self.parts.first, part is Image {
            self.parts[0] = backgroundImage
        } else {
            self.parts.insert(backgroundImage, at: 0)
        }
        
        self.requireRedraw()
    }
    
    func save() {
        // 念のため再描画
        updateCurrentImage()
//        UIImageWriteToSavedPhotosAlbum(self.currentImage!, self, Selector("image:didFinishSavingWithError:contextInfo"), nil)
        UIImageWriteToSavedPhotosAlbum(self.currentImage!, self, #selector(DrawableView.image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    func image(_ image: UIImage, didFinishSavingWithError error: NSError!, contextInfo: UnsafeMutableRawPointer) {
        if error != nil {
            // プライバシー設定不許可など書き込み失敗時は　-3310 （ALAssetsLibraryDataUnavailableError）
            print("Drawableview:Error -> " +  String(error.code))
        } else {
            delegate?.onFinishSave()
        }
    }
    
    // 描画設定
    override func draw(_ rect: CGRect) {
        delegate?.onUpdateDrawableView()
        
        _ = UIGraphicsGetImageFromCurrentImageContext()
        
        updateCurrentImage()
        self.currentImage?.draw(in: self.bounds)
    }
}
