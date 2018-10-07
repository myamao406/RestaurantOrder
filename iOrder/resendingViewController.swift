//
//  resendingViewController.swift
//  iOrder2
//
//  Created by 山尾 守 on 2016/11/29.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit
import FontAwesomeKit
import FMDB

class resendingViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UINavigationBarDelegate,UIActionSheetDelegate  {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var navBar: UINavigationBar!
    
    var tableViewMain = UITableView()
    
    struct resendData {
        var id:Int
        var resend_kbn:Int
        var resend_no:Int
        var resend_count:Int
        var resend_time:String
    }

    var resend:[resendData] = []
    
    var error_timer = Timer()
    
    // DBファイルパス
    var _path:String = ""
    
    let initVal = CustomProgressModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navBar.delegate = self
        navBar.barTintColor = iOrder_titleBlueColor

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
        iconImage = FAKFontAwesome.chevronCircleRightIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
        //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
        Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        okButton.setImage(Image, for: UIControlState())
        
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

        self.loadData()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DemoLabel.Show(self.view)
        DemoLabel.modeChange()
        
        if let indexPathForSelectedRow = tableViewMain.indexPathForSelectedRow {
            tableViewMain.deselectRow(at: indexPathForSelectedRow, animated: true)
        }
        
        // 未送信データがない場合は送信ボタンを押せなくする
        let db = FMDatabase(path: _path)
        
        // データベースをオープン
        db.open()
        
