//
//  TapSound.swift
//  iOrder2
//
//  Created by 山尾 守 on 2016/10/04.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit
import Foundation
import AudioToolbox

open class TapSound {
    open class func buttonTap(_ file:String,type:String){
        
        // タップ音設定
//        print(file,type)
        AVAudioPlayerUtil.setValue(
            URL(
                fileURLWithPath: Bundle.main.path(
                    forResource: file,
                    ofType: type)!
            )
        )
        // 音設定（ボリューム）
        AVAudioPlayerUtil.audioPlayer.volume = 1.0

        AVAudioPlayerUtil.play()
    }
    
    open class func errorBeep(_ file:String,type:String){
        
        if file == "" || type == "" {return}
        
        // タップ音設定
        AVAudioPlayerUtil.setValue_loop(
            URL(
                fileURLWithPath: Bundle.main.path(
                    forResource: file,
                    ofType: type)!
            )
        )
        // 音設定（ボリューム）
        AVAudioPlayerUtil.audioPlayer.volume = 1.0
        
        AVAudioPlayerUtil.play()
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
    
    open class func errorBeep_stop(){
        AVAudioPlayerUtil.stop()
    }
}
