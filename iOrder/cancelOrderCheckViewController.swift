//
//  cancelOrderCheckViewController.swift
//  iOrder2
//
//  Created by 山尾 守 on 2017/01/24.
//  Copyright © 2017年 山尾守. All rights reserved.
//

import UIKit
import FontAwesomeKit
import FMDB
import Toast_Swift

class cancelOrderCheckViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UINavigationBarDelegate,UIActionSheetDelegate {

    fileprivate var onceTokenViewDidAppear: Int = 0
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var okButton: UIButton!
    
    var handImage:UIImage?
    var subMenuImage:UIImage?
    var speMenuImage:UIImage?

    lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        return dateFormatter
    }()

    var cancel_Disp_backup:[[cancel_cellData]] = []
    
    var tableViewMain = UITableView()

    // DBファイルパス
    var _path:String = ""

    //CustomProgressModelにあるプロパティが初期設定項目
    let initVal = CustomProgressModel()

    // 送信日時
    var sendTime = ""
    
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
        iconImage = FAKFontAwesome.checkIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
        //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
        Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        okButton.setImage(Image, for: UIControlState())

        // 手書きイメージ
        iconImage = FAKFontAwesome.handPointerOIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.black)
        handImage = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        
        // サブメニューアイコン
        iconImage = FAKFontAwesome.caretRightIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_subMenuColor)
        subMenuImage = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        
        // スペシャルメニューアイコン
        iconImage = FAKFontAwesome.caretRightIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_specialMenuColor)
        speMenuImage = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))

        
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
        
        // セクションをシートNO順にする
        Section.sort(by: {$0.seat_no < $1.seat_no})
        
        cancel_Disp_backup = cancel_Disp
        
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
        let xib = UINib(nibName: "orderMakeSureTableViewCell", bundle: nil)
        self.tableViewMain.register(xib, forCellReuseIdentifier: "Cell")

    }
    
    // 行数を返す（UITableViewDataSource）
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 行数はセルデータの個数
        
        return cancel_Disp[section].count
    }

    // セルにデータを設定する（UITableViewDataSource）
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // セルを取り出す
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! orderMakeSureTableViewCell
        
        // 選択時に色を変えない
        cell.selectionStyle = UITableViewCellSelectionStyle.none
    
        // ラベルにテキストを設定する
        // まずすべてのアイテムを非表示にする
        cell.setButton.isHidden = true
        cell.orderCountLabel.isHidden = true
        cell.handWrightButton.isHidden = true
        cell.orderAddButton.isHidden = true
        cell.subOrderNameLabel.isHidden = true
        cell.subOrderImage.isHidden = true
        cell.orderNameLabel.isHidden = true
        cell.orderName2Label.isHidden = true
        cell.orderNameKanaLabel.isHidden = true
        
        let cell_data = cancel_Disp[indexPath.section][indexPath.row]

        // 支払者の席番号
        if cell_data.MenuType == 1 {
            cell.setButton.isHidden = false
            cell.setButton.setTitle(cell_data.seat, for: UIControlState())
        }
        cell.setButton.setTitle(cell_data.seat  , for: UIControlState())

        // メニュー名
        if cell_data.MenuType == 1 {
            cell.orderNameLabel.isHidden = false
            cell.orderNameLabel.text = cell_data.Name
        } else {    // サブ or オプション
            cell.orderNameLabel.text = "   ∟  " + cell_data.Name
            cell.orderNameLabel.isHidden = true
            cell.subOrderNameLabel.text = cell_data.Name
            cell.subOrderNameLabel.isHidden = false
        }
        
        // 注文数
