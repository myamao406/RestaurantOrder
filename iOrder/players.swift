//
//  players.swift
//  iOrder2
//
//  Created by 山尾 守 on 2017/03/10.
//  Copyright © 2017年 山尾守. All rights reserved.
//

import Foundation
import FMDB
import Alamofire
import Toast_Swift

open class playersClass {
    
    let initVal = CustomProgressModel()
    
    
    
    // ユーザー情報取得（全体・および差分）
    open class func get(_ updateTime:String = "1900/01/01 00:00:00",error:Bool = false) {
        
        // デモモードのときは処理をしない
        if demo_mode != 0 {return;}
        
        var alamofireManager : Alamofire.SessionManager?
        
        // お客様情報
        struct players_data {
            var shop_code       :Int
            var member_no       :String
            var member_category :Int
            var group_no        :Int
            var player_name_kana:String
            var player_name_kanji:String
            var birthday        :String
            var require_nm      :String
            var sex             :Int
            var message1        :String
            var message2        :String
            var message3        :String
            var price_tanka     :Int
            var status          :Int
            var pm_start_time   :String
            var created         :String
            var modified        :String
        }
        var players:[players_data] = []
        
        
        let now = Date() // 現在日時の取得
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
        dateFormatter.dateStyle = .medium
        
        let today = dateFormatter.string(from: now)
        
        // 使用DB
        let use_db = production_db
        
        // /Documentsまでのパスを取得
        let paths = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask, true)
        let _path = (paths[0] as NSString).appendingPathComponent(use_db)
        
        let db = FMDatabase(path: _path)
        
        // データベースをオープン
        db.open()
        
        if updateTime == "1900/01/01 00:00:00" {
            let sql_del = "DELETE FROM players"
            let _ = db.executeUpdate(sql_del, withArgumentsIn: [])
            print("DELETE OK")
        }
        
        let url = urlString + "GetUpdateCustomer"
        
        // お客様情報
        players = []
        
        print(url,updateTime)
        print("---S-------------------------------------------",Date())
        
        alamofireManager = ApiManager.sharedInstance
        
        self.spinnerStart()
        
