//
//  tablenoinputViewContoroller.swift
//  iOrder
//
//  Created by 山尾守 on 2016/06/29.
//  Copyright © 2016年 山尾守. All rights reserved.
//


import UIKit
import FontAwesomeKit
import FMDB
import Alamofire
import Toast_Swift

class tablenoinputViewContoroller: UIViewController,UIActionSheetDelegate,UINavigationBarDelegate {
    
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
    
    struct seat_holder_kbn {
        var seat_no:Int
        var holder_no:String
        var order_kbn:Int
    }
    var seat_holder_kbns:[seat_holder_kbn] = []
    var seat_holder_kbns9:[seat_holder_kbn] = []
    
//    var seat_holders:[takeSeatPlayer] = []
    
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
        okButton.alpha = 0.6
        
//        let attributes = [
//            NSFontAttributeName : UIFont(name: "YuGo-Bold", size: 21)!
//        ]
//        tableNoTextField.attributedPlaceholder = NSAttributedString(string: "最大テーブル番号は999です", attributes:attributes)
        
//        tableNoTextField.contentVerticalAlignment = UIControlContentVerticalAlignment.Center
        
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
//                self.tableNoTextField.text = ""
                self.button_off()
                return;
            }
            alertController2.addAction(cancelAction)
            present(alertController2, animated: true, completion: nil)
            return;

        }
        
        let tableno:Int = Int(tableNoTextField.text!)!
        
        takeSeatPlayers_temp = []

        globals_table_no = tableno
        globals_timezone = 0
        globals_is_new_wait = 0
        
        // 本番モード
        if demo_mode == 0 {
            self.spinnerStart()
            let status = 0

            // --------------
            // 来場者情報GET
            // --------------
            
            // お客様情報テーブルから更新日付の最大値を取得
            let db = FMDatabase(path: _path)
            db.open()
            let sql = "select MAX(modified) from players;"
            let results = db.executeQuery(sql, withArgumentsIn: [])
            
            var updateTime = "1900/01/01 00:00:00"
            
            while (results?.next())! {
                if results?.string(forColumnIndex: 0) != nil {
                    print(results?.string(forColumnIndex: 0) as Any)
                    updateTime = (results?.string(forColumnIndex: 0))!
                }
            }
            db.close()
            playersClass.get(updateTime)
            
            
            self.dispatch_async_global {
                // 状態チェック
                self.get_table_info(status,tableno: tableno)
            }
            
            
        // デモモード
        } else {
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
                    seat = []
                    seat_holder_kbns = []
                    seat_holder_kbns9 = []
                    
                    while (results1?.next())! {
                        seat.append(seat_info(
                            seat_no         : Int((results1?.int(forColumn:"seat_no"))!),
                            seat_name       : (results1?.string(forColumn:"seat_name"))!,
                            disp_position   : Int((results1?.int(forColumn:"disp_position"))!),
                            seat_kbn        : Int((results1?.int(forColumn:"seat_kbn"))!)
                            )
                        )
                        
                        if results1?.string(forColumn:"holder_no") != "" && results1?.string(forColumn:"holder_no") != nil {
                            seat_holder_kbns.append(seat_holder_kbn(
                                seat_no     :Int((results1?.int(forColumn:"seat_no"))!),
                                holder_no   : (results1?.string(forColumn:"holder_no"))!,
                                order_kbn   : Int((results1?.int(forColumn:"order_kbn"))!)
                                )
                            )
                            
                        }
                        
                        if results1?.string(forColumn:"holder_no9") != "" && results1?.string(forColumn:"holder_no9") != nil {
                            seat_holder_kbns9.append(seat_holder_kbn(
                                seat_no     :Int((results1?.int(forColumn:"seat_no"))!),
                                holder_no   : (results1?.string(forColumn:"holder_no9"))!,
                                order_kbn   : Int((results1?.int(forColumn:"order_kbn9"))!)
                                )
                            )
                        }
                        
                    }
                    
                    if seat.count <= 0 {
                        seat = []
                        seat.append(seat_info(seat_no: 0, seat_name: "A", disp_position: 1, seat_kbn: 1))
                        seat.append(seat_info(seat_no: 1, seat_name: "B", disp_position: 2, seat_kbn: 1))
                        seat.append(seat_info(seat_no: 2, seat_name: "C", disp_position: 3, seat_kbn: 1))
                        seat.append(seat_info(seat_no: 3, seat_name: "D", disp_position: 4, seat_kbn: 1))
                    }
                }
            }
            
            if seat_holder_kbns9.count > 0 {
                let idx9 = seat_holder_kbns9.index(where: {$0.order_kbn == 9 || $0.order_kbn == 10})
                if idx9 != nil {
                    let alertController = UIAlertController(title: "確認", message: "入力中のデータがありますが呼び出しますか？", preferredStyle: .alert)
                    let OKAction = UIAlertAction(title: "はい", style: .default){
                        action in
                        // タップ音
                        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                        print("Pushed はい")
                        var argumentArray:Array<Any> = []
                        let sql3 = "DELETE FROM new_or_edit;"
                        let _ = db.executeUpdate(sql3, withArgumentsIn: [])
                        
                        let sql4 = new_or_edit_insert
                        argumentArray.append(9)
                        argumentArray.append(tableno)
                        
                        let now = Date() // 現在日時の取得
                        let dateFormatter = DateFormatter()
                        dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
                        dateFormatter.timeStyle = .medium
                        dateFormatter.dateStyle = .medium
                        let created = dateFormatter.string(from: now)
                        let modified = dateFormatter.string(from: now)
                        
                        argumentArray.append(created)
                        argumentArray.append(modified)
                        
                        // INSERT文を実行
                        let result4 = db.executeUpdate(sql4, withArgumentsIn: argumentArray)
                        // INSERT文の実行に失敗した場合
                        if !result4 {
                            print(result4.description)
                            
                        } else {
                            // 手書き削除
                            //                            fmdb.remove_hand_image()
                            
//                            globals_is_new = 9
                            globals_is_new = self.seat_holder_kbns9[idx9!].order_kbn
                            // お客様設定画面に移動
                            self.performSegue(withIdentifier: "toPlayerssetViewSegue",sender: nil)
                            self.button_off()
                        }
                        return;
                    }
                    
                    let cancelAction = UIAlertAction(title: "いいえ", style: .cancel){
                        action in
                        // タップ音
                        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                        print("Pushed いいえ")
                        self.free_seat_check_demo(tableno)
                        
                    }
                    alertController.addAction(OKAction)
                    alertController.addAction(cancelAction)
                    present(alertController, animated: true, completion: nil)
                    return;
                    
                }
                
                let idx2 = seat_holder_kbns.index(where: {$0.order_kbn == 1 || $0.order_kbn == 2})
                if idx2 != nil {
                    self.free_seat_check_demo(tableno)
                    
                    // 保存していたデータを削除
                    let sql6 = "DELETE FROM iOrder_detail WHERE order_no in ( SELECT order_no FROM iOrder WHERE status_kbn = ? AND table_no = ?)"
                    let _ = db.executeUpdate(sql6, withArgumentsIn: [9,tableno])
                    print("delete iorder_detail9",tableno)
                    
                    let sql5 = "DELETE FROM iOrder WHERE status_kbn = ? AND table_no = ?;"
                    let _ = db.executeUpdate(sql5, withArgumentsIn: [9,tableno])
                    print("delete iorder9",tableno)
                    
                }
            } else if seat_holder_kbns.count > 0 {
                
                self.free_seat_check_demo(tableno)
            
            } else {
                // 新規
                takeSeatPlayers = []
                globals_pm_start_time = ""
                globals_is_new = 1
                
                // 時間帯設定画面に移動
                if is_timezone == 1 {
                    self.performSegue(withIdentifier: "toTimezoneViewSegue",sender: nil)
                } else {
                    self.performSegue(withIdentifier: "toPlayerssetViewSegue",sender: nil)
                }
            }
            
            
