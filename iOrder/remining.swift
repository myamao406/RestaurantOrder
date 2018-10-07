//
//  remining.swift
//  iOrder2
//
//  Created by 山尾 守 on 2017/03/17.
//  Copyright © 2017年 山尾守. All rights reserved.
//

import Foundation
import FMDB
import Alamofire

open class remining {
    
    open class func get() {
        print("remining start...")
        
        dispatch_async_main{
            spinnerStart()
        }
        
        dispatch_async_global{
//            var alamofireManager : Alamofire.SessionManager?
            let alamofireManager = ApiManager.sharedInstance
            let url = urlString + "RemainNumSend"

            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForResource = 10 // seconds
            
//            alamofireManager = Alamofire.SessionManager(configuration: configuration)
            alamofireManager.request(url, parameters: ["Store_CD":shop_code.description])
                .responseJSON{ response in
                    // エラーの時
                    if response.result.error != nil {
                        self.dispatch_async_main {
                            print(response.result.error as Any)
                            let e = response.result.description
                            
                            // エラー音
                            TapSound.buttonTap(err_sound_file.sound_file, type: err_sound_file.file_type)
                            
                            print("e1",e)
                            self.spinnerEnd()
                            return;
                        }
                    } else {
                        let json = JSON(response.result.value!)
                        // エラーの時
                        if json.asError != nil {
                            self.dispatch_async_main {
                                let e = json.asError
                                // エラー音
                                TapSound.buttonTap(err_sound_file.sound_file, type: err_sound_file.file_type)
                                print("e2",e as Any)
                                
                                self.spinnerEnd()
                                return;
                            }
                        } else {
                            // 使用DB
                            var use_db = production_db
                            if demo_mode != 0{
                                use_db = demo_db
                            }
                            
                            // /Documentsまでのパスを取得
                            let paths = NSSearchPathForDirectoriesInDomains(
                                .documentDirectory,
                                .userDomainMask, true)
                            let _path = (paths[0] as NSString).appendingPathComponent(use_db)
                            
                            // FMDatabaseクラスのインスタンスを作成
                            // 引数にファイルまでのパスを渡す
                            let db = FMDatabase(path: _path)
                            db.open()
                            // 一旦、残数テーブルを削除
                            var sql = "DELETE FROM items_remaining;"
                            let _ = db.executeUpdate(sql, withArgumentsIn: [])
                            
                            sql = "INSERT INTO items_remaining (item_no , remaining_count, created , modified) VALUES (?,?,?,?);"
                            
                            for (_,remain) in json["t_remain_num"]{
                                var argumentArray:Array<Any> = []
                                
                                if remain["menu_cd"].type == "Int" && remain["remain_num"].type == "Int" {
                                    argumentArray.append(NSNumber(value: remain["menu_cd"].asInt64!))
                                    argumentArray.append(remain["remain_num"].asInt!)
                                    
                                    let now = Date() // 現在日時の取得
                                    let dateFormatter = DateFormatter()
                                    dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
                                    dateFormatter.timeStyle = .medium
                                    dateFormatter.dateStyle = .medium
                                    
                                    let created = dateFormatter.string(from: now)
                                    let modified = created
                                    argumentArray.append(created)
                                    argumentArray.append(modified)
                                    
                                    db.beginTransaction()
                                    let success = db.executeUpdate(sql, withArgumentsIn: argumentArray)
                                    if !success {
                                        print("insert error!!")
                                    }
                                    db.commit()
                                }                             }
                            
                            db.close()
                            
                            self.dispatch_async_main {
                                spinnerEnd()
                                print("remining end...")
                            }

                        }
                    }
            }
            
        }
        
    }
    
    fileprivate class func dispatch_async_main(_ block: @escaping () -> ()) {
        DispatchQueue.main.async(execute: block)
    }
    
    fileprivate class func dispatch_async_global(_ block: @escaping () -> ()) {
        DispatchQueue.global().async(execute: block)
    }
    
    fileprivate class func spinnerStart() {
        let initVal = CustomProgressModel()
        CustomProgress.Create((UIApplication.shared.topViewController()?.view)!,initVal: initVal,modeView: EnumModeView.uiActivityIndicatorView)
        
        //ネットワーク接続中のインジケータを表示
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    fileprivate class func spinnerEnd() {
        CustomProgress.Instance.mrprogress.dismiss(true)
        //ネットワーク接続中のインジケータを消去
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

}

class ApiManager {
    static let sharedInstance: SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        configuration.timeoutIntervalForRequest = 10
        return SessionManager(configuration: configuration)
    }()
}
