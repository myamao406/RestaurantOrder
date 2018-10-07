//
//  staffNoInputViewController.swift
//  iOrder
//
//  Created by 山尾守 on 2016/07/25.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit
import FontAwesomeKit
//import AudioToolbox
import FMDB
import Toast_Swift
import Alamofire
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

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}


class staffNoInputViewController: UIViewController,UINavigationBarDelegate {

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
    @IBOutlet weak var buttonclear: UIButton!
    @IBOutlet weak var staffNoTextField: UITextField!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var navBar: UINavigationBar!
    
    // DBファイルパス
    var _path:String = ""
    
    //CustomProgressModelにあるプロパティが初期設定項目
    let initVal = CustomProgressModel()
    
    var alamofireManager : Alamofire.SessionManager?
    
    let jsonErrorMsg = "担当者情報の取得に失敗しました。"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navBar.delegate = self
        navBar.barTintColor = iOrder_titleBlueColor

        let noKeyButton:[UIButton] = [button0,button1,button2,button3,button4,button5,button6,button7,button8,button9]
        
        for num in 0...noKeyButton.count - 1 {
            let button :UIButton = noKeyButton[num]
            
            button.addTarget(self, action: #selector(tablenoinputViewContoroller.noButtomTap(_:)), for: .touchUpInside)
            
        }
        
        let iconImage = FAKFontAwesome.chevronCircleLeftIcon(withSize: iconSize)
        
        // 下記でアイコンの色も変えられます
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_bargainsYellowColor)
        //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
        let Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        backButton.setImage(Image, for: UIControlState())
        
        // 長押し
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.pressedLong(_:)))
        
        backButton.addGestureRecognizer(longPress)

        let iconImage2 = FAKFontAwesome.checkIcon(withSize: iconSize)
        
        // 下記でアイコンの色も変えられます
        iconImage2?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
        //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
        let Image2 = iconImage2?.image(with: CGSize(width: iconSize, height: iconSize))
        okButton.setImage(Image2, for: UIControlState())
        
        // クリアボタン
        let iconImage3 = FAKFontAwesome.timesCircleIcon(withSize: iconSize)
        iconImage3?.addAttribute(NSForegroundColorAttributeName, value: iOrder_greenColor)
        //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
        let Image3 = iconImage3?.image(with: CGSize(width: iconSize, height: iconSize))
        buttonclear.setImage(Image3, for: UIControlState())
 
//        let attributes = [NSFontAttributeName : UIFont(name: "YuGo-Bold", size: 23)!]
//        staffNoTextField.attributedPlaceholder = NSAttributedString(string: "最大担当者番号は5桁です", attributes:attributes)
        
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

        
        self.button_off()
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        dispatch_once(&self.onceTokenViewDidAppear) {
            DemoLabel.Show(self.view)
//        }
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
        var str = staffNoTextField.text! + "\(sender.tag - 1)"
        
        if !(str.characters.count == 1 && sender.tag == 1){
            // 文字数がmaxLength以下なら表示する.
            if str.characters.count <= maxLength {
                staffNoTextField.textAlignment = NSTextAlignment.right
                staffNoTextField.text = str
                
                okButton.isEnabled = true
                okButton.alpha = 1.0
                buttonclear.isEnabled = true
                buttonclear.alpha = 1.0
                
            } else {
                print("5文字を超えています")
            }
            
        } else {
            str = ""
            // 確定ボタンは担当者番号入力時だけ押せるようにする。
            okButton.isEnabled = false
            okButton.alpha = 0.6
            
            buttonclear.isEnabled = false
            buttonclear.alpha = 0.6
        }

    }
    
    // クリアボタンタップ
    @IBAction func clearButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        // 担当者No 入力エリアをクリアする
        self.button_off()
