//
//  String+Extension.swift
//  iOrder2
//
//  Created by 山尾 守 on 2016/09/26.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import Foundation

extension String{
    func substringWithRange(_ start: Int, end: Int) -> String{
        return self.substring(with: Range(self.characters.index(self.startIndex, offsetBy: start) ..< self.characters.index(self.startIndex, offsetBy: end)))
    }
    
    func substringWithRange(_ range: Range <Int>) -> String{
        return self.substring(with: Range(self.characters.index(self.startIndex, offsetBy: range.lowerBound) ..< self.characters.index(self.startIndex, offsetBy: range.upperBound)))
    }
    
    func substringWithRange(_ position: Int) -> String{
        return self.substring(with: Range(self.characters.index(self.startIndex, offsetBy: position) ..< self.characters.index(self.startIndex, offsetBy: position + 1)))
    }
    
    func substringToEnd(_ position: Int) -> String{
        return self.substring(with: Range(self.characters.index(self.startIndex, offsetBy: position) ..< self.endIndex))
    }
    
    func substringFromEnd(_ position: Int) -> String{
        return self.substring(with: Range(self.characters.index(self.endIndex, offsetBy: -position) ..< self.endIndex))
    }
    
    func katakana() -> String {
        var str = ""
        
        for c in unicodeScalars {
            if c.value >= 0x3041 && c.value <= 0x3096 {
                str += String(describing: UnicodeScalar(c.value + 96)!)
            } else {
                str += String(c)
            }
        }
        
        return str
    }
    
    func hiragana() -> String {
        var str = ""
        
        for c in unicodeScalars {
            if c.value >= 0x30A1 && c.value <= 0x30F6 {
                str += String(describing: UnicodeScalar(c.value - 96)!)
            } else {
                str += String(c)
            }
        }
        
        return str
    }
    
//    func katakana() -> String {
//        var str = ""
//
//        // 文字列を表現するUInt32
//        for c in unicodeScalars {
//            if c.value >= 0x3041 && c.value <= 0x3096 {
//                str.append(UnicodeScalar(c.value+96)!)
//            } else {
//                str.append(String(c))
//            }
//        }
//
//        return str
//    }
//
//    func hiragana() -> String {
//        var str = ""
//        for c in unicodeScalars {
//            if c.value >= 0x30A1 && c.value <= 0x30F6 {
//                str.append(String(describing: UnicodeScalar(c.value-96)))
//            } else {
//                str.append(String(c))
//            }
//        }
//
//        return str
//    }

    enum CharacterType {
        case numeric, english, katakana, other
    }
    
    func transformFullwidthHalfwidth(transformTypes types :[CharacterType], reverse :Bool=false) -> String {
        var transformedChars :[String] = []
        
        let chars = self.characters.map{ String($0) }
        chars.forEach{
            let halfwidthChar = NSMutableString(string: $0) as CFMutableString
            CFStringTransform(halfwidthChar, nil, kCFStringTransformFullwidthHalfwidth, false)
            let char = halfwidthChar as String
            
            if char.isNumber(transformHalfwidth: true) {
                if let _ = types.filter({$0 == .numeric}).first {
                    CFStringTransform(halfwidthChar, nil, kCFStringTransformFullwidthHalfwidth, reverse)
                    transformedChars.append(halfwidthChar as String)
                } else {
                    transformedChars.append($0)
                }
            }
            else if char.isEnglish(transformHalfwidth: true) {
                if let _ = types.filter({$0 == .english}).first {
                    CFStringTransform(halfwidthChar, nil, kCFStringTransformFullwidthHalfwidth, reverse)
                    transformedChars.append(halfwidthChar as String)
                } else {
                    transformedChars.append($0)
                }
            }
            else if char.isKatakana() {
                if let _ = types.filter({$0 == .katakana}).first {
                    CFStringTransform(halfwidthChar, nil, kCFStringTransformFullwidthHalfwidth, reverse)
                    transformedChars.append(halfwidthChar as String)
                } else {
                    transformedChars.append($0)
                }
            }
            else {
                if let _ = types.filter({$0 == .other}).first {
                    CFStringTransform(halfwidthChar, nil, kCFStringTransformFullwidthHalfwidth, reverse)
                    transformedChars.append(halfwidthChar as String)
                } else {
                    transformedChars.append($0)
                }
            }
        }
        
        var transformedString = ""
        transformedChars.forEach{ transformedString += $0 }
        
        return transformedString
    }
    
    func isNumber(transformHalfwidth transform :Bool) -> Bool {
        let halfwidthStr = NSMutableString(string: self) as CFMutableString
        CFStringTransform(halfwidthStr, nil, kCFStringTransformFullwidthHalfwidth, false)
        let str = halfwidthStr as String
        
        return Int(str) != nil ? true : false
    }
    
    func isEnglish(transformHalfwidth transform :Bool) -> Bool {
        let halfwidthStr = NSMutableString(string: self) as CFMutableString
        if transform {
            CFStringTransform(halfwidthStr, nil, kCFStringTransformFullwidthHalfwidth, false)
        }
        let str = halfwidthStr as String
        
        let pattern = "[A-z]*"
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let result = regex.stringByReplacingMatches(in: str, options: [], range: NSMakeRange(0, str.characters.count), withTemplate: "")
            if result == "" { return true }
            else { return false }
        }
        catch { return false }
    }
    
    func isKatakana() -> Bool {
        let halfwidthStr = NSMutableString(string: self) as CFMutableString
        CFStringTransform(halfwidthStr, nil, kCFStringTransformFullwidthHalfwidth, true)
        let str = halfwidthStr as String
        
        let pattern = "^[\\u30A0-\\u30FF]+$"
        do {           
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let result = regex.stringByReplacingMatches(in: str, options: [], range: NSMakeRange(0, str.characters.count), withTemplate: "")
            if result == "" { return true }
            else { return false }
        }
        catch { return false }
    }
    
    var lines: [String] {
        var lines = [String]()
        self.enumerateLines { (line, stop) -> () in
            lines.append(line)
        }
        return lines
    }
    
    func find(pattern: String) -> NSTextCheckingResult? {
        do {
            let re = try NSRegularExpression(pattern: pattern, options: [])
            return re.firstMatch(
                in: self,
                options: [],
                range: NSMakeRange(0, self.utf16.count))
        } catch {
            return nil
        }
    }
    
    func replace(pattern: String, template: String) -> String {
        do {
            let re = try NSRegularExpression(pattern: pattern, options: [])
            return re.stringByReplacingMatches(
                in: self,
                options: [],
                range: NSMakeRange(0, self.utf16.count),
                withTemplate: template)
        } catch {
            return self
        }
    }
}