        self.dispatch_async_global {
            
            alamofireManager!.request( url, parameters: ["Store_CD":shop_code.description,"UpdateTime":updateTime])
                .responseJSON { response in
                    //                    print(response.result.error)
                    
                    if response.result.error == nil {
                        let json = JSON(response.result.value!)
                        print(json)
                        if json.asError == nil {
                            for (key, value) in json {
                                if key as! String == "Return" {
                                    if value.toString() == "false" {
                                        print("更新情報なし")
                                    }
                                } else {
                                    //                                    let now = Date() // 現在日時の取得
                                    //                                    let dateFormatter = DateFormatter()
                                    //                                    dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
                                    //                                    dateFormatter.timeStyle = .medium
                                    //                                    dateFormatter.dateStyle = .medium
                                    //
                                    //                                    let created = dateFormatter.stringFromDate(now)
                                    print(json["t_customer"])
                                    for (_,custmer) in json["t_customer"]{
                                        players.append(players_data(
                                            shop_code: custmer["store_cd"].asInt!,
                                            member_no: "\(custmer["customer_no"].asInt!)",
                                            member_category: custmer["member_kbn"].asInt!,
                                            group_no: custmer["group_id"].asString! != "" ? Int(custmer["group_id"].asString!)! : -1,
                                            player_name_kana: custmer["customer_kana"].asString!,
                                            player_name_kanji: custmer["customer_nm"].asString!,
                                            birthday: "",
                                            require_nm: custmer["require_nm"].asString!,
                                            sex: 0,
                                            message1: custmer["message1"].asString!,
                                            message2: custmer["message2"].asString!,
                                            message3: custmer["message3"].asString!,
                                            price_tanka: custmer["unit_price_kbn"].asInt!,
                                            status: custmer["status"].asInt!,
                                            pm_start_time: custmer["pm_start_time"].asString!,
                                            created: custmer["import_dt"].asString!,
                                            modified: custmer["import_dt"].asString!
                                            )
                                        )
                                    }
                                    
                                    let sql = "INSERT OR REPLACE INTO players (shop_code,member_no ,member_category,group_no,player_name_kana ,player_name_kanji ,birthday ,require_nm,sex,message1,message2,message3,price_tanka,status,pm_start_time,created ,modified) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?,?,?, ?,?, ?, ?, ?);"
                                    
                                    // トランザクションを開始
                                    db.beginTransaction()
                                    
                                    for player in players {
                                        var argumentArray:Array<Any> = []
                                        argumentArray.append(player.shop_code)
                                        argumentArray.append(player.member_no)
                                        argumentArray.append(player.member_category)
                                        argumentArray.append(player.group_no)
                                        argumentArray.append(player.player_name_kana)
                                        argumentArray.append(player.player_name_kanji)
                                        argumentArray.append(player.birthday)
                                        argumentArray.append(player.require_nm)
                                        argumentArray.append(player.sex)
                                        argumentArray.append(player.message1)
                                        argumentArray.append(player.message2)
                                        argumentArray.append(player.message3)
                                        argumentArray.append(player.price_tanka)
                                        argumentArray.append(player.status)
                                        argumentArray.append(player.pm_start_time)
                                        argumentArray.append(player.created)
                                        argumentArray.append(player.modified)
                                        
                                        // INSERT文を実行
                                        let success = db.executeUpdate(sql, withArgumentsIn: argumentArray)
                                        // INSERT文の実行に失敗した場合
                                        if !success {
                                            print(errno.description)
                                            // ループを抜ける
                                        }
                                    }
                                    db.commit()
                                    
                                    db.close()
                                    
                                }
                            }
                            print("---E-------------------------------------------",Date())
                            self.dispatch_async_main {
                                self.spinnerEnd()
                                //                                let e = json.asError
                                //                                print(e)
                                // 通信完了時に日付テーブルを更新させる
                                db.open()
                                var sql = "DELETE FROM once_a_day;"
                                let _ = db.executeUpdate(sql, withArgumentsIn:[])
                                sql = "INSERT INTO once_a_day (day) VALUES(?);"
                                let success = db.executeUpdate(sql, withArgumentsIn: [today])
                                if !success {
                                    print("insert error!!")
                                }
                                db.close()
                                
//                                callBackClosure()
                                return ;
                            }
                            
                        } else {
                            self.dispatch_async_main {
                                self.spinnerEnd()
                                let e = json.asError
                                print(e as Any)
                                if error {
                                    self.toast(e!.localizedDescription)
                                }
                                
                            }
                        }
                        
                    } else {
                        self.dispatch_async_main {
                            self.spinnerEnd()
                            print(response.result.error as Any)
                            if error {
                                self.toast(response.result.error!.localizedDescription)
                            }
                        }
                    }
            }
        }
    }
    
    fileprivate class func toast(_ msg:String){
        var style = ToastStyle()
        style.backgroundColor = UIColor.red
        
        UIApplication.shared.topViewController()?.view.makeToast(msg, duration: 3.0, position: .top ,style: style)
    }
    
    fileprivate class func dispatch_async_main(_ block: @escaping () -> ()) {
        DispatchQueue.main.async(execute: block)
    }
    
    fileprivate class func dispatch_async_global(_ block: @escaping () -> ()) {
        DispatchQueue.global().async(execute: block)
    }
    
    fileprivate class func spinnerStart() {
//        CustomProgress.Create(self.view,initVal: initVal,modeView: EnumModeView.UIActivityIndicatorView)
        
        //ネットワーク接続中のインジケータを表示
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    fileprivate class func spinnerEnd() {
//        CustomProgress.Instance.mrprogress.dismiss(true)
        //ネットワーク接続中のインジケータを消去
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    class ApiManager {
        static let sharedInstance: SessionManager = {
            let configuration = URLSessionConfiguration.default
            configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
            configuration.timeoutIntervalForRequest = 10
            return SessionManager(configuration: configuration)
        }()
    }
}

