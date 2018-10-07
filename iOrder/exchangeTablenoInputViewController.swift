//
//  exchangeTablenoInputViewController.swift
//  iOrder2
//
//  Created by 山尾 守 on 2017/01/12.
//  Copyright © 2017年 山尾守. All rights reserved.
//

import UIKit
import FontAwesomeKit
import FMDB
import Alamofire


class exchangeTablenoInputViewController: UIViewController,UIActionSheetDelegate,UINavigationBarDelegate {

    fileprivate var onceTokenViewDidAppear: Int = 0
    
    @IBOutlet weak var button0: UIButton!
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    @IBOutlet weak var button4: UIButton!
    @IBOutlet weak var button5: UIButton!
    @IBOutlet weak var button6: UIButton!
    @IBOutlet weak var button7: UIButton!
    @IBOutlet weak var button8: UIButton!
    @IBOutlet weak var button9: UIButton!
    
    @IBOutlet weak var tableNoTextField: UITextField!
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var navBar: UINavigationBar!

    // DBファイルパス
    var _path:String = ""
    
    var seat_temp:[seat_info] = []
    
    let initVal = CustomProgressModel()
    
    let jsonErrorMsg = "テーブル番号の取得に失敗しました。"

    var alamofireManager : Alamofire.SessionManager?

