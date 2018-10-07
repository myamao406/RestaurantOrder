//
//  AVAudioPlayerUtil.swift
//  iOrder
//
//  Created by 山尾 守 on 2016/08/01.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import AVFoundation


struct AVAudioPlayerUtil {
    
    static var audioPlayer:AVAudioPlayer = AVAudioPlayer();
    static var sound_data:URL?
    
    static func setValue(_ nsurl:URL){
        
        self.sound_data = nsurl;
        
        do {
            self.audioPlayer = try AVAudioPlayer(contentsOf: self.sound_data!);
            //rateの変更を許可しない。
            audioPlayer.enableRate = false
            self.audioPlayer.numberOfLoops = 0
            self.audioPlayer.prepareToPlay()
        } catch let error as NSError {
            print(error)
        }
    }
    
    static func setValue_loop(_ nsurl:URL){
        self.sound_data = nsurl;
        
        do {
            self.audioPlayer = try AVAudioPlayer(contentsOf: self.sound_data!);
            //rateの変更を許可する。
            audioPlayer.enableRate = true
            
            //少し遅くする
            audioPlayer.rate = 0.8
            
            self.audioPlayer.numberOfLoops = -1
            self.audioPlayer.prepareToPlay()
            
        } catch let error as NSError {
            print(error)
        }
        
    }
    
    
    static func play(){
        self.audioPlayer.currentTime = 0
        self.audioPlayer.play();
    }
    
    static func stop(){
        self.audioPlayer.stop();
    }
}
