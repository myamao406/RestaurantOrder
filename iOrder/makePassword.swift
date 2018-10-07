//
//  makePassword.swift
//  iOrder2
//
//  Created by 山尾 守 on 2017/06/21.
//  Copyright © 2017年 山尾守. All rights reserved.
//

import Foundation

class makePassword {
    init() {
        
    }
    
    func check() -> String {
        var pwd = ""

/*
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let dateFromFmt1 = fmt.date(from: "2017-11-01")
        let now = dateFromFmt1
*/
        let now = Date() // 現在日時の取得
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        let y = dateFormatter.string(from: now)
        let y1 = y.substringWithRange(2, end: 3)
        let y2 = y.substringWithRange(3, end: 4)
        let iy1 = 10 - Int(y1)!
        let iy2 = 10 - Int(y2)!
        
        dateFormatter.dateFormat = "MM"
        let m = dateFormatter.string(from: now)
        let m1 = m.substringWithRange(1, end: 2)
        let m2 = m.substringWithRange(0, end: 1)
        let im1 = 10 - Int(m1)! == 10 ? 0 : 10 - Int(m1)!
        let im2 = m2 == "0" ? 0 : 9
        
        let p1 = ((100 - (iy1 * im1)) + ((iy2*10) + im2)) * 7
//        print(p1,iy1,im1,iy2,im2)
        let p1_str = (p1.description).substringFromEnd(2)
        
        let p2 = ((iy1 * im1) + ((iy2*10) + im2)) * 3
//        print(p2,iy1,im1,iy2,im2)
        let p2_str = (p2.description).substringFromEnd(2)
        
        pwd = p1_str + p2_str
        
        return pwd
    }

}