//        if Int(cell_data.Count) >= 0 {
//            cell.orderCountLabel.hidden = false
//            cell.orderCountLabel.text = cell_data.Count
//        }
        cell.orderCountLabel.isHidden = false
        cell.orderCountLabel.text = cell_data.Count
        
        // 手書き表示有無ボタン
        if cell_data.Hand == true {
            // ボタンに画像をセットする
            cell.handWrightButton.setImage(handImage, for: UIControlState())
            
            cell.handWrightButton.isHidden = false
        }
        
        // cellの色を設定
        switch cell_data.MenuType {
        case 1:
            cell.orderNameLabel.textColor = iOrder_blackColor
        case 2:
            cell.orderNameLabel.textColor = iOrder_subMenuColor
            cell.subOrderImage.image = subMenuImage
            cell.subOrderImage.isHidden = false
        case 3:
            cell.orderNameLabel.textColor = iOrder_specialMenuColor
            cell.subOrderImage.image = speMenuImage
            cell.subOrderImage.isHidden = false
        default:
            break
        }

        //セルに左スワイプをつける
        let swipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(cancelOrderSelectViewController.swipeLabel(_:)))
        swipeRecognizer.direction = .left
        cell.addGestureRecognizer(swipeRecognizer)

        
        return cell
    }
    
    // セクション数
    func numberOfSections(in tableView: UITableView) -> Int {

        return Section.count
    }

    // セクションの高さ
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return tableViewHeaderHeight
    }
    
    // セクションのタイトルを詳細に設定
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView:UIView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: tableViewHeaderHeight))
        
        let fontName = "YuGo-Bold"    // "YuGo-Medium"
        
        var posX:CGFloat = 0.0
        let posY:CGFloat = tableViewHeaderHeight / 2
        let betweenWidth:CGFloat = 10.0
        
        // 席ボタンの設置
        let seatNameButton   = UIButton()
        seatNameButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        seatNameButton.backgroundColor = iOrder_orangeColor
        seatNameButton.layer.position = CGPoint(x: posX + seatNameButton.frame.width / 2 + betweenWidth - 2 , y: posY  )
        
        seatNameButton.setTitleColor(UIColor.white, for: UIControlState())
        // フォント名の指定はPostScript名
        seatNameButton.titleLabel!.font = UIFont(name: fontName,size: CGFloat(20))
        
        seatNameButton.setTitle(Section[section].seat, for: UIControlState())
        // タグ番号
        seatNameButton.tag = section + 1
        
        posX = betweenWidth + seatNameButton.frame.width
        
        // ホルダNOの設定
        let holderNoLabel = UILabel()
        holderNoLabel.frame = CGRect(x: 0, y: 0, width: 70, height: 30)
        holderNoLabel.layer.position = CGPoint(x:posX + holderNoLabel.frame.width / 2 + betweenWidth, y: posY)
        holderNoLabel.font = UIFont(name: fontName,size: CGFloat(20))
        holderNoLabel.layer.cornerRadius = 5.0
        holderNoLabel.clipsToBounds = true
        holderNoLabel.textAlignment = .center
        holderNoLabel.text = Section[section].No
        holderNoLabel.textColor = UIColor.white
        
        let status = fmdb.getPlayerStatus(Section[section].No)
        switch status {
        case 0,1:       // チェックイン
            break;
        case 2:         // チェックアウト
            holderNoLabel.backgroundColor = iOrder_grayColor
            holderNoLabel.textColor = UIColor.white
            
            break;
        case 3:         // キャンセル
            holderNoLabel.backgroundColor = iOrder_grayColor
            holderNoLabel.textColor = UIColor.white
            break;
        case 9:         // 予約
            holderNoLabel.backgroundColor = iOrder_grayColor
            holderNoLabel.textColor = UIColor.white
            break;
        default:
            break;
        }

        
        posX = posX + betweenWidth + holderNoLabel.frame.width
        
        // プレイヤー名の設定
        let playerNameLabel = UILabel()
        playerNameLabel.frame = CGRect(x: 0, y: 0, width: headerView.frame.width - posX - (betweenWidth * 2), height: 30)
        
        let marginY:CGFloat = furigana == 1 ? 7 : 0
        
        playerNameLabel.layer.position = CGPoint(x:posX + playerNameLabel.frame.width / 2 + betweenWidth, y: posY + marginY)
        playerNameLabel.font = UIFont(name: fontName,size: CGFloat(20))
        playerNameLabel.numberOfLines = 0
        playerNameLabel.adjustsFontSizeToFitWidth = true
        playerNameLabel.minimumScaleFactor = 0.5
        playerNameLabel.lineBreakMode = .byTruncatingTail
        playerNameLabel.text = Section[section].Name
        playerNameLabel.textColor = UIColor.white
        
        if furigana == 1 {
            // プレイヤー名かなの設定
            let playerNameKanaLabel = UILabel()
            playerNameKanaLabel.frame = CGRect(x: 0, y: 0, width: headerView.frame.width - posX - (betweenWidth * 2), height: 14)
            //        playerNameLabel.backgroundColor = iOrder_borderColor
            playerNameKanaLabel.layer.position = CGPoint(x:posX + playerNameLabel.frame.width / 2 + betweenWidth, y: posY - 14)
            playerNameKanaLabel.font = UIFont(name: fontName,size: CGFloat(15))
            playerNameKanaLabel.numberOfLines = 0
            playerNameKanaLabel.adjustsFontSizeToFitWidth = true
            playerNameKanaLabel.minimumScaleFactor = 0.5
            playerNameKanaLabel.lineBreakMode = .byTruncatingTail
            playerNameKanaLabel.text = fmdb.getNameKana(Section[section].No)
            playerNameKanaLabel.textColor = UIColor.white
            //        playerNameKanaLabel.backgroundColor = iOrder_noticeRedColor
            
            headerView.addSubview(playerNameKanaLabel)
        }
        
        headerView.backgroundColor = iOrder_greenColor
        
        headerView.addSubview(seatNameButton)
        headerView.addSubview(holderNoLabel)
        headerView.addSubview(playerNameLabel)
        
        return headerView
    }

    // セルの高さを返す（UITableViewDelegate）
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat{

        return (tableViewMain.bounds.height / table_row[disp_row_height])
    }
    
    // Cell が選択された場合
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath:IndexPath) {
        
        let select_cell = cancel_Disp[indexPath.section][indexPath.row]
        
        if select_cell.Count != "" {
            var iCount:Int = Int(select_cell.Count)!
            var iCountAbs = abs(iCount)     // カウントの絶対値
            var maxCount = 0
            var maxCountAbs = 0
            // 注文数以上の数字入力抑止
            for main_menu in MainMenu {
                if main_menu.seat == select_cell.seat && main_menu.No == select_cell.No && main_menu.MenuNo == select_cell.MenuNo && main_menu.BranchNo == select_cell.BranchNo {
                    //注文数の最大値を取得
                    maxCount = Int(main_menu.Count)!
                    maxCountAbs = abs(maxCount)
                    break
                }
            }
            
            if !((maxCount < 0 && iCountAbs <= maxCountAbs && iCountAbs > 0 ) || (maxCount > 0 && iCountAbs < maxCountAbs)) {
            
//            if iCount >= maxCount {
                if maxCount > 0 {
                
                    // toast with a specific duration and position
                    self.view.makeToast("注文数以上のキャンセルは出来ません", duration: 1.0, position: .top)
                    return
                }
            }
            
            // タップ音
            TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
            if (maxCount < 0 && iCount < 0) || (maxCount > 0 && iCount >= 0){
//            if iCount >= 0 {
                iCount += 1
                iCountAbs = abs(iCount)
                cancel_Disp[indexPath.section][indexPath.row].Count = iCount.description
                self.tableViewMain.reloadRows(at: [indexPath], with: .none)
            }
        }
        
    }
    
    
    // 戻るボタンタップ
    @IBAction func backButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        self.performSegue(withIdentifier: "toCancelOrderSelectViewSegue",sender: nil)
    }

    // 送信ボタンタップ時
    @IBAction func dataSend(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
 
        // 確認のアラート画面を出す
        // タイトル
        let alert: UIAlertController = UIAlertController(title: "確認", message: "送信します。よろしいですか？", preferredStyle: UIAlertControllerStyle.alert)
        // アクションの設定
        let defaultAction: UIAlertAction = UIAlertAction(title: "送信", style: UIAlertActionStyle.default, handler: {(action: UIAlertAction!) -> Void in
            // タップ音
            TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
            
            print("OK")
            // 本番モード
            if demo_mode == 0 {
                
                
                // まずはデータ送信
                var params:[[String:Any]] = [[:]]
                
                let now = Date() // 現在日時の取得
                self.dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
                self.dateFormatter.timeStyle = .medium
                self.dateFormatter.dateStyle = .short
                
                self.sendTime = self.dateFormatter.string(from: now)
                
                params[0]["Process_Div"] = "1"
                
                let staff = fmdb.getStaffName()
                
                let db = FMDatabase(path: self._path)
                
                
                var cnt = 0
                
                for (i,sect) in Section.enumerated() {
                    // データベースをオープン
                    let cancel_orders = cancel_Disp[i].filter({$0.Count != "0"})
                    
                    db.open()
                    for cancel_order in cancel_orders {
                        
                        cnt += 1
                        
                        // プライス区分取得
                        var price_kbn = "1" // 存在しないプレイヤーの時
                        let results = db.executeQuery(SELECT_PLAYERS, withArgumentsIn: [Int(Section[i].No)!,shop_code,globals_today + "%"])

                        while (results?.next())! {
                            price_kbn = ((results?.int(forColumn:"price_tanka"))?.description)!
                        }
                        
                        params.append([String:Any]())
                        params[cnt]["Store_CD"] = shop_code.description
                        params[cnt]["Table_NO"] = "\(globals_table_no)"
                        params[cnt]["Detail_KBN"] = "3"
                        params[cnt]["Order_KBN"] = "1"
                        params[cnt]["Seat_NO"] = "\(sect.seat_no + 1)"
                        params[cnt]["Menu_CD"] = cancel_order.MenuNo
                        params[cnt]["Menu_SEQ"] = (cancel_order.BranchNo).description
                        params[cnt]["Store_Menu_CD"] = "1"
                        params[cnt]["Sub_Menu_KBN"] = ""
                        params[cnt]["Sub_Menu_CD"] = ""
                        params[cnt]["Spe_Menu_KBN"] = ""
                        params[cnt]["Spe_Menu_CD"] = ""
                        
                        // カテゴリ番号取得
                        var cc1 = ""
                        var cc2 = ""
//                        let cc = fmdb.getMenuCategory(Int64(cancel_order.MenuNo)!)
//                        cc1 = (cc.category1).description
//                        cc2 = (cc.category2).description
                        
                        let idx_cate = select_menu_categories.index(where: {$0.id == cancel_order.id})
                        if idx_cate != nil {
                            cc1 = (select_menu_categories[idx_cate!].category1).description
                            cc2 = (select_menu_categories[idx_cate!].category2).description
                        }
                        
                        
                        params[cnt]["Category_CD1"] = cc1
                        params[cnt]["Category_CD2"] = cc2
                        params[cnt]["Timezone_KBN"] = "\(cancel_order.timezone_kbn)"
                        params[cnt]["Qty"] = cancel_order.Count
                        params[cnt]["Serve_Customer_NO"] = sect.No
                        
                        params[cnt]["Payment_Customer_NO"] = cancel_order.payment_customer_no
                        
                        params[cnt]["Employee_CD"] = staff
                        params[cnt]["Unit_Price_KBN"] = price_kbn
                        params[cnt]["Pm_Start_Time"] = globals_pm_start_time
                        
                        // 手書き情報取得
                        params[cnt]["Handwriting"] = ""
                        params[cnt]["SendTime"] = self.sendTime // 送信日時（yyyy/mm/dd HH:mm:ss）（拡張用）
                        params[cnt]["Selling_Price"] = ""       // 金額（拡張用）
                        params[cnt]["TerminalID"] = TerminalID  // 端末ID（拡張用）
                        params[cnt]["Reference"] = cancel_order.Name    // メニュー名
                        params[cnt]["Payment_Customer_Seat_No"] = cancel_order.payment_seat_no + 1    // 支払者のシートNO
                        params[cnt]["Slip_NO"] = cancel_order.Slip_NO

                    }
                    db.close()
                }

                let json = JSON(params)
                
                let str = "sJson=" + json.toString()
                let strData = str.data(using: String.Encoding.utf8)
                
                let url = URL(string:urlString + "SendOrder")
                var request = URLRequest(url: url!)
                
                print(str)
                
                request.httpMethod = "POST"
                request.httpBody = strData
                request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData
                request.timeoutInterval = 10.0
                
                let configuration = URLSessionConfiguration.default
                let session = URLSession(configuration: configuration, delegate:nil, delegateQueue:OperationQueue.main)
                
                //                var is_err = false
                let task = session.dataTask(with: request, completionHandler: {
                    (data, response, error) -> Void in
                    if error == nil {
                        do {
                            let json2 = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.allowFragments ) as! NSDictionary
                            print(json2)
                            let rs_json = JSON(json2)
                            if rs_json.asError == nil {
                                for (key, value) in rs_json {
                                    if key as! String == "Return" {
                                        if value.toString() == "false" {
                                            print("更新情報なし")
                                        }
                                    }
                                    if key as! String == "Message" {
                                        if value.toString() != "" {
                                            self.jsonError(value.toString(),back_flag: true)
                                        } else {
                                            self.performSegue(withIdentifier: "toTopViewSegue",sender: nil)
                                        }
                                    }
                                }
                            } else {
                                self.spinnerEnd()
                                let e = rs_json.asError
                                print(e as Any)
                                self.jsonError("送信出来ませんでした。",back_flag:true)
                                
                            }
                            
                        } catch {
                            print("ERROR",error)
                            //エラー処理
                            self.jsonError("送信出来ませんでした。",back_flag:true)
                        }
                        
                    } else {
                        print("ERROR",error as Any)
                        //エラー処理
                        self.jsonError("送信出来ませんでした。",back_flag:true)
                    }
                })
                task.resume()
                
            } else {        // デモモード
                let db = FMDatabase(path: self._path)
                db.open()
                
                let sql = "UPDATE iOrder_detail SET qty = ? WHERE store_cd = ? AND order_no = ? AND branch_no = ?;"
                for (i,_) in Section.enumerated() {
                    for cancel_order in cancel_Disp[i] {
                        let iCount:Int = Int(cancel_order.Count)!
//                        var iCountAbs = abs(iCount)     // カウントの絶対値
                        var maxCount = 0
//                        var maxCountAbs = 0
                        for main_menu in MainMenu {
                            if main_menu.seat == cancel_order.seat && main_menu.No == cancel_order.No && main_menu.MenuNo == cancel_order.MenuNo && main_menu.BranchNo == cancel_order.BranchNo {
                                //注文数の最大値を取得
                                maxCount = Int(main_menu.Count)!
//                                maxCountAbs = abs(maxCount)
                                break
                            }
                        }
                        
                        let cansel_count = maxCount - iCount

                        
                        var argumentArray:Array<Any> = []
                        argumentArray.append(cansel_count)
                        argumentArray.append(shop_code)
                        argumentArray.append(cancel_order.order_no)
                        argumentArray.append(cancel_order.order_branch)
                        print(argumentArray)
                        let success = db.executeUpdate(sql, withArgumentsIn: argumentArray)
                        if !success {
                            // エラー時
                            print(success.description)
                        }
                    }
                }
                
                let sql_del = "DELETE FROM iOrder_detail WHERE qty = 0;"
                let _ = db.executeUpdate(sql_del, withArgumentsIn: [])
                
                db.close()
                self.performSegue(withIdentifier: "toTopViewSegue",sender: nil)
            }
        })
        // キャンセルボタン
        let cancelAction: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertActionStyle.cancel, handler: {(action: UIAlertAction!) -> Void in
            // タップ音
            TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
            
            print("キャンセル")
        })
        
        // UIAlertControllerにActionを追加
        alert.addAction(cancelAction)
        alert.addAction(defaultAction)
        
        // Alertを表示
        present(alert, animated: true, completion: nil)

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

    func swipeLabel(_ sender:UISwipeGestureRecognizer){
        let cell = sender.view as! UITableViewCell
        let indexPath = self.tableViewMain.indexPath(for: cell)!
        //        print(indexPath)
        
        let cell_data = cancel_Disp[indexPath.section][indexPath.row]
        
        switch(sender.direction){
        case UISwipeGestureRecognizerDirection.up:
            print("上")
            
        case UISwipeGestureRecognizerDirection.down:
            print("下")
            
        case UISwipeGestureRecognizerDirection.left:
            print("左1")
            if cell_data.Count != "" {
                // 音
                TapSound.buttonTap("swish1", type: "mp3")
                
                var iCount:Int = Int(cell_data.Count)!
                var iCountAbs = abs(iCount)     // カウントの絶対値

                var maxCount = 0
                var maxCountAbs = 0
                // 注文数以上の数字入力抑止
                let idx = MainMenu.index(where: {$0.id == cell_data.id})
                
                if idx != nil {
                    maxCount = Int(MainMenu[idx!].Count)!
                    maxCountAbs = abs(maxCount)
                }
                
//                for main_menu in MainMenu {
//                    if main_menu.seat == cell_data.seat && main_menu.No == cell_data.No && main_menu.MenuNo == cell_data.MenuNo && main_menu.BranchNo == cell_data.BranchNo {
//                        //注文数の最大値を取得
//                        maxCount = Int(main_menu.Count)!
//                        maxCountAbs = abs(maxCount)
//                        break
//                    }
//                }

                if (maxCount > 0 && iCountAbs > 0) || (maxCount < 0 && iCountAbs < maxCountAbs) {

//                if iCount > 0 {
                    iCount -= 1
                    iCountAbs = abs(iCount)
                    cancel_Disp[indexPath.section][indexPath.row].Count = iCount.description
                } else {
                    if maxCount < 0 {
                        // toast with a specific duration and position
                        self.view.makeToast("注文数以上のキャンセルは出来ません", duration: 1.0, position: .top)
                    }
                }
            }
            
            self.tableViewMain.reloadRows(at: [indexPath], with: .none)
            
        case UISwipeGestureRecognizerDirection.right:
            print("右1")
        default:
            break
        }
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
    
    func jsonError(_ msg:String,back_flag:Bool){
        // エラー音
        TapSound.buttonTap(err_sound_file.sound_file, type: err_sound_file.file_type)

        // エラー表示
        let alertController = UIAlertController(title: "エラー！", message: msg, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default){
            action in print("Pushed OK")
            if back_flag == true {
                self.performSegue(withIdentifier: "toTopViewSegue",sender: nil)
            }
            
            return;
        }
        
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
        
    }

}
