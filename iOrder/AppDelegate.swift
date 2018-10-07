//
//  AppDelegate.swift
//  iOrder
//
//  Created by 山尾守 on 2016/06/25.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit
import FMDB
import Alamofire
import ReachabilitySwift
import LUKeychainAccess

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var backgroundTaskID : UIBackgroundTaskIdentifier = 0
    
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
    
    var alamofireManager : Alamofire.SessionManager?
    
    var reachability: Reachability?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        sleep(3)
        
        //UUID

        let keychainAccess = LUKeychainAccess.standard()
        let UUID_String = keychainAccess.string(forKey: "KEY_CHAIN_UUID_STRING")
        if UUID_String == "" || UUID_String == nil {
            TerminalID = UIDevice().identifierForVendor?.uuidString
            keychainAccess.setString(TerminalID, forKey: "KEY_CHAIN_UUID_STRING")
        } else {
            TerminalID = UUID_String
        }
        
//        TerminalID = UIDevice().identifierForVendor?.uuidString
        print("UUID identifireForVender",TerminalID as Any)
        
        // ID for Vender.
        let myIDforVender = UIDevice.current.identifierForVendor
        print(myIDforVender as Any)
        
        ip_address = UserDefaults().string(forKey: "address_preference")
        if ip_address == nil {
            getPlist()
        } else {
            setPlist(ip_address!)
        }
        
        is_shop_code_change = UserDefaults().bool(forKey: "shop_code_change")
        setPlist_shop(is_shop_code_change)
        
        print(ip_address as Any)
        print(is_shop_code_change)
        NotificationCenter.default.addObserver(self, selector: #selector(settingChanged), name: UserDefaults.didChangeNotification, object: nil)
        
        
        // /Documentsまでのパスを取得
        let paths = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask, true)
        let _path = (paths[0] as NSString).appendingPathComponent(production_db)

        let db = FMDatabase(path: _path)
        
        // データベースをオープン
        db.open()
        
        // 項目追加した時には、ここでチェックする
        // テーブルがあるか確認する
        // 2017/1/26 add
        
        let db_version = db.userVersion
        
        if db_version <= 0 {
            let _ = db.executeUpdate("DROP TABLE app_config", withArgumentsIn:[])
            let _ = db.executeUpdate("DROP TABLE players;", withArgumentsIn:[])
            let _ = db.executeUpdate("DROP TABLE categorys_master;", withArgumentsIn:[])
            let _ = db.executeUpdate("DROP TABLE seat_master;", withArgumentsIn:[])
            let _ = db.executeUpdate("DROP TABLE iorder_detail;", withArgumentsIn:[])
            
            db.userVersion = 1
        }
        
        // 5/17 追加
        if db_version <= 1 {
            let _ = db.executeUpdate("DROP TABLE app_config", withArgumentsIn:[])
            print("drop table")
            
            db.userVersion = 2
            print("db.userVersion()",db.userVersion)
        }
        
        if db_version <= 2 {
            let _ = db.executeUpdate("DROP TABLE players;", withArgumentsIn:[])
            db.userVersion = 3
            print("db.userVersion()",db.userVersion)
            
        }

        // タブレット認証で追加
        if db_version <= 3 {
            let _ = db.executeUpdate("DROP TABLE server_certification;", withArgumentsIn:[])
            db.userVersion = 4
            print("db.userVersion()",db.userVersion)
            
        }
        
    
        // トランザクションを開始
        db.beginTransaction()
        // テーブルを作成する
        for num in 0..<sql.count {
            db.executeUpdate(sql[num], withArgumentsIn: [])
        }
        db.commit()
        
        // データベースクローズ
        db.close()

        db.open()
        //
        // サウンドデータがない場合、CSVよりデータを格納する
        let sql_sound = "SELECT count(*) FROM app_config_sound;"
        
        let rs_sound = db.executeQuery(sql_sound, withArgumentsIn: [])
        
        while (rs_sound?.next())! {
            // カラムのインデックスを指定して取得
            let data_count = rs_sound?.int(forColumnIndex:0)
            //            print("data_count = \(data_count)")
            if data_count! <= 0 {
                //CSVファイル読み込み
                let csvBundle = Bundle.main.path(forResource: demo_csv[8][0], ofType: demo_csv[8][1])
                do {
                    var csvData: String = try String(contentsOfFile: csvBundle!, encoding: String.Encoding.utf8)
                    csvData = csvData.replacingOccurrences(of: "\r", with: "")
                    let csvArray = csvData.components(separatedBy: "\n")
                    
                    var success = true
                    // トランザクションの開始
                    db.beginTransaction()
                    
                    for line in csvArray {
                        var staff_info:Array<Any> = []
                        let parts = line.components(separatedBy: ",")
                        
                        for part in parts {
                            staff_info.append(part)
                        }
                        let now = Date() // 現在日時の取得
                        let dateFormatter = DateFormatter()
                        dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
                        dateFormatter.timeStyle = .medium
                        dateFormatter.dateStyle = .medium
                        
                        let created = dateFormatter.string(from: now)
                        let modified = dateFormatter.string(from: now)
                        
                        staff_info.append(created)
                        staff_info.append(modified)
                        
                        let sql_insert = demo_csv[8][2]
                        
                        // INSERT文を実行
                        success = db.executeUpdate(sql_insert, withArgumentsIn: staff_info)
                        // INSERT文の実行に失敗した場合
                        if !success {
                            // ループを抜ける
                            break
                        }
                    }
                    if success {
                        // 全てのINSERT文が成功した場合はcommit
                        db.commit()
                    } else {
                        // 1つでも失敗したらrollback
                        db.rollback()
                    }
                } catch let error as NSError {
                    print(error.localizedDescription)
                }
            }
        }
        rs_sound?.close()
        
        // モード取得
        let sql_select = "SELECT * FROM app_config;"
        let results_select = db.executeQuery(sql_select, withArgumentsIn: [])
        while (results_select?.next())! {
            demo_mode = Int((results_select?.int(forColumn: "is_demo"))!)
        }
        
        db.close()

        // デモ用データ作成 ////////////////////////////////////////////////////////////////
        let _path_demo = (paths[0] as NSString).appendingPathComponent(demo_db)
        
        let db_demo = FMDatabase(path: _path_demo)
        
        // デモ用データベースをオープン
        db_demo.open()
        
        let db_version_demo = db_demo.userVersion
        
        if db_version_demo <= 0 {
            let _ = db_demo.executeUpdate("DROP TABLE app_config", withArgumentsIn: [])
            let _ = db_demo.executeUpdate("DROP TABLE players;", withArgumentsIn: [])
            let _ = db_demo.executeUpdate("DROP TABLE categorys_master;", withArgumentsIn: [])
            let _ = db_demo.executeUpdate("DROP TABLE seat_master;", withArgumentsIn: [])
            let _ = db_demo.executeUpdate("DROP TABLE iorder_detail;", withArgumentsIn: [])
            
            db_demo.userVersion = 1
        }

        // 5/17 追加
        if db_version_demo <= 1 {
            let _ = db_demo.executeUpdate("DROP TABLE app_config", withArgumentsIn:[])
            print("drop table")
            
            db_demo.userVersion = 2
            print("db.userVersion()",db_demo.userVersion)
        }
        
        if db_version_demo <= 2 {
            let _ = db_demo.executeUpdate("DROP TABLE players;", withArgumentsIn:[])
            db_demo.userVersion = 3
            print("db.userVersion()",db_demo.userVersion)
        }

        // トランザクションを開始
        db_demo.beginTransaction()
        // テーブルを作成する
        for num in 0..<sql_demo.count {
            db_demo.executeUpdate(sql_demo[num], withArgumentsIn: [])
        }
        db_demo.commit()
        
        //
        // デモデータがない場合、CSVよりデータを格納する
        let sql_staff = "SELECT count(*) FROM staffs_info;"
        
        let results = db_demo.executeQuery(sql_staff, withArgumentsIn: [])
        
        while (results?.next())! {
            // カラムのインデックスを指定して取得
            let data_count = results?.int(forColumnIndex:0)
//            print("data_count = \(data_count)")
            if data_count! <= 0 {
                
                for num in 0..<demo_csv.count {
//                    print(demo_csv[num])
                    //CSVファイル読み込み
                    let csvBundle = Bundle.main.path(forResource: demo_csv[num][0], ofType: demo_csv[num][1])
                    do {
                        let csvData: String = try String(contentsOfFile: csvBundle!, encoding: String.Encoding.utf8)
//                        csvData = csvData.stringByReplacingOccurrencesOfString("\r", withString: "")
//                        let csvArray = csvData.componentsSeparatedByString("\n")
                        
                        let csvArray = csvData.lines
                        
                        var success = true
                        // トランザクションの開始
                        db_demo.beginTransaction()
                        
                        for line in csvArray {
                            var staff_info:Array<Any> = []
                            let parts = line.components(separatedBy: ",")
                            
                            for part in parts {
                                staff_info.append(part)
                            }
                            let now = Date() // 現在日時の取得
                            let dateFormatter = DateFormatter()
                            dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
                            dateFormatter.timeStyle = .medium
                            dateFormatter.dateStyle = .medium
                            
                            let created = dateFormatter.string(from: now)
                            let modified = dateFormatter.string(from: now)
                            
                            staff_info.append(created)
                            staff_info.append(modified)
                            
                            let sql_insert = demo_csv[num][2]
                            
                            // INSERT文を実行
                            success = db_demo.executeUpdate(sql_insert, withArgumentsIn: staff_info)
                            // INSERT文の実行に失敗した場合
                            if !success {
                                print(staff_info)
                                // ループを抜ける
                                break
                            }
                        }
                        if success {
                            // 全てのINSERT文が成功した場合はcommit
                            db_demo.commit()
                        } else {
                            // 1つでも失敗したらrollback
                            db_demo.rollback()
                        }
                    } catch let error as NSError {
                        print(error.localizedDescription)
                    }
                }
            }
        }
        results?.close()
        db_demo.close()
        
        // get_players()
        
        // 日時文字列をNSDate型に変換するためのDateFormatterを生成
        let now = Date() // 現在日時の取得
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
        dateFormatter.dateFormat = "yyyy/MM/dd"
        
        globals_today = demo_mode == 0 ? dateFormatter.string(from: now) : ""
        
        
        return true
    }

    //上記のNotificatioを５秒後に受け取る関数