        let sql = "SELECT count(*) FROM resending WHERE resend_kbn in (1,2);"
        let results = db.executeQuery(sql, withArgumentsIn: [])
        while (results?.next())! {
            if (results?.int(forColumnIndex:0))! <= 0 {
                okButton.isEnabled = false
                okButton.alpha = 0.6
            }
        }
    }

    
    // ステータスバーとナビゲーションバーの色を同じにする
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.topAttached
    }
    
    // ステータスバーの文字を白にする
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    func loadData() {
        
        resend = []

        let db = FMDatabase(path: _path)
        
        // データベースをオープン
        db.open()
        
//        "CREATE TABLE IF NOT EXISTS resending(id INTEGER PRIMARY KEY AUTOINCREMENT, resend_kbn INTEGER, resend_no INTEGER, resend_count INTEGER, sendtime TEXT);"
        
        let sql = "SELECT * FROM resending WHERE resend_kbn in (1,2);"
        let results = db.executeQuery(sql, withArgumentsIn: [])
        while (results?.next())! {
            resend.append(resendData(
                id          : Int((results?.int(forColumn:"id"))!),
                resend_kbn  : Int((results?.int(forColumn:"resend_kbn"))!),
                resend_no   : Int((results?.int(forColumn:"resend_no"))!),
                resend_count: Int((results?.int(forColumn:"resend_count"))!),
                resend_time : (results?.string(forColumn:"sendtime"))!)
            )
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
        let xib = UINib(nibName: "resendingTableViewCell", bundle: nil)
        self.tableViewMain.register(xib, forCellReuseIdentifier: "Cell")
        
    }
    
    // 行数を返す（UITableViewDataSource）
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 行数はセルデータの個数
        return resend.count
        
    }
    // セルにデータを設定する（UITableViewDataSource）
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セルを取り出す
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! resendingTableViewCell
        // セルに表示するデータを取り出す
        let resendData = resend[indexPath.row]
        
        cell.resend_kbnLabel.text = resendData.resend_kbn == 1 ? "オーダー" : "残数設定"
        cell.resend_timeLabel.text = resendData.resend_time + " 送信"
        
       return cell
    }
    
    // セクション数
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // セクションヘッダーの高さ
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    // セルの高さを返す（UITableViewDelegate）
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat{
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! resendingTableViewCell
        // セルの高さ
                return cell.bounds.height
//        return (tableViewMain.bounds.height / table_row[disp_row_height])
    }

    // Cell が選択された場合
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath:IndexPath) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        // SubViewController へ遷移するために Segue を呼び出す
        // セルに表示するデータを取り出す
        let resendData = resend[indexPath.row]
        globals_resend_no.0 = resendData.resend_kbn
        globals_resend_no.1 = resendData.resend_no
        globals_resend_id = resendData.id

        if resendData.resend_kbn == 1 {         // オーダー
            performSegue(withIdentifier: "toResendingDetailSegue",sender: nil)
            
        } else {                                // 残数
            performSegue(withIdentifier: "toResendingDetailSegue",sender: nil)
        }
    }

    // 全送信ボタンタップ
    @IBAction func resendButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        let alertController = UIAlertController(title: "全送信 確認", message: "リストの未送信データを再送信します。\nよろしいですか？", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel){
            action in print("Pushed cancel")
            return;
        }
        
        let okAction = UIAlertAction(title: "OK", style: .default){
            action in
            // タップ音
            TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
            print("Pushed OK")
            
            self.spinnerStart()
            
//            var is_err = true
            
            for (icnt,send) in self.resend.enumerated() {
                if send.resend_kbn == 1 {       // オーダー
                    let db = FMDatabase(path: self._path)
                    db.open()
                    
                    var staff = ""
                    
                    // 送信時間
                    let send_time = send.resend_time
                    
                    // 担当者名を取得
                    var sql = "SELECT * FROM staffs_now;"
                    let rs2 = db.executeQuery(sql, withArgumentsIn: [])
                    while (rs2?.next())! {
                        staff = (rs2?.string(forColumn:"staff_no"))!
                    }
                    
                    var params:[[String:Any]] = [[:]]
                    
                    params[0]["Process_Div"] = "1"
                    
                    var cnt = 0
                    
                    sql = "SELECT iorder_detail.*,iorder.table_no,iorder.Timezone_kbn,seat_master.seat_name,players.player_name_kanji FROM ((iorder INNER JOIN iorder_detail ON iorder.facility_cd = iorder_detail.facility_cd AND iorder.order_no = iorder_detail.order_no ) INNER JOIN seat_master ON iorder.table_no = seat_master.table_no AND iorder_detail.seat_no = seat_master.seat_no) INNER JOIN players ON players.member_no = iorder_detail.serve_customer_no WHERE iorder.order_no = ? AND iorder.store_cd = ?"
                    let results = db.executeQuery(sql, withArgumentsIn: [send.resend_no,shop_code])
                    while (results?.next())! {
                        let table_no = Int((results?.int(forColumn:"table_no"))!)
                        let detail_kbn = Int((results?.int(forColumn:"detail_kbn"))!)
                        let seat_no = Int((results?.int(forColumn:"seat_no"))!)
//                        let seat_name = results?.string(forColumn:"seat_name")
                        let customer_no = Int((results?.int(forColumn:"serve_customer_no"))!)
//                        let payment_customer_no = Int(results?.int(forColumn:"payment_customer_no"))
                        let payment_seat_no = Int((results?.int(forColumn:"payment_customer_seat_no"))!)
//                        let customer_name = results?.string(forColumn:"player_name_kanji")
                        let order_kbn = results?.int(forColumn:"order_kbn")
//                        let menu_no = Int(results?.int(forColumn:"menu_cd"))
                        let menu_no = results?.longLongInt(forColumn:"menu_cd")
                        let menu_name = results?.string(forColumn:"menu_name")
                        let p_menu_no = Int((results?.int(forColumn:"parent_menu_cd"))!)
                        let qty = Int((results?.int(forColumn:"qty"))!)
                        let timezone_kbn = Int((results?.int(forColumn:"Timezone_kbn"))!)
                        let price_kbn = Int((results?.int(forColumn:"unit_price_kbn"))!)
                        let image:Data? = results?.data(forColumn:"hand_image")
                        let branch_no = Int((results?.int(forColumn:"menu_branch"))!)
                        
//                        if order_kbn == 1 && menu_no <= 0 {
//                            // メインメニューでメニューNOが0以下の時、次のループに行く
//                            continue
//                        }
                        
                        cnt += 1
                        params.append([String:Any]())

                        params[cnt]["Store_CD"] = shop_code.description
                        params[cnt]["Table_NO"] = "\(table_no)"
                        params[cnt]["Detail_KBN"] = "\(detail_kbn)"
                        params[cnt]["Order_KBN"] = order_kbn?.description
                        params[cnt]["Seat_NO"] = "\(seat_no + 1)"
                        params[cnt]["Store_Menu_CD"] = "1"
                        params[cnt]["Timezone_KBN"] = "\(timezone_kbn)"
                        params[cnt]["Qty"] = qty
                        params[cnt]["Serve_Customer_NO"] = customer_no
                        
//                        params[cnt]["Payment_Customer_NO"] = payment_customer_no
                        
                        params[cnt]["Employee_CD"] = staff
                        params[cnt]["Unit_Price_KBN"] = price_kbn
                        params[cnt]["Pm_Start_Time"] = globals_pm_start_time

                        params[cnt]["SendTime"] = send_time      // 送信日時（yyyy/mm/dd HH:mm:ss）（拡張用）
                        params[cnt]["Selling_Price"] = ""       // 金額（拡張用）
                        params[cnt]["TerminalID"] = TerminalID          // 端末ID（拡張用）
                        params[cnt]["Reference"] = menu_name    // メニュー名
                        params[cnt]["Payment_Customer_Seat_No"] = payment_seat_no + 1   // 支払者のシートNO
                        params[cnt]["Slip_NO"] = ""             // 伝票NO

                        
                        if order_kbn == 1 {             // メインメニュー
                            let payment_customer_no = Int((results?.int(forColumn:"payment_customer_no"))!)

                            params[cnt]["Payment_Customer_NO"] = payment_customer_no
                            
                            if menu_no! > 0 {
                                params[cnt]["Menu_CD"] = menu_no?.description
                                params[cnt]["Menu_SEQ"] = branch_no.description
                            } else {
                                params[cnt]["Menu_CD"] = ""
                                params[cnt]["Menu_CEQ"] = ""
                            }
                            params[cnt]["Sub_Menu_KBN"] = ""
                            params[cnt]["Sub_Menu_CD"] = ""
                            params[cnt]["Spe_Menu_KBN"] = ""
                            params[cnt]["Spe_Menu_CD"] = ""
                            
                            // カテゴリ番号取得
                            var cc1 = ""
                            var cc2 = ""
                            let sql1 = "SELECT * FROM menus_master WHERE item_no = ?"
                            let rs1 = db.executeQuery(sql1, withArgumentsIn: [NSNumber(value: menu_no!)])
                            while (rs1?.next())! {
                                cc1 = ((rs1?.int(forColumn:"category_no1"))?.description)!
                                cc2 = ((rs1?.int(forColumn:"category_no2"))?.description)!
                            }
                            
                            params[cnt]["Category_CD1"] = cc1
                            params[cnt]["Category_CD2"] = cc2

                            // 手書き情報取得
                            var image_string = ""
                            if image != nil {
                                image_string = image!.base64EncodedString(options: .lineLength64Characters)
                            }
                            //                        image_string = image!.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
                            
                            let urlencodeString = image_string.replacingOccurrences(of: "+", with: "%2B")
                            params[cnt]["Handwriting"] = urlencodeString

                            
                        } else if order_kbn == 2 {      // セレクトメニュー
                            let payment_customer_no = fmdb.get_payment_customer_no(results!)
                            
                            params[cnt]["Payment_Customer_NO"] = payment_customer_no
                            
                            // メニュー区分、サブメニューコード取得
                            var menu_kbn = ""
                            let sql = "SELECT * from sub_menus_master WHERE menu_no = ? AND item_name = ?;"
                            let rs = db.executeQuery(sql, withArgumentsIn: [p_menu_no,menu_name!])
                            while (rs?.next())! {
                                menu_kbn = ((rs?.int(forColumn:"sub_menu_group"))?.description)!
                            }
                            
                            params[cnt]["Menu_CD"] = "\(p_menu_no)"
                            params[cnt]["Menu_SEQ"] = branch_no.description
                            params[cnt]["Sub_Menu_KBN"] = menu_kbn
                            params[cnt]["Sub_Menu_CD"] = menu_no?.description
                            params[cnt]["Spe_Menu_KBN"] = ""
                            params[cnt]["Spe_Menu_CD"] = ""
                            
                            params[cnt]["Category_CD1"] = ""
                            params[cnt]["Category_CD2"] = ""
                            params[cnt]["Handwriting"] = ""

                            
                        } else if order_kbn == 3 {      // オプションメニュー
                            let payment_customer_no = fmdb.get_payment_customer_no(results!)
                            
                            params[cnt]["Payment_Customer_NO"] = payment_customer_no
                            
                            // 特殊メニュー区分、特殊メニューコード取得
                            var spe_menu_kbn = ""
                            let sql = "SELECT * from special_menus_master WHERE item_name = ?;"
                            let rs = db.executeQuery(sql, withArgumentsIn: [menu_name!])
                            while (rs?.next())! {
                                spe_menu_kbn = ((rs?.int(forColumn: "category_no"))?.description)!
                            }
                            
                            params[cnt]["Menu_CD"] = "\(p_menu_no)"
                            params[cnt]["Menu_SEQ"] = branch_no.description
                            params[cnt]["Sub_Menu_KBN"] = ""
                            params[cnt]["Sub_Menu_CD"] = ""
                            params[cnt]["Spe_Menu_KBN"] = spe_menu_kbn
                            params[cnt]["Spe_Menu_CD"] = (menu_no)?.description
                            
                            params[cnt]["Category_CD1"] = ""
                            params[cnt]["Category_CD2"] = ""
                            params[cnt]["Handwriting"] = ""

                        }
                    }
                    
                    let json = JSON(params)
                    
                    let str = "sJson=" + json.toString()
                    let strData = str.data(using: String.Encoding.utf8)
                    
                    print(str)
                    
                    let url = URL(string:urlString + "SendOrder")
                    var request = URLRequest(url: url!)

                    request.httpMethod = "POST"
                    request.httpBody = strData
                    request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData
                    request.timeoutInterval = 10.0
                    
//                    let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
//                    let session = NSURLSession(configuration: configuration, delegate:nil, delegateQueue:NSOperationQueue.mainQueue())

//                    self.dispatch_async_global {
                        self.sendSynchronize(request, completion:{data, res, error in
//                        let task = session.dataTaskWithRequest(request, completionHandler: {
//                            (data, response, error) -> Void in
                            
                            do {
                                
                                if error == nil {
                                    let json2 = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.allowFragments ) as! NSDictionary
                                    print(json2)
                                    
                                    let json_return = JSON(json2)
                                    if json_return.asError == nil {
                                        for (key, value) in json_return {
                                            if key as! String == "Return" {
                                                if value.toString() == "true" {
                                                    let db = FMDatabase(path: self._path)
                                                    db.open()
                                                    let sql = "DELETE FROM resending WHERE resend_no = ?"
                                                    let _ = db.executeUpdate(sql, withArgumentsIn: [send.resend_no])
                                                    db.close()
                                                    self.performSegue(withIdentifier: "toTopSegue",sender: nil)
                                                    self.spinnerEnd()

                                                }
                                            }
                                            if key as! String == "Message" {
                                                if value.toString() != "" {
                                                    self.spinnerEnd()

                                                    let msg = value.toString()
                                                    print(msg)
                                                    self.return_error(msg)
                                                } else {
                                                    let db = FMDatabase(path: self._path)
                                                    db.open()
                                                    let sql = "DELETE FROM resending WHERE resend_no = ?"
                                                    let _ = db.executeUpdate(sql, withArgumentsIn: [send.resend_no])
                                                    db.close()
                                                    
                                                    if icnt >= self.resend.count {
                                                    self.performSegue(withIdentifier: "toTopSegue",sender: nil)
                                                    }
                                                    
                                                    self.spinnerEnd()
                                                    
                                                }
                                            }
                                        }
                                    }

//                                    is_err = false
//
//                                    self.spinnerEnd()
                                    
                                    //                            self.performSegue(withIdentifier:"toMainMenuViewController",sender: nil);
                                } else {
//                                    is_err = true
                                    print("ERROR1",error?.localizedDescription as Any )
                                    
                                    //エラー処理
                                    self.dispatch_async_main {
                                        self.spinnerEnd()
                                        let msg = "再送信に失敗しました。\nネットワークの設定を確認して下さい。"
                                        self.send_error(msg)
                                        return;
                                    }

                                    
                                }
                            } catch {
//                                is_err = true
                                print("ERROR2",error )
                                
                                //エラー処理
                                self.dispatch_async_main {
                                    self.spinnerEnd()
                                    self.send_error("")
                                    return;
                                }
                            }
                            
                        })
                        
//                        task.resume()
                    
//                    }
                    
                    db.close()
                    
                } else {                        // 残数
                    
                    self.spinnerStart()
                    

                    let url = URL(string:urlString + "SendRemainNum?Store_CD=" + shop_code.description + "&" + "Menu_CD=" + "\(send.resend_no)" + "&" + "Remain_Num=" + "\(send.resend_count)")
                    var request = URLRequest(url: url!)
                    
                    request.httpMethod = "GET"
                    request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData
                    request.timeoutInterval = 10.0
                    
                     self.sendSynchronize(request, completion:{data, res, error in
                        
                        do {
                            if error == nil {
                                let json2 = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.allowFragments ) as! NSDictionary
                                print(json2)
                                
                                let json_return = JSON(json2)
                                
                                if json_return.asError == nil {
                                    for (key, value) in json_return {
                                        if key as! String == "Return" {
                                            if value.toString() == "true" {
                                                let db = FMDatabase(path: self._path)
                                                db.open()
                                                let sql = "DELETE FROM resending WHERE resend_no = ?"
                                                let _ = db.executeUpdate(sql, withArgumentsIn: [send.resend_no])
                                                db.close()
                                                self.performSegue(withIdentifier: "toTopSegue",sender: nil)
                                                self.spinnerEnd()
                                                
                                            }
                                        }
                                        if key as! String == "Message" {
                                            if value.toString() != "" {
                                                self.spinnerEnd()
                                                
                                                let msg = value.toString()
                                                print(msg)
                                                self.return_error(msg)
                                            } else {
                                                let db = FMDatabase(path: self._path)
                                                db.open()
                                                let sql = "DELETE FROM resending WHERE resend_no = ?"
                                                let _ = db.executeUpdate(sql, withArgumentsIn: [send.resend_no])
                                                db.close()
                                                
                                                if icnt >= self.resend.count {
                                                    self.performSegue(withIdentifier: "toTopSegue",sender: nil)
                                                }
                                                
                                                self.spinnerEnd()
                                                
                                            }
                                        }
                                    }
                                }
                                
                                
                            } else {
                                print("ERROR1",error?.localizedDescription as Any )
                                
                                //エラー処理
                                self.dispatch_async_main {
                                    self.spinnerEnd()
                                    let msg = "再送信に失敗しました。\nネットワークの設定を確認して下さい。"
                                    self.send_error(msg)
                                    return;
                                }
                            }
                        } catch {
                            //                                is_err = true
                            print("ERROR2",error )
                            
                            //エラー処理
                            self.dispatch_async_main {
                                self.spinnerEnd()
                                self.send_error("")
                                return;
                            }
                        }
                    })

                }
                
            }
            
            return;
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)

    }
    
    
    // 戻るボタンタップ
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

    // 戻るボタンで戻ってくるためのおまじない
    @IBAction func unwindToResendingView(_ segue: UIStoryboardSegue) {
        
    }

    func updateList() {
        loadData()
        tableViewMain.reloadData()
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

    func return_error(_ msg:String){
        
        let error_timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(error_beep), userInfo: nil, repeats: true)

        
        let alertController = UIAlertController(title: "エラー！", message: msg , preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default){
            action in print("Pushed OK")
            // タイマー破棄
            error_timer.invalidate()
            
            return;
        }
        
        alertController.addAction(okAction)
        
        present(alertController, animated: true, completion: nil)
        
    }
    
    func send_error(_ msg:String){
        
        let message = msg != "" ? msg : "送信エラーが発生しました。\n再送信を行ってください。"

        if error_timer.isValid {
            self.error_timer.invalidate()
        }
        error_timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(error_beep), userInfo: nil, repeats: true)

        let alertController = UIAlertController(title: "エラー！", message: message , preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default){
            action in print("Pushed OK")
            
            // タイマー破棄
            self.error_timer.invalidate()
            // 再送信エラーのタイマー破棄
            order_resend_time = 0
            order_resend_timer.invalidate()

            self.performSegue(withIdentifier: "toTopSegue",sender: nil);
            
            return;
        }
        
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }

    func error_beep(_ sender:Timer){
        // エラー音
        TapSound.buttonTap(err_sound_file.sound_file, type: err_sound_file.file_type)
    }

    func sendSynchronize(_ request:URLRequest,completion: @escaping (Data?, URLResponse?, NSError?) -> Void) {
        let semaphore = DispatchSemaphore(value: 0)
        let subtask = URLSession.shared.dataTask(with: request, completionHandler: { data, res, error in
            completion(data, res, error as NSError?)
            semaphore.signal()
        })
        subtask.resume()
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    }

}
