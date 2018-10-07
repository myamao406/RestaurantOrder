//
//  cancelTableNoViewController.swift
//  iOrder
//
//  Created by 山尾守 on 2016/07/27.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit
import FontAwesomeKit
import FMDB

class cancelTableNoViewController: UIViewController,UINavigationBarDelegate,UIActionSheetDelegate {
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
    
    @IBOutlet weak var tebleNoTextField: UITextField!
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var navBar: UINavigationBar!

    
    //CustomProgressModelにあるプロパティが初期設定項目
    let initVal = CustomProgressModel()

    let message = "テーブル番号の取得に失敗しました。"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navBar.delegate = self
        navBar.barTintColor = iOrder_titleBlueColor

        let noKeyButton:[UIButton] = [button0,button1,button2,button3,button4,button5,button6,button7,button8,button9]
        
        for num in 0..<noKeyButton.count {
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
        self.button_off()
        
        // メニューテーブルがあるか確認
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
        let _path = (paths[0] as NSString).appendingPathComponent(use_db)
        // FMDatabaseクラスのインスタンスを作成
        // 引数にファイルまでのパスを渡す
        let db = FMDatabase(path: _path)
        
        // データベースをオープン
        db.open()
        let sql = "SELECT count(*) FROM menus_master"
        let results = db.executeQuery(sql, withArgumentsIn: [])
        
        var cnt = 0
        while (results?.next())! {
            cnt = Int((results?.int(forColumnIndex:0))!)
        }
        
        db.close()

        if cnt <= 0 {
            let alertController = UIAlertController(title: "エラー！", message: "メニュー情報がありません。\nデータ取り込みを再度実施して下さい。", preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "OK", style: .default){
                action in print("Pushed OK")
                
                return;
            }
            
            alertController.addAction(okAction)
            UIApplication.shared.topViewController()?.present(alertController, animated: true, completion: nil)
            
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
//        AVAudioPlayerUtil.play()
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        // 数字未入力の時
        if (tebleNoTextField.text?.characters.count)! <= 0 {
            // UIAlertController を作成
            let alertController2 = UIAlertController(title: "エラー！", message: "番号を入力してください", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel){
                action in print("Pushed OK")
//                self.tebleNoTextField.textAlignment = NSTextAlignment.Left
//                self.tebleNoTextField.text = ""
                self.button_off()
                return;
            }
            alertController2.addAction(cancelAction)
            present(alertController2, animated: true, completion: nil)
            return;
            
        }
        
        let tableno:Int = Int(tebleNoTextField.text!)!

        globals_table_no = tableno
        
        // 本番モード
        if demo_mode == 0 {
            self.spinnerStart()
            dispatch_async_global {
            // 取消
                let url = urlString + "CheckTable?Store_CD=" + shop_code.description + "&" + "Table_NO=" + "\(tableno)" + "&" + "Process_Div=9"
                print(url)
                let json = JSON(url: url)
                if json.asError == nil {
                    print("json", json)
                    for (key, value) in json {
                        if key as! String == "Return" {
                            if value.toString() == "false" {
                                self.dispatch_async_main {
                                    self.spinnerEnd()
                                    self.jsonError("テーブル番号：" + "\(tableno)" + "はありません。")
                                    self.button_off()
                                    return;
                                }
                            }
                        } else if key as! String == "status_kbn" {
                            if value.asInt == 1 || value.asInt == 9 {
                                self.dispatch_async_main {
                                    self.spinnerEnd()
                                    self.jsonError("取消データはありません。")
                                    self.button_off()
                                    return;
                                }
                            } else {
                                self.dispatch_async_main {
                                    self.spinnerEnd()
                                    //                                self.tebleNoTextField.text = ""
                                    self.button_off()
                                    self.performSegue(withIdentifier: "toCancelOrderSelectViewSegue",sender: nil)
                                }
                                
                            }
                        }
                    }
                } else {
                    self.dispatch_async_main {
                        self.spinnerEnd()
                        let e = json.asError
                        self.jsonError(self.message)
                        self.button_off()
                        print(e as Any)
                    }
                }
            
            }
//            self.spinnerEnd()
//            
//            self.performSegue(withIdentifier:"toCancelOrderSelectViewSegue",sender: nil)

        } else {    // デモモード
            // まずテーブルNOが存在するか確認
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
            let _path = (paths[0] as NSString).appendingPathComponent(use_db)
            // FMDatabaseクラスのインスタンスを作成
            // 引数にファイルまでのパスを渡す
            let db = FMDatabase(path: _path)
            
            
            // データベースをオープン
            db.open()
            let sql = "SELECT count(*) FROM table_no WHERE table_no = ?;"
            
            let results = db.executeQuery(sql, withArgumentsIn: [tableno])
            while (results?.next())! {
                // テーブルNOがない場合
                if (results?.int(forColumnIndex:0))! <= 0 {
                    // エラー表示
                    let alertController = UIAlertController(title: "エラー！", message: "テーブル番号「" + "\(tableno)" + "」は存在しません", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "OK", style: .cancel){
                        action in print("Pushed OK")
//                        self.tebleNoTextField.textAlignment = NSTextAlignment.Left
//                        self.tebleNoTextField.text = ""
                        self.button_off()
                        return;
                    }
                    alertController.addAction(cancelAction)
                    present(alertController, animated: true, completion: nil)
                    
                    return;
                    // 登録されている場合
                }
            }
            
            let sql1 = "SELECT count(*) FROM ((iorder INNER JOIN iorder_detail ON iorder.facility_cd = iorder_detail.facility_cd AND iorder.order_no = iorder_detail.order_no ) INNER JOIN seat_master ON iorder_detail.serve_customer_no = seat_master.holder_no AND iorder_detail.seat_no = seat_master.seat_no) WHERE seat_master.table_no = ? AND iorder_detail.qty != 0 AND iorder_detail.detail_kbn != 9;"
            
            let results1 = db.executeQuery(sql1, withArgumentsIn: [tableno])
            while (results1?.next())! {
                // テーブルNOがない場合
                if (results1?.int(forColumnIndex:0))! <= 0 {
                    // エラー表示
                    let alertController = UIAlertController(title: "エラー！", message: "テーブル番号「" + "\(tableno)" + "」で取消できるオーダーはありません", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "OK", style: .cancel){
                        action in print("Pushed OK")
                        self.tebleNoTextField.textAlignment = NSTextAlignment.left
                        self.tebleNoTextField.text = ""
                        return;
                    }
                    alertController.addAction(cancelAction)
                    present(alertController, animated: true, completion: nil)
                    
                    return;
                }
            }
            self.button_off()
            self.performSegue(withIdentifier: "toCancelOrderSelectViewSegue",sender: nil)
        }
    }
    
    // 数字ボタンタップ
    func noButtomTap(_ sender: UIButton){
        // タップ音
//        AVAudioPlayerUtil.play()
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        // 入力済みの文字と入力された文字を合わせて取得.
        var str = tebleNoTextField.text! + "\(sender.tag - 1)"
        
        if !(str.characters.count == 1 && sender.tag == 1){
            // 文字数がtableNoMaxLength以下ならh表示する.
            if str.characters.count <= tableNoMaxLength {
                tebleNoTextField.textAlignment =   NSTextAlignment.right
                tebleNoTextField.text = str
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
//            okButton.enabled = false
//            okButton.alpha = 0.6
            
        }
    }

    // クリアボタンタップ
    @IBAction func clearButtonTap(_ sender: AnyObject) {
        // タップ音
//        AVAudioPlayerUtil.play()
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        // テーブルNo 入力エリアをクリアする
        self.button_off()
//        tebleNoTextField.text = ""
//        tebleNoTextField.textAlignment = NSTextAlignment.Left
//        // 確定ボタンはテーブルNO入力時だけ押せるようにする。
//        okButton.enabled = false
//        okButton.alpha = 0.6
        
    }
    
    // 戻るボタンタップ
    @IBAction func backButtonTap(_ sender: AnyObject) {
        // タップ音
//        AVAudioPlayerUtil.play()
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        self.performSegue(withIdentifier: "toTopViewSegue",sender: nil)
    }
    
    @IBAction func unwindToCancelTableNoInput(_ segue: UIStoryboardSegue) {
        
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
    
    func dispatch_async_main(_ block: @escaping () -> ()) {
        DispatchQueue.main.async(execute: block)
    }
    
    func dispatch_async_global(_ block: @escaping () -> ()) {
        DispatchQueue.global().async(execute: block)
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

    func button_off(){
        self.tebleNoTextField.textAlignment = NSTextAlignment.left
        self.tebleNoTextField.text = ""
        self.okButton.isEnabled = false
        self.okButton.alpha = 0.6
        self.clearButton.isEnabled = false
        self.clearButton.alpha = 0.6
    }

    
}
