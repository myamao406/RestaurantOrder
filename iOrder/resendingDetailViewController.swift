//
//  resendingDetailViewController.swift
//  iOrder2
//
//  Created by 山尾 守 on 2016/11/29.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit
import FontAwesomeKit
import FMDB

class resendingDetailViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UINavigationBarDelegate {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var navBar: UINavigationBar!

    var handImage:UIImage?
    var subMenuImage:UIImage?
    var speMenuImage:UIImage?
    
    // DBファイルパス
    var _path:String = ""
    
    // テーブルビュー
    var tableViewMain = UITableView()

    // ユーザー別表示用バッファ
    var Section_User:[SectionData] = []             // セクションデータ
    var MainMenu_User:[CellData] = []               // メインメニュー
    var SubMenu_User:[SubMenuData] = []             // セレクトメニュー（サブメニュー）
    var SpecialMenu_User:[SpecialMenuData] = []     // オプションメニュー（特殊メニュー）

    // 画面表示用バッファ
    var Disp:[[CellData]] = []
    var Disp_Section:[SectionData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navBar.delegate = self
        navBar.barTintColor = iOrder_titleBlueColor

        // 戻るボタン
        var iconImage = FAKFontAwesome.chevronCircleLeftIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_bargainsYellowColor)
        var Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        backButton.setImage(Image, for: UIControlState())
        
