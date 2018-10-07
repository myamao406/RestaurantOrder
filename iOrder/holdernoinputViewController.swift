
//
//  holdernoinputViewController.swift
//  iOrder
//
//  Created by 山尾守 on 2016/07/04.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit
import FontAwesomeKit
import FMDB
import Alamofire

class holdernoinputViewController: UIViewController,UINavigationBarDelegate {

    private lazy var __once: () = {
            // 本番モードのときだけ取り込む
            if demo_mode == 0 {
                // 使用DB
                var use_db = production_db
                if demo_mode != 0{
                    use_db = demo_db
                }
                // /Documentsまでのパスを取得
                let paths = NSSearchPathForDirectoriesInDomains(
                    .documentDirectory,
                    .userDomainMask, true)
                let path2 = (paths[0] as NSString).appendingPathComponent(use_db)
                let db = FMDatabase(path: path2)
                
                // データベースをオープン
                db.open()
                
                // お客様情報テーブルから更新日付の最大値を取得
                let sql = "select MAX(modified) from players;"
                let results = db.executeQuery(sql, withArgumentsIn: [])
                
                var updateTime = "1900/01/01 00:00:00"
                
                while (results?.next())! {
                    if results?.string(forColumnIndex: 0) != nil {
                        print(results?.string(forColumnIndex: 0) as Any)
                        updateTime = (results?.string(forColumnIndex: 0))!
                    }
                }
                
                playersClass.get(updateTime)
//                self.get_players()
            }
        
        }()

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
    
    @IBOutlet weak var nameSearchButton: UIButton!
    @IBOutlet weak var allOkButton: UIButton!
    @IBOutlet weak var holderNoTextField: UITextField!
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var rightBarButton: UIBarButtonItem!
    @IBOutlet weak var navBar: UINavigationBar!
    
    // シートNOとホルダ番号（ホルダNO入力画面がら戻ってくる値）
    struct seat_holder {
        var seat_no:Int
        var holder_no:String
    }
    var seat_holders:[seat_holder] = []
    
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
    
    // DBパス
    var _path = ""
    
    let initVal = CustomProgressModel()
    
    var alamofireManager : Alamofire.SessionManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navBar.delegate = self
        navBar.barTintColor = iOrder_titleBlueColor

        let noKeyButton:[UIButton] = [button0,button1,button2,button3,button4,button5,button6,button7,button8,button9]
        
        for num in 0...noKeyButton.count - 1 {
            let button :UIButton = noKeyButton[num]
            button.tag = num + 1
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

        // 名前検索ボタン
        iconImage = FAKFontAwesome.searchIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
        //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
        Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        nameSearchButton.setImage(Image, for: UIControlState())

        // 一括登録ボタン
        iconImage = FAKFontAwesome.checkCircleIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
        //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
        Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        allOkButton.setImage(Image, for: UIControlState())
        
        let selectedAttributes = [NSForegroundColorAttributeName : UIColor.white]
        
        let barItem = UIBarButtonItem(title: "テーブルNo: " + "\(globals_table_no)", style: .done, target: self, action: nil)
        
        barItem.setTitleTextAttributes(selectedAttributes, for: UIControlState())
        barItem.setTitleTextAttributes(selectedAttributes, for: .disabled)
        
        barItem.isEnabled = false
        navBar.topItem?.setRightBarButton(barItem, animated: false)
        
        
        self.button_off()

        // 使用DB
        var use_db = production_db
        if demo_mode != 0{
            use_db = demo_db
        }
        
        // /Documentsまでのパスを取得
        let paths = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask, true)
        _path = (paths[0] as NSString).appendingPathComponent(use_db)
        
        // FMDatabaseクラスのインスタンスを作成
        // 引数にファイルまでのパスを渡す
        let db = FMDatabase(path: _path)
        
        // seat_holder テーブルの中身を削除
        db.open()
        let sql = "DELETE FROM seat_holder;"
        let _ = db.executeUpdate(sql, withArgumentsIn: [])
        db.close()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _ = self.__once
        