//    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
//        
//        
//        
//        if application.applicationState == .Active {
//            print("aaaaaaaaaaaaaaaa----------------------")
//            if let title = notification.alertTitle, let body = notification.alertBody {
//                
//                
//                let alert = UIAlertController(title: title, message: body, preferredStyle: .Alert)
//                alert.addAction( UIAlertAction(title: "OK", style: .Default, handler: nil))
//                UIApplication.sharedApplication().topViewController()?.presentViewController(alert, animated: true, completion: nil)
//            }
//        }
//        
//        
//        //アプリがactive時に通知を発生させた時にも呼ばれる
//        if application.applicationState != .Active{
//            
//            
//            
//            //バッジを０にする
////            application.applicationIconBadgeNumber = 0
//            //通知領域から削除する
////            application.cancelLocalNotification(notification)
//        }else{
//            //active時に通知が来たときはそのままバッジを0に戻す
//            if application.applicationIconBadgeNumber != 0{
////                application.applicationIconBadgeNumber = 0
////                application.cancelLocalNotification(notification)
//            }
//        }
//    }
    
    
    //バックグラウンド遷移移行直前に呼ばれる
    func applicationWillResignActive(_ application: UIApplication) {
        self.backgroundTaskID = application.beginBackgroundTask() {
            [weak self] in
            application.endBackgroundTask((self?.backgroundTaskID)!)
            self?.backgroundTaskID = UIBackgroundTaskInvalid
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        // アプリがフォアグラウンドへ移行した時
//        get_players()
        
        // 日時文字列をNSDate型に変換するためのDateFormatterを生成
        let now = Date() // 現在日時の取得
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
        dateFormatter.dateFormat = "yyyy/MM/dd"
        
        globals_today = demo_mode == 0 ? dateFormatter.string(from: now) : ""
        
    }

    //アプリがアクティブになる度に呼ばれる
    func applicationDidBecomeActive(_ application: UIApplication) {
        application.endBackgroundTask(self.backgroundTaskID)
        print("アプリがアクティブになりました")
        self.get_players()
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func getPlist() {
        let path = Bundle.main.path(forResource: "Root", ofType: "plist", inDirectory: "Settings.bundle")
        
        // rootがDictionaryなのでNSDictionaryに取り込み
        let dict = NSDictionary(contentsOfFile: path!)
        
        // キー"PreferenceSpecifiers"の中身はarrayなのでNSArrayで取得
        let arr:NSArray = dict!.object(forKey: "PreferenceSpecifiers") as! NSArray
        
        // arrayで取れた分だけループ
        for value in arr {
            if (value as AnyObject).object(forKey:"Type") as! String == "PSTextFieldSpecifier" {
                
                if (value as AnyObject).object(forKey:"Key") as! String == "address_preference" {
                    ip_address = (value as AnyObject).object(forKey:"DefaultValue") as? String
                    print(#function,ip_address as Any)
                }
            }
            if (value as AnyObject).object(forKey:"Type") as! String == "PSToggleSwitchSpecifier" {
                if (value as AnyObject).object(forKey:"Key") as! String == "shop_code_change" {
                    is_shop_code_change = ((value as AnyObject).object(forKey:"DefaultValue") as? Bool)!
                    print(#function,is_shop_code_change)
                }
            }
            
        }
        
        print(ip_address as Any,is_shop_code_change)
    }
    
    func setPlist(_ ip:String) {
        // プロパティファイルをバインド
        let path = Bundle.main.path(forResource: "Root", ofType: "plist", inDirectory: "Settings.bundle")
        
        // rootがDictionaryなのでNSDictionaryに取り込み
        let dict = NSDictionary(contentsOfFile: path!)
        
        // キー"PreferenceSpecifiers"の中身はarrayなのでNSArrayで取得
        let arr:NSArray = dict!.object(forKey: "PreferenceSpecifiers") as! NSArray
        
        //        let idx = arr.indexOfObject(passingTest: {$0.0["Type"] as? String == "PSTextFieldSpecifier" && $0.0["Key"] as? String == "address_preference"})
        //        if idx != NSNotFound {
        //            arr[idx].set(ip, forKey: "DefaultValue")
        //        }
        
        // arrayで取れた分だけループ
        for value in arr {
            if (value as AnyObject).object(forKey:"Type") as! String == "PSToggleSwitchSpecifier" {
                
                if (value as AnyObject).object(forKey:"Key") as! String == "address_preference" {
                    //                    (value as AnyObject).set(ip, forKey: "DefaultValue")
                }
                
            }
        }
        
        //        ip_address = NSUserDefaults().stringForKey("address_preference")
        print(ip_address as Any)
        urlString = "http://" + ip_address! + "/Iorder_WebService/WebService.asmx/"
        
    }
    
    func setPlist_shop(_ val:Bool) {
        
        let path = Bundle.main.path(forResource: "Root", ofType: "plist", inDirectory: "Settings.bundle")
        
        // rootがDictionaryなのでNSDictionaryに取り込み
        let dict = NSDictionary(contentsOfFile: path!)
        
        // キー"PreferenceSpecifiers"の中身はarrayなのでNSArrayで取得
        let arr:NSArray = dict!.object(forKey: "PreferenceSpecifiers") as! NSArray
        
        // arrayで取れた分だけループ
        for value in arr {
            if (value as AnyObject).object(forKey:"Type") as! String == "PSToggleSwitchSpecifier" {
                if (value as AnyObject).object(forKey:"Key") as! String == "shop_code_change" {
                    //                    (value as AnyObject).set(val, forKey: "DefaultValue")
                    print(#function,is_shop_code_change)
                }
            }
        }
    }
    
    func settingChanged(_ NSNotification:NotificationCenter) {
        print(ip_address as Any)
        ip_address = UserDefaults().string(forKey: "address_preference")
        if ip_address == nil {
            getPlist()
        } else {
            setPlist(ip_address!)
        }
//        setPlist(ip_address!)
        
        is_shop_code_change = UserDefaults().bool(forKey: "shop_code_change")
        setPlist_shop(is_shop_code_change)
        
        print(ip_address as Any,is_shop_code_change)
    }
    
    // ユーザー情報取得（全体・および差分）
    func get_players(){
        
        // デモモードのときは抜ける
        if demo_mode != 0 { return }

        // 通信状況の確認
//        do {
//            reachability = try Reachability.reachabilityForLocalWiFi()
//            print("WiFi",reachability?.isReachableViaWiFi())
//            if ((reachability?.isReachableViaWiFi()) == true) {
//                print("Reachable via WiFi")
//            } else {
//                print("not Reachable via WiFi")
//                return
//            }
//        } catch {
//            return
//        }
        
        // /Documentsまでのパスを取得
        let paths = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask, true)
        let _path = (paths[0] as NSString).appendingPathComponent(production_db)
        
        let db = FMDatabase(path: _path)

        // データベースをオープン
        db.open()
        
        // 一日一回だけ動くように
        let sql = "SELECT day FROM once_a_day;"
        let results = db.executeQuery(sql, withArgumentsIn: [])
        var day = ""
        while (results?.next())! {
            day = (results?.string(forColumn:"day"))!
        }
        
        let now = Date() // 現在日時の取得
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
        dateFormatter.dateStyle = .medium
        
        let today = dateFormatter.string(from: now)
        
        if day != "" {
            // 同じ日付の場合は処理しない
            if today == day {
                print("同じ日付の場合は処理しない")
                return;
            }
        }
        
        // 一日一回　いらないデータを削除する。
        let _ = db.executeUpdate("DELETE FROM iOrder", withArgumentsIn: [])
        let _ = db.executeUpdate("DELETE FROM iOrder_detail", withArgumentsIn: [])
        let _ = db.executeUpdate("DELETE FROM resending", withArgumentsIn: [])
        let _ = db.executeUpdate("DELETE FROM hand_image", withArgumentsIn: [])
        
        
        // 一日一回 サーバ認証の確認
        print("一日一回 サーバ認証の確認")
        self.setServerAuth()
        
        // お客様情報の取得
        playersClass.get()
        
    }

    func dispatch_async_main(_ block: @escaping () -> ()) {
        DispatchQueue.main.async(execute: block)
    }
    
    func dispatch_async_global(_ block: @escaping () -> ()) {
        DispatchQueue.global().async(execute: block)
    }
    
    func spinnerStart() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func spinnerEnd() {
        //ネットワーク接続中のインジケータを消去
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    func setServerAuth() {
    
        self.dispatch_async_global{
        
            let url = urlString + "GetAuthorization?TerminalId=" + TerminalID! + "&StoreKbn=" + store_kbn.description
            let encUrl = url.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            print(encUrl as Any)
            let json = JSON(url: encUrl!)
            print(json)
            
            // 通信エラーの時
            if json.asError != nil {
                print("setServerAuth_ng")
                // エラーなし
            } else {
                print("setServerAuth_ok")
                
                // メッセージ取得
                for (key, value) in json {
                    if key as! String == "Message" {
                        authErrMessage = value.toString()
                    }
                }
                let authErrMessageW:String = authErrMessage
                print(authErrMessageW as Any)

                print(json)
                for (key, value) in json {
                    if key as! String == "Return" {
                        if value.toString() == "true" {
                            print("true")
                            self.dispatch_async_main{
                                self.spinnerEnd()
                                // サーバ認証フラグを1にする
                                print("サーバ認証フラグを確認する_ok")
                                let serverAuth:checkServerAuth = checkServerAuth()
                                let serverCertification_flag = serverAuth.checkCertification()
                                if (serverCertification_flag == 0 || serverCertification_flag == 2) {
                                    print("サーバ認証フラグを1にする")
                                    serverAuth.setCertification()
                                }
                                                                
                                return;
                            }
                            
                        }else if value.toString() == "false" {
                            print("false")
                            self.dispatch_async_main{
                                self.spinnerEnd()
                                // サーバ認証フラグを0にする
                                print("サーバ認証フラグを確認する_ng")
                                let serverAuth:checkServerAuth = checkServerAuth()
                                let serverCertification_flag = serverAuth.checkCertification()
                                if (serverCertification_flag == 1 || serverCertification_flag == 2) {
                                    print("サーバ認証フラグを0にする")
                                    authErrMessage = authErrMessageW
                                    serverAuth.setNoCertification()
                                }
                                
                                return;
                            }
                        }else if value.toString() == "reserve" { // 認証待ち
                            print("reserve")
                            self.dispatch_async_main{
                                self.spinnerEnd()
                                // サーバ認証フラグを1にする
                                print("サーバ認証フラグを確認する_ok")
                                authErrMessage = authErrMessageW
                                let serverAuth:checkServerAuth = checkServerAuth()
                                let serverCertification_flag = serverAuth.checkCertification()
                                if (serverCertification_flag == 0) {
                                    print("サーバ認証フラグを2にする")
                                    serverAuth.setReserve()
                                }
                                return;
                            }
                        }
                    }
                }
            }
        }
    }
    
    
}

extension UIApplication {
    func topViewController() -> UIViewController? {
        guard var topViewController = UIApplication.shared.keyWindow?.rootViewController else { return nil }
        
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }
        return topViewController
    }
}