        // 長押し
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.pressedLong2(_:)))
        
        backButton.addGestureRecognizer(longPress)

        // 削除ボタン
        iconImage = FAKFontAwesome.checkIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
        Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        deleteButton.setImage(Image, for: UIControlState())
        
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
        
        // テーブルNOを取得する
        _path = (paths[0] as NSString).appendingPathComponent(use_db)

        // ヘッダー表示
        var head_string = ""
        if globals_resend_no.0 == 1 {           // オーダー
            var table_no = 0
            let db = FMDatabase(path: _path)
            db.open()
            let sql = "SELECT * FROM iorder WHERE order_no = ?"
            let results = db.executeQuery(sql, withArgumentsIn: [globals_resend_no.1])
            while (results?.next())! {
                table_no = Int((results?.int(forColumn:"table_no"))!)
            }
            head_string = "テーブルNo：" + "\(table_no)"
            
        } else {                                // 残数
            head_string = "残数設定"
        }
        
        
        self.navBar.topItem?.title = head_string
        
        loadData()
        
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

    // MARK - TableView

    func loadData(){
        // ユーザー順データ
        self.Section_User = []
        self.MainMenu_User = []
        self.SubMenu_User = []
        self.SpecialMenu_User = []

        let db = FMDatabase(path: _path)
        db.open()
        
        if globals_resend_no.0 == 1 {           // オーダー
            let sql = "SELECT iorder_detail.*,seat_master.seat_name,players.player_name_kanji FROM ((iorder INNER JOIN iorder_detail ON iorder.facility_cd = iorder_detail.facility_cd AND iorder.order_no = iorder_detail.order_no ) INNER JOIN seat_master ON iorder.table_no = seat_master.table_no AND iorder_detail.seat_no = seat_master.seat_no) INNER JOIN players ON players.member_no = iorder_detail.serve_customer_no WHERE iorder.order_no = ? AND iorder.store_cd = ? "
            let results = db.executeQuery(sql, withArgumentsIn: [globals_resend_no.1,shop_code])
            while (results?.next())! {
                let seat_no = Int((results?.int(forColumn:"seat_no"))!)
                let seat_name = results?.string(forColumn:"seat_name")
                let customer_no = Int((results?.int(forColumn:"serve_customer_no"))!)
                let customer_name = results?.string(forColumn:"player_name_kanji")
                let payment_seat_no = Int((results?.int(forColumn:"payment_customer_seat_no"))!)
                let order_kbn = Int((results?.int(forColumn:"order_kbn"))!)
                let menu_no = results?.longLongInt(forColumn:"menu_cd")
                let menu_branch = Int((results?.int(forColumn:"menu_branch"))!)
                let qty = Int((results?.int(forColumn:"qty"))!)
                
                // セクション
                if Section_User.count > 0 {

                    let index = Section_User.index(where: {$0.seat_no == seat_no})
                    if index == nil {
                        Section_User.append(SectionData(
                            seat_no: seat_no,
                            seat: seat_name!,
                            No: "\(customer_no)",
                            Name: customer_name!
                            )
                        )
                    }
                    
                } else {
                    Section_User.append(SectionData(
                        seat_no: seat_no,
                        seat: seat_name!,
                        No: "\(customer_no)",
                        Name: customer_name!
                        )
                    )
                }
                
                
                switch order_kbn {
                case 1:
                    if menu_no! > 0 {
                        let menu_name = getMenuName(menu_no!)
                        let isHand = results?.data(forColumn:"hand_image") != nil ? true : false
                        // メイン
                        let id = MainMenu_User.count
                        MainMenu_User.append(CellData(
                            id:id,
                            seat: seat_name!,
                            No: "\(customer_no)",
                            Name: menu_name,
                            MenuNo: ((menu_no)?.description)! ,
                            BranchNo: menu_branch,
                            Count: "\(qty)",
                            Hand: isHand,
                            MenuType: 1,
                            payment_seat_no:payment_seat_no
                            )
                        )                        
                    }
                case 2:
                    let p_menu_no = results?.longLongInt(forColumn:"parent_menu_cd")
                    let sub_menu_group = Int((results?.string(forColumn:"payment_customer_no"))!)
                    
                    let sub_menu_name = getSubMenuName(p_menu_no!,sub_menu_group: sub_menu_group!,sub_menu_no: Int(menu_no!))
                    
                    // サブ
                    SubMenu_User.append(SubMenuData(
                        id:-1,
                        seat: seat_name!,
                        No: "\(customer_no)",
                        MenuNo: ((p_menu_no)?.description)! ,
                        BranchNo: menu_branch,
                        Name: sub_menu_name,
                        sub_menu_no: Int(menu_no!),
                        sub_menu_group: sub_menu_group!
                        )
                    )

                case 3:
                    let p_menu_no = Int((results?.int(forColumn:"parent_menu_cd"))!)
                    let category_no = Int((results?.string(forColumn:"payment_customer_no"))!)
                    let spe_menu_name = getSpeMenuName(Int(menu_no!),category_no: category_no!)
                    
                    // オプション
                    SpecialMenu_User.append(SpecialMenuData(
                        id:-1,
                        seat: seat_name!,
                        No: "\(customer_no)",
                        MenuNo: "\(p_menu_no)",
                        BranchNo: menu_branch,
                        Name: spe_menu_name,
                        category:category_no!
                        )
                    )
                default:
                    break;
                }
 
            }
            
            // id を振り分け
            for m in MainMenu_User {
                for (i,s) in SubMenu_User.enumerated() {
                    if (s.seat == m.seat && s.No == m.No && s.MenuNo == m.MenuNo && s.BranchNo == m.BranchNo) {
                        SubMenu_User[i].id = m.id
                    }
                }
                
                for (j,o) in SpecialMenu_User.enumerated() {
                    if (o.seat == m.seat && o.No == m.No && o.MenuNo == m.MenuNo && o.BranchNo == m.BranchNo) {
                        SpecialMenu_User[j].id = m.id
                    }
                }
            }

            
            
        } else if globals_resend_no.0 == 2 {                                // 残数
            var menu_no:Int64 = 0
            var cancel_count = 0
//            var send_time = ""
            
            let sql = "SELECT * FROM resending WHERE id = ?"
            let results = db.executeQuery(sql, withArgumentsIn: [globals_resend_id])
            while (results?.next())! {
                menu_no = (results?.longLongInt(forColumn:"resend_no"))!
                cancel_count = Int((results?.int(forColumn:"resend_count"))!)
//                send_time = results?.string(forColumn:"sendtime")
            }
         
            let menu_name = getMenuName(menu_no)
            
            MainMenu_User.append(CellData(
                id: -1,
                seat: "残",
                No: "",
                Name: menu_name,
                MenuNo: "\(menu_no)",
                BranchNo: 0,
                Count: "\(cancel_count)",
                Hand: false,
                MenuType: 1,
                payment_seat_no: 0
                )
            )
            
        }
        
        db.close()
        
        print(self.Section_User)
        print(self.MainMenu_User)
        print(self.SubMenu_User)
        print(self.SpecialMenu_User)

        
        // 表示用データの作成
        self.makeDispData()
        
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

    // 表示用データの作成
    func makeDispData() {
        // 表示用のデータを作成する
        Disp_Section = []
        
        Section_User = Section_User.sorted(by: {$0.seat_no < $1.seat_no})
        
        Disp_Section = Section_User
        Disp = []

        if globals_resend_no.0 == 1 {           // オーダー
//            for num in 0..<Section_User.count {
            for (num,sec) in Section_User.enumerated() {
                let holderNo = sec.No
                let seat = sec.seat
                
                // 多次元の可変配列の初期化
                self.Disp.append([CellData]())
                
                // メニュー
                for table in MainMenu_User {
                    if holderNo == table.No && seat == table.seat{
                        // メニューNOが0以外のもの
                        if table.MenuNo != "0" {
//                            if holderNo == table.No && seat == table.seat {
//                                
//                            }
                            let addData = CellData(
                                id: table.id,
                                seat: table.seat,
                                No: table.No,
                                Name: table.Name,
                                MenuNo: table.MenuNo,
                                BranchNo: table.BranchNo,
                                Count: table.Count,
                                Hand: table.Hand,
                                MenuType: table.MenuType,
                                payment_seat_no: table.payment_seat_no
                            )
                            self.Disp[num].append(addData)
                            
                            // サブメニュー
                            for sub in SubMenu_User {
                                if table.id == sub.id {
//                                if holderNo == sub.No {
                                    if table.seat == seat && table.MenuNo == sub.MenuNo && table.BranchNo == sub.BranchNo{
                                        let addData = CellData(
                                            id:table.id,
                                            seat: seat,
                                            No: sub.No,
                                            Name: sub.Name,
                                            MenuNo: sub.MenuNo,
                                            BranchNo: sub.BranchNo,
                                            Count: "",
                                            Hand: false,
                                            MenuType: 2,
                                            payment_seat_no: table.payment_seat_no
                                        )
                                        self.Disp[num].append(addData)
                                    }
                                }
                            }
                            
                            // 特殊メニュー
                            for special in SpecialMenu_User {
                                if table.id == special.id {
//                                if holderNo == special.No {
                                    if table.seat == seat && table.MenuNo == special.MenuNo && table.BranchNo == special.BranchNo{
                                        let index = self.Disp[num].filter{$0.seat == seat && $0.No == special.No && $0.Name == special.Name && $0.MenuNo == special.MenuNo && $0.BranchNo == special.BranchNo}
                                        if index.count == 0 {
                                            let addData = CellData(
                                                id:table.id,
                                                seat: seat,
                                                No: special.No,
                                                Name: special.Name,
                                                MenuNo: special.MenuNo,
                                                BranchNo: special.BranchNo,
                                                Count: "",
                                                Hand: false,
                                                MenuType: 3,
                                                payment_seat_no: table.payment_seat_no
                                            )
                                            self.Disp[num].append(addData)
                                            
                                        }
                                        
                                    }
                                }
                            }

                        }
                        
                    }
                }
            }
       
        } else {                                // 残数
            // 多次元の可変配列の初期化
            self.Disp.append([CellData]())
            
            // メニュー
            for (i,table) in MainMenu_User.enumerated() {
                let addData = CellData(
                    id:-1,
                    seat: table.seat,
                    No: table.No,
                    Name: table.Name,
                    MenuNo: table.MenuNo,
                    BranchNo: table.BranchNo,
                    Count: table.Count,
                    Hand: table.Hand,
                    MenuType: table.MenuType,
                    payment_seat_no: 0
                )
                self.Disp[i].append(addData)
            }
        }
            
        print(Disp_Section)
        print(Disp)
    }
    
    // 行数を返す（UITableViewDataSource）
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 行数はセルデータの個数
        
        return self.Disp[section].count
    }

    // セルにデータを設定する（UITableViewDataSource）
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // セルを取り出す
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! orderMakeSureTableViewCell
        
        // 選択時に色を変えない
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        
        let Disp_data = self.Disp[indexPath.section][indexPath.row]
 
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


        // メニュー名
        if Disp_data.MenuType == 1 {
            // 支払者の席番号
            var seat_name = ""
            
            if globals_resend_no.0 == 1 {           // オーダー
                let idx = Section_User.index(where: {$0.seat_no == Disp_data.payment_seat_no})
                if idx != nil {
                    seat_name = Section_User[idx!].seat
                }
            } else {                                // 残数
                seat_name = Disp_data.seat
            }
            
            
            cell.setButton.isHidden = false
//            cell.setButton.setTitle(Disp_data.seat, forState: .Normal)
            cell.setButton.setTitle(seat_name, for: UIControlState())

            cell.orderNameLabel.isHidden = false
            cell.orderNameLabel.text = Disp_data.Name
            cell.orderNameLabel.baselineAdjustment = .alignCenters
            // 注文数
            cell.orderCountLabel.isHidden = false
            cell.orderCountLabel.text = Disp_data.Count
            // cellの色を設定
            cell.orderNameLabel.textColor = iOrder_blackColor
        } else {    // サブ or オプション
            cell.orderNameLabel.text = "   ∟  " + Disp_data.Name
            cell.orderNameLabel.isHidden = true
            cell.subOrderNameLabel.text = Disp_data.Name
            cell.subOrderNameLabel.isHidden = false
            cell.subOrderNameLabel.baselineAdjustment = .alignCenters
            // cellの色を設定
            if Disp_data.MenuType == 2 {    // セレクト
                cell.orderNameLabel.textColor = iOrder_subMenuColor
                cell.subOrderImage.image = subMenuImage
                cell.subOrderImage.isHidden = false
            } else {                        // オプション
                cell.orderNameLabel.textColor = iOrder_specialMenuColor
                cell.subOrderImage.image = speMenuImage
                cell.subOrderImage.isHidden = false

            }
        }

        // 手書き表示有無ボタン
        if Disp_data.Hand == true {
            // ボタンに画像をセットする
            cell.handWrightButton.setImage(handImage, for: UIControlState())
            
            cell.handWrightButton.isHidden = false
        }

        return cell
    }
    
    // セクション数
    func numberOfSections(in tableView: UITableView) -> Int {
        //        return Section.count
        let section_count = globals_resend_no.0 == 1 ? Disp_Section.count : 1
        
        return section_count
    }

    // セクションヘッダーの高さ
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        let header_height:CGFloat = globals_resend_no.0 == 1 ? tableViewHeaderHeight : 0
        
        return header_height
    }

    // セクションのタイトルを詳細に設定
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView:UIView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: tableViewHeaderHeight))
        
        var posX:CGFloat = 0.0
        let posY:CGFloat = tableViewHeaderHeight / 2
        let betweenWidth:CGFloat = 10.0
        
        let fontName = "YuGo-Bold"    // "YuGo-Bold"
        
        // 席ボタンの設置
        let seatNameButton   = UIButton()
        seatNameButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        seatNameButton.backgroundColor = iOrder_orangeColor
        seatNameButton.layer.position = CGPoint(x: posX + seatNameButton.frame.width / 2 + betweenWidth - 2 , y: posY  )
        
        seatNameButton.setTitleColor(UIColor.white, for: UIControlState())
        // フォント名の指定はPostScript名
        seatNameButton.titleLabel!.font = UIFont(name: fontName,size: CGFloat(20))
        
        seatNameButton.setTitle(Disp_Section[section].seat, for: UIControlState())