        DemoLabel.Show(self.view)
        DemoLabel.modeChange()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // ステータスバーとナビゲーションバーの色を同じにする
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.topAttached
    }
    
    // ステータスバーの文字を白にする
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    // 数字ボタンタップ
    func noButtomTap(_ sender: UIButton){
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        // 文字数最大を決める.
        let maxLength: Int = 5
        
        // 入力済みの文字と入力された文字を合わせて取得.
        var str = holderNoTextField.text! + "\(sender.tag - 1)"
        
        if !(str.characters.count == 1 && sender.tag == 1){
            // 文字数がmaxLength以下ならh表示する.
            if str.characters.count <= maxLength {
                holderNoTextField.textAlignment = NSTextAlignment.right
                holderNoTextField.text = str
                allOkButton.isEnabled = true
                allOkButton.alpha = 1.0
                okButton.isEnabled = true
                okButton.alpha = 1.0
                clearButton.isEnabled = true
                clearButton.alpha = 1.0

            } else {
                print("5文字を超えています")
            }
        } else {
            str = ""
            allOkButton.isEnabled = false
            allOkButton.alpha = 0.6
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
//        AVAudioPlayerUtil.play()
        
        // テーブルNo 入力エリアをクリアする
        self.button_off()
        
    }
    
    // 一括登録ボタンタップ時
    @IBAction func allOkButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        // 入力確認
        // 数字未入力の時
        if (holderNoTextField.text?.characters.count)! <= 0 {
            // UIAlertController を作成
            let alertController2 = UIAlertController(title: "エラー！", message: "ホルダ番号を入力してください", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel){
                action in print("Pushed OK")
                self.button_off()
                return;
            }
            alertController2.addAction(cancelAction)
            present(alertController2, animated: true, completion: nil)
            return;
        }
        
        let holderno = Int(holderNoTextField.text!)
        
        let db = FMDatabase(path: _path)
        
        // データベースをオープン
        db.open()
        
        let rs = db.executeQuery(SELECT_PLAYERS, withArgumentsIn: [holderno!,shop_code,globals_today + "%"])
        
        var is_entity = false
        var status:Int = 0
        var g_no = -1
        
        while rs!.next() {
            is_entity = true
            
            status = Int(rs!.int(forColumn: "status"))
            g_no = Int(rs!.int(forColumn: "group_no"))
        }
        
        // データがない場合
        if is_entity == false {
            let alertController = UIAlertController(title: "エラー！", message: "ホルダ番号「" + "\(holderno!)" + "」" + "は存在しません。" , preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "OK", style: .default){
                action in print("Pushed OK")
                
                let sql2 = "INSERT INTO seat_holder (seat_no,holder_no) VALUES (?,?);"
                let success = db.executeUpdate(sql2, withArgumentsIn: [globals_select_seat_no,self.holderNoTextField.text!])
                if !success {
                    print("insert error!!")
                }
                
                self.button_off()
                
                self.spinnerEnd()
                return;
            }
            
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
        } else {
            switch status {
            case -1,3:    // -1:存在しない 2:チェックアウト済み　3:キャンセル　9:予約
                var message = ""
                switch status {
                case -1:
                    message = "は\n存在しません。"
                    break
                case 2:
                    message = "は\nチェックアウト済みです。"
                    break
                case 3:
                    message = "は\nキャンセルされています。"
                    break
                case 9:
                    message = "は\n予約されています。"
                    break
                default:
                    message = "は\n存在しません。"
                    break
                }
                
                let alertController = UIAlertController(title: "エラー！", message: "ホルダ番号「" + "\(holderno!)" + "」" + message , preferredStyle: .alert)
                
                let okAction = UIAlertAction(title: "OK", style: .default){
                    action in print("Pushed OK")
                    
                    self.button_off()
                    
                    return;
                }
                
                alertController.addAction(okAction)
                present(alertController, animated: true, completion: nil)
                return;
                
            case 0,1:     // チェックイン
                if g_no == -1 {     // グループNOがない場合
                    if self.set_folder_number(holderno!) == false {
                        print("error")
                    } else {
                        self.performSegue(withIdentifier: "toPlayerssetSegue",sender: nil)
                        self.button_off()
                    }
                } else {
                    set_folder_numbers(holderno!, success: {() -> Void in
                        self.performSegue(withIdentifier: "toPlayerssetSegue",sender: nil)
                        
                        self.button_off()
                        
                    }) {() -> Void in
                        print("error")
                        
                    }
                    
                }
                
                break
            case 2,9:     // チェックアウト済み,9:予約
                spinnerEnd()
                
                // 精算者振替がOFFの場合はオーダー登録させない
                if status == 2 && is_payer_allocation != 1 {
                    let message = "は\nチェックアウト済みです。(精算者振替機能OFF)"
                    let alertController = UIAlertController(title: "エラー！", message: "ホルダ番号「" + "\(holderno!)" + "」" + message , preferredStyle: .alert)
                    
                    let okAction = UIAlertAction(title: "はい", style: .default){
                        action in print("Pushed OK")
                        // タップ音
                        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                        return;
                    }
                    alertController.addAction(okAction)
                    present(alertController, animated: true, completion: nil)
                    return;
                }
                
                var message = ""
                switch status {
                case 2:
                    message = "は\nチェックアウト済みです。"
                    break
                case 9:
                    message = "は\n予約されています。"
                    break
                default:
                    break
                }
                
                //                let message = "はチェックアウト済みです。"
                let alertController = UIAlertController(title: "エラー！", message: "ホルダ番号「" + "\(holderno!)" + "」" + message + "\nそれでもオーダー登録しますか？", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "いいえ", style: .cancel){
                    action in
                    // タップ音
                    TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                    print("Pushed cancel")
                    self.button_off()
                }
                
                let okAction = UIAlertAction(title: "はい", style: .default){
                    action in print("Pushed OK")
                    // タップ音
                    TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                    
                    if g_no == -1 {     // グループNOがない場合
                        if self.set_folder_number(holderno!) == false {
                            print("error")
                        } else {
                            self.performSegue(withIdentifier: "toPlayerssetSegue",sender: nil)
                            self.button_off()
                        }
                    } else {
                        self.set_folder_numbers(holderno!, success: {() -> Void in
                            self.performSegue(withIdentifier: "toPlayerssetSegue",sender: nil)
                            
                            self.button_off()
                            
                        }) {() -> Void in
                            print("error")
                            
                        }
                        
                    }
                    
                    
                    return;
                }
                
                alertController.addAction(cancelAction)
                alertController.addAction(okAction)
                present(alertController, animated: true, completion: nil)
                return;
                
            default:
                break
            }
            
        }
    }
    
    
    //確定ボタンタップ
    @IBAction func okButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        // 入力確認
        // 数字未入力の時
        if (holderNoTextField.text?.characters.count)! <= 0 {
            // UIAlertController を作成
            let alertController2 = UIAlertController(title: "エラー！", message: "ホルダ番号を入力してください", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel){
                action in print("Pushed OK")
                self.button_off()
                return;
            }
            alertController2.addAction(cancelAction)
            present(alertController2, animated: true, completion: nil)
            return;
        }
   
        let holderno = Int(holderNoTextField.text!)
        
        let db = FMDatabase(path: _path)
        
        // データベースをオープン
        db.open()
        

        let rs = db.executeQuery(SELECT_PLAYERS, withArgumentsIn: [holderno!,shop_code,globals_today + "%"])

        var is_entity = false
        
        var status:Int = 0
        
        while rs!.next() {
            is_entity = true
            
            status = Int(rs!.int(forColumn: "status"))
        }
        
        // データがない場合
        if is_entity == false {
            let alertController = UIAlertController(title: "エラー！", message: "ホルダ番号「" + "\(holderno!)" + "」" + "は\n存在しません。" + "\nそれでもオーダー登録しますか？", preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "いいえ", style: .cancel){
                action in
                // タップ音
                TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                print("Pushed cancel")
                self.button_off()
            }
            
            let okAction = UIAlertAction(title: "OK", style: .default){
                action in print("Pushed OK")
                // タップ音
                TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                if self.set_folder_number(holderno!) == false {
                    print("error")
                } else {
                    self.performSegue(withIdentifier: "toPlayerssetSegue",sender: nil)
                    self.button_off()
                }
                return;
            }
            
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
        } else {
            switch status {
            case -1,9:    // -1:存在しない 9:予約

//            case -1,3,9:    // -1:存在しない 2:チェックアウト済み　3:キャンセル　9:予約
                var message = ""
                switch status {
                case -1:
                    message = "は\n存在しません。"
                    break
                case 2:
                    message = "は\nチェックアウト済みです。"
                    break
                case 3:
                    message = "は\nキャンセルされています。"
                    break
                case 9:
                    message = "は\n予約されています。"
                    break
                default:
                    message = "は\n存在しません。"
                    break
                }
                
                let alertController = UIAlertController(title: "エラー！", message: "ホルダ番号「" + "\(holderno!)" + "」" + message + "\nそれでもオーダー登録しますか？", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "いいえ", style: .cancel){
                    action in
                    // タップ音
                    TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                    
                    print("Pushed cancel")
                    self.button_off()
                    
                    return;
                }
                
                let okAction = UIAlertAction(title: "はい", style: .default){
                    action in
                    // タップ音
                    TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                    
                    print("Pushed OK")
                    
                    if self.set_folder_number(holderno!) == false {
                        print("error")
                    } else {
                        self.performSegue(withIdentifier: "toPlayerssetSegue",sender: nil)
                        self.button_off()
                    }
                    return;
                }
                
                alertController.addAction(cancelAction)
                alertController.addAction(okAction)
                present(alertController, animated: true, completion: nil)
                return;
                
            case 0,1:     // チェックイン
                if self.set_folder_number(holderno!) == false {
                    print("error")
                } else {
                    self.performSegue(withIdentifier: "toPlayerssetSegue",sender: nil)
                    self.button_off()
                }
                
                break
            case 2:     // チェックアウト済み
                spinnerEnd()
                
                // 精算者振替がOFFの場合はオーダー登録させない
                if is_payer_allocation != 1 {
                    let message = "は\nチェックアウト済みです。(精算者振替機能OFF)"
                    let alertController = UIAlertController(title: "エラー！", message: "ホルダ番号「" + "\(holderno!)" + "」" + message , preferredStyle: .alert)
                    
                    let okAction = UIAlertAction(title: "はい", style: .default){
                        action in print("Pushed OK")
                        // タップ音
                        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                        return;
                    }
                    alertController.addAction(okAction)
                    present(alertController, animated: true, completion: nil)
                    return;
                }
                
                
                let message = "は\nチェックアウト済みです。"
                let alertController = UIAlertController(title: "エラー！", message: "ホルダ番号「" + "\(holderno!)" + "」" + message + "\nそれでもオーダー登録しますか？", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "いいえ", style: .cancel){
                    action in
                    // タップ音
                    TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                    print("Pushed cancel")
                    self.button_off()
                }
                
                let okAction = UIAlertAction(title: "はい", style: .default){
                    action in print("Pushed OK")
                    // タップ音
                    TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                    if self.set_folder_number(holderno!) == false {
                        print("error")
                    } else {
                        self.performSegue(withIdentifier: "toPlayerssetSegue",sender: nil)
                        self.button_off()
                    }
                    return;
                }
                
                alertController.addAction(cancelAction)
                alertController.addAction(okAction)
                present(alertController, animated: true, completion: nil)
                return;
            case 3:    // 3:キャンセル
                let message = "は\nキャンセルされています。"
                let alertController = UIAlertController(title: "エラー！", message: "ホルダ番号「" + "\(holderno!)" + "」" + message , preferredStyle: .alert)
                
                let okAction = UIAlertAction(title: "OK", style: .default){
                    action in print("Pushed OK")
                    
//                    let sql2 = "INSERT INTO seat_holder (seat_no,holder_no) VALUES (?,?);"
//                    let success = db.executeUpdate(sql2, withArgumentsIn: [globals_select_seat_no,self.holderNoTextField.text!])
//                    if !success {
//                        print("insert error!!")
//                    }
                    
                    self.button_off()
                    
                    return;
                }
                
                alertController.addAction(okAction)
                present(alertController, animated: true, completion: nil)
                return;
   
            default:
                break
            }
            
        }

    }
    
    // 戻るボタンタップ
    @IBAction func backButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        // お客様設定画面に移動
        self.performSegue(withIdentifier: "toPlayerssetSegue",sender: nil)
    }
    
    // 名前検索ボタンタップ
    @IBAction func nameSeachButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        // お客様設定画面に移動
        self.performSegue(withIdentifier: "toNameSearchViewSegue",sender: nil)
        
    }
    // 次の画面から戻ってくるときに必要なsegue情報
    @IBAction func unwindToHoldernoinput(_ segue: UIStoryboardSegue) {
        
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
        }
    }
    
    override func motionCancelled(_ motion: UIEventSubtype, with event: UIEvent?) {
        if event?.type == UIEventType.motion && event?.subtype == UIEventSubtype.motionShake {
            print("Motion cancelled")
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

    // 単体登録
    func set_folder_number(_ holderno:Int) -> Bool{
        let db2 = FMDatabase(path: _path)
        
        // データベースをオープン
        db2.open()
        let sql2 = "INSERT INTO seat_holder (seat_no,holder_no) VALUES (?,?);"
        let success = db2.executeUpdate(sql2, withArgumentsIn: [globals_select_seat_no,self.holderNoTextField.text!])
        if !success {
            print("insert error!!",success.description)
            db2.close()
            return false
        }
        db2.close()
        return true
        
    }
    
    // グループ一括登録
    func set_folder_numbers(_ holderno:Int,success: (() -> Void)? , cancel: (() -> Void)?) {
        let db = FMDatabase(path: _path)
        
        // データベースをオープン
        db.open()
        
        let sql = "SELECT * FROM players WHERE group_no IN (SELECT group_no FROM players WHERE member_no = ?) AND created LIKE ? ORDER BY cast(member_no as integer);"

        let rs = db.executeQuery(sql, withArgumentsIn: [holderno,globals_today + "%"])

        seat_holders = []
        var seatno = 0
        var is_status = false
        var mn3 = ""
        
        while (rs?.next())! {
            let mn = rs?.string(forColumn:"member_no")
            let status = Int((rs?.int(forColumn:"status"))!)
            if (status == 3) || (status == 2 && is_payer_allocation != 1) {
                mn3 = mn!
                is_status = true
            } else {
                var is_update = false
                
                let seats = takeSeatPlayers_temp.filter({$0.holder_no == ""})
                
                if seats.count > 0 {
                    for seat in seats {
                        if seat.seat_no == globals_select_seat_no {
                            if mn == self.holderNoTextField.text! {
                                seatno = seat.seat_no
                                is_update = true
                                break;
                            }
                        } else {
                            if mn != self.holderNoTextField.text! {
                                seatno = seat.seat_no
                                is_update = true
                                break;
                            }
                        }
                    }
                    
                    if is_update == true {
                        self.seat_holders.append(seat_holder(seat_no: seatno, holder_no: mn!))
                        let index = takeSeatPlayers_temp.index(where: {$0.seat_no == seatno})
                        if index != nil {
                            takeSeatPlayers_temp[index!].holder_no = mn!
                        }
                        is_update = false
                    }
                    
                }
            }
        }

        if is_status == true {
            let message = "はキャンセルもしくはチェックアウト(精算者振替機能OFF)されていますので一括登録の対象外です。"
            
            let alertController = UIAlertController(title: "情報", message: "ホルダ番号「" + mn3 + "」" + message , preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "OK", style: .default){
                action  in
                print("Pushed OK")
                
                
                let sql1 = "INSERT INTO seat_holder (seat_no,holder_no) VALUES (?,?);"
                db.beginTransaction()
                for num in 0..<self.seat_holders.count {
                    let success = db.executeUpdate(sql1, withArgumentsIn: [self.seat_holders[num].seat_no,self.seat_holders[num].holder_no])
                    if !success {
                        print("insert error!!")
                        db.rollback()
                        cancel?()
                        //                    return false
                    }
                }
                db.commit()
                
                success?()
            }
            
            alertController.addAction(okAction)
            UIApplication.shared.topViewController()?.present(alertController, animated: true, completion: nil)
            
        } else {
            
            let sql1 = "INSERT INTO seat_holder (seat_no,holder_no) VALUES (?,?);"
            db.beginTransaction()
            for num in 0..<seat_holders.count {
                let success = db.executeUpdate(sql1, withArgumentsIn: [seat_holders[num].seat_no,seat_holders[num].holder_no])
                if !success {
                    print("insert error!!")
                    db.rollback()
                    cancel?()

                }
            }
            db.commit()
            
            success?()
        }

    }
    
    // ユーザー情報取得（全体・および差分）
    func get_players(){
        let db = FMDatabase(path: _path)
        
        // データベースをオープン
        db.open()
        
        // お客様情報テーブルから更新日付の最大値を取得
        let sql = "select MAX(modified) from players;"
        let results = db.executeQuery(sql, withArgumentsIn: [])
        
        var updateTime = "1900/01/01 00:00:00"
        
        while (results?.next())! {
            if results?.string(forColumnIndex: 0) != nil {
                print(results?.string(forColumnIndex: 0) as Any)
                updateTime = (results?.string(forColumnIndex: 0))!
            }
        }
        
//        updateTime = "1900/01/01 00:00:00"
        
        let url = urlString + "GetUpdateCustomer"

        // お客様情報
        players = []

        print(url,updateTime)
        print("---S-------------------------------------------",Date())
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForResource = 10 // seconds

        self.alamofireManager = Alamofire.SessionManager(configuration: configuration)

        self.spinnerStart()
        
        self.dispatch_async_global {
            
            self.alamofireManager!.request( url, parameters: ["Store_CD":shop_code.description,"UpdateTime":updateTime])
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
                                        self.players.append(players_data(
                                            shop_code: custmer["store_cd"].asInt!,
                                            member_no: "\(custmer["customer_no"].asInt!)",
                                            member_category: custmer["member_kbn"].asInt!,
                                            group_no: Int(custmer["group_id"].asString!)!,
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
                                    
                                    for player in self.players {
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
                                return;
                            }
                            
                        } else {
                            self.dispatch_async_main {
                                self.spinnerEnd()
                                let e = json.asError
                                print(e as Any)
                                
                            }
                        }
                        
                    } else {
                        self.dispatch_async_main {
                            self.spinnerEnd()
                            print(response.result.error as Any)
                        }
                    }
            }
        }
//        db.close()
    }
    
    func jsonError(){
        // エラー音
        TapSound.buttonTap(err_sound_file.sound_file, type: err_sound_file.file_type)

        // エラー表示

        CustomProgress.Instance.mrprogress.dismiss(true)
        //        self.spinnerEnd()
        let alertController = UIAlertController(title: "エラー！", message: "お客様情報の取り込みに失敗しました。\n再度実行してください。", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default){
            action in print("Pushed OK")
            self.button_off()
            return;
        }
        
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
        
    }

    func button_off(){
        self.holderNoTextField.textAlignment = NSTextAlignment.left
        self.holderNoTextField.text = ""
        self.allOkButton.isEnabled = false
        self.allOkButton.alpha = 0.6
        self.okButton.isEnabled = false
        self.okButton.alpha = 0.6
        self.clearButton.isEnabled = false
        self.clearButton.alpha = 0.6
    }

    
}