/*
            var argumentArray:Array<Any> = []
            // let iorder = "CREATE TABLE IF NOT EXISTS iorder(facility_cd INTEGER, store_cd INTEGER, order_no INTEGER,entry_date TEXT, table_no INTEGER, table_name TEXT, status_kbn INTEGER, created TEXT, modified TEXT);"
            let sql2 = "SELECT COUNT(*) FROM iOrder WHERE status_kbn = ? AND table_no = ?;"
            let results2 = db.executeQuery(sql2, withArgumentsIn: [9,tableno])
            while results2.next() {
                // 保留がある場合
                if results2.int(forColumnIndex:0) > 0 {
                    
                    let alertController = UIAlertController(title: "確認", message: "入力中のデータがありますが呼び出しますか？", preferredStyle: .Alert)
                    let OKAction = UIAlertAction(title: "はい", style: .Default){
                        action in
                        // タップ音
                        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                        print("Pushed はい")
                        
                        let sql3 = "DELETE FROM new_or_edit;"
                        let _ = db.executeUpdate(sql3, withArgumentsIn: [])
                        
                        let sql4 = new_or_edit_insert
                        argumentArray.append(9)
                        argumentArray.append(tableno)
                        
                        let now = Date() // 現在日時の取得
                        let dateFormatter = DateFormatter()
                        dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
                        dateFormatter.timeStyle = .medium
                        dateFormatter.dateStyle = .medium
                        let created = dateFormatter.stringFromDate(now)
                        let modified = dateFormatter.stringFromDate(now)
                        
                        argumentArray.append(created)
                        argumentArray.append(modified)
                        
                        // INSERT文を実行
                        let result4 = db.executeUpdate(sql4, withArgumentsIn: argumentArray)
                        // INSERT文の実行に失敗した場合
                        if !result4 {
                            print(result4.description)
                            
                        } else {
                            // 手書き削除
//                            fmdb.remove_hand_image()
                            
                            globals_is_new = 9
                            // お客様設定画面に移動
                            self.performSegue(withIdentifier:"toPlayerssetViewSegue",sender: nil)
                            self.button_off()
                        }
                        return;
                    }
                    
                    let cancelAction = UIAlertAction(title: "いいえ", style: .Cancel){
                        action in
                        // タップ音
                        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                        print("Pushed いいえ")
                        
                        self.free_seat_check_demo(tableno)
                        
                        // 保存していたデータを削除
                        let sql5 = "DELETE FROM iOrder WHERE status_kbn = ? AND table_no = ?;"
                        let _ = db.executeUpdate(sql5, withArgumentsIn: [9,tableno])
                        print("delete iorder")
                        let sql6 = "DELETE FROM iOrder_detail WHERE table_no = ?;"
                        let _ = db.executeUpdate(sql6, withArgumentsIn: [tableno])
                        print("delete iorder_detail")
                    }
                    alertController.addAction(OKAction)
                    alertController.addAction(cancelAction)
                    presentViewController(alertController, animated: true, completion: nil)
                    return;
                }
            }
*/
            
