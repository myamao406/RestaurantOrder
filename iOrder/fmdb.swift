//
//  fmdb.swift
//  iOrder2
//
//  Created by 山尾 守 on 2016/12/08.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import Foundation
import FMDB
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


open class fmdb {
    
    static var path: String {
        var path = ""
        // 使用DB
        var use_db = production_db
        if demo_mode != 0{
            use_db = demo_db
        }
        
        // /Documentsまでのパスを取得
        let paths = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask, true)
        path = (paths[0] as NSString).appendingPathComponent(use_db)
        return path
    }
    
    
//    // ローカルのオーダーNo最大値
//    var max_oeder_no : Int?
    
    class func getNameKana(_ member_no:String) -> String {
//        // 使用DB
//        var use_db = production_db
//        if demo_mode != 0{
//            use_db = demo_db
//        }
//        
//        // /Documentsまでのパスを取得
//        let paths = NSSearchPathForDirectoriesInDomains(
//            .DocumentDirectory,
//            .UserDomainMask, true)
//        let _path = (paths[0] as NSString).stringByAppendingPathComponent(use_db)
        
        // FMDatabaseクラスのインスタンスを作成
        // 引数にファイルまでのパスを渡す
        let db = FMDatabase(path: fmdb.path)
        
        // メニューを取得する
        db.open()

        var player_name_kana = ""
        if demo_mode == 0 {
            let sql = "select player_name_kana from players where member_no = ? AND created LIKE ? AND player_name_kana IS NOT NULL"
            let results = db.executeQuery(sql, withArgumentsIn:[member_no,globals_today + "%"])
            while (results?.next())! {
                player_name_kana = (results?.string(forColumn:"player_name_kana"))!
            }
        } else {
            let sql = "select player_name_kana from players where member_no = ? AND player_name_kana IS NOT NULL"
            let results = db.executeQuery(sql, withArgumentsIn:[member_no])
            while (results?.next())! {
                player_name_kana = (results?.string(forColumn:"player_name_kana"))!
            }
            
        }
        return player_name_kana
    }

    open class func getPlayerName(_ member_no:String) -> String {
        let db = FMDatabase(path: fmdb.path)
        
        // メニューを取得する
        db.open()
        var player_name = ""
        
        if demo_mode == 0 {     // 本番モード
            let sql = "select player_name_kanji from players where member_no = ? AND created LIKE ? AND player_name_kanji IS NOT NULL"
            let results = db.executeQuery(sql, withArgumentsIn:[member_no,globals_today + "%"])
            while (results?.next())! {
                player_name = (results?.string(forColumn:"player_name_kanji"))!
            }
            
        } else {                // デモモード
            let sql = "select player_name_kanji from players where member_no = ? AND player_name_kanji IS NOT NULL"
            let results = db.executeQuery(sql, withArgumentsIn:[member_no])
            while (results?.next())! {
                player_name = (results?.string(forColumn:"player_name_kanji"))!
            }
            
        }
        return player_name
    }

    open class func getStaffName() -> String {

        let db = FMDatabase(path: fmdb.path)
        
        db.open()
        var staff = ""
        
        // 担当者名を取得
        let sql2 = "SELECT * FROM staffs_now;"
        let rs2 = db.executeQuery(sql2, withArgumentsIn: [])
        while (rs2?.next())! {
            staff = (rs2?.string(forColumn:"staff_no"))!
        }
        db.close()
        
        return staff
    }

    
    open class func getMenuName(_ menu_cd:Int64) -> String {

        let db = FMDatabase(path: fmdb.path)
        
        // データベースをオープン
        db.open()
        
        let sql = "select * from menus_master where item_no = ?;"
        let results = db.executeQuery(sql, withArgumentsIn: [NSNumber(value: menu_cd as Int64)])
        
        var menu_name = ""
        while (results?.next())! {
            menu_name = (results?.string(forColumn:"item_name"))!
        }
        db.close()
        
        return menu_name
        
    }

    open class func getMenuCategory(_ menu_cd:Int64) -> (category1:Int,category2:Int) {
        
        let db = FMDatabase(path: fmdb.path)
        
        // データベースをオープン
        db.open()
        
        let sql = "select * from menus_master where item_no = ?;"
        let results = db.executeQuery(sql, withArgumentsIn: [NSNumber(value: menu_cd as Int64)])
        
        var c1 = 0
        var c2 = 0
        while (results?.next())! {
            c1 = Int((results?.int(forColumn:"category_no1"))!)
            c2 = Int((results?.int(forColumn:"category_no1"))!)
        }
        db.close()
        
        return (c1,c2)
        
    }
    
    
    open class func getSelectMenuName(_ menu_no:Int,sub_menu_group:Int,sub_menu_no:Int) -> String {
        
        let db = FMDatabase(path: fmdb.path)
        
        // データベースをオープン
        db.open()
        
        let sql = "select * from sub_menus_master where menu_no = ? AND sub_menu_group = ? AND sub_menu_no = ?;"
        var argumentArray:Array<Any> = []
        argumentArray.append(menu_no)
        argumentArray.append(sub_menu_group)
        argumentArray.append(sub_menu_no)
        
        let results = db.executeQuery(sql, withArgumentsIn: argumentArray)
        
        var sub_menu_name = ""
        while (results?.next())! {
            sub_menu_name = (results?.string(forColumn:"item_name"))!
        }
        db.close()
        
        return sub_menu_name
        
    }

    open class func getOptionMenuName(_ opt_menu_no:Int,category_no:Int) -> String {
        
        let db = FMDatabase(path: fmdb.path)
        
        // データベースをオープン
        db.open()
        
        let sql = "select * from special_menus_master where item_no = ? AND category_no = ? ;"
        var argumentArray:Array<Any> = []
        argumentArray.append(opt_menu_no)
        argumentArray.append(category_no)
        
        let results = db.executeQuery(sql, withArgumentsIn: argumentArray)
        
        var spe_menu_name = ""
        while (results?.next())! {
            spe_menu_name = (results?.string(forColumn:"item_name"))!
        }
        db.close()
        
        return spe_menu_name
        
    }
    
    open class func getTanka(_ sub_menu_group:Int,sub_menu_no:Int,unit_price_kbn:Int) -> (kbn_name:String,price:Int) {
        
        var prices:(kbn_name:String,price:Int) = ("",0)
        
        let db = FMDatabase(path: fmdb.path)
        
        db.open()
        
        let sql = "select sub_menus_master.item_name, unit_price_kbn.price_kbn_name, menus_price.price FROM ((menus_price INNER JOIN unit_price_kbn ON menus_price.unit_price_kbn = unit_price_kbn.price_kbn_no) INNER JOIN sub_menus_master ON menus_price.parent_menu_cd = sub_menus_master.menu_no AND menus_price.menu_cd = sub_menus_master.sub_menu_no and menus_price.category_no = sub_menus_master.sub_menu_group) where sub_menus_master.menu_no = ? and sub_menus_master.sub_menu_group = ? and sub_menus_master.sub_menu_no = ? and menus_price.unit_price_kbn = ? and menus_price.order_kbn = 2"
        var argumentArray:Array<Any> = []
        argumentArray.append(NSNumber(value: globals_select_menu_no.menu_no as Int64))
        argumentArray.append(sub_menu_group)
        argumentArray.append(sub_menu_no)
        argumentArray.append(unit_price_kbn)
        
        let results = db.executeQuery(sql, withArgumentsIn:argumentArray)
        while (results?.next())! {
            prices.kbn_name = (results?.string(forColumn:"price_kbn_name"))!
            prices.price = Int((results?.int(forColumn:"price"))!)
        }
        db.close()
        
        return prices
    }

    open class func getOptionTanka(_ spe_menu_group:Int,spe_menu_no:Int,unit_price_kbn:Int) -> (kbn_name:String,price:Int) {
        
        var prices:(kbn_name:String,price:Int) = ("",0)
        
        let db = FMDatabase(path: fmdb.path)
        
        db.open()
        
        let sql = "select special_menus_master.item_name, unit_price_kbn.price_kbn_name, menus_price.price FROM ((menus_price INNER JOIN unit_price_kbn ON menus_price.unit_price_kbn = unit_price_kbn.price_kbn_no) INNER JOIN special_menus_master ON menus_price.menu_cd = special_menus_master.item_no AND menus_price.category_no = special_menus_master.category_no ) where special_menus_master.category_no = ? and special_menus_master.item_no = ? and menus_price.unit_price_kbn = ? and menus_price.order_kbn = 3;"
        
        var argumentArray:Array<Any> = []
        argumentArray.append(spe_menu_group)
        argumentArray.append(spe_menu_no)
        argumentArray.append(unit_price_kbn)
        
        let results = db.executeQuery(sql, withArgumentsIn:argumentArray)
        while (results?.next())! {
            prices.kbn_name = (results?.string(forColumn:"price_kbn_name"))!
            prices.price = Int((results?.int(forColumn:"price"))!)
        }
        db.close()
        
        return prices
    }

    open class func getPlayerStatus(_ player_no:String) -> Int {
        
        var status = 0
//        let sql = "SELECT * FROM players WHERE member_no in (?);"
        
        let db = FMDatabase(path: fmdb.path)
        // データベースをオープン
        db.open()
        
        // 来場者テーブルからステータスを取得
//        let results = db.executeQuery(sql, withArgumentsIn: [Int(player_no)!])
        
        let results = db.executeQuery(SELECT_PLAYERS, withArgumentsIn: [Int(player_no)!,shop_code,globals_today + "%"])
        while results!.next() {
            status = Int(results!.int(forColumn: "status"))
        }
        results!.close()
        db.close()
        
        return status
    }

    open class func resend_db_save(_ max_oeder_no:Int,send_time:String,resend_kbn:Int = 1) {
        
        let db = FMDatabase(path: fmdb.path)
        
        // データベースをオープン
        db.open()
        
        var argumentArray:Array<Any> = []
        
        argumentArray.append(resend_kbn)
        argumentArray.append(max_oeder_no)
        argumentArray.append(0)
        argumentArray.append(send_time)
        
        let sql = "INSERT INTO resending(resend_kbn,resend_no,resend_count,sendtime) VALUES(?,?,?,?)"
        let success = db.executeUpdate(sql, withArgumentsIn: argumentArray)
        if !success {
            // エラー時
            print(success.description)
        }
        
//        fmdb.db_save(send_time,detail_kbn: 9)

    }

    
    open class func db_save(_ sendTime:String,detail_kbn:Int) {
        
        print(detail_kbn)
        // ローカルのオーダーNo最大値
        var max_oeder_no : Int?
        
        let dateFormatter: DateFormatter = {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .medium
            
            return dateFormatter
        }()

        let db = FMDatabase(path: fmdb.path)

        // データベースをオープン
        db.open()
        let sql2 = "SELECT * FROM staffs_now;"
//        let sql6 = "SELECT MAX(order_no) FROM iOrder WHERE facility_cd = 1 AND store_cd = " + shop_code.description + " AND order_no >= ?"
        
//        dateFormatter.dateFormat = "MMddyy"
        
//        // 2016/11/1 の場合 1101160000 にする
//        let datestr = dateFormatter.string(from: Date())
//        let dateInt = Int(datestr)! * 10000
        var staff = ""
//        max_oeder_no = dateInt
//
//        // オーダーテーブルからMAXオーダー番号取得
//        let rs6 = db.executeQuery(sql6, withArgumentsIn: [dateInt])
//        while (rs6?.next())! {
//
//            max_oeder_no = Int((rs6?.int(forColumnIndex:0))!) + 1
//        }
//
//        if max_oeder_no < dateInt {
//            max_oeder_no = dateInt
//        }
        
        max_oeder_no = get_max_order_no()
        
        print(max_oeder_no as Any,detail_kbn)
        
        // デモモードの時のみ
        if demo_mode != 0 {
            if detail_kbn == 1 {
                let sql_del_iorder_detail = "DELETE FROM iOrder_detail WHERE order_no in ( SELECT order_no FROM iOrder WHERE store_cd = ? AND table_no = ?)"

                print(#function,globals_table_no)
                let _ = db.executeUpdate(sql_del_iorder_detail, withArgumentsIn: [shop_code,globals_table_no])
                
                let sql_del = "DELETE FROM iOrder WHERE store_cd = ? AND table_no = ?;"
                let _ = db.executeUpdate(sql_del, withArgumentsIn: [shop_code,globals_table_no])
                print(#function,globals_table_no)
            } else if globals_is_new == 9 {
                let sql_del_iorder_detail = "DELETE FROM iOrder_detail WHERE order_no in ( SELECT order_no FROM iOrder WHERE store_cd = ? AND table_no = ? AND detail_kbn == 9)"
                let _ = db.executeUpdate(sql_del_iorder_detail, withArgumentsIn: [shop_code,globals_table_no])
                let sql_del = "DELETE FROM iOrder WHERE store_cd = ? AND table_no = ? AND status_kbn = 9;"
                let _ = db.executeUpdate(sql_del, withArgumentsIn:[shop_code,globals_table_no])
            }
            
            // 同じオーダーNOのデータが残っていれば消去
            let sql_debris_delete = "DELETE FROM iOrder_detail WHERE order_no = ?;"
            let _ = db.executeUpdate(sql_debris_delete, withArgumentsIn: [max_oeder_no!])
            
            // seat_masterの情報を更新
            let sql_update_seat_master = "UPDATE seat_master SET holder_no = ?,order_kbn = ?,holder_no9 = ?,order_kbn9 = ? WHERE table_no = ? AND seat_no = ?"
            
            let sql_update_seat_master9 = "UPDATE seat_master SET holder_no9 = ?,order_kbn9 = ? WHERE table_no = ? AND seat_no = ?"
            
            let sql_update_players = "UPDATE players SET pm_start_time = ? WHERE shop_code = ? AND member_no = ?;"
            
            for s in seat {
                var argumentArray:Array<Any> = []

                let idx = takeSeatPlayers.index(where: {$0.seat_no == s.seat_no})
                if idx != nil {
                    argumentArray.append(takeSeatPlayers[idx!].holder_no)
                } else {
                    argumentArray.append(NSNull.self)
                }
                
                if detail_kbn == 1 || detail_kbn == 2 {
                    argumentArray.append(detail_kbn)
                    argumentArray.append(NSNull.self)
                    argumentArray.append(NSNull.self)
                    argumentArray.append(globals_table_no)
                    argumentArray.append(s.seat_no)
                    
                    let _ = db.executeUpdate(sql_update_seat_master, withArgumentsIn: argumentArray)
                    
                } else {
                    argumentArray.append(detail_kbn)
                    argumentArray.append(globals_table_no)
                    argumentArray.append(s.seat_no)
                    
                    let _ = db.executeUpdate(sql_update_seat_master9, withArgumentsIn: argumentArray)
                    
                }
                
                
                
                // PM スタート時間を 来場者情報に保存する
                argumentArray = []
                if idx != nil {
                    argumentArray.append(globals_pm_start_time)
                    argumentArray.append(shop_code)
                    argumentArray.append(takeSeatPlayers[idx!].holder_no)
               
                    let _ = db.executeUpdate(sql_update_players, withArgumentsIn: argumentArray)
                
                }
                
                
            }
            
            
        }
        
        
        // 今接客している、従業員情報取得
        let rs2 = db.executeQuery(sql2, withArgumentsIn: [])
        while (rs2?.next())! {
            staff = (rs2?.string(forColumn:"staff_no"))!
        }
        
        var argumentArray:Array<Any> = []
        let now = Date() // 現在日時の取得
        dateFormatter.timeStyle = .medium
        dateFormatter.dateStyle = .medium
        let nowStr = dateFormatter.string(from: now)
        
        argumentArray.append(1)                     // facility_cd
        argumentArray.append(shop_code)             // store_cd
        argumentArray.append(max_oeder_no!)         // order_no
        argumentArray.append(nowStr)                // entry_date
        argumentArray.append(globals_table_no)      // table_no
        argumentArray.append(detail_kbn)            // status_kbn
        argumentArray.append(globals_pm_start_time) // pm_start_time
        argumentArray.append(1)                     // Timezone_KBN
        argumentArray.append(staff)                 // Employee_CD
        argumentArray.append(sendTime)              // SendTime
        argumentArray.append(TerminalID!)           // TerminalID
        argumentArray.append(nowStr)
        argumentArray.append(nowStr)
        
        // INSERT文を実行(iOrder)
//        print(argumentArray)
        let success = db.executeUpdate(INSERT_OR_REPLACE_INTO_iOrder, withArgumentsIn: argumentArray)
        if !success {
            // エラー時
            print(success.description)
        }
        
        var main_slip = 0
        
        for i in 0..<Section.count {
            var price_kbn = ""
            
            // 来場者テーブルから単価区分を取得
            
            let results = db.executeQuery(SELECT_PLAYERS, withArgumentsIn: [Int(Section[i].No)!,shop_code,globals_today + "%"])

            
            while results!.next() {
                price_kbn = "\(results!.int(forColumn: "price_tanka"))"
            }
            
            let now = Date() // 現在日時の取得
            
            let nowStr = dateFormatter.string(from: now)
            
            var argumentArray:Array<Any> = []
            
            // メインメニュー
            // シートNOからシート名を取得する
            var seat_name = ""
            let idx = seat.index(where: {$0.seat_no == Section[i].seat_no})
            if idx != nil {
                seat_name = seat[idx!].seat_name
            }
            
            let MainMenu_filter = MainMenu.filter({$0.No == Section[i].No && $0.seat == seat_name})
            // 選択メニューデータの中に、着席しているホルダ番号のデータがあるかチェック
            if MainMenu_filter.count > 0 {
                for md in MainMenu_filter {
                    if Section[i].No == md.No {
                        print(md)
                        var cc1 = 0
                        var cc2 = 0
                        let idx_cc = select_menu_categories.index(where: {$0.id == md.id})
                        if idx_cc != nil {
                            cc1 = select_menu_categories[idx_cc!].category1
                            cc2 = select_menu_categories[idx_cc!].category2
                        }
                        
                        var argumentArray:Array<Any> = []
                        
                        main_slip += 1
                        argumentArray.append(1)                     // facility_cd
                        argumentArray.append(shop_code)             // store_cd
                        argumentArray.append(max_oeder_no!)         // order_no
                        argumentArray.append(main_slip)             // branch_no
                        argumentArray.append(detail_kbn)            // detail_kbn
                        argumentArray.append(1)                     // order_kbn
                        argumentArray.append(Section[i].seat_no)    // seat_no
                        argumentArray.append(cc1)                   // category_cd1
                        argumentArray.append(cc2)                   // category_cd2
                        argumentArray.append(md.MenuNo)             // menu_cd
                        argumentArray.append(md.Name)               // menu_name
                        argumentArray.append(md.BranchNo)           // menu_branch
                        argumentArray.append(0)                     // parent_menu_cd
                        
                        let image = fmdb.get_PngData(Section[i].seat,holder_no: Section[i].No, menu_no: md.MenuNo,branch_no: md.BranchNo)
                        
                        argumentArray.append(image)                 // hand_image
                        argumentArray.append(md.Count)              // qty
                        argumentArray.append(price_kbn)             // unit_price_kbn
                        argumentArray.append(Section[i].No)         // serve_customer_no
                        
                        var pay_No = ""
                        
                        // 支払い者のホルダ番号取得
                        var seat_nm = ""
                        let idx = seat.index(where: {$0.seat_no == md.payment_seat_no})
                        if idx != nil {
                            seat_nm = seat[idx!].seat_name
                        }
                        
                        let index = Section.index(where: {$0.seat == seat_nm})
                        if index != nil {
                            pay_No = Section[index!].No
                        }
                        
                        argumentArray.append(pay_No)                // payment_customer_no
                        argumentArray.append(md.payment_seat_no)    // payment_custmoer_seat_no
                        argumentArray.append(0)                     // selling_price
                        argumentArray.append(nowStr)                // created
                        argumentArray.append(nowStr)                // modified
                        
                        // INSERT文を実行(iOrder)
                        
                        print("mainmenu0:",argumentArray)
                        let success = db.executeUpdate(INSERT_INTO_iorder_detail, withArgumentsIn: argumentArray)
                        if !success {
                            // エラー時
                            print(success.description)
                        }
                        
                        
                        // セレクトメニュー（サブメニュー）
                        let sub_filter = SubMenu.filter({$0.id == md.id})
                        if sub_filter.count > 0 {
                            for sd in sub_filter {
                                if sd.No == Section[i].No {
                                    main_slip += 1
                                    
                                    var sub_menu_code = ""
                                    var sub_menu_group = ""
                                    var sub_menu_name = ""
                                    let sql = "SELECT * from sub_menus_master WHERE menu_no = ? AND item_name = ?;"
                                    let rs = db.executeQuery(sql, withArgumentsIn: [sd.MenuNo,sd.Name])
                                    while (rs?.next())! {
                                        sub_menu_code = ((rs?.int(forColumn:"sub_menu_no"))?.description)!
                                        sub_menu_group = ((rs?.int(forColumn:"sub_menu_group"))?.description)!
                                        sub_menu_name = (rs?.string(forColumn:"item_name"))!
                                    }
                                    
                                    var argumentArray:Array<Any> = []
                                    
                                    argumentArray.append(1)                     // facility_cd
                                    argumentArray.append(shop_code)             // store_cd
                                    argumentArray.append(max_oeder_no!)         // order_no
                                    argumentArray.append(main_slip)             // branch_no
                                    argumentArray.append(detail_kbn)            // detail_kbn
                                    argumentArray.append(2)                     // order_kbn
                                    argumentArray.append(Section[i].seat_no)    // seat_no
                                    argumentArray.append(0)                     // category_cd1
                                    argumentArray.append(0)                     // category_cd2
                                    argumentArray.append(sub_menu_code)         // menu_cd
                                    argumentArray.append(sub_menu_name)         // menu_name
                                    argumentArray.append(sd.BranchNo)           // menu_branch
                                    argumentArray.append(sd.MenuNo)             // parent_menu_cd
                                    argumentArray.append(NSNull())              // hand_image
                                    
                                    
                                    argumentArray.append(md.Count)              // qty
                                    argumentArray.append(price_kbn)             // unit_price_kbn
                                    argumentArray.append(Section[i].No)         // serve_customer_no
                                    
                                    argumentArray.append(sub_menu_group)        // payment_customer_no
                                    
                                    argumentArray.append(md.payment_seat_no)           // payment_custmoer_seat_no
                                    argumentArray.append(0)                     // selling_price
                                    argumentArray.append(nowStr)                // created
                                    argumentArray.append(nowStr)                // modified
                                    
                                    // INSERT文を実行(iOrder)
                                    print("submenu:",argumentArray)
                                    let success = db.executeUpdate(INSERT_INTO_iorder_detail, withArgumentsIn: argumentArray)
                                    if !success {
                                        // エラー時
                                        print(success.description)
                                    }
                                }
                            }

                        }
                        
                        // スペシャルメニュー（特殊メニュー）
                        let SpecialMenu_filter = SpecialMenu.filter({$0.id == md.id})
                        if SpecialMenu_filter.count > 0 {
                            for spd in SpecialMenu_filter {
                                if spd.No == Section[i].No {
                                    main_slip += 1
                                    
                                    var spe_menu_code = ""
                                    var spe_menu_category = ""
                                    var spe_menu_name = ""
                                    let sql = "SELECT * from special_menus_master WHERE item_name = ?;"
                                    let rs = db.executeQuery(sql, withArgumentsIn: [spd.Name])
                                    while (rs?.next())! {
                                        spe_menu_code = ((rs?.int(forColumn:"item_no"))?.description)!
                                        spe_menu_category = ((rs?.int(forColumn:"category_no"))?.description)!
                                        spe_menu_name = (rs?.string(forColumn:"item_name"))!
                                    }
                                    
                                    var argumentArray:Array<Any> = []
                                    
                                    argumentArray.append(1)                     // facility_cd
                                    argumentArray.append(shop_code)             // store_cd
                                    argumentArray.append(max_oeder_no!)    // order_no
                                    argumentArray.append(main_slip)             // branch_no
                                    argumentArray.append(detail_kbn)            // detail_kbn
                                    argumentArray.append(3)                     // order_kbn
                                    argumentArray.append(Section[i].seat_no)    // seat_no
                                    argumentArray.append(0)                     // category_cd1
                                    argumentArray.append(0)                     // category_cd2
                                    argumentArray.append(spe_menu_code)         // menu_cd
                                    argumentArray.append(spe_menu_name)         // menu_name
                                    argumentArray.append(spd.BranchNo)          // menu_branch
                                    argumentArray.append(spd.MenuNo)            // parent_menu_cd
                                    argumentArray.append(NSNull())              // hand_image
                                    
                                    
                                    argumentArray.append(md.Count)              // qty
                                    argumentArray.append(price_kbn)             // unit_price_kbn
                                    argumentArray.append(Section[i].No)         // serve_customer_no
                                    argumentArray.append(spe_menu_category)                // payment_customer_no
                                    
                                    
                                    argumentArray.append(md.payment_seat_no)           // payment_custmoer_seat_no
                                    argumentArray.append(0)                     // selling_price
                                    argumentArray.append(nowStr)                // created
                                    argumentArray.append(nowStr)                // modified
                                    
                                    // INSERT文を実行(iOrder)
                                    print("specialmenu:",argumentArray)
                                    let success = db.executeUpdate(INSERT_INTO_iorder_detail, withArgumentsIn: argumentArray)
                                    if !success {
                                        // エラー時
                                        print(success.description)
                                    }
                                    
                                }
                                
                            }
                        }
                    }
                }
                
            } else {
                main_slip += 1
                argumentArray.append(1)                     // facility_cd
                argumentArray.append(shop_code.description) // store_cd
                argumentArray.append(max_oeder_no!)    // order_no
                argumentArray.append(main_slip)             // branch_no
                argumentArray.append(detail_kbn)            // detail_kbn
                argumentArray.append(1)                     // order_kbn
                argumentArray.append(Section[i].seat_no)    // seat_no
                argumentArray.append(0)                     // category_cd1
                argumentArray.append(0)                     // category_cd2
                argumentArray.append(0)                     // menu_cd
                argumentArray.append("")                    // menu_name
                argumentArray.append(0)                     // menu_branch
                argumentArray.append(0)                     // parent_menu_cd
                
                argumentArray.append(NSNull())              // hand_image
                argumentArray.append(0)                     // qty
                argumentArray.append(price_kbn)             // unit_price_kbn
                argumentArray.append(Section[i].No)         // serve_customer_no
                
                argumentArray.append(0)                     // payment_customer_no
                argumentArray.append(Section[i].seat_no)    // payment_custmoer_seat_no
                argumentArray.append(0)                     // selling_price
                argumentArray.append(nowStr)                // created
                argumentArray.append(nowStr)                // modified
                
                // INSERT文を実行(iOrder)
                
                print("mainmenu1:",argumentArray)
                let success = db.executeUpdate(INSERT_INTO_iorder_detail, withArgumentsIn: argumentArray)
                if !success {
                    // エラー時
                    print(success.description)
                }
                
            }
            
        }
        
        db.close()
        print("DB_save")
    }

    open class func table_master_save (_ tableno:Int,json_data:JSON, ex_flag:Bool = false) {
        
        let db = FMDatabase(path: fmdb.path)
        // データベースをオープン
        db.open()
        
        var seat0:[seat_info] = []
        
        var success = true
        var sql = "DELETE FROM seat_master WHERE table_no = ?"
        let _ = db.executeUpdate(sql, withArgumentsIn: [tableno])
        
        for (_,custmer) in json_data{
            let index = seat0.index(where: {$0.seat_no == custmer["seat_no"].asInt! - 1})
            
            if index == nil {
                seat0.append(seat_info(
                    seat_no         : custmer["seat_no"].asInt! - 1,
                    seat_name       : custmer["seat_nm"].asString!,
                    disp_position   : custmer["disp_position"].asInt!,
                    seat_kbn        : custmer["seat_kbn"].asInt!
                    )
                )
            }
        }
        
        sql = "INSERT INTO seat_master (table_no,seat_no,seat_name,disp_position,seat_kbn ,modified) VALUES(?,?,?,?,?,?);"
        
        for s in seat0 {
            var argumentArray:Array<Any> = []
            argumentArray.append(tableno)
            argumentArray.append(s.seat_no)
            argumentArray.append(s.seat_name)
            argumentArray.append(s.disp_position)
            argumentArray.append(s.seat_kbn)
            
            let now = Date() // 現在日時の取得
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
            dateFormatter.timeStyle = .medium
            dateFormatter.dateStyle = .medium
            let modified = dateFormatter.string(from: now)
            argumentArray.append(modified)
            
            // INSERT文を実行
            success = db.executeUpdate(sql, withArgumentsIn: argumentArray)
            // INSERT文の実行に失敗した場合
            if !success {
                print(errno.description)
                // ループを抜ける
                break
            }
        }
        
        db.close()
        
        if ex_flag {
            seat_to = []
            seat_to = seat0
        }else{
            seat = []
            seat = seat0
        }
        
    }

    open class func get_max_order_no() -> Int {
        
        let dateFormatter: DateFormatter = {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .medium
            
            return dateFormatter
        }()
        
        let db = FMDatabase(path: fmdb.path)
        
        let sql6 = "SELECT MAX(order_no) FROM iOrder WHERE facility_cd = 1 AND store_cd = " + shop_code.description + " AND order_no >= ?"
        
        dateFormatter.dateFormat = "MMddyy"
        
        // 2016/11/1 の場合 1101160000 にする
        let datestr = dateFormatter.string(from: Date())
        let dateInt = Int(datestr)! * 10000
        var max_oeder_no = dateInt
        
        // オーダーテーブルからMAXオーダー番号取得
        db.open()

        let rs6 = db.executeQuery(sql6, withArgumentsIn: [dateInt])
        while (rs6?.next())! {
            
            max_oeder_no = Int((rs6?.int(forColumnIndex:0))!) + 1
        }
        db.close()

        if max_oeder_no < dateInt {
            max_oeder_no = dateInt
        }
        
        return max_oeder_no
    }
    
    open class func remove_hand_image() {
        let db = FMDatabase(path: fmdb.path)
        db.open()
        let sql = "DELETE FROM hand_image;"
        let _ = db.executeUpdate(sql, withArgumentsIn: [])
        db.close()
        
        selectMenuCount = []
    }

    open class func get_payment_customer_no (_ rs:FMResultSet) -> Int {
        var payment_customer_no = 0
        let db = FMDatabase(path: fmdb.path)
        db.open()
        let sql = "SELECT payment_customer_no FROM iorder_detail WHERE store_cd = ? AND order_no = ? AND seat_no = ? AND menu_cd = ? AND menu_branch = ? AND order_kbn = 1;"
        var argumentArray:Array<Any> = []
        argumentArray.append(shop_code)                                 // store_cd
        argumentArray.append(Int(rs.int(forColumn: "order_no")))          // order_no
        argumentArray.append(Int(rs.int(forColumn: "seat_no")))           // seat_no
        argumentArray.append(Int(rs.int(forColumn: "parent_menu_cd")))    // menu_no
        argumentArray.append(Int(rs.int(forColumn: "menu_branch")))       // menu_branch
//        print(argumentArray)
        let results = db.executeQuery(sql, withArgumentsIn: argumentArray)
        while (results?.next())! {
            payment_customer_no = Int((results?.int(forColumn:"payment_customer_no"))!)
        }
        
        db.close()
        return payment_customer_no
    }
    
    open class func get_PngData(_ seat:String,holder_no:String,menu_no:String,branch_no:Int) -> Data{
        // 使用DB
        
        let db = FMDatabase(path: fmdb.path)
        db.open()
        
        let sql = "SELECT * from hand_image WHERE seat = ? AND holder_no = ? AND order_no = ? AND branch_no = ?;"
        var image = Data()
        
        let rs = db.executeQuery(sql, withArgumentsIn: [seat,holder_no,menu_no,branch_no])
        while (rs?.next())! {
            image = rs?.data(forColumn:"hand_image") != nil ? (rs?.data(forColumn:"hand_image"))! : Data()
        }
        db.close()
        return image
        
        
    }

    open class func soundsListMake(_ indexPath:IndexPath) {
        let db = FMDatabase(path: fmdb.path)
        db.open()
        
        var sql = "select * from app_config_sound where sound_no >= ? and sound_no < ?; "
        var from = 0
        var to = 0
        switch globals_config_info!.item {
        case "is_tapsound":
            from = 0
            to = 100
        case "is_errorbeep":
            from = 100
            to = 200
        case "topreturn_sound":
            from = 200
            to = 300
        case "is_senddata","is_senderror","is_order_s2e" :
            from = 100
            to = 200
        default:
            from = 100
            to = 200
        }
        
        var results = db.executeQuery(sql, withArgumentsIn:[from,to])
        
        var sound:[Int] = []
        while (results?.next())! {
            sound.append(Int((results?.int(forColumn:"sound_no"))!))
        }

        
        sql = "select * from app_config_sound where sound_no = ?; "
        
        results = db.executeQuery(sql, withArgumentsIn:[sound[indexPath.row]])
        while (results?.next())! {
            let sound_file = results?.string(forColumn:"sound_file")
            let file_type = results?.string(forColumn:"file_type")
            
            switch globals_config_info!.item {
            case "is_tapsound":     // 操作音
                tap_sound_file.sound_file = sound_file!
                tap_sound_file.file_type = file_type!
            case "is_errorbeep":     // エラー音
                err_sound_file.sound_file = sound_file!
                err_sound_file.file_type = file_type!
            case "topreturn_sound":     // トップに戻る音
                top_sound_file.sound_file = sound_file!
                top_sound_file.file_type = file_type!
            case "is_senddata":
                not_send_alert_file.sound_file = sound_file!
                not_send_alert_file.file_type = file_type!
            case "is_senderror":
                data_not_send_alert_file.sound_file = sound_file!
                data_not_send_alert_file.file_type = file_type!
            case "is_order_s2e" :
                order_start2end_alert_file.sound_file = sound_file!
                order_start2end_alert_file.file_type = file_type!
            default:
                break
            }
            
            // 音設定
            AVAudioPlayerUtil.audioPlayer.volume = 1.0
            
            AVAudioPlayerUtil.setValue(
                URL(
                    fileURLWithPath: Bundle.main.path(
                        forResource: sound_file,
                        ofType: file_type)!
                )
            )
            
            // タップ音
            TapSound.buttonTap(sound_file!, type: file_type!)
        }
        db.close()
    }
}