    override func viewDidLoad() {
        super.viewDidLoad()

        navBar.delegate = self
        navBar.barTintColor = iOrder_titleBlueColor
        
        let noKeyButton:[UIButton] = [button0,button1,button2,button3,button4,button5,button6,button7,button8,button9]
        
        for num in 0...noKeyButton.count - 1 {
            let button :UIButton = noKeyButton[num]
            
            button.addTarget(self, action: #selector(tablenoinputViewContoroller.noButtomTap(_:)), for: .touchUpInside)
        }
        
        // 戻るボタン
        var iconImage = FAKFontAwesome.chevronCircleLeftIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_bargainsYellowColor)
        //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
        var Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        backButton.setImage(Image, for: UIControlState())
        
        // 長押し
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.pressedLong(_:)))
        
        backButton.addGestureRecognizer(longPress)
        
        // 確定ボタン
        iconImage = FAKFontAwesome.checkIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
        //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
        Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        okButton.setImage(Image, for: UIControlState())
        
        // クリアボタン
        iconImage = FAKFontAwesome.timesCircleIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_greenColor)
        //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
        Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        clearButton.setImage(Image, for: UIControlState())
        
        // 確定ボタンはテーブルNO入力時だけ押せるようにする。
        okButton.isEnabled = false
        okButton.alpha = 0.6
        
        clearButton.isEnabled = false
        clearButton.alpha = 0.6
        
        // /Documentsまでのパスを取得
        let paths = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask, true)
        
        // 使用DB
        var use_db = production_db
        if demo_mode != 0{
            use_db = demo_db
        }
        
        // テーブルNOを取得する
        _path = (paths[0] as NSString).appendingPathComponent(use_db)
     
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 一番手前にする
        DemoLabel.Show(self.view)
        DemoLabel.modeChange()
    }
    
    
    // ステータスバーとナビゲーションバーの色を同じにする
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.topAttached
    }
    
    // ステータスバーの文字を白にする
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func OKButton(_ sender: UIButton) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        // 数字未入力の時
        if (tableNoTextField.text?.characters.count)! <= 0 {
            // UIAlertController を作成
            let alertController2 = UIAlertController(title: "エラー！", message: "番号を入力してください", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel){
                action in print("Pushed OK")
                self.tableNoTextField.textAlignment = NSTextAlignment.left
                self.button_off()
                return;
            }
            alertController2.addAction(cancelAction)
            present(alertController2, animated: true, completion: nil)
            return;
        }
        
        let tableno:Int = Int(tableNoTextField.text!)!
        
        // 移動元と移動先のテーブル番号が同じ場合はエラーにする
        if tableno == globals_table_no {
            // UIAlertController を作成
            let alertController2 = UIAlertController(title: "エラー！", message: "移動元と同じ番号です。" + "(テーブル番号:" + "\(tableno)" + ")", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel){
                action in print("Pushed OK")
                self.tableNoTextField.textAlignment = NSTextAlignment.left
                self.button_off()
                return;
            }
            alertController2.addAction(cancelAction)
            present(alertController2, animated: true, completion: nil)
            return;
        }
        
        globals_exchange_table_no = tableno
        
        // 本番モード
        if demo_mode == 0 {
            self.spinnerStart()

            self.dispatch_async_global{
                self.get_table_info(tableno)
            }
        } else {
            self.get_table_info_demo(tableno)
        }
        
    }

    // JSON
    func get_table_info(_ tableno:Int){
        
        var status = 0
        
        let url = urlString + "GetTableInfo"
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForResource = 10 // seconds
        
        self.alamofireManager = Alamofire.SessionManager(configuration: configuration)
        self.alamofireManager!.request( url, parameters: ["Store_CD":shop_code.description,"Table_NO":"\(tableno)"])
            .responseJSON{ response in
                // エラーの時
                if response.result.error != nil {
                    // エラー音
                    TapSound.buttonTap(err_sound_file.sound_file, type: err_sound_file.file_type)
//                    self.spinnerEnd()
                    let e = response.result.description

                    // ローカルにシート番号があるかチェックする。
                    let db = FMDatabase(path: self._path)
                    // データベースをオープン
                    db.open()
                    let sql = "SELECT count(*) FROM table_no WHERE table_no = ?;"
                    
                    let rs = db.executeQuery(sql, withArgumentsIn: [tableno])
                    var table_count = 0
                    while (rs?.next())! {
                        table_count = Int((rs?.int(forColumnIndex:0))!)
                    }
                    
                    if table_count <= 0 {
                        self.spinnerEnd()
                        self.dispatch_async_main {
                            let msg = "テーブル番号「" + "\(tableno)" + "」は存在しません"
                            self.jsonError(msg)
                            self.button_off()
                        }
                        return;
                    }
 
                    // シート情報を取得
                    let sql1 = "SELECT * FROM seat_master WHERE table_no = ?;"
                    let rs1 = db.executeQuery(sql1, withArgumentsIn: [tableno])
                    seat_to = []
                    while (rs1?.next())! {
                        let index = seat_to.index(where: {$0.seat_no == Int((rs1?.int(forColumn:"seat_no"))!)})
                        
                        if index == nil {
                            seat_to.append(seat_info(
                                seat_no         : Int((rs1?.int(forColumn:"seat_no"))!),
                                seat_name       : (rs1?.string(forColumn:"seat_name"))!,
                                disp_position   : Int((rs1?.int(forColumn:"disp_position"))!),
                                seat_kbn        : Int((rs1?.int(forColumn:"seat_kbn"))!)
                                )
                            )
                        }
                    }
                    
                    db.close()

                    self.spinnerEnd()
                    self.button_off()
                    
                    print(e)
                    
                    self.dispatch_async_main {
                        self.spinnerEnd()
                        // 席移動画面に移動
                        
                        takeSeatPlayers_to = []
                        self.performSegue(withIdentifier: "toExchangeSeatViewSegue",sender: nil)
                        self.button_off()
                    }

                    
                    return;
                } else {
                    let json = JSON(response.result.value!)
                    print("abc:json",json)
                    if json.asError != nil {
                        self.spinnerEnd()
                        let e = json.asError
                        self.jsonError(self.jsonErrorMsg)
                        self.button_off()
                        
                        print(e as Any)
                        return;
                        
                    } else {
                        for (key,value) in json {
                            if key as! String == "Return" {
                                if value.toString() == "false" {
                                    print("テーブル情報なし")
                                    status = -1
                                    self.spinnerEnd()
                                    self.dispatch_async_main {
                                        let msg = "テーブル番号「" + "\(tableno)" + "」は存在しません"
                                        self.jsonError(msg)
                                        self.button_off()
                                    }
                                    return;
                                }
                            }
                        }
                        
                        status = json["t_order_seat"][0]["status_kbn"].asInt!
                        
                        if status == -1 {
                            self.spinnerEnd()
                            self.dispatch_async_main {
                                let msg = "テーブル番号「" + "\(tableno)" + "」は存在しません"
                                self.jsonError(msg)
                                self.button_off()
                            }
                            return;
                        }else{
                            if status == 9 {
                                let alertController = UIAlertController(title: "移動先のテーブル：" + "\(tableno)" + " には保留データがあります。", message: "座席移動を行うと、保留中のオーダーはすべて消去されます。" + "\nよろしいですか？", preferredStyle: .alert)
                                let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel){
                                    action in print("Pushed cancel")
                                    self.dispatch_async_main {
                                        self.spinnerEnd()
                                        self.button_off()
                                    }

                                    return;
                                }
                                
                                let okAction = UIAlertAction(title: "OK", style: .default){
                                    action in
                                    // タップ音
                                    TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                                    print("Pushed OK")
                                    seat_to = []
                                    takeSeatPlayers_to = []
                                    
                                    fmdb.table_master_save(tableno, json_data: json["t_order_seat"],ex_flag:true)
                                    
                                    let db = FMDatabase(path: self._path)
                                    // データベースをオープン
                                    db.open()
                                    
                                    for (_,custmer) in json["t_order_seat"] {
                                        if custmer["customer_no"].type == "Int" {
                                            if custmer["customer_no"].asInt! > 0 {
                                                takeSeatPlayers_to.append(takeSeatPlayer(
                                                    seat_no:    custmer["seat_no"].asInt! - 1,
                                                    holder_no:  "\(custmer["customer_no"].asInt!)"
                                                    )
                                                )
                                            }
                                            
                                        } else {
                                            takeSeatPlayers_to.append(takeSeatPlayer(
                                                seat_no:    custmer["seat_no"].asInt! - 1,
                                                holder_no:  custmer["customer_no"].asString!
                                                )
                                            )
                                        }
                                        
                                    }
                                    db.close()
                                    
                                    self.dispatch_async_main {
                                        self.spinnerEnd()
                                        // 席移動画面に移動
                                        self.performSegue(withIdentifier: "toExchangeSeatViewSegue",sender: nil)
                                        self.button_off()
                                    }

                                }
                                
                                alertController.addAction(cancelAction)
                                alertController.addAction(okAction)
                                self.present(alertController, animated: true, completion: nil)

                            } else {
                                seat_to = []
                                takeSeatPlayers_to = []
                                
                                let db = FMDatabase(path: self._path)
                                // データベースをオープン
                                db.open()
                                
                                fmdb.table_master_save(tableno, json_data: json["t_order_seat"],ex_flag:true)
                                
                                for (_,custmer) in json["t_order_seat"] {
                                    if custmer["customer_no"].type == "Int" {
                                        if custmer["customer_no"].asInt! > 0 {
                                            takeSeatPlayers_to.append(takeSeatPlayer(
                                                seat_no:    custmer["seat_no"].asInt! - 1,
                                                holder_no:  "\(custmer["customer_no"].asInt!)"
                                                )
                                            )
                                        }
                                        
                                    } else {
                                        takeSeatPlayers_to.append(takeSeatPlayer(
                                            seat_no:    custmer["seat_no"].asInt! - 1,
                                            holder_no:  custmer["customer_no"].asString!
                                            )
                                        )
                                    }
                                    
                                }
                                db.close()
                                
                                self.dispatch_async_main {
                                    self.spinnerEnd()
                                    // 席移動画面に移動
                                    self.performSegue(withIdentifier: "toExchangeSeatViewSegue",sender: nil)
                                    self.button_off()
                                }
                                
                            }
                        }
                    }
                }
        }

    }

    func get_table_info_demo(_ tableno:Int) {
        
        var order_kbns:[Int] = []
        // まずテーブルNOが存在するか確認
        let db = FMDatabase(path: _path)
        db.open()
        let sql = "SELECT count(*) FROM table_no WHERE table_no = ?;"
        
        let results = db.executeQuery(sql, withArgumentsIn: [tableno])
        while (results?.next())! {
            // テーブルNOがない場合
            if (results?.int(forColumnIndex:0))! <= 0 {
                let msg = "テーブル番号「" + "\(tableno)" + "」は存在しません"
                self.jsonError(msg)
                self.button_off()
                
                return;
                
            // 登録されている場合
            } else {
                let sql1 = "SELECT * FROM seat_master WHERE table_no = ? ORDER BY seat_no;"
                let results1 = db.executeQuery(sql1, withArgumentsIn: [tableno])
                seat_to = []
                takeSeatPlayers_to = []
                order_kbns = []
                while (results1?.next())! {
                    
                    seat_to.append(seat_info(
                        seat_no         : Int((results1?.int(forColumn:"seat_no"))!),
                        seat_name       : (results1?.string(forColumn:"seat_name"))!,
                        disp_position   : Int((results1?.int(forColumn:"disp_position"))!),
                        seat_kbn        : Int((results1?.int(forColumn:"seat_kbn"))!)
                        )
                    )
                    takeSeatPlayers_to.append(takeSeatPlayer(
                        seat_no     : Int((results1?.int(forColumn:"seat_no"))!),
                        holder_no   : results1?.string(forColumn:"holder_no") != nil ? (results1?.string(forColumn:"holder_no"))! : ""
                        )
                    )
                    if !((results1?.columnIsNull("order_kbn"))!) {
                        order_kbns.append(Int((results1?.int(forColumn:"order_kbn"))!))
                    }
                }
            }
        }
        db.close()
        
        if seat_to.count <= 0 {
            seat = []
            seat.append(seat_info(seat_no: 0, seat_name: "A", disp_position: 1, seat_kbn: 1))
            seat.append(seat_info(seat_no: 1, seat_name: "B", disp_position: 2, seat_kbn: 1))
            seat.append(seat_info(seat_no: 2, seat_name: "C", disp_position: 3, seat_kbn: 1))
            seat.append(seat_info(seat_no: 3, seat_name: "D", disp_position: 4, seat_kbn: 1))
        }

        let idx = order_kbns.index(where: {$0 == 9})
        if idx != nil {
            let alertController = UIAlertController(title: "移動先のテーブル：" + "\(tableno)" + " には保留データがあります。", message: "座席移動を行うと、保留中のオーダーはすべて消去されます。" + "\nよろしいですか？", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel){
                action in
                // タップ音
                TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                print("Pushed いいえ")
                
                self.button_off()
                return;
            }
            let OKAction = UIAlertAction(title: "OK", style: .default){
                action in
                // タップ音
                TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                print("Pushed はい")
                
                // 席移動画面に移動
                self.performSegue(withIdentifier: "toExchangeSeatViewSegue",sender: nil)
                self.button_off()
                db.close()
                return;
            }
            
            alertController.addAction(OKAction)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
            return;
        }
        // 席移動画面に移動
        self.performSegue(withIdentifier: "toExchangeSeatViewSegue",sender: nil)
        self.button_off()
        db.close()
        return;
        
/*
        
//        var argumentArray:Array<Any> = []
        // let iorder = "CREATE TABLE IF NOT EXISTS iorder(facility_cd INTEGER, store_cd INTEGER, order_no INTEGER,entry_date TEXT, table_no INTEGER, table_name TEXT, status_kbn INTEGER, created TEXT, modified TEXT);"
        let sql2 = "SELECT COUNT(*) FROM iOrder WHERE status_kbn = ? AND table_no = ?;"
        let results2 = db.executeQuery(sql2, withArgumentsIn: [9,tableno])
        while results2.next() {
            // 保留がある場合
            if results2.int(forColumnIndex:0) > 0 {
                
                let alertController = UIAlertController(title: "移動先のテーブル：" + "\(tableno)" + " には保留データがあります。", message: "座席移動を行うと、保留中のオーダーはすべて消去されます。" + "\nよろしいですか？", preferredStyle: .Alert)
                let cancelAction = UIAlertAction(title: "キャンセル", style: .Cancel){
                    action in
                    // タップ音
                    TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                    print("Pushed いいえ")
                    
                    self.button_off()
                    return;
                }
                
                let OKAction = UIAlertAction(title: "OK", style: .Default){
                    action in
                    // タップ音
                    TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                    print("Pushed はい")
                    
                    seat_to = []
                    takeSeatPlayers_to = []
                    
                    // 最大オーダー番号を取得する
                    // MAXオーダーNO　ゲット
                    let sql_max_order_no = "SELECT MAX(order_no) FROM iOrder WHERE store_cd = ? AND table_no = ? AND status_kbn in (1,2,9);"
                    let rs_sql_max_order_no = db.executeQuery(sql_max_order_no, withArgumentsIn: [shop_code,tableno])
                    
                    var max_order_no = -1
                    while rs_sql_max_order_no.next() {
                        max_order_no = Int(rs_sql_max_order_no.int(forColumnIndex:0))
                    }
                    
                    if max_order_no > 0 {
                        let sql_iOrder_detail = "SELECT * FROM iOrder_detail WHERE order_no = ?;"
                        let rs_sql_iOrder_detail = db.executeQuery(sql_iOrder_detail, withArgumentsIn: [max_order_no])
                        
                        
                        while rs_sql_iOrder_detail.next() {
                            // 同じシート番号がすでにあるか？
                            let index = takeSeatPlayers_to.indexOf({$0.seat_no == Int(rs_sql_iOrder_detail.int(forColumn:"seat_no"))})
                            if index == nil {       // 無い時だけ追加
                                takeSeatPlayers_to.append(takeSeatPlayer(
                                    seat_no     : Int(rs_sql_iOrder_detail.int(forColumn:"seat_no")),
                                    holder_no   : (rs_sql_iOrder_detail.int(forColumn:"serve_customer_no")).description
                                    )
                                )
                            }
                        }
                        
                    }

                    // 席移動画面に移動
                    self.performSegue(withIdentifier:"toExchangeSeatViewSegue",sender: nil)
                    self.button_off()
                    db.close()
                    return;
                }
                
                
                alertController.addAction(OKAction)
                alertController.addAction(cancelAction)
                presentViewController(alertController, animated: true, completion: nil)
                return;
            }
        }
        
//        argumentArray = []
        // let iorder = "CREATE TABLE IF NOT EXISTS iorder(facility_cd INTEGER, store_cd INTEGER, order_no INTEGER,entry_date TEXT, table_no INTEGER, table_name TEXT, status_kbn INTEGER, created TEXT, modified TEXT);"
        let sql3 = "SELECT COUNT(*) FROM iOrder WHERE status_kbn != ? AND table_no = ?;"
        let results3 = db.executeQuery(sql3, withArgumentsIn: [2,tableno])
        while results3.next() {
            // 注文データがある場合
            takeSeatPlayers_to = []
            
            if results3.int(forColumnIndex:0) > 0 {
                // 最大オーダー番号を取得する
                // MAXオーダーNO　ゲット
                let sql_max_order_no = "SELECT MAX(order_no) FROM iOrder WHERE store_cd = ? AND table_no = ? AND status_kbn in (1,2,9);"
                let rs_sql_max_order_no = db.executeQuery(sql_max_order_no, withArgumentsIn: [shop_code,tableno])
                
                var max_order_no = -1
                while rs_sql_max_order_no.next() {
                    max_order_no = Int(rs_sql_max_order_no.int(forColumnIndex:0))
                }
                
                if max_order_no > 0 {
                    let sql_iOrder_detail = "SELECT * FROM iOrder_detail WHERE order_no = ?;"
                    let rs_sql_iOrder_detail = db.executeQuery(sql_iOrder_detail, withArgumentsIn: [max_order_no])
                    
                    
                    while rs_sql_iOrder_detail.next() {
                        // 同じシート番号がすでにあるか？
                        let index = takeSeatPlayers_to.indexOf({$0.seat_no == Int(rs_sql_iOrder_detail.int(forColumn:"seat_no"))})
                        if index == nil {       // 無い時だけ追加
                            takeSeatPlayers_to.append(takeSeatPlayer(
                                seat_no     : Int(rs_sql_iOrder_detail.int(forColumn:"seat_no")),
                                holder_no   : (rs_sql_iOrder_detail.int(forColumn:"serve_customer_no")).description
                                )
                            )
                        }
                    }
                    
                }
            
            } else {
                for s in seat_to {
                    takeSeatPlayers_to.append(takeSeatPlayer(
                        seat_no     : s.seat_no,
                        holder_no   : ""
                        )
                    )
                }
            }
            // 席移動画面に移動
            self.performSegue(withIdentifier:"toExchangeSeatViewSegue",sender: nil)
            self.button_off()
            db.close()
            return;
        }
        
        db.close()
        self.button_off()
*/
    }
    
    
    // 数字ボタンタップ
    func noButtomTap(_ sender: UIButton){
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        // 入力済みの文字と入力された文字を合わせて取得.
        var str = tableNoTextField.text! + "\(sender.tag - 1)"
        
        if !(str.characters.count == 1 && sender.tag == 1){
            // 文字数がtableNoMaxLength以下ならh表示する.
            if str.characters.count <= tableNoMaxLength {
                tableNoTextField.textAlignment =   NSTextAlignment.right
                tableNoTextField.text = str
                // 確定ボタンはテーブルNO入力時だけ押せるようにする。
                okButton.isEnabled = true
                okButton.alpha = 1.0
                
                clearButton.isEnabled = true
                clearButton.alpha = 1.0
                
                
            } else {
                print( "\(tableNoMaxLength)" + "文字を超えています")
            }
        } else {
            str = ""
            // 確定ボタンはテーブルNO入力時だけ押せるようにする。
            self.button_off()
            
        }
    }

    // クリアボタンタップ
    @IBAction func clearButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        // テーブルNo 入力エリアをクリアする
        self.button_off()
        
        tableNoTextField.textAlignment = NSTextAlignment.left
        
    }

    
    @IBAction func unwindToexchangeTableNoInput(_ segue: UIStoryboardSegue) {
        
    }

    // 戻るボタンタップ
    @IBAction func backButtonTap(_ sender: AnyObject) {
        
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        self.performSegue(withIdentifier: "toPlayerSeatViewSegue",sender: nil)
    }

    
    // ボタンを長押ししたときの処理
    @IBAction func pressedLong(_ sender: UILongPressGestureRecognizer!) {
        let alertController = UIAlertController(title: "戻るが長押しされました", message: "メインメニューに戻りますか？\n入力中の内容がすべて消去されます！", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel){
            action in print("Pushed cancel")
            return;
        }
        
        let okAction = UIAlertAction(title: "削除", style: .default){
            action in
            // メインメニューに戻る音
            TapSound.buttonTap(top_sound_file.0, type: top_sound_file.1)
            print("Pushed OK")
            self.performSegue(withIdentifier: "toTopViewSegue",sender: nil)
            
            return;
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
        
    }
    
    // MARK: - Override methods
    
    override var canBecomeFirstResponder : Bool {
        return true
    }
    
    override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) {
        if event?.type == UIEventType.motion && event?.subtype == UIEventSubtype.motionShake {
            print("Motion began")
            // エラー表示
            let alertController = UIAlertController(title: "シェイクされました", message: "メインメニューに戻りますか？\n入力中の内容がすべて消去されます！", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel){
                action in print("Pushed cancel")
                return;
            }
            
            let okAction = UIAlertAction(title: "削除", style: .default){
                action in
                // メインメニューに戻る音
                TapSound.buttonTap(top_sound_file.0, type: top_sound_file.1)
                print("Pushed OK")
                self.performSegue(withIdentifier: "toTopViewSegue",sender: nil)
                
                return;
            }
            
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
            
        }
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if event?.type == UIEventType.motion && event?.subtype == UIEventSubtype.motionShake {
            print("Motion ended")
            //            let text = self.textView.text
            //            self.textView.text = text + "\nMotion ended"
        }
    }
    
    override func motionCancelled(_ motion: UIEventSubtype, with event: UIEvent?) {
        if event?.type == UIEventType.motion && event?.subtype == UIEventSubtype.motionShake {
            print("Motion cancelled")
            //            let text = self.textView.text
            //            self.textView.text = text + "\nMotion cancelled"
        }
    }
    
    func dispatch_async_main(_ block: @escaping () -> ()) {
        DispatchQueue.main.async(execute: block)
    }
    
    func dispatch_async_global(_ block: @escaping () -> ()) {
        DispatchQueue.global().async (execute: block)
    }
    
    func spinnerStart() {
        CustomProgress.Instance.title = "受信中..."
        CustomProgress.Create(self.view,initVal: initVal,modeView: EnumModeView.uiActivityIndicatorView)
        
        //ネットワーク接続中のインジケータを表示
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func spinnerEnd() {
        CustomProgress.Instance.mrprogress.dismiss(true)
        //ネットワーク接続中のインジケータを消去
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    func jsonError(_ msg:String){
        // エラー音
        TapSound.buttonTap(err_sound_file.sound_file, type: err_sound_file.file_type)

        // エラー表示
        let alertController = UIAlertController(title: "エラー！", message: msg, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default){
            action in print("Pushed OK")
            return;
        }
        
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
        
    }

    func button_off(){
        self.tableNoTextField.text = ""
        okButton.isEnabled = false
        okButton.alpha = 0.6
        
        clearButton.isEnabled = false
        clearButton.alpha = 0.6
        
    }

    
}
