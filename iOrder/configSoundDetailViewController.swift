//
//  configSoundDetailViewController.swift
//  iOrder2
//
//  Created by 山尾 守 on 2017/01/31.
//  Copyright © 2017年 山尾守. All rights reserved.
//

import UIKit
import FontAwesomeKit
import FMDB


class configSoundDetailViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UINavigationBarDelegate{

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var navBar: UINavigationBar!

    var tableViewMain = UITableView()
    
    // 表示データ
    var dispData:[String] = []
    var selected:[Bool] = []
    var sound:[Int] = []
    
    let intervals = [["しない",0],["5分",5],["10分",10],["15分",15],["30分",30],["1時間",60]]
    
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
        
        var title = ""
        if globals_select_row == 0 {
            title = "サウンド"
        } else {
            title = "繰り返し間隔"
        }
        self.navBar.topItem?.title = title
        
        self.loadData()
        
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
        if globals_select_row == 0 {
//            switch globals_config_info!.item {
//            case "is_senddata" :
//                break
//            case "is_senderror" :
//                break
//            default:
//                break
//            }
            
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
                dispData.append((results?.string(forColumn: "disp_name"))!)
                selected.append(false)
                sound.append(Int((results?.int(forColumn:"sound_no"))!))
            }
            
            db.close()

            var sound_no = -1
            switch globals_config_info!.item {
            case "is_senddata" :
                sound_no = not_send_alert.sound_no
                break
            case "is_senderror" :
                sound_no = data_not_send_alert.sound_no
                break
            case "is_order_s2e" :
                sound_no = order_start2end_alert.sound_no
                break
            default:
                break
            }

            for i in 0..<sound.count {

                if sound[i] == sound_no {
                    selected[i] = true
                } else {
                    selected[i] = false
                }
            }

            
        } else {
            dispData = []
            selected = []

            for interval in intervals {
                print(interval[0])
                dispData.append(interval[0] as! String)
            }
            selected = Array(repeating: false, count: intervals.count)
            var select = -1
            var index = -1
            switch globals_config_info!.item {
            case "is_senddata" :
                select = not_send_alert.interval
                break
            case "is_senderror" :
                select = data_not_send_alert.interval
                break
            case "is_order_s2e" :
                select = order_start2end_alert.interval
                break
            default:
                break
            }
            index = (intervals.index(where: {$0[1] as! Int == select}))!
            selected[index] = true
            
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
        
        
        tableViewMain.rowHeight = UITableViewAutomaticDimension
        tableViewMain.allowsSelection = true

    }
    
    // セクション数
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
 
    // 行数を返す（UITableViewDataSource）
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dispData.count
    }
    
    
    // セルにデータを設定する（UITableViewDataSource）
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
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
    
    // Cell が選択された場合
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath:IndexPath) {
        
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! configDetailTableViewCell
        
        for i in 0..<dispData.count {
            cell.accessoryType = .none
            selected[i] = false
        }
        
        selected[indexPath.row] = true
        cell.accessoryType = .checkmark
        
        if globals_select_row == 0 {
            fmdb.soundsListMake(indexPath)
        }
        
        self.tableViewMain.reloadSections(IndexSet(integer: indexPath.section), with: .none)
        
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
            let sound_file = results?.string(forColumn: "sound_file")
            let file_type = results?.string(forColumn: "file_type")
            
            switch globals_config_info!.item {
            case "is_tapsound":     // 操作音
                tap_sound_file.0 = sound_file!
                tap_sound_file.1 = file_type!
            case "is_errorbeep":     // エラー音
                err_sound_file.0 = sound_file!
                err_sound_file.1 = file_type!
            case "topreturn_sound":     // トップに戻る音
                top_sound_file.0 = sound_file!
                top_sound_file.1 = file_type!
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

    
    // 戻るボタンタップ
    @IBAction func backButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        for (i,select) in selected.enumerated() {
            if select == true {
                switch globals_config_info!.item {
                case "is_senddata":     // データ送信失敗時の設定
                    // エラー音
                    if globals_select_row == 0 {
                        not_send_alert.sound_no = sound[i]
                    } else {        // 繰り返し設定
                        not_send_alert.interval = intervals[i][1] as! Int
                    }
                    
                case "is_senderror":     // データ未送信時の設定
                    // エラー音
                    if globals_select_row == 0 {
                        data_not_send_alert.sound_no = sound[i]
                    } else {        // 繰り返し設定
                        data_not_send_alert.interval = intervals[i][1] as! Int
                    }
                case "is_order_s2e" :
                    // エラー音
                    if globals_select_row == 0 {
                        order_start2end_alert.sound_no = sound[i]
                    } else {        // 繰り返し設定
                        order_start2end_alert.interval = intervals[i][1] as! Int
                    }
                default:
                    break
                }
                
            }
        }
        
        self.performSegue(withIdentifier: "toConfigDetailViewSegue",sender: nil)
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

}