//        staffNoTextField.textAlignment = NSTextAlignment.Left
//        staffNoTextField.text = ""
    }
    
    @IBAction func unwindToStaffNoInput(_ segue: UIStoryboardSegue) {
        
    }
    
    // 確定ボタンタップ
    @IBAction func okButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        // 数字未入力の時
        if staffNoTextField.text?.characters.count <= 0 {
            let alertController = UIAlertController(title: "エラー！", message: "番号を入力してください", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel){
                action in print("Pushed OK")
//                self.staffNoTextField.textAlignment = NSTextAlignment.Left
//                self.staffNoTextField.text = ""
                self.button_off()

            }
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
        } else {
            let staffno = staffNoTextField.text
            
            // 本番モード
            if demo_mode == 0 {
                spinnerStart()
                
                self.dispatch_async_global {
                    let url = urlString + "GetEmployee"
                    
                    let configuration = URLSessionConfiguration.default
                    configuration.timeoutIntervalForResource = 10 // seconds

                    self.alamofireManager = Alamofire.SessionManager(configuration: configuration)
                    self.alamofireManager!.request( url, parameters: ["Store_CD":shop_code.description,"Employee_CD":staffno!])
                        .responseJSON{ response in
                            // エラーの時
                            if response.result.error != nil {
                                self.spinnerEnd()
                                let e = response.result.description
                                self.jsonError(self.jsonErrorMsg)
                                self.button_off()
                                
                                print(e)
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
                                            if value.toString() != "true" {
//                                            if value.toString() == "false" {
                                                print("担当者情報なし")
                                                self.spinnerEnd()
                                                self.dispatch_async_main {
                                                    let msg = value.toString()
//                                                    let msg = "担当者番号「" + staffno! + "」は存在しません"
                                                    self.jsonError(msg)
                                                    self.button_off()
                                                }
                                                return;
                                            }
                                        }

                                        let db = FMDatabase(path: self._path)
                                        
                                        // データベースをオープン
                                        db.open()
                                        
                                        var success = true
                                        let sql = "INSERT OR REPLACE INTO staffs_info (staff_no, staff_name_kana,staff_name_kanji, created, modified) VALUES (?, ?, ?, ?, ?);"
                                        var argumentArray:Array<Any> = []
                                        argumentArray.append(Int(staffno!)!)
                                        argumentArray.append("")
                                        argumentArray.append(json_table["employee_nm"].asString!)
                                        
                                        let now = Date() // 現在日時の取得
                                        let dateFormatter = DateFormatter()
                                        dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
                                        dateFormatter.timeStyle = .medium
                                        dateFormatter.dateStyle = .medium
                                        
                                        let modified = dateFormatter.string(from: now)
                                        argumentArray.append(modified)
                                        argumentArray.append(modified)
                                        
                                        // INSERT文を実行
                                        success = db.executeUpdate(sql, withArgumentsIn: argumentArray)
                                        // INSERT文の実行に失敗した場合
                                        if !success {
                                            print(errno.description)
                                            // ループを抜ける
                                            //                            break
                                        }
                                        
                                        argumentArray = []
                                        
                                        // まず現行のデータをすべて消す
                                        let sql3 = "DELETE FROM staffs_now;"
                                        let _ = db.executeUpdate(sql3, withArgumentsIn: [])
                                        
                                        let sql4 = staffs_now_insert
                                        argumentArray.append(Int(staffno!)!)
                                        argumentArray.append("")
                                        argumentArray.append(json_table["employee_nm"].asString!)
                                        
                                        argumentArray.append(modified)
                                        argumentArray.append(modified)
                                        
                                        
                                        // INSERT文を実行
                                        let result4 = db.executeUpdate(sql4, withArgumentsIn: argumentArray)
                                        // INSERT文の実行に失敗した場合
                                        if !result4 {
                                            // ループを抜ける
                                            print(result4.description)
                                            //                        break
                                        }
                                        db.close()
                                        self.dispatch_async_main {
                                            self.spinnerEnd()
                                            self.performSegue(withIdentifier:"toTopSegue",sender: nil)
                                            self.button_off()
                                            
                                        }
                                        
                                    }
                                    
                                }
                                
                            }
                    }
                }

            } else {
                let db = FMDatabase(path: _path)
                
                // データベースをオープン
                db.open()
                //            var params = ["staff_no" : Int(staffno!)]
                let sql = "SELECT count(*) FROM staffs_info WHERE staff_no = ?;"
                
                let results = db.executeQuery(sql, withArgumentsIn: [staffno!])
                while (results?.next())! {
                    // 担当者が登録されていない場合
                    if results?.int(forColumnIndex:0) <= 0 {
                        // エラー表示
                        let alertController = UIAlertController(title: "エラー！", message: "指定した担当者番号「" + staffno! + "」は存在しません", preferredStyle: .alert)
                        let cancelAction = UIAlertAction(title: "OK", style: .cancel){
                            action in print("Pushed OK")
//                            self.staffNoTextField.textAlignment = NSTextAlignment.Left
//                            self.staffNoTextField.text = ""
                            self.button_off()

                        }
                        alertController.addAction(cancelAction)
                        present(alertController, animated: true, completion: nil)
                        // 登録されている場合
                    } else {
                        var argumentArray:Array<Any> = []
                        
                        // 該当する担当者情報を今の担当者テーブルにコピーする
                        let sql2 = "SELECT * FROM staffs_info WHERE staff_no = ?;"
                        let results2 = db.executeQuery(sql2, withArgumentsIn: [staffno!])
                        while (results2?.next())! {
                            // まず現行のデータをすべて消す
                            let sql3 = "DELETE FROM staffs_now;"
                            let _ = db.executeUpdate(sql3, withArgumentsIn: [])
                            
                            let sql4 = staffs_now_insert
                            var kana = ""
                            if let ka = results2?.string(forColumn:"staff_name_kana") {
                                kana = ka
                            }
                            var kanji = ""
                            if let kan = results2?.string(forColumn:"staff_name_kanji") {
                                kanji = kan
                            }
                            
                            argumentArray.append(Int((results2?.int(forColumn:"staff_no"))!))
                            argumentArray.append(kana)
                            argumentArray.append(kanji)
                            
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
                                // ループを抜ける
                                print(result4.description)
                                break
                            }
                            
                        }
                        performSegue(withIdentifier: "toTopSegue",sender: nil)
                        self.button_off()

                    }
                }
                db.close()

            }

        }
    
    }
    
    
    @IBAction func backButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        self.performSegue(withIdentifier: "toTopSegue",sender: nil)
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
            self.performSegue(withIdentifier: "toTopSegue",sender: nil)
            
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
                self.performSegue(withIdentifier: "toTopSegue",sender: nil)
                
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
        DispatchQueue.global().async(execute: block)
    }

    
    func spinnerStart() {
        CustomProgress.Instance.title = "受信中..."
//        self.view.makeToastActivity(.Center);
        CustomProgress.Create(self.view,initVal: initVal,modeView: EnumModeView.uiActivityIndicatorView)

        //ネットワーク接続中のインジケータを表示
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func spinnerEnd() {
//        self.view.hideToastActivity();
        CustomProgress.Instance.mrprogress.dismiss(true)
        //ネットワーク接続中のインジケータを消去
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    func jsonError(_ msg:String){
        // エラー音
        TapSound.buttonTap(err_sound_file.sound_file, type: err_sound_file.file_type)

        // エラー表示        
        let alertController = UIAlertController(title: "エラー！", message: msg, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel){
            action in print("Pushed OK")
            self.staffNoTextField.textAlignment = NSTextAlignment.left
            self.staffNoTextField.text = ""
        }
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)

        
    }

    func button_off(){
        self.staffNoTextField.textAlignment = NSTextAlignment.left
        self.staffNoTextField.text = ""
        self.okButton.isEnabled = false
        self.okButton.alpha = 0.6
        self.buttonclear.isEnabled = false
        self.buttonclear.alpha = 0.6
    }

}
