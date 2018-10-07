//
//  reminingCountSetViewController.swift
//  iOrder
//
//  Created by 山尾守 on 2016/07/25.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit
import FontAwesomeKit
import FMDB

class reminingCountSetViewController: UIViewController,UINavigationBarDelegate {

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

    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var reminingResetButton: UIButton!
    @IBOutlet weak var reminingCountText: UITextField!
    @IBOutlet weak var navBar: UINavigationBar!

    // 文字数最大を決める.
    let maxLength: Int = 4
    
    // DBファイルパス
    var _path:String = ""
    
    let initVal = CustomProgressModel()

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

        // 残数削除ボタン
        iconImage = FAKFontAwesome.trashIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
        //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
        Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        reminingResetButton.setImage(Image, for: UIControlState())

        
        // メニュー名
        self.navBar.topItem?.title = (globals_select_menu_no.menu_name)
        
        // /Documentsまでのパスを取得
        let paths = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask, true)
        
        // 使用DB
        var use_db = production_db
        if demo_mode != 0{
            use_db = demo_db
        }
        _path = (paths[0] as NSString).appendingPathComponent(use_db)
        
        //残数取得
        let remining_count = self.getremainCount(globals_select_menu_no.menu_no)

        if remining_count >= 0 {
            self.reminingCountText.text = "\(remining_count)"
            okButton.isEnabled = true
            okButton.alpha = 1.0
            clearButton.isEnabled = true
            clearButton.alpha = 1.0
        } else {
            self.button_off()
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        dispatch_once(&self.onceTokenViewDidAppear) {
            DemoLabel.Show(self.view)
//        }
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
//        AVAudioPlayerUtil.play()
        
        // 数字未入力の時
        if (reminingCountText.text?.characters.count)! <= 0 {
            // UIAlertController を作成
            let alertController2 = UIAlertController(title: "エラー！", message: "数を入力してください", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel){
                action in print("Pushed OK")
                self.button_off()
//                self.reminingCountText.text = ""
                return;
            }
            alertController2.addAction(cancelAction)
            present(alertController2, animated: true, completion: nil)
            return;
        }
        
        if demo_mode == 0 {
            
            self.spinnerStart()
            
            self.dispatch_async_global{
                let url = urlString + "SendRemainNum?Store_CD=" + shop_code.description + "&" + "Menu_CD=" + "\(globals_select_menu_no.menu_no)" + "&" + "Remain_Num=" + self.reminingCountText.text!
                
                let json = JSON(url: url)
                
                // エラーの時
                if json.asError != nil {
                    self.dispatch_async_main{
                        let alertController = UIAlertController(title: "確認", message: "残数登録の送信に失敗しました。\n未送信データに登録しますか？", preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "はい", style: .default){
                            action in
                            // タップ音
                            TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                            print("Pushed はい")
                            let db = FMDatabase(path: self._path)
                            
                            // データベースをオープン
                            db.open()
                            
                            var argumentArray:Array<Any> = []
                            let now = Date() // 現在日時の取得
                            let dateFormatter = DateFormatter()
                            dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
                            dateFormatter.timeStyle = .short
                            dateFormatter.dateStyle = .short
                            
                            let created = dateFormatter.string(from: now)
                            
                            argumentArray.append(2)
                            argumentArray.append(NSNumber(value: globals_select_menu_no.menu_no as Int64))
                            argumentArray.append(Int(self.reminingCountText.text!)!)
                            argumentArray.append(created)
                            
                            let sql = "INSERT INTO resending(resend_kbn,resend_no,resend_count,sendtime) VALUES (?,?,?,?)"
                            let success = db.executeUpdate(sql, withArgumentsIn: argumentArray)
                            if !success {
                                // エラー時
                                print(success.description)
                            }
                            
                            self.dispatch_async_main{
                                self.spinnerEnd()
                                self.button_off()
                                self.performSegue(withIdentifier: "toRemainingCountSetViewSegue",sender: nil)
                                return;
                            }
                            
                            return;
                        }
                        
                        let cancelAction = UIAlertAction(title: "いいえ", style: .cancel){
                            action in
                            // タップ音
                            TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                            print("Pushed いいえ")
                            self.dispatch_async_main{
                                self.spinnerEnd()
                                self.button_off()
                                return;
                            }
                            
                            return;
                        }
                        alertController.addAction(OKAction)
                        alertController.addAction(cancelAction)
                        self.present(alertController, animated: true, completion: nil)
                        return;
                    }
                } else {
                    print(json)
                    for (key, value) in json {
                        if key as! String == "Return" {
                            if value.toString() == "true" {
                                self.remain_Data_DB_save()
                                self.dispatch_async_main{
                                    self.spinnerEnd()
                                    self.performSegue(withIdentifier: "toRemainingCountSetViewSegue",sender: nil)
                                    self.button_off()
                                }
                            }
                        }
                        if key as! String == "Message" {
                            if value.toString() != "" {
                                self.dispatch_async_main{
                                    self.spinnerEnd()
                                    let msg = value.toString()
                                    print(msg)
                                    self.return_error(msg)
                                    self.button_off()
                                }
                            }
                        }
                    }
                    
                }

            }
            
        } else {    // デモモードの時
            self.remain_Data_DB_save()
            self.spinnerEnd()
            self.performSegue(withIdentifier: "toRemainingCountSetViewSegue",sender: nil)
            self.button_off()
        }
    }
    
    func remain_Data_DB_save() {
        let db = FMDatabase(path: _path)
        
        // データベースをオープン
        db.open()
        let sql = "SELECT count(*) FROM items_remaining WHERE item_no = ?;"
        
        let results = db.executeQuery(sql, withArgumentsIn: [NSNumber(value: globals_select_menu_no.menu_no as Int64)])
        while (results?.next())! {
            
            let now = Date() // 現在日時の取得
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
            dateFormatter.timeStyle = .medium
            dateFormatter.dateStyle = .medium
            let created = dateFormatter.string(from: now)
            let modified = dateFormatter.string(from: now)
            
            // テーブルNOがない場合
            if (results?.int(forColumnIndex: 0))! <= 0 {
                let sql2 = "INSERT INTO items_remaining (item_no , remaining_count, created , modified) VALUES (?,?,?,?);"
                db.beginTransaction()
                let success = db.executeUpdate(sql2, withArgumentsIn: [NSNumber(value: globals_select_menu_no.menu_no as Int64),Int(reminingCountText.text!)!,created,modified])
                if !success {
                    print("insert error!!")
                }
                db.commit()
                
            } else {
                print("update")
                let sql3 = "UPDATE items_remaining SET remaining_count = :COUNT ,modified = :MODIFI WHERE item_no = :ITEM;"
                
                // 名前を付けたパラメータに値を渡す場合
                let results2 = db.executeUpdate(sql3, withParameterDictionary: ["COUNT":Int(reminingCountText.text!)!, "MODIFI":modified,"ITEM":NSNumber(value: globals_select_menu_no.menu_no as Int64)])
                if !results2 {
                    // エラー時
                    print(results2.description)
                }
            }
        }

    }
    
    // 数字ボタンタップ
    func noButtomTap(_ sender: UIButton){
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        // 入力済みの文字と入力された文字を合わせて取得.
        if reminingCountText.text! != "0" {
            let str = reminingCountText.text! + "\(sender.tag - 1)"
            // 文字数がmaxLength以下ならh表示する.
            if str.characters.count <= maxLength {
                reminingCountText.textAlignment =   NSTextAlignment.right
                reminingCountText.text = str
                // 確定ボタンは残数入力時だけ押せるようにする。
                okButton.isEnabled = true
                okButton.alpha = 1.0
                clearButton.isEnabled = true
                clearButton.alpha = 1.0
                
            } else {
                print( "\(maxLength)" + "文字を超えています")
            }
            
        }
    }

    // クリアボタンタップ
    @IBAction func clearButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
//        AVAudioPlayerUtil.play()
        
        // 残数 入力エリアをクリアする
        reminingCountText.text = ""
//        reminingCountText.textAlignment = NSTextAlignment.Left
        // 確定ボタンはテーブルNO入力時だけ押せるようにする。
        self.button_off()
//        okButton.enabled = false
//        okButton.alpha = 0.6
        
    }

    // 戻るボタンタップ
    @IBAction func backButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        self.performSegue(withIdentifier: "toRemainingCountSetViewSegue",sender: nil)
    }

    // 残数解除(-1を送信)
    @IBAction func remainingCountResetButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        let alertController = UIAlertController(title: "残数解除", message: "残数登録を解除します。\nよろしいですか？", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel){
            action in print("Pushed cancel")
            // タップ音
            TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

            return;
        }
        
        let okAction = UIAlertAction(title: "OK", style: .default){
            action in
            print("Pushed OK")
            // タップ音
            TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

            if demo_mode == 0 {
                self.spinnerStart()
                
                self.dispatch_async_global{
                    let url = urlString + "SendRemainNum?Store_CD=" + shop_code.description + "&" + "Menu_CD=" + "\(globals_select_menu_no.menu_no)" + "&" + "Remain_Num=" + "-1"
                    
                    let json = JSON(url: url)
                    
                    // エラーの時
                    if json.asError != nil {
                        self.dispatch_async_main{
                            let alertController = UIAlertController(title: "確認", message: "残数解除に失敗しました。\n通信状態を確認してください", preferredStyle: .alert)
                            let OKAction = UIAlertAction(title: "はい", style: .default){
                                action in
                                // タップ音
                                TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                                print("Pushed はい")
                                
                                return;
                            }
                            
                            alertController.addAction(OKAction)
                            self.present(alertController, animated: true, completion: nil)
                            return;
                        }
                    } else {
                        print(json)
                        var is_cancel_error = false
                        for (key, value) in json {
                            if key as! String == "Return" {
                                if value.toString() == "true" {
                                    self.remain_Data_DB_clear()
                                    self.dispatch_async_main{
                                        self.spinnerEnd()
                                        self.performSegue(withIdentifier: "toRemainingCountSetViewSegue",sender: nil)
                                        self.button_off()
                                    }
                                } else {
                                    is_cancel_error = true
                                }
                            }
                            if key as! String == "Message" {
                                if value.toString() != "" {
                                    self.dispatch_async_main{
                                        self.spinnerEnd()
                                        let msg = value.toString()
                                        print(msg)
                                        self.return_error(msg)
                                        self.button_off()
                                        is_cancel_error = false
                                    }
                                }
                            }
                            if is_cancel_error {
                                self.dispatch_async_main{
                                    self.spinnerEnd()
                                    let msg = "残数解除が出来ませんでした。"
                                    print(msg)
                                    self.return_error(msg)
                                    self.button_off()
                                    is_cancel_error = !is_cancel_error
                                }
                            }
                        }
                        
                    }
                    
                }

//                self.spinnerStart()
//                
//                self.dispatch_async_global {
//                    let url = urlString + "SendRemainNum?Store_CD=" + shop_code.description + "&" + "Menu_CD=" + "\(globals_select_menu_no.menu_no)" + "&" + "Remain_Num=" + "-1"
//                    
//                    let json = JSON(url: url)
//                    if json.asError != nil {
//                        self.spinnerEnd()
//                        self.dispatch_async_main{
//                            let e = json.asError
//                            print(e)
//                            self.jsonError()
//                            
//                        }
//                        
//                    }
//                    
//                }
                
            } else {    // デモモードの時
                self.remain_Data_DB_clear()
                self.spinnerEnd()
                self.performSegue(withIdentifier: "toRemainingCountSetViewSegue",sender: nil)
                self.button_off()
                return;
            }
            
            
//            // 使用DB
//            var use_db = production_db
//            if demo_mode != 0{
//                use_db = demo_db
//            }
//            
//            // /Documentsまでのパスを取得
//            let paths = NSSearchPathForDirectoriesInDomains(
//                .DocumentDirectory,
//                .UserDomainMask, true)
//            let _path = (paths[0] as NSString).stringByAppendingPathComponent(use_db)
//            
//            // FMDatabaseクラスのインスタンスを作成
//            // 引数にファイルまでのパスを渡す
//            let db = FMDatabase(path: _path)
//            
//            // seat_holder テーブルの中身を削除
//            db.open()
//            let sql = "DELETE FROM items_remaining WHERE item_no = ?;"
//            let _ = db.executeUpdate(sql, withArgumentsIn: [globals_select_menu_no.menu_no])
//            db.close()
//            
//            self.performSegue(withIdentifier:"toRemainingCountSetViewSegue",sender: nil)
//            self.button_off()
//            
//            return;
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)

    }
    
    func remain_Data_DB_clear() {
        
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
        
        // seat_holder テーブルの中身を削除
        db.open()
        let sql = "DELETE FROM items_remaining WHERE item_no = ?;"
        let _ = db.executeUpdate(sql, withArgumentsIn: [NSNumber(value: globals_select_menu_no.menu_no as Int64)])
        db.close()
        
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
    
    func jsonError(){
        // エラー音
        TapSound.buttonTap(err_sound_file.sound_file, type: err_sound_file.file_type)

        // エラー表示        
        CustomProgress.Instance.mrprogress.dismiss(true)
        //        self.spinnerEnd()
        let alertController = UIAlertController(title: "エラー！", message: "残数登録の送信に失敗しました。\n再送信を行ってください。", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default){
            action in print("Pushed OK")
            return;
        }
        
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
        
    }

    func return_error(_ msg:String){
        let alertController = UIAlertController(title: "エラー！", message: msg , preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default){
            action in print("Pushed OK")
            return;
        }
        
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
        
    }
    
    func button_off(){
        self.reminingCountText.text = ""
        okButton.isEnabled = false
        okButton.alpha = 0.6
        
        clearButton.isEnabled = false
        clearButton.alpha = 0.6
        
    }

    // 残数情報を取得する
    func getremainCount(_ menu_no:Int64) -> Int {
        let db = FMDatabase(path: _path)
        
        // データベースをオープン
        db.open()
        
        let sql = "select * from items_remaining where item_no = ?;"
        let results = db.executeQuery(sql, withArgumentsIn: [NSNumber(value: menu_no as Int64)])
        
        var count = -1
        while (results?.next())! {
            count = Int((results?.int(forColumn:"remaining_count"))!)
        }
        db.close()
        
        return count
    }

    
}
