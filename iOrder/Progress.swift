//
//  Progress.swift
//  iOrder
//
//  Created by 山尾守 on 2016/07/23.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import Foundation
import MRProgress

enum EnumModeView{
    
    case mrActivityIndicatorView
    case mrCircularProgressView
    case uiProgressView
    case uiActivityIndicatorView
    case mrCheckmarkIconView
    case mrCrossIconView
    case none
}

/*
初期値オブジェクト
*/
class CustomProgressModel{
    
    var progress:Float = 0.0
    var title:String = "受信中..."
    var trackTintColor:UIColor = UIColor.white
    var progressTintColor:UIColor = UIColor.blue
    //** tdaiku add property
//    var compliteTitle:String = "Complite!!"
    var compliteTitle:String = "終了!!"
}


class CustomProgress{
    //static init 用
    init(){
        Instance.progressChange = 0
        Instance.modeView = EnumModeView.none
        Instance.view = nil
    }
    
    //static struct
    struct Instance{
        static var mrprogress:MRProgressOverlayView = MRProgressOverlayView()
        static var modeView = EnumModeView.none
        static var view:UIView! = nil
        static var progressChange:Float = 0.0{
            didSet {
                if(CustomProgress.Instance.progressChange >= 1.0){
                    progressChange = 1.0
                    CustomProgress.Instance.mrprogress.titleLabelText = compliteTitle
                } else {
                    CustomProgress.Instance.mrprogress.titleLabelText = title
                }
                mrprogress.setProgress(progressChange, animated: true)
            }
        }
        static var compliteTitle = "complite!!"
        static var title = "受信中..."
    }
    
    class func Create(_ view:UIView,initVal:CustomProgressModel,modeView:EnumModeView){
        
        Instance.mrprogress = MRProgressOverlayView()
        Instance.modeView = modeView
        Instance.view = nil
        Instance.compliteTitle = initVal.compliteTitle
        
        let mrprogress = Instance.mrprogress
//        mrprogress.titleLabelText = initVal.title
        mrprogress.titleLabelText = Instance.title
        
        switch modeView{
            
        case .uiProgressView:
            mrprogress.mode = MRProgressOverlayViewMode.determinateHorizontalBar
            
            let progress = UIProgressView()
            progress.progressViewStyle = UIProgressViewStyle.default
            progress.progress = initVal.progress
            progress.trackTintColor = initVal.trackTintColor
            progress.progressTintColor = initVal.progressTintColor
            mrprogress.modeView = progress
            
        case .uiActivityIndicatorView:
            mrprogress.mode = MRProgressOverlayViewMode.indeterminateSmall
            let progress = UIActivityIndicatorView()
            progress.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
            mrprogress.modeView = progress
            
        case .mrCrossIconView:
            MRProgressOverlayView.showOverlayAdded(to: view,title:initVal.title,mode:MRProgressOverlayViewMode.cross, animated: true);
            Instance.view = view
            return
            
        case .mrCheckmarkIconView:
            MRProgressOverlayView.showOverlayAdded(to: view,title:initVal.title,mode:MRProgressOverlayViewMode.checkmark, animated: true);
            Instance.view = view
            return
            
        case .mrCircularProgressView:
            mrprogress.mode = MRProgressOverlayViewMode.determinateCircular
            mrprogress.setTintColor(initVal.progressTintColor)
            let progress = MRCircularProgressView()
            progress.animationDuration = 0.3
            //progress.mayStop = true
            progress.progress = initVal.progress
            mrprogress.modeView = progress
            break;
            
        case .mrActivityIndicatorView:
            break
            
        case .none:
            break
        }
        
        view.addSubview(mrprogress)
        mrprogress.show(true)
        
    }
    
    class func isEnabledProgress() -> Bool{
        if CustomProgress.Instance.modeView == EnumModeView.uiProgressView ||
            CustomProgress.Instance.modeView == EnumModeView.mrCircularProgressView{
                return true
        }else{
            return false
        }
    }
    
    fileprivate class func Get(_ progress:UIProgressView){
        
    }
    
}

/*
progress完了時にtouchBeginイベントが動作したらprogressを削除する
*/
extension MRProgressOverlayView{
    var complite:Bool{
        get{
            if(CustomProgress.isEnabledProgress()){
                if(CustomProgress.Instance.progressChange >= 1.0){
                    _ = CustomProgress()
                    return true
                }else{
                    return false
                }
            }
            return true
        }
    }
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch CustomProgress.Instance.modeView{
        case .none,.uiActivityIndicatorView:
            break;
        case .mrCheckmarkIconView,.mrCrossIconView:
            MRProgressOverlayView.dismissAllOverlays(for: CustomProgress.Instance.view, animated: true)
        case .uiProgressView,.mrCircularProgressView:
            if(CustomProgress.Instance.mrprogress.complite){
                CustomProgress.Instance.mrprogress.dismiss(true)
            }
        default:
            CustomProgress.Instance.mrprogress.dismiss(true)
        }
        
    }
}
