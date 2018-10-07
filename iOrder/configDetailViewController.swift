//
//  configDetailViewController.swift
//  iOrder2
//
//  Created by 山尾 守 on 2016/09/28.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit
import FontAwesomeKit
import FMDB

class configDetailViewController: UIViewController, UITableViewDelegate,UITableViewDataSource,UINavigationBarDelegate{

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var licenseText: UITextView!
    
    var tableViewMain = UITableView()
    
    // 表示データ
    var dispData:[String] = []
    var selected:[Bool] = []
    var sound:[Int] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navBar.delegate = self
        navBar.barTintColor = iOrder_titleBlueColor
        
        let iconImage = FAKFontAwesome.chevronCircleLeftIcon(withSize: iconSize)
        
        // 下記でアイコンの色も変えられます
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_bargainsYellowColor)
        //        iconImage?.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
        let Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        backButton.setImage(Image, for: UIControlState())
        
        // 長押し
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.pressedLong(_:)))
        
        backButton.addGestureRecognizer(longPress)

        self.navBar.topItem?.title = globals_config_info?.itemName
        
//        self.loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if globals_config_info!.item != "license" {
            self.loadData()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if globals_config_info!.item == "license" {
            licenseText.setContentOffset(CGPoint.zero, animated: false)
        }
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
    
    
    func loadData(){
                
        switch globals_config_info!.item {
        case "is_demo":
            dispData = []
            selected = []

            dispData.append("無効")
            dispData.append("有効-取込データを使用する")
            dispData.append("有効-デモデータを使用する")
            selected = Array(repeating: false, count: 3)
            let select = globals_config_info!.defaultNo
            selected[select] = true
        case "is_guide":
            dispData = []
            selected = []

            dispData.append("無効")
            dispData.append("有効-ガイダンス表示有効")
            selected = Array(repeating: false, count: 2)
            let select = globals_config_info!.defaultNo
            selected[select] = true
        case "new_order_category_DEFAULT","add_order_category_DEFAULT":
            dispData = []
            selected = []

            for i in 0..<12 {
                dispData.append("\(i+1)")
            }
            selected = Array(repeating: false, count: 12)
            let select = globals_config_info!.defaultNo
            selected[select-1] = true

        case "is_tapsound", "is_errorbeep","topreturn_sound":
            
            // 使用DB
            let use_db = production_db
//            if demo_mode != 0{
//                use_db = demo_db
//            }
            // /Documentsまでのパスを取得
            let paths = NSSearchPathForDirectoriesInDomains(
                .documentDirectory,
                .userDomainMask, true)
            let _path = (paths[0] as NSString).appendingPathComponent(use_db)
            let db = FMDatabase(path: _path)
            db.open()
            let sql = "select * from app_config_sound where sound_no >= ? and sound_no < ?; "
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
                        
            let results = db.executeQuery(sql, withArgumentsIn:[from,to])
            dispData = []
            selected = []
            sound = []
            
            while (results?.next())! {
                dispData.append((results?.string(forColumn:"disp_name"))!)
                selected.append(false)
                sound.append(Int((results?.int(forColumn:"sound_no"))!))
            }
            
            db.close()
            
            for i in 0..<dispData.count {
                if dispData[i] == globals_config_info!.defaultSt {
                    selected[i] = true
                } else {
                    selected[i] = false
                }
            }

            break;
        case "is_senddata","is_senderror","is_order_s2e" :
            dispData = []
            dispData.append("サウンド")
            dispData.append("アラート間隔")
            if globals_config_info!.item != "is_order_s2e" {
                dispData.append("繰り返し")
            }

        default:
            break;
        }
        
        

        // テーブルビューを作る
        // Status Barの高さを取得する.
        let barHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
                
        // Viewの高さと幅を取得する.
        let displayWidth: CGFloat = self.view.frame.width
        let displayHeight: CGFloat = self.view.frame.height - toolBarHeight
        
        // TableViewの生成する(status barの高さ分ずらして表示).
        self.tableViewMain = UITableView(frame: CGRect(x: 0, y: barHeight + NavHeight , width: displayWidth, height: displayHeight - barHeight - NavHeight ), style: UITableViewStyle.plain)
        
        // テーブルビューを追加する
        self.view.addSubview(self.tableViewMain)
        
        // テーブルビューのデリゲートとデータソースになる
        self.tableViewMain.delegate = self
        self.tableViewMain.dataSource = self
        
        // xibをテーブルビューのセルとして使う
        tableViewMain.register(UINib(nibName: "configDetailTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        
        tableViewMain.register(UINib(nibName: "configStepperTableViewCell", bundle: nil), forCellReuseIdentifier: "configStepperCell")

        tableViewMain.rowHeight = UITableViewAutomaticDimension
        tableViewMain.allowsSelection = true
        
    }

    
    // セクション数
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // 行数を返す（UITableViewDataSource）
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(dispData.count)
        return dispData.count
    }

    // セルにデータを設定する（UITableViewDataSource）
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let item = globals_config_info!.item
        
//        let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as! configDetailTableViewCell
        
        switch item {
        case "is_senddata","is_senderror","is_order_s2e" :
            let cell = tableView.dequeueReusableCell(withIdentifier: "configStepperCell") as! configStepperTableViewCell
            
            // 選択時に色を変えない
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            
            cell.configImage.isHidden = true
            //            cell.configImage.image = Image
            cell.configLabel1.text = dispData[indexPath.row]
            
            cell.configLabel2.text = ""
            
            switch indexPath.row {
            case 0:
                if item == "is_senddata" {
                    cell.configLabel2.text = getSound(not_send_alert.sound_no)
                } else if item == "is_senderror" {
                    cell.configLabel2.text = getSound(data_not_send_alert.sound_no)
                } else {
                    cell.configLabel2.text = getSound(order_start2end_alert.sound_no)
                }
                break
            case 1:
//                let min = item == "is_order_s2e" ? "分" : "秒"
                let min = "分"
                cell.configLabel2.text = String(globals_config_info!.defaultNo) + min
                let stepper = UIStepper()
                
                // 最小値, 最大値, 規定値の設定をする.
                
                stepper.minimumValue = 0
                stepper.maximumValue = 999
                stepper.value = Double(globals_config_info!.defaultNo)
                
                stepper.addTarget(self, action: #selector(configDetailViewController.stepperDidTap(_:)), for: UIControlEvents.valueChanged)
                
                
                cell.accessoryView = stepper
                break
            case 2:
                var interval = -1
                if item == "is_senddata" {
                    interval = not_send_alert.interval
                } else if item == "is_senderror" {
                    interval = data_not_send_alert.interval
                } else {
                    interval = order_start2end_alert.interval
                }
                if interval <= 0 {
                    cell.configLabel2.text = "しない"
                } else {
                    cell.configLabel2.text = "\(interval)" + "分"
                }
                
                break
            default:
                break
            }
            return cell
            
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! configDetailTableViewCell
            
            // 選択時に色を変えない
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            cell.detailLabel.text = dispData[indexPath.row]
            if selected[indexPath.row] == true {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
            
            return cell

        }
        
    }
    
    // Cell が選択された場合
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath:IndexPath) {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! configDetailTableViewCell

        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        
        // サウンド設定
        switch globals_config_info!.item {
        case "is_tapsound","is_errorbeep","topreturn_sound":
            
            for i in 0..<dispData.count {
                cell.accessoryType = .none
                selected[i] = false
            }
            
            selected[indexPath.row] = true
            cell.accessoryType = .checkmark
            

            for i in 0..<dispData.count {
                cell.accessoryType = .none
                selected[i] = false
            }
            
            selected[indexPath.row] = true
            cell.accessoryType = .checkmark

            soundsListMake(indexPath)
            
            self.tableViewMain.reloadSections(IndexSet(integer: indexPath.section), with: .none)

            break
        case "is_senddata","is_senderror", "is_order_s2e":
            switch indexPath.row {
            case 0,2:
                globals_select_row = indexPath.row
                self.performSegue(withIdentifier: "toConfigSoundDetailViewSegue",sender: nil)

                break
            case 1:
                break
            default:
                break
            }
            break

        case "is_demo":

//            // ooishi
//            // デモモード認証状態取得
//            let demoAuth:checkDemoAuth = checkDemoAuth()
//            let certification_flag = demoAuth.checkCertification()
//
//            // デモモードをタップ且つ、デモ認証がまだの場合
//            if (certification_flag == 0 && indexPath.row == 2){
//                let alertDemo:UIAlertController = UIAlertController(title:"デモモード認証",message: "デモモード使用のためのパスワードを入力してください。",preferredStyle: UIAlertControllerStyle.alert)
//                let cancelActionDemo:UIAlertAction = UIAlertAction(title: "キャンセル",style: UIAlertActionStyle.cancel,handler:{(action:UIAlertAction!) ->
//                    Void in
//                    print("Cancel")
//                })
//                let defaultActionDemo:UIAlertAction = UIAlertAction(title: "OK",style: UIAlertActionStyle.default,handler:{(action:UIAlertAction!) ->
//                    Void in
//                    print("OK")
//
//                    // パスワードの判定
//                    var passtxt:String = ""
//                    let textFields2:Array<UITextField>? =  alertDemo.textFields as Array<UITextField>?
//                    for textField:UITextField in textFields2! {
//                        passtxt = textField.text!
//                    }
//                    let mp = makePassword()
//
//                    // 認証OKの場合、認証フラグを1にする
//                    if passtxt == mp.check(){
//                        demoAuth.setCertification()
//
//                        // チエックマークを全て外してつけ直す
//                        for i in 0..<self.dispData.count {
//                            cell.accessoryType = .none
//                            self.selected[i] = false
//                        }
//                        self.selected[indexPath.row] = true
//                        cell.accessoryType = .checkmark
//                        self.tableViewMain.reloadSections(IndexSet(integer: indexPath.section), with: .none)
//
//                    }else{
//                        // パスが異なる場合
//                        let alert3:UIAlertController = UIAlertController(title:"デモモード認証",message: "パスワードが間違っています。",preferredStyle: UIAlertControllerStyle.alert)
//                        let defaultAction3:UIAlertAction = UIAlertAction(title: "OK",style: UIAlertActionStyle.default,handler:{(action:UIAlertAction!) ->
//                            Void in
//                            print("OK")
//                        })
//                        alert3.addAction(defaultAction3)
//                        self.present(alert3, animated: true, completion: nil)
//                    }
//                })
//                alertDemo.addAction(cancelActionDemo)
//                alertDemo.addAction(defaultActionDemo)
//                //textfiledの追加
//                alertDemo.addTextField(configurationHandler: {(alertText:UITextField!) -> Void in
//                    // キーボードは数字のみ
//                    alertText.keyboardType = .numberPad
//                    alertText.isSecureTextEntry = true
//                })
//                present(alertDemo, animated: true, completion: nil)
            
//            }else{
                // チエックマークを全て外してつけ直す
                for i in 0..<dispData.count {
                    cell.accessoryType = .none
                    selected[i] = false
                }
                selected[indexPath.row] = true
                cell.accessoryType = .checkmark
                self.tableViewMain.reloadSections(IndexSet(integer: indexPath.section), with: .none)
//            }
            break

        default:

            // チエックマークを全て外してつけ直す
            for i in 0..<dispData.count {
                cell.accessoryType = .none
                selected[i] = false
            }
            selected[indexPath.row] = true
            cell.accessoryType = .checkmark
            self.tableViewMain.reloadSections(IndexSet(integer: indexPath.section), with: .none)
            break
        }
    }
    
    func getSound(_ sound_no : Int) -> String {
        var disp_name = ""
        
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
        let db = FMDatabase(path: _path)
        db.open()
        
        let sql = "select * from app_config_sound where sound_no = ? ; "
        let results = db.executeQuery(sql, withArgumentsIn:[sound_no])
        
        while (results?.next())! {
            disp_name = (results?.string(forColumn:"disp_name"))!
        }
        db.close()

        return disp_name
    }
    
    func soundsListMake(_ indexPath:IndexPath) {
        // サウンド番号からサウンドファイルを選択
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
        let db = FMDatabase(path: _path)
        db.open()
        let sql = "select * from app_config_sound where sound_no = ?; "
        
        let results = db.executeQuery(sql, withArgumentsIn:[sound[indexPath.row]])
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
            case "is_order_s2e":
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
    
    func stepperDidTap(_ stepper: UIStepper) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        let point = stepper.convert(CGPoint.zero, to: tableViewMain)
        let indexPath = self.tableViewMain.indexPathForRow(at: point)!

        for (i,conf_section) in configtableData.enumerated() {
            let row = conf_section.index(where: {$0.item == globals_config_info!.item})
            if row != nil {
                configtableData[i][row!].defaultNo = Int(stepper.value)
                globals_config_info?.defaultNo = Int(stepper.value)
                if globals_config_info!.item == "is_senddata" {
                    print(stepper.value,i,row as Any,indexPath)
                    not_send_alert.sound_interval = Int(stepper.value)
                    
                } else if globals_config_info!.item == "is_senderror"{
                    data_not_send_alert.sound_interval = Int(stepper.value)
                } else {
                    order_start2end_alert.sound_interval = Int(stepper.value)
                }
            }
        }
        
        self.tableViewMain.reloadRows(at: [indexPath], with: .none)
        
    }

    
    // 戻るボタンタップ
    @IBAction func backButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        for (section,confData) in configtableData.enumerated() {
            let row = confData.index(where: {$0.item == globals_config_info?.item})
            
            if row != nil {
                for (i,select) in selected.enumerated() {
                    if select == true {
                        switch globals_config_info!.item {
                        case "new_order_category_DEFAULT","add_order_category_DEFAULT":     // 初期表示カテゴリ（新規）,初期表示カテゴリ（追加）
                            configtableData[section][row!].defaultNo = i+1
                            configtableData[section][row!].defaultSt = dispData[i]
                            
                        case "is_tapsound","is_errorbeep","topreturn_sound","is_senddata","is_senderror","is_order_s2e":     // 音設定
                            configtableData[section][row!].defaultNo = sound[i]
                            configtableData[section][row!].defaultSt = dispData[i]
                        default:
                            configtableData[section][row!].defaultNo = i
                            configtableData[section][row!].defaultSt = dispData[i]
                            break
                        }

                    }
                }
            }
            
        }
        
        

        self.performSegue(withIdentifier: "toConfigViewSegue",sender: nil)
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

    // 戻るボタンで戻ってくるためのおまじない
    @IBAction func unwindToConfigDetailView(_ segue: UIStoryboardSegue) {
        
    }

}