//        seatNameButton.addTarget(self, action: #selector(orderMakeSureViewController.payChangeHeader(_:)), forControlEvents: .TouchUpInside)
        // 長押し
//        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(orderMakeSureViewController.pressedLong(_:)))
        
//        seatNameButton.addGestureRecognizer(longPress)
        // タグ番号
        seatNameButton.tag = section + 1
        
        posX = betweenWidth + seatNameButton.frame.width
        
        // ホルダNOの設定
        let holderNoLabel = UILabel()
        holderNoLabel.frame = CGRect(x: 0, y: 0, width: 70, height: 30)
        holderNoLabel.layer.position = CGPoint(x:posX + holderNoLabel.frame.width / 2 + betweenWidth, y: posY)
        holderNoLabel.font = UIFont(name: fontName,size: CGFloat(20))
        holderNoLabel.text = Disp_Section[section].No
        holderNoLabel.textColor = UIColor.white
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
        playerNameLabel.text = Disp_Section[section].Name
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
            playerNameKanaLabel.text = fmdb.getNameKana(self.Disp_Section[section].No)
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
        // セルの高さ
        return (tableViewMain.bounds.height / table_row[disp_row_height])
    }
    
    // ボタンを長押ししたときの処理
    @IBAction func pressedLong2(_ sender: UILongPressGestureRecognizer!) {
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
    
    // 削除ボタンタップ
    @IBAction func deleteButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        let alertController = UIAlertController(title: "削除　確認", message: "データを削除します。\nよろしいですか？", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel){
            action in print("Pushed cancel")
            return;
        }
        
        let okAction = UIAlertAction(title: "削除", style: .default){
            action in print("Pushed OK")
            
            let db = FMDatabase(path: self._path)
            
            // seat_holder テーブルの中身を削除
            db.open()
            let sql = "DELETE FROM resending WHERE id = ?"
            let _ = db.executeUpdate(sql, withArgumentsIn: [globals_resend_id])
            db.close()
            
            // 親VCを取り出し
            let parentVC = self.presentingViewController as? resendingViewController
            // ユーザデフォルトでラベル更新
            parentVC!.updateList()

            self.performSegue(withIdentifier: "toResendingViewSegue",sender: nil)
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
        self.performSegue(withIdentifier: "toResendingViewSegue",sender: nil)
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
    
    func getMenuName(_ menu_no:Int64) -> String {
        var menu_name = ""
        let db = FMDatabase(path: _path)
        db.open()
        let sql = "SELECT * FROM menus_master WHERE item_no = ?"
        let results = db.executeQuery(sql, withArgumentsIn: [NSNumber(value: menu_no as Int64)])
        while (results?.next())! {
            menu_name = (results?.string(forColumn:"item_name"))!
        }
        db.close()
        
        return menu_name
    }

    func getSubMenuName(_ menu_no:Int64,sub_menu_group:Int,sub_menu_no:Int) -> String {
        var sub_menu_name = ""
        
        let db = FMDatabase(path: _path)
        db.open()
        let sql = "SELECT * from sub_menus_master WHERE menu_no = ? AND sub_menu_group = ? AND sub_menu_no = ?"
        let results = db.executeQuery(sql, withArgumentsIn: [NSNumber(value: menu_no as Int64),sub_menu_group,sub_menu_no])
        while (results?.next())! {
            sub_menu_name = (results?.string(forColumn:"item_name"))!
        }
        db.close()
        return sub_menu_name
    }
    
    
    func getSpeMenuName(_ item_no:Int,category_no:Int) -> String {
        var spe_menu_name = ""
        
        let db = FMDatabase(path: _path)
        db.open()
        let sql = "SELECT * from special_menus_master WHERE item_no = ? AND category_no = ?"
        let results = db.executeQuery(sql, withArgumentsIn: [item_no,category_no])
        while (results?.next())! {
            spe_menu_name = (results?.string(forColumn:"item_name"))!
        }
        db.close()
        return spe_menu_name
    }

}