/*
            var argumentArray = []
            
            let sql3 = "SELECT COUNT(*) FROM iOrder WHERE status_kbn != ? AND table_no = ?;"
            let results3 = db.executeQuery(sql3, withArgumentsIn: [2,tableno])
            while results3.next() {
                // 注文データがある場合
                if results3.int(forColumnIndex:0) > 0 {
                    
                    self.free_seat_check_demo(tableno)
                    
                } else {
                    // 全くの新規の場合
                    takeSeatPlayers = []
                    globals_is_new = 1
                    // 時間帯設定画面に移動
                    if is_timezone == 1 {
                        self.performSegue(withIdentifier:"toTimezoneViewSegue",sender: nil)
                    } else {
                        self.performSegue(withIdentifier:"toPlayerssetViewSegue",sender: nil)
                    }
                    
                }
            }
*/
            self.button_off()

        }
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
            okButton.isEnabled = false
            okButton.alpha = 0.6
            
            clearButton.isEnabled = false
            clearButton.alpha = 0.6
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
    
    // 戻るボタンタップ
    @IBAction func backButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        self.performSegue(withIdentifier: "toTopViewSegue",sender: nil)
    }
    
    @IBAction func unwindToTableNoInput(_ segue: UIStoryboardSegue) {
        
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
    
    // JSON
    func get_table_info(_ status:Int,tableno:Int){
        
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
                    seat = []
                    while (rs1?.next())! {
                        let index = seat.index(where: {$0.seat_no == Int((rs1?.int(forColumn:"seat_no"))!)})
                        
                        if index == nil {
                            seat.append(seat_info(
                                seat_no         : Int((rs1?.int(forColumn:"seat_no"))!),
                                seat_name       : (rs1?.string(forColumn:"seat_name"))!,
                                disp_position   : Int((rs1?.int(forColumn:"disp_position"))!),
                                seat_kbn        : Int((rs1?.int(forColumn:"seat_kbn"))!)
                                )
                            )
                            print(seat)
                        }
                    }
                    
                    db.close()
                    self.spinnerEnd()
                    self.button_off()
                    
                    print("response.result.error",e)
                    
                    self.dispatch_async_main {
                        self.spinnerEnd()
                        globals_is_new = 1
                        // 時間帯設定画面に移動
                        
                        takeSeatPlayers = []
                        
                        let nextDisp = is_timezone == 1 ? "toTimezoneViewSegue" : "toPlayerssetViewSegue"
                        self.performSegue(withIdentifier: nextDisp,sender: nil)
                        
                        self.button_off()
                    }
                    return;
                } else {
                    let json_table = JSON(response.result.value!)
                    print("abc:json",json_table)
                    if json_table.asError != nil {
                        self.spinnerEnd()
                        let e = json_table.asError
                        self.jsonError(self.jsonErrorMsg)
                        self.button_off()
                        
                        print(e as Any)
                        return;
                        
                    } else {
                        for (key,value) in json_table {
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
                        
                        status = json_table["t_order_seat"][0]["status_kbn"].asInt!
                        
                        if status == -1 {
                            self.spinnerEnd()
                            self.dispatch_async_main {
                                let msg = "テーブル番号「" + "\(tableno)" + "」は存在しません"
                                self.jsonError(msg)
                                self.button_off()
                            }
                            return;
                        }else{
                            switch status {
                            case 1:     // 新規
                                //　テーブル情報取得
                                takeSeatPlayers = []
                                
                                fmdb.table_master_save(tableno, json_data: json_table["t_order_seat"])

                                for (_,custmer) in json_table["t_order_seat"]{
                                    if custmer["customer_no"].type == "Int" {
                                        if custmer["customer_no"].asInt! > 0 {
                                            takeSeatPlayers.append(takeSeatPlayer(
                                                seat_no:    custmer["seat_no"].asInt! - 1,
                                                holder_no:  "\(custmer["customer_no"].asInt!)"
                                                )
                                            )
                                        }
                                        
                                    } else {
                                        takeSeatPlayers.append(takeSeatPlayer(
                                            seat_no:    custmer["seat_no"].asInt! - 1,
                                            holder_no:  custmer["customer_no"].asString!
                                            )
                                        )
                                    }

                                }
 
                                self.dispatch_async_main {
                                    self.spinnerEnd()
                                    globals_is_new = 1
                                    // 時間帯設定画面に移動
                                    let nextDisp = is_timezone == 1 ? "toTimezoneViewSegue" : "toPlayerssetViewSegue"
                                    self.performSegue(withIdentifier:nextDisp,sender: nil)
                                    self.button_off()
                                }
                                break;
                            case 2:     // 追加
                                print("1")
                                self.free_seat_check(json_table,tableno: tableno)
                                break;
                            case 9:     // 保留
                                self.dispatch_async_main {
                                    self.spinnerEnd()
                                }
                                
                                let alertController = UIAlertController(title: "確認", message: "入力中のデータがありますが\n呼び出しますか？", preferredStyle: .alert)
                                let OKAction = UIAlertAction(title: "はい", style: .default){
                                    action in
                                    // タップ音
                                    TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                                    
                                    print("Pushed はい")
                                    self.dispatch_async_main {
                                        self.spinnerStart()
                                    }
                                    
                                    
                                    // 保留
                                    globals_is_new = 9
                                    // 保留時の新規追加
                                    globals_is_new_wait = json_table["t_order_seat"][0]["reserved_kbn"].asInt! + 1
                                    
                                    
                                    let db = FMDatabase(path: self._path)
                                    
                                    self.seat_temp = []
                                    
                                    fmdb.table_master_save(tableno, json_data: json_table["t_order_seat"])
                                    
                                    // 席に座っていた人の情報
                                    takeSeatPlayers = []
                                    
                                    for (_,custmer) in json_table["t_order_seat"]{
                                        
                                        var custmer_seat_no = ""
                                        
                                        if custmer["customer_no"].type == "Int" {
                                            custmer_seat_no = (custmer["customer_no"].asInt!).description
                                        } else {
                                            custmer_seat_no = custmer["customer_no"].asString!
                                        }
                                        
                                        if custmer_seat_no != "" && custmer_seat_no != "0" {
                                            if custmer["timezone_kbn"].type == "Int" {
                                                if globals_timezone <= 0 {
                                                    globals_timezone = custmer["timezone_kbn"].asInt!
                                                    
                                                }
                                            } else {
                                                if globals_timezone <= 0 {
                                                    globals_timezone = custmer["timezone_kbn"].asString! == "" ? 0 : Int(custmer["timezone_kbn"].asString!)!
                                                }
                                            }
                                        }
                                        
                                        
                                        if custmer["customer_no"].type == "Int" {
                                            if custmer["customer_no"].asInt! > 0 {
                                                takeSeatPlayers.append(takeSeatPlayer(
                                                    seat_no:    custmer["seat_no"].asInt! - 1,
                                                    holder_no:  "\(custmer["customer_no"].asInt!)"
                                                    )
                                                )
                                            }
                                            
                                        } else {
                                            takeSeatPlayers.append(takeSeatPlayer(
                                                seat_no:    custmer["seat_no"].asInt! - 1,
                                                holder_no:  custmer["customer_no"].asString!
                                                )
                                            )
                                            
                                        }
                                        
                                    }
                                    
                                    // データベースをオープン
                                    db.open()
                                    // 状態チェック
                                    let url = urlString + "CheckTable?Store_CD=" + shop_code.description + "&" + "Table_NO=" + "\(tableno)" + "&" + "Process_Div=3"
                                    print(url)
                                    let json = JSON(url: url)
                                    if json.asError == nil {
                                        print("json", json)
                                        select_menu_categories = []
                                        MainMenu = []
                                        SubMenu = []
                                        SpecialMenu = []
                                        fmdb.remove_hand_image()
                                        
                                        for (_,custmer) in json["t_order_seat"]{
                                            if custmer["order_kbn"].asInt == 1 {        // メインメニュー
                                                
                                                var menu_nm = ""
                                                let sql = "SELECT * FROM menus_master where item_no = ?;"
                                                let results = db.executeQuery(sql, withArgumentsIn:[NSNumber(value: custmer["menu_cd"].asInt64!)])
                                                while (results?.next())! {
                                                    menu_nm = (results?.string(forColumn:"item_name"))!
                                                }
                                                
                                                let seat_nm = custmer["seat_nm"].asString!
                                                let custmer_no = "\(custmer["customer_no"].asInt!)"
                                                let menu_no = "\(custmer["menu_cd"].asInt!)"
                                                let payment_seat_no = custmer["payment_customer_seat_no"].asInt! - 1
                                                let oder_count = "\(custmer["qty"].asInt!)"
                                                let branchNo = Int(custmer["menu_seq"].asString!)
                                                let imageString = (custmer["handwriting_path"].asString!)
                                                let category1 = custmer["category_cd1"].asInt!
                                                let category2 = custmer["category_cd2"].asInt!
                                                var imageData:Data?
                                                if imageString != "" {
                                                    imageData = self.String2Nsdata(imageString)
                                                }
                                                
                                                let id = MainMenu.count
                                                MainMenu.append(CellData(
                                                    id      : id,
                                                    seat    : seat_nm,
                                                    No      : custmer_no,
                                                    Name    : menu_nm,
                                                    MenuNo  : menu_no,
                                                    BranchNo: branchNo!,
                                                    Count   : oder_count,
                                                    Hand    : imageString == "" ? false : true,
                                                    MenuType: 1,
                                                    payment_seat_no:payment_seat_no
                                                    )
                                                )
                                                
                                                select_menu_categories.append(select_menu_category(
                                                    id: id,
                                                    category1: category1,
                                                    category2: category2
                                                    )
                                                )
                                                if imageString != "" {
                                                    var argumentArray:Array<Any> = []
                                                    let sql_insert = "INSERT INTO hand_image (hand_image,holder_no,order_no,branch_no,order_count,seat) VALUES(?,?,?,?,?,?);"
                                                    argumentArray.append(imageData!)
                                                    argumentArray.append(custmer_no)
                                                    argumentArray.append(menu_no)
                                                    argumentArray.append(branchNo!)
                                                    argumentArray.append(oder_count)
                                                    argumentArray.append(seat_nm)
                                                    
                                                    let results2 = db.executeUpdate(sql_insert, withArgumentsIn: argumentArray)
                                                    if !results2 {
                                                        // エラー時
                                                        print(results2.description)
                                                    }
                                                }
                                                
                                                
                                            } else if custmer["order_kbn"].asInt == 2 { // サブメニュー（セレクトメニュー）
                                                
                                                var sub_menu_nm = ""
                                                let sql = "SELECT * FROM sub_menus_master where menu_no = ? and sub_menu_group = ? and sub_menu_no = ?;"
                                                
                                                var argumentArray:Array<Any> = []
                                                argumentArray.append(custmer["menu_cd"].asInt!)
                                                argumentArray.append(custmer["sub_menu_kbn"].asInt!)
                                                argumentArray.append(custmer["sub_menu_cd"].asInt!)
                                                
                                                let results = db.executeQuery(sql, withArgumentsIn: argumentArray)
                                                while (results?.next())! {
                                                    sub_menu_nm = (results?.string(forColumn:"item_name"))!
                                                }
                                                
                                                let branchNo = Int(custmer["menu_seq"].asString!)
                                                
                                                SubMenu.append(SubMenuData(
                                                    id      : -1,
                                                    seat    : custmer["seat_nm"].asString!,
                                                    No      : "\(custmer["customer_no"].asInt!)",
                                                    MenuNo  : "\(custmer["menu_cd"].asInt!)",
                                                    BranchNo: branchNo!,
                                                    Name    : sub_menu_nm,
                                                    sub_menu_no : custmer["sub_menu_cd"].asInt!,
                                                    sub_menu_group : custmer["sub_menu_kbn"].asInt!
                                                    )
                                                )
                                            } else if custmer["order_kbn"].asInt == 3 {    // 特殊メニュー（オプションメニュー）
                                                var spe_menu_name = ""
                                                let sql = "SELECT * FROM special_menus_master WHERE item_no = ? AND category_no = ?;"
                                                var argumentArray:Array<Any> = []
                                                argumentArray.append(custmer["spe_menu_cd"].asInt!)
                                                argumentArray.append(custmer["spe_menu_kbn"].asInt!)
                                                
                                                let results = db.executeQuery(sql, withArgumentsIn: argumentArray)
                                                while (results?.next())! {
                                                    spe_menu_name = (results?.string(forColumn:"item_name"))!
                                                }
                                                let branchNo = Int(custmer["menu_seq"].asString!)
                                                
                                                SpecialMenu.append(SpecialMenuData(
                                                    id      : -1,
                                                    seat    :custmer["seat_nm"].asString!,
                                                    No      : "\(custmer["customer_no"].asInt!)",
                                                    MenuNo  : "\(custmer["menu_cd"].asInt!)",
                                                    BranchNo: branchNo!,
                                                    Name    : spe_menu_name,
                                                    category:custmer["spe_menu_kbn"].asInt!
                                                    )
                                                )
                                            }
                                        }
                                        
                                        // id を振り分け
                                        for m in MainMenu {
                                            for (i,s) in SubMenu.enumerated() {
                                                if (s.seat == m.seat && s.No == m.No && s.MenuNo == m.MenuNo && s.BranchNo == m.BranchNo) {
                                                    SubMenu[i].id = m.id
                                                }
                                            }
                                            
                                            for (j,o) in SpecialMenu.enumerated() {
                                                if (o.seat == m.seat && o.No == m.No && o.MenuNo == m.MenuNo && o.BranchNo == m.BranchNo) {
                                                    SpecialMenu[j].id = m.id
                                                }
                                            }
                                        }
                                        
                                        
                                        print(MainMenu)
                                        print(SubMenu)
                                        print(SpecialMenu)
                                        
                                        self.dispatch_async_main {
                                            //                        self.tableNoTextField.text = ""
                                            self.button_off()
                                            
                                            self.spinnerEnd()
                                            
                                            // お客様設定画面に移動
                                            self.performSegue(withIdentifier:"toPlayerssetViewSegue",sender: nil)
                                        }
                                    } else {
                                        self.dispatch_async_main {
                                            self.spinnerEnd()
                                            let e = json.asError
                                            self.jsonError(self.jsonErrorMsg)
                                            
                                            self.button_off()
                                            
                                            print(e as Any)
                                            return;
                                        }
                                    }
                                    self.dispatch_async_main {
                                        self.spinnerEnd()
                                    }
                                    db.close()
                                    
                                    return;

                                }
                                
                                let cancelAction = UIAlertAction(title: "いいえ", style: .cancel){
                                    action in print("Pushed いいえ")
                                    // タップ音
                                    TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                                    
                                    print("2")
                                    self.free_seat_check2(tableno)
                                    
                                }
                                
                                self.dispatch_async_main {
                                    alertController.addAction(OKAction)
                                    alertController.addAction(cancelAction)
                                    self.present(alertController, animated: true, completion: nil)
                                }

                                
                                break;
                            default:
                                break;
                            }
                        }
                    }
                }
        }
        
    }

    func free_seat_check(_ json_table:JSON,tableno:Int) {
        // 座っている人が居なければ、新規にする
        takeSeatPlayers = []
        var is_seat_def = false
        for (_,custmer) in json_table["t_order_seat"]{
            let seat_kbn = custmer["seat_kbn"].asInt!
            
            var custmer_seat_no = ""
            
            if custmer["customer_no"].type == "Int" {
                custmer_seat_no = (custmer["customer_no"].asInt!).description
            } else {
                custmer_seat_no = custmer["customer_no"].asString!
            }
            
            if custmer_seat_no != "" && custmer_seat_no != "0" {
                if custmer["timezone_kbn"].type == "Int" {
                    if globals_timezone <= 0 {
                        globals_timezone = custmer["timezone_kbn"].asInt!
                    }
                } else {
                    if globals_timezone <= 0 {
                        globals_timezone = custmer["timezone_kbn"].asString! == "" ? 0 : Int(custmer["timezone_kbn"].asString!)!
                    }
                }
            }
            
            
            if custmer["customer_no"].type == "Int" {
                // 同じシート番号がすでにあるか？
                let index = takeSeatPlayers.index(where: {$0.seat_no == custmer["seat_no"].asInt! - 1})
                if index != nil {       // ある場合
                    if custmer["customer_no"].asInt! > 0 {
                        if seat_kbn == 1 {
                            is_seat_def = true
                        }
                        takeSeatPlayers[index!].holder_no = seat_kbn == 1 ? "\(custmer["customer_no"].asInt!)" : custmer["customer_no_def"].asString!
                    } else {
                        if seat_kbn != 1 {
                            takeSeatPlayers[index!].holder_no = custmer["customer_no_def"].asString!
                        }
                    }
                } else {                // ない場合
                    if custmer["customer_no"].asInt! > 0 {
                        if seat_kbn == 1 {
                            is_seat_def = true
                        }
                        takeSeatPlayers.append(takeSeatPlayer(
                            seat_no     : custmer["seat_no"].asInt! - 1,
                            holder_no   : seat_kbn == 1 ? "\(custmer["customer_no"].asInt!)" : custmer["customer_no_def"].asString!
                            )
                        )
                    } else {
                        if seat_kbn != 1 {
                            takeSeatPlayers.append(takeSeatPlayer(
                                seat_no     : custmer["seat_no"].asInt! - 1,
                                holder_no   : custmer["customer_no_def"].asString!
                                )
                            )
                        }
                    }
                }
                
            } else {
                // 同じシート番号がすでにあるか？
                let index = takeSeatPlayers.index(where: {$0.seat_no == custmer["seat_no"].asInt! - 1})
                if index == nil {       // 無い時だけ追加
                    if seat_kbn == 1 {
                        is_seat_def = true
                    }
                    takeSeatPlayers.append(takeSeatPlayer(
                        seat_no     : custmer["seat_no"].asInt! - 1,
                        holder_no   : seat_kbn == 1 ? custmer["customer_no"].asString! : custmer["customer_no_def"].asString!
                        )
                    )
                }
            }
        }
        let index = takeSeatPlayers.index(where: {$0.holder_no != "" && is_seat_def == true})
        if index == nil {
            print("Pushed 新規")
//            takeSeatPlayers = []
            
            fmdb.table_master_save(tableno, json_data: json_table["t_order_seat"])
            
            self.dispatch_async_main {
                self.spinnerEnd()
                globals_is_new = 1
                select_menu_categories = []
                MainMenu = []
                
                let nextDisp = is_timezone == 1 ? "toTimezoneViewSegue" : "toPlayerssetViewSegue"
                self.performSegue(withIdentifier: nextDisp,sender: nil)
                
                self.button_off()
                return
            }
        }
        
        self.dispatch_async_main {
            self.spinnerEnd()
            let alertController = UIAlertController(title: "退席確認", message: "新規注文ですか？追加注文ですか？", preferredStyle: .actionSheet)
            
            if UIDevice.current.userInterfaceIdiom == .phone {
                print("iPhone")
            }else if UIDevice.current.userInterfaceIdiom == .pad{
                print("iPad")
                alertController.popoverPresentationController!.sourceView = self.view;
                alertController.popoverPresentationController!.sourceRect = CGRect(x: self.view.bounds.size.width / 2, y: self.view.bounds.size.height / 2, width: 1.0, height: 1.0);
                alertController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.up
            }else{
                print("Unspecified")
            }
            
            let firstAction = UIAlertAction(title: "新規注文", style: .default){
                action in
                // タップ音
                TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                
                print("Pushed 新規")
                
                //　テーブル情報取得
                seat = []
                takeSeatPlayers = []
                
                fmdb.table_master_save(tableno, json_data: json_table["t_order_seat"])
                
                for (_,custmer) in json_table["t_order_seat"]{
                    let seat_kbn = custmer["seat_kbn"].asInt!
                    
                    if custmer["customer_no"].type == "Int" {
                        if custmer["customer_no"].asInt! > 0 {
                            takeSeatPlayers.append(takeSeatPlayer(
                                seat_no:    custmer["seat_no"].asInt! - 1,
                                holder_no:  seat_kbn == 1 ? "" : custmer["customer_no_def"].asString!
                                )
                            )
                        }
                        
                    } else {
                        takeSeatPlayers.append(takeSeatPlayer(
                            seat_no:    custmer["seat_no"].asInt! - 1,
                            holder_no:  seat_kbn == 1 ? "" : custmer["customer_no_def"].asString!
                            )
                        )
                    }
                    
                }
                
                self.dispatch_async_main {
                    self.spinnerEnd()
                    globals_is_new = 1
                    select_menu_categories = []
                    MainMenu = []
                    
                    let nextDisp = is_timezone == 1 ? "toTimezoneViewSegue" : "toPlayerssetViewSegue"
                    self.performSegue(withIdentifier: nextDisp,sender: nil)
                    
                    // 時間帯設定画面に移動
                    //                    self.performSegue(withIdentifier:"toTimezoneViewSegue",sender: nil)
                    self.button_off()
                    
                }
            }
            let secondAction = UIAlertAction(title: "追加注文", style: .default){
                action in
                // タップ音
                TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                
                print("Pushed 追加")
                globals_is_new = 2
                
                
                fmdb.table_master_save(tableno, json_data: json_table["t_order_seat"])
                
                //　テーブル情報取得
                takeSeatPlayers = []
                let db = FMDatabase(path: self._path)
                // データベースをオープン
                db.open()
                for (_,custmer) in json_table["t_order_seat"]{
                    
                    if custmer["customer_no"].type == "Int" {
                        // 同じシート番号がすでにあるか？
                        let index = takeSeatPlayers.index(where: {$0.seat_no == custmer["seat_no"].asInt! - 1})
                        if index != nil {       // ある場合
                            if custmer["customer_no"].asInt! > 0 {
                                takeSeatPlayers[index!].holder_no = "\(custmer["customer_no"].asInt!)"
                            }
                        } else {                // ない場合
                            if custmer["customer_no"].asInt! > 0 {
                                takeSeatPlayers.append(takeSeatPlayer(
                                    seat_no:    custmer["seat_no"].asInt! - 1,
                                    holder_no:  "\(custmer["customer_no"].asInt!)"
                                    )
                                )
                            }
                        }
                        
                    } else {
                        // 同じシート番号がすでにあるか？
                        let index = takeSeatPlayers.index(where: {$0.seat_no == custmer["seat_no"].asInt! - 1})
                        if index == nil {       // 無い時だけ追加
                            takeSeatPlayers.append(takeSeatPlayer(
                                seat_no:    custmer["seat_no"].asInt! - 1,
                                holder_no:  custmer["customer_no"].asString!
                                )
                            )
                        }
                    }
                    
                    
                }
                db.close()
                
                // seat_holder テーブルの中身を削除
                db.open()
                let sql1 = "DELETE FROM seat_holder;"
                let _ = db.executeUpdate(sql1, withArgumentsIn: [])
                
                let sql2 = "INSERT INTO seat_holder (seat_no,holder_no) VALUES (?,?);"
                db.beginTransaction()
                for num in 0..<takeSeatPlayers.count {
                    let success = db.executeUpdate(sql2, withArgumentsIn: [takeSeatPlayers[num].seat_no,takeSeatPlayers[num].holder_no])
                    if !success {
                        print("insert error!!")
                    }
                }
                db.commit()
                db.close()
                
                self.dispatch_async_main {
                    self.spinnerEnd()
                    select_menu_categories = []
                    MainMenu = []
                    self.performSegue(withIdentifier: "toPlayerssetViewSegue",sender: nil)
                    self.button_off()
                    
                }
            }
            let cancelAction = UIAlertAction(title: "戻る", style: .cancel){
                action in
                self.dispatch_async_main {
                    self.spinnerEnd()
                    self.button_off()
                    
                }
                print("Pushed cancel")
            }
            
            alertController.addAction(firstAction)
            alertController.addAction(secondAction)
            alertController.addAction(cancelAction)
            
            //            alertController.popoverPresentationController?.sourceRect = CGRect(x:(sender.frame.width/2),y:sender.frame.height,width:0,height:0)
            alertController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.up
            
            self.present(alertController, animated: true, completion: nil)
        }
        
    }
    
    // 保留データがある時に呼ばれる
    func free_seat_check2(_ tableno:Int) {
        var status = 0
        
        let url = urlString + "GetTableInfoUndo"
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForResource = 10 // seconds
        
        self.alamofireManager = Alamofire.SessionManager(configuration: configuration)
        self.alamofireManager!.request( url, parameters: ["Store_CD":shop_code.description,"Table_NO":"\(tableno)"])
            .responseJSON{ response in
                // エラーの時
                if response.result.error != nil {
                    self.dispatch_async_main {
                        self.spinnerEnd()
                        let e = response.result.description
                        self.jsonError(self.jsonErrorMsg)
                    
                        self.button_off()
                    
                        print(e)
                        return;
                    }
                } else {
                    let json_table = JSON(response.result.value!)
                    print(#function,json_table)
                    if json_table.asError != nil {
                        self.spinnerEnd()
                        let e = json_table.asError
                        self.jsonError(self.jsonErrorMsg)
                        self.button_off()
                        
                        print(e as Any)
                        return;
                    } else {
                        for (key,value) in json_table {
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

                        status = json_table["t_order_seat"][0]["status_kbn"].asInt!
                        globals_is_new_wait = status == 9 ? json_table["t_order_seat"][0]["reserved_kbn"].asInt! + 1 : 0
                        
                        if status == -1 {
                            self.spinnerEnd()
                            self.dispatch_async_main {
                                let msg = "テーブル番号「" + "\(tableno)" + "」は存在しません"
                                self.jsonError(msg)
                                self.button_off()
                            }
                            return;
                        } else {
                            
                            if status == 1 || (status == 9 && globals_is_new_wait == 1) {
                                //　テーブル情報取得
                                takeSeatPlayers = []
                                
                                fmdb.table_master_save(tableno, json_data: json_table["t_order_seat"])
                                
                                for (_,custmer) in json_table["t_order_seat"]{
                                    if custmer["customer_no"].type == "Int" {
                                        if custmer["customer_no"].asInt! > 0 {
                                            takeSeatPlayers.append(takeSeatPlayer(
                                                seat_no:    custmer["seat_no"].asInt! - 1,
                                                holder_no:  "\(custmer["customer_no"].asInt!)"
                                                )
                                            )
                                        }
                                        
                                    } else {
                                        takeSeatPlayers.append(takeSeatPlayer(
                                            seat_no:    custmer["seat_no"].asInt! - 1,
                                            holder_no:  custmer["customer_no"].asString!
                                            )
                                        )
                                    }
                                    
                                }
                                
                                self.dispatch_async_main {
                                    self.spinnerEnd()
                                    globals_is_new = 1
                                    // 時間帯設定画面に移動
                                    let nextDisp = is_timezone == 1 ? "toTimezoneViewSegue" : "toPlayerssetViewSegue"
                                    self.performSegue(withIdentifier:nextDisp,sender: nil)
                                    self.button_off()
                                }
                                
                            } else {
                                self.free_seat_check(json_table,tableno: tableno)

                            }
                        }
                    }
                }
        }
    }
    
    
    func free_seat_check_demo(_ tableno:Int) {
        
        let db = FMDatabase(path: self._path)
        
        db.open()
        
        let sql1 = "SELECT * FROM seat_master WHERE table_no = ? ORDER BY seat_no;"
        let results1 = db.executeQuery(sql1, withArgumentsIn: [tableno])
        seat = []
        self.seat_holder_kbns = []
        
        while (results1?.next())! {
            seat.append(seat_info(
                seat_no         : Int((results1?.int(forColumn:"seat_no"))!),
                seat_name       : (results1?.string(forColumn:"seat_name"))!,
                disp_position   : Int((results1?.int(forColumn:"disp_position"))!),
                seat_kbn        : Int((results1?.int(forColumn:"seat_kbn"))!)
                )
            )
            
            if results1?.string(forColumn:"holder_no") != "" && results1?.string(forColumn:"holder_no") != nil {
                self.seat_holder_kbns.append(seat_holder_kbn(
                    seat_no     :Int((results1?.int(forColumn:"seat_no"))!),
                    holder_no   : (results1?.string(forColumn:"holder_no"))!,
                    order_kbn   : Int((results1?.int(forColumn:"order_kbn"))!)
                    )
                )
            }
        }

        db.close()
        
        if seat_holder_kbns.count <= 0 {
            // 手書き削除
            fmdb.remove_hand_image()
            
            globals_pm_start_time = ""
            
            takeSeatPlayers = []
            globals_is_new = 1
            
            let nextDisp = is_timezone == 1 ? "toTimezoneViewSegue" : "toPlayerssetViewSegue"
            self.performSegue(withIdentifier: nextDisp,sender: nil)
            
            self.button_off()
            return;
        }
        
        
        // 送信データがあるかチェック
        let alertController = UIAlertController(title: "退席確認", message: "新規注文ですか？追加注文ですか？", preferredStyle: .actionSheet)
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            print("iPhone")
        }else if UIDevice.current.userInterfaceIdiom == .pad{
            print("iPad")
            alertController.popoverPresentationController!.sourceView = self.view;
            alertController.popoverPresentationController!.sourceRect = CGRect(x: self.view.bounds.size.width / 2, y: self.view.bounds.size.height / 2, width: 1.0, height: 1.0);
            alertController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.up
        }else{
            print("Unspecified")
        }
        
        
        let firstAction = UIAlertAction(title: "新規注文", style: .default){
            action in
            // タップ音
            TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
            
            print("Pushed 新規")
            // 手書き削除
            fmdb.remove_hand_image()
            
            globals_pm_start_time = ""
            
            takeSeatPlayers = []
            globals_is_new = 1
            
            let nextDisp = is_timezone == 1 ? "toTimezoneViewSegue" : "toPlayerssetViewSegue"
            self.performSegue(withIdentifier: nextDisp,sender: nil)
            
            self.button_off()
            
        }
        let secondAction = UIAlertAction(title: "追加注文", style: .default){
            action in
            // タップ音
            TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
            
            print("Pushed 追加")
                        
            // 手書き削除
            fmdb.remove_hand_image()
            
            globals_pm_start_time = ""
            globals_is_new = 2
            
            takeSeatPlayers = []
        
            for seat_hk in self.seat_holder_kbns {
                takeSeatPlayers.append(takeSeatPlayer(
                    seat_no: seat_hk.seat_no,
                    holder_no: seat_hk.holder_no
                    )
                )
            }
            
            self.performSegue(withIdentifier: "toPlayerssetViewSegue",sender: nil)
            self.button_off()
            
        }
        let cancelAction = UIAlertAction(title: "戻る", style: .cancel){
            action in
            // タップ音
            TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
            self.button_off()
            print("Pushed cancel")
        }
        
        alertController.addAction(firstAction)
        alertController.addAction(secondAction)
        alertController.addAction(cancelAction)
        //For iPad And Univasal Device
        //        alertController.popoverPresentationController?.sourceView = sender as? UIView
        //            alertController.popoverPresentationController?.sourceRect = CGRect(x:(sender.frame.width/2),y:sender.frame.height,width:0,height:0)
        //            alertController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.Up
        
        present(alertController, animated: true, completion: nil)
        
        return;
        
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

    //StringをUIImageに変換する
    func String2Nsdata(_ imageString:String) -> Data?{
        
        //空白を+に変換する
        let base64String = imageString.replacingOccurrences(of: " ", with:"+")
        
        //BASE64の文字列をデコードしてNSDataを生成
        let decodeBase64:Data? =
            Data(base64Encoded:base64String, options: NSData.Base64DecodingOptions.ignoreUnknownCharacters)
        
        if let decodeSuccess = decodeBase64 {
            
            return decodeSuccess
        }
        
        return nil
        
    }
    
}
