//
//  playerssetViewController.swift
//  iOrder
//
//  Created by 山尾守 on 2016/06/30.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit
import FontAwesomeKit
import FMDB
import Toast_Swift

class playerssetViewController: UIViewController, UITableViewDelegate,UITableViewDataSource, UIPopoverPresentationControllerDelegate,UINavigationBarDelegate{

    private lazy var __once: () = {
                // Viewの高さと幅を取得する.
                let displayWidth: CGFloat = self.tableView.frame.width
                let displayHeight: CGFloat = self.tableView.frame.height
                
                // TableViewの生成する(status barの高さ分ずらして表示).
                self.tableViewMain = LPRTableView(frame: CGRect(x: 0, y: 0, width: displayWidth, height: displayHeight), style: UITableViewStyle.plain)
                
                
                // テーブルビューを追加する
                if !self.tableViewMain.isDescendant(of: self.tableView) {
                    self.tableView.addSubview(self.tableViewMain)
                }
                
                // テーブルビューのデリゲートとデータソースになる
                self.tableViewMain.delegate = self
                self.tableViewMain.dataSource = self
                
                // xibをテーブルビューのセルとして使う
                let xib = UINib(nibName: "playerTableViewCell", bundle: nil)
                self.tableViewMain.register(xib, forCellReuseIdentifier: "PlayersCell")
            }()

    fileprivate var onceTokenViewDidAppear: Int = 0

    // セルデータの型
    struct CellData2 {
        var id : Int
        var seat:String
        var holder:String
        var price:String
        var name:String
        var kana:String
        var message1:String
        var message2:String
        var message3:String
        var tanka:String
        var pmStartTime:String
        var status:Int
    }

    // セルデータの配列
    var tableData:[CellData2] = []
    var tableData_save:[CellData2] = []
    
    var seat_holders:[takeSeatPlayer] = []
    
    
    // シートの名称データ
    var seatName:[String] = []
    
    var timezone:String?
    
    //CustomProgressModelにあるプロパティが初期設定項目
    let initVal = CustomProgressModel()

    // 検索日付
    var today = ""
    
    // 選択された行
    var selectRow = -1
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var rightBarButton: UIBarButtonItem!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var tableView: UIView!
    
//    var tableViewMain = UITableView()
    var tableViewMain = LPRTableView()

    fileprivate var refreshControl = UIRefreshControl()
    
    // DBファイルパス
    var _path:String = ""

    // プライス区分
    var price_kbn:[(Int,String)] = []
    
    // メッセージエリアのtag番号
    var msgTag = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 背景色を白に設定する.
        self.view.backgroundColor = UIColor.white
        
        navBar.delegate = self
        navBar.barTintColor = iOrder_titleBlueColor

        // 戻るボタン
        let iconImage = FAKFontAwesome.chevronCircleLeftIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_bargainsYellowColor)
        //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
        let Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        backButton.setImage(Image, for: UIControlState())
        
        // 長押し
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.pressedLong(_:)))
        
        backButton.addGestureRecognizer(longPress)
        
        // 次へボタン
        let iconImage2 = FAKFontAwesome.chevronCircleRightIcon(withSize: iconSize)
        iconImage2?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
        //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
        let Image2 = iconImage2?.image(with: CGSize(width: iconSize, height: iconSize))
        okButton.setImage(Image2, for: UIControlState())

        if UIDevice.current.userInterfaceIdiom == .pad {
            okButton.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
            okButton.titleEdgeInsets = UIEdgeInsetsMake(0,-50, 0, 50)
            okButton.imageEdgeInsets = UIEdgeInsetsMake(0, 80.0, 0, -80)
        } else {
            okButton.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
            okButton.titleEdgeInsets = UIEdgeInsetsMake(0,-25, 0, 25)
            okButton.imageEdgeInsets = UIEdgeInsetsMake(0, 40.0, 0, -40)
        }
        
        // クリアボタン
        let iconImage3 = FAKFontAwesome.trashOIcon(withSize: iconSize)
        iconImage3?.addAttribute(NSForegroundColorAttributeName, value: iOrder_greenColor)
        //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
        let Image3 = iconImage3?.image(with: CGSize(width: iconSize, height: iconSize))
        clearButton.setImage(Image3, for: UIControlState())

        // clearボタンはリスト選択時だけ押せるようにする。
        clearButton.isEnabled = false
        clearButton.alpha = 0.6
        
        // 次へボタンはユーザーが座っているときだけ
        okButton.isEnabled = false
        okButton.alpha = 0.6
        
        
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
        
        // FMDatabaseクラスのインスタンスを作成
        // 引数にファイルまでのパスを渡す
        let db = FMDatabase(path: _path)
        
        // seat_holder テーブルの中身を削除
        db.open()
        let sql = "DELETE FROM seat_holder;"
        let _ = db.executeUpdate(sql, withArgumentsIn: [])
        
        // プライス区分情報を取得する
        price_kbn = []
        let sql1 = "SELECT * FROM unit_price_kbn ORDER BY price_kbn_no"
        let rs1 = db.executeQuery(sql1, withArgumentsIn: [])
        
        while (rs1?.next())!{
            price_kbn.append((Int((rs1?.int(forColumn:"price_kbn_no"))!),(rs1?.string(forColumn:"price_kbn_name"))!))
        }
        
        if price_kbn.count <= 0 {
            price_kbn.append((1,"一般"))
            price_kbn.append((2,"従業員"))
            price_kbn.append((3,"その他"))
        }
        
        db.close()
        
        takeSeatPlayers_temp = []
        
        // シートNO順でソート
        seat.sort{$0.seat_no < $1.seat_no}
        print(seat)
        for s in seat {
            self.seatName.append(s.seat_name)
        }
        
        let now = Date() // 現在日時の取得
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
        dateFormatter.dateFormat = "yyyy/MM/dd"
        
        today = dateFormatter.string(from: now)
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let selectedAttributes = [NSForegroundColorAttributeName : UIColor.white]
        
        let barItem = UIBarButtonItem(title: "テーブルNo: " + "\(globals_table_no)", style: .done, target: self, action: #selector(playerssetViewController.onClickExchangeSeat(_:)))
        
        barItem.setTitleTextAttributes(selectedAttributes, for: UIControlState())
        barItem.setTitleTextAttributes(selectedAttributes, for: .disabled)
        
        //        barItem.enabled = false
        barItem.isEnabled = true
        navBar.topItem?.setRightBarButton(barItem, animated: false)

//        if demo_mode == 0 {
//            // お客様情報取得
//            playersClass.get()
//        }
        
        self.loadData()
        if tableData.count > 0 {
            tableData_save = []
            tableData_save = tableData
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 0秒遅延
        let delayTime = DispatchTime.now() + Double(Int64(0.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            _ = self.__once
            
            // リフレッシュコントロールの設定をしてテーブルビューに追加
            self.refreshControl.attributedTitle = NSAttributedString(string: "来場者情報更新")
            self.refreshControl.addTarget(self, action: #selector(self.refresh), for: .valueChanged)
            self.tableViewMain.addSubview(self.refreshControl)
        
        }

        
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
        let db = FMDatabase(path: _path)
        
        // データベースをオープン
        db.open()
        var sql = "select * from seat_holder ORDER BY seat_no;"
        var results = db.executeQuery(sql, withArgumentsIn: [])
        
        self.seat_holders = []
        while (results?.next())! {
            
            self.seat_holders.append(takeSeatPlayer(
                seat_no     : Int((results?.int(forColumn:"seat_no"))!),
                holder_no   : (results?.string(forColumn:"holder_no"))!)
            )
        }
        db.close()
        
        // 新規の場合
        if globals_is_new == 1 {

            if tableData.count <= 0 {
                self.makeTableData()
            }

            // ホルダNO選択画面からの戻り値がある場合
            if seat_holders.count > 0 {
                self.set_players_data()
            }
            
        // 追加の場合
        } else {
            
            // デモモードの場合
            if demo_mode != 0{
                
                if tableData.count <= 0 {
                    self.makeTableData()
                }
                
                // ホルダNO選択画面からの戻り値がある場合
                if seat_holders.count > 0 {
                    self.set_players_data()
                // ホルダNO選択画面からの戻り値がない場合
                } else {
                    if self.tableData.count > 0 {
                        common.clear()
                        
                        db.open()
                        
                        if globals_is_new == 9 || globals_is_new == 10 {
                            sql = "SELECT  seat_master.seat_name,seat_master.seat_no,seat_master.holder_no9 AS holder_no, players.* FROM (seat_master LEFT JOIN players ON players.member_no = seat_master.holder_no9) WHERE seat_master.table_no = ? AND seat_master.holder_no9 > 0 ORDER BY seat_master.seat_no;"
                            
                        } else {
                            sql = "SELECT  seat_master.seat_name,seat_master.seat_no,seat_master.holder_no, players.* FROM (seat_master LEFT JOIN players ON players.member_no = seat_master.holder_no) WHERE seat_master.table_no = ? AND seat_master.holder_no > 0 ORDER BY seat_master.seat_no;"
                            
                        }
                        
                        results = db.executeQuery(sql, withArgumentsIn: [globals_table_no])
                        self.tableData = []
                        
                        for s in seat {
                            self.tableData.append (CellData2(
                                id:s.seat_no,
                                seat  :s.seat_name,
                                holder:"",
                                price :"",
                                name :"",
                                kana: "",
                                message1: "",
                                message2: "",
                                message3: "",
                                tanka: price_kbn[0].1  ,
                                pmStartTime: "",
                                status: 0
                                )
                            )
                            takeSeatPlayers_temp.append(takeSeatPlayer(
                                seat_no: s.seat_no,
                                holder_no: "")
                            )
                        }

                        
                        
                        while (results?.next())! {
                            let seat_no = Int((results?.int(forColumn:"seat_no"))!)
                            let seat_name = results?.string(forColumn:"seat_name")
                            let customer_no = Int((results?.int(forColumn:"holder_no"))!)
                            let mc = (results?.string(forColumn:"require_nm") != nil) ? results?.string(forColumn:"require_nm") : ""
                            let customer_name = (results?.string(forColumn:"player_name_kanji") != nil) ? results?.string(forColumn:"player_name_kanji") : ""
                            let customer_name_kana = (results?.string(forColumn:"player_name_kana") != nil) ? results?.string(forColumn:"player_name_kana") : ""
                            let m1 = (results?.string(forColumn:"message1") != nil) ? results?.string(forColumn:"message1") : ""
                            let m2 = (results?.string(forColumn:"message2") != nil) ? results?.string(forColumn:"message2") : ""
                            let m3 = (results?.string(forColumn:"message3") != nil) ? results?.string(forColumn:"message3") : ""
                            let pk = Int((results?.int(forColumn:"price_tanka"))!)
                            let pm_start_time = (results!.string(forColumn:"pm_start_time") != nil) ? results!.string(forColumn:"pm_start_time") : ""
                            let status = Int((results?.int(forColumn:"status"))!)
                            
                            let index = tableData.index(where: {$0.seat == seat_name})
                            
                            if index != nil {
                                
                                tableData[index!].holder = customer_no.description
                                tableData[index!].price = mc!
                                tableData[index!].name = customer_name!
                                tableData[index!].kana = customer_name_kana!
                                tableData[index!].message1 = m1!
                                tableData[index!].message2 = m2!
                                tableData[index!].message3 = m3!
                                tableData[index!].tanka = pk > 0 ? price_kbn[pk - 1].1 : price_kbn[0].1
                                tableData[index!].pmStartTime = pm_start_time!
                                tableData[index!].status = status
                            }
                            
                            let idx1 = takeSeatPlayers_temp.index(where: {$0.seat_no == seat_no})
                            if idx1 != nil {
                                takeSeatPlayers_temp[idx1!].holder_no = customer_no.description
                            }
  
                        }
                        
                        if globals_is_new == 9 || globals_is_new == 10 {
                            sql = "SELECT MAX(order_no) FROM iorder WHERE status_kbn = ? AND store_cd = ? AND table_no = ?;"
                            results = db.executeQuery(sql, withArgumentsIn: [globals_is_new,shop_code,globals_table_no])
                            var order_no_max = 0
                            while (results?.next())! {
                                order_no_max = Int((results?.int(forColumnIndex:0))!)
                            }
                            
                            sql = "SELECT iorder_detail.*,seat_master.seat_name,players.* FROM ((iorder INNER JOIN iorder_detail ON iorder.facility_cd = iorder_detail.facility_cd AND iorder.order_no = iorder_detail.order_no ) INNER JOIN seat_master ON iorder.table_no = seat_master.table_no AND iorder_detail.seat_no = seat_master.seat_no) LEFT JOIN players ON players.member_no = iorder_detail.serve_customer_no WHERE iorder.store_cd = ? AND iorder.table_no = ? AND iorder.order_no = ? ORDER BY iorder.order_no DESC , iorder_detail.seat_no;"
                            results = db.executeQuery(sql, withArgumentsIn: [shop_code,globals_table_no,order_no_max])
                            while (results?.next())! {
                                let seat_no = Int((results?.int(forColumn:"seat_no"))!)
                                let seat_name = results?.string(forColumn:"seat_name")
                                let customer_no = Int((results?.int(forColumn:"serve_customer_no"))!)
                                let customer_name = (results?.string(forColumn:"player_name_kanji") != nil) ? results?.string(forColumn:"player_name_kanji") : ""
                                
                                let payment_seat_no = Int((results?.int(forColumn:"payment_customer_seat_no"))!)
                                let order_kbn = Int((results?.int(forColumn:"order_kbn"))!)
                                let menu_no = results?.longLongInt(forColumn:"menu_cd")
                                let menu_branch = Int((results?.int(forColumn:"menu_branch"))!)
                                let qty = Int((results?.int(forColumn:"qty"))!)
                                let detail_kbn = Int((results?.int(forColumn:"detail_kbn"))!)
                                
                                // セクション
                                if Section.count > 0 {
                                    
                                    let index = Section.index(where: {$0.seat_no == seat_no})
                                    if index == nil {
                                        Section.append(SectionData(
                                            seat_no: seat_no,
                                            seat: seat_name!,
                                            No: "\(customer_no)",
                                            Name: customer_name!
                                            )
                                        )
                                    }
                                    
                                } else {
                                    Section.append(SectionData(
                                        seat_no: seat_no,
                                        seat: seat_name!,
                                        No: "\(customer_no)",
                                        Name: customer_name!
                                        )
                                    )
                                }
                                
                                if detail_kbn == 9 || detail_kbn == 10 {
                                    switch order_kbn {
                                    case 1:
                                        if menu_no! > 0 {
                                            let menu_name = getMenuName(menu_no!)
                                            var isHand = false
                                            if results?.data(forColumn: "hand_image") != nil {
                                                isHand = true
                                                // すでに存在していれば、UPDATE　なければ、INSERT
                                                let sql_hand = "SELECT COUNT(*) FROM hand_image WHERE seat = ? AND holder_no = ? AND branch_no = ? AND order_no = ?"
                                                
                                                let rs_hand = db.executeQuery(sql_hand, withArgumentsIn: [seat_name!, customer_no.description ,menu_branch,Int(menu_no!)])
                                                
                                                var image_count = 0
                                                while (rs_hand?.next())! {
                                                    image_count = Int((rs_hand?.int(forColumnIndex:0))!)
                                                }

                                                let imageData: Data? = results?.data(forColumn: "hand_image")

                                                var sql2 = ""
                                                var argumentArray:Array<Any> = []
                                                if image_count > 0 {
                                                    sql2 = "UPDATE hand_image SET hand_image = ? WHERE holder_no = ? AND order_no = ? AND branch_no = ? AND seat = ?;"
                                                    argumentArray.append(imageData!)
                                                    argumentArray.append(customer_no.description)
                                                    argumentArray.append(Int(menu_no!))
                                                    argumentArray.append(menu_branch)
                                                    argumentArray.append(seat_name!)
                                                } else {
                                                    sql2 = "INSERT INTO hand_image (hand_image,holder_no,order_no,branch_no,order_count,seat) VALUES(?,?,?,?,?,?);"
                                                    argumentArray.append(imageData!)
                                                    argumentArray.append(customer_no.description)
                                                    argumentArray.append(Int(menu_no!))
                                                    argumentArray.append(menu_branch)
                                                    argumentArray.append(qty)
                                                    argumentArray.append(seat_name!)
                                                }
                                                print(sql2)
                                                let results2 = db.executeUpdate(sql2, withArgumentsIn: argumentArray)
                                                if !results2 {
                                                    // エラー時
                                                    print(results2.description)
                                                }

                                            }
                                            
//                                            let isHand = results?.data(forColumn:"hand_image") != nil ? true : false
                                            // メイン
                                            let id = MainMenu.count
                                            
                                            MainMenu.append(CellData(
                                                id:id,
                                                seat: seat_name!,
                                                No: "\(customer_no)",
                                                Name: menu_name,
                                                MenuNo: (menu_no?.description)!,
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
                                        SubMenu.append(SubMenuData(
                                            id:-1,
                                            seat: seat_name!,
                                            No: "\(customer_no)",
                                            MenuNo: (p_menu_no?.description)!,
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
                                        SpecialMenu.append(SpecialMenuData(
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
    
                        
                        
                        }
                        
                        db.close()
/*
                        // 席数以下の場合は空データを追加する
                        if self.tableData.count < seat.count {
                            // シート名だけは変えない
                            for _ in 0..<seat.count - tableData.count  {
                                self.tableData.append (CellData2(
                                    id:-1,
                                    seat  :"",
                                    holder:"",
                                    price :"",
                                    name :"",
                                    kana: "",
                                    message1: "",
                                    message2: "",
                                    message3: "",
                                    tanka: price_kbn[0].1,
                                    pmStartTime: "",
                                    status: 0
                                    )
                                )
                                takeSeatPlayers_temp.append(takeSeatPlayer(
                                    seat_no: -1,
                                    holder_no: "")
                                )

                            }
                            
                            // シート名だけは変えない
                            for num in 0..<seat.count {
                                if tableData.count > num {
                                    tableData[num].seat = seat[num].seat_name
                                    takeSeatPlayers_temp[num].seat_no = seat[num].seat_no
                                }
                            }
                        }
 */
                    }
                }
                
            // 本番モード
            } else {
                if tableData.count <= 0 {
                    self.makeTableData()
                }
                // ホルダNO選択画面からの戻り値がある場合
                if seat_holders.count > 0 {
                    self.set_players_data()
                }
            }
        }
        
        // ホルダNOが一件でも入っていれば、次へボタンを活かす
        let index = tableData.index(where: {$0.holder != ""})
        if index != nil {
            okButton.isEnabled = true
            okButton.alpha = 1.0
        } else {
            okButton.isEnabled = false
            okButton.alpha = 0.6
        }
        
        self.tableViewMain.reloadData()
        
    }
    
    func makeTableData() {
        let db = FMDatabase(path: _path)
        
        self.tableData = []
        
        // シートNO順でソート
        seat.sort{$0.seat_no < $1.seat_no}
        print(seat)
        db.open()
        
        for s in seat {
            let index = takeSeatPlayers.index(where: {$0.seat_no == s.seat_no})
            if index != nil {
                let p_no = takeSeatPlayers[index!].holder_no
                if p_no != "" {
//                    let sql = "select * from players where member_no in (?) AND created LIKE ?;"
                    
                    let results = db.executeQuery(SELECT_PLAYERS, withArgumentsIn: [p_no,shop_code,today + "%"])
                    var is_no = true
                    while results!.next() {
                        is_no = false
                        let mn = (results!.string(forColumn: "member_no") != nil) ? results!.string(forColumn: "member_no") : ""
                        let mc = (results!.string(forColumn: "require_nm") != nil) ? results!.string(forColumn: "require_nm") : ""
                        
                        let pnkana = (results!.string(forColumn: "player_name_kana") != nil) ? results!.string(forColumn: "player_name_kana") : ""
                        let pnkanji = (results!.string(forColumn: "player_name_kanji") != nil) ? results!.string(forColumn: "player_name_kanji") : ""
                        let m1 = (results!.string(forColumn: "message1") != nil) ? results!.string(forColumn: "message1") : ""
                        let m2 = (results!.string(forColumn: "message2") != nil) ? results!.string(forColumn: "message2") : ""
                        let m3 = (results!.string(forColumn: "message3") != nil) ? results!.string(forColumn: "message3") : ""
                        
                        let pk = (Int(results!.int(forColumn: "price_tanka")) <= 0) ? 1 : Int(results!.int(forColumn: "price_tanka"))
                        let pm_start_time = (results!.string(forColumn: "pm_start_time") != nil) ? results!.string(forColumn: "pm_start_time") : ""
                        let status = Int(results!.int(forColumn: "status"))
                
                        
                        self.tableData.append (CellData2(
                            id      :s.seat_no,
                            seat  :s.seat_name,
                            holder:mn!,
                            price :mc!,
                            name :pnkanji!,
                            kana: pnkana!,
                            message1: m1!,
                            message2: m2!,
                            message3: m3!,
                            tanka: price_kbn[pk-1].1,
                            pmStartTime: s.seat_kbn == 1 ? pm_start_time! : "",
                            status:status
                            
                            )
                        )
                        
                        takeSeatPlayers_temp.append(takeSeatPlayer(
                            seat_no: s.seat_no,
                            holder_no: mn!)
                        )
                    }
                    
                    // レコードが存在しない時
                    if is_no == true {
                        self.tableData.append (CellData2(
                            id:s.seat_no,
                            seat  :s.seat_name,
                            holder:p_no,
                            price :"",
                            name :"",
                            kana: "",
                            message1: "",
                            message2: "",
                            message3: "",
                            tanka: price_kbn[0].1,
                            pmStartTime: "",
                            status:0
                            )
                        )
                        
                        takeSeatPlayers_temp.append(takeSeatPlayer(
                            seat_no: s.seat_no,
                            holder_no: p_no)
                        )
                    }
                    
                } else {        // 空き席の分を作る
                    self.tableData.append (CellData2(
                        id:s.seat_no,
                        seat  :s.seat_name,
                        holder:"",
                        price :"",
                        name :"",
                        kana: "",
                        message1: "",
                        message2: "",
                        message3: "",
                        tanka: price_kbn[0].1,
                        pmStartTime: "",
                        status:0
                        )
                    )
                    takeSeatPlayers_temp.append(takeSeatPlayer(
                        seat_no: s.seat_no,
                        holder_no: "")
                    )
                }
            } else {
                self.tableData.append (CellData2(
                    id:s.seat_no,
                    seat  :s.seat_name,
                    holder:"",
                    price :"",
                    name :"",
                    kana: "",
                    message1: "",
                    message2: "",
                    message3: "",
                    tanka: price_kbn[0].1,
                    pmStartTime: "",
                    status:0
                    )
                )
                
                takeSeatPlayers_temp.append(takeSeatPlayer(
                    seat_no: s.seat_no,
                    holder_no: "")
                )
                
            }
        }
        db.close()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // 行数を返す（UITableViewDataSource）
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 行数はセルデータの個数
        return tableData.count
    }
    
    // セルにデータを設定する（UITableViewDataSource）
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // セルを取り出す
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlayersCell") as! playerTableViewCell
        // セルに表示するデータを取り出す
        let cellData = tableData[indexPath.row]
        print(#function,cellData)
        
        // 円
        let iconImage = FAKFontAwesome.circleIcon(withSize: 50)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.darkGray)
        let Image = iconImage?.image(with: CGSize(width: 50, height: 50))
        cell.playerCellSeatImage.image = Image

        // ラベルにテキストを設定する
        let seat = cellData.seat
        let holder = cellData.holder
        var price = cellData.price
        var name = cellData.name
        var kana = cellData.kana
        var message1 = cellData.message1
        var msg = ""
        if cellData.message2 != "" {
            msg = cellData.message2
            if cellData.message3 != "" {
                msg = msg + "\n" + cellData.message3
            }
        } else {
            if cellData.message3 != "" {
                msg = cellData.message3
            }
        }
        var message2 = msg
        var tanka = cellData.tanka

        var status = cellData.status
        
        // ホルダ番号があって、名前がない場合は再度確認する
        if holder != "" && name == "" {
            let db = FMDatabase(path: _path)
            
            db.open()
            

            let results = db.executeQuery(SELECT_PLAYERS, withArgumentsIn: [holder,shop_code,today + "%"])
            while results!.next() {
                price = (results!.string(forColumn:"require_nm") != nil) ? results!.string(forColumn:"require_nm")! : ""
                
                kana = (results!.string(forColumn:"player_name_kana") != nil) ? results!.string(forColumn:"player_name_kana")! : ""
                name = (results!.string(forColumn:"player_name_kanji") != nil) ? results!.string(forColumn:"player_name_kanji")! : ""
                message1 = (results!.string(forColumn:"message1") != nil) ? results!.string(forColumn:"message1")! : ""
                let m2 = (results!.string(forColumn: "message2") != nil) ? results!.string(forColumn: "message2") : ""
                let m3 = (results!.string(forColumn: "message3") != nil) ? results!.string(forColumn: "message3") : ""
                var msg1 = ""
                if m2 != "" {
                    msg1 = m2!
                    if m3 != "" {
                        msg1 = msg1 + "\n" + m3!
                    }
                } else {
                    if m3 != "" {
                        msg1 = m3!
                    }
                }
                message2 = msg1
//                let pk = results?.int(forColumn:"price_tanka")
                let pk = (Int(results!.int(forColumn: "price_tanka")) <= 0) ? 1 : Int(results!.int(forColumn: "price_tanka"))

                tanka = price_kbn[pk-1].1
                
                tableData[indexPath.row].pmStartTime = (results!.string(forColumn:"pm_start_time") != nil) ? results!.string(forColumn:"pm_start_time")! : ""
                status = Int(results!.int(forColumn: "status"))
                
            }
            db.close()
        }
        
        
        tableView.setNeedsLayout()
//      余分な線が出ていたのでコメントアウトにした。
//        tableView.layoutIfNeeded()
        cell.playerCellSeat.clipsToBounds = true
        
        // シート名
        cell.playerCellSeat.text = seat
        // ホルダ番号
        cell.playerCellHolder.text = holder
//        cell.playerCellKana.textAlignment =
        // お客様名カナ
        cell.playerCellKana.text = furigana == 0 ? "" : kana
        // メッセージ1
        cell.playerCellMessage.text = message1
//        if holder != "" {
//            cell.playerCellName.placeholder = ""
//        } else {
//            cell.playerCellName.placeholder = "タップしてください"
//        }

        if holder != "" {
            cell.placeholderLabel.isHidden = true
        } else {
            cell.placeholderLabel.isHidden = false
        }

        
        // お客様名
        cell.playerCellName.text = name
        // 資格（料金）表示
        cell.playerCellPrice.text = cost_disp == 1 ? price : ""
        
        let radius2:CGFloat = 5.0
        cell.playerCelltanka.layer.cornerRadius = radius2
        cell.playerCelltanka.clipsToBounds = true
        
        // 幅に合わせて文字サイズを縮小させる
        cell.playerCelltanka.titleLabel?.adjustsFontSizeToFitWidth = true
        cell.playerCelltanka.titleLabel?.minimumScaleFactor = 0.5
                
        cell.playerCelltanka.setTitle(tanka, for: UIControlState())
        cell.playerCelltanka.tag = indexPath.row
        
        var small_font_size:Float = 0.0
        if tableData.count == 5 {
            small_font_size = 12.0
        } else if tableData.count > 5 {
            small_font_size = 14.0
        } else if tableData.count <= 4 {
            small_font_size = 17.0
        }
        cell.playerCellHolder.font = UIFont(name: "YuGo-Medium",size: CGFloat(small_font_size * font_scale[text_size]))
        
        cell.playerCellHolder.adjustsFontSizeToFitWidth = true
        cell.playerCellHolder.minimumScaleFactor = 0.5
        cell.playerCellHolder.backgroundColor = UIColor.clear
        cell.playerCellHolder.textColor = UIColor.black
        cell.playerCellHolder.textAlignment = .center
        cell.playerCellHolder.layer.cornerRadius = 5.0
        cell.playerCellHolder.clipsToBounds = true
        cell.playerCellHolder.layer.borderColor = UIColor.clear.cgColor
        cell.playerCellHolder.layer.borderWidth = 0.0
        
        if holder != "" {
            switch status {
            case 0,1:       // チェックイン
                break;
            case 2:         // チェックアウト
                cell.playerCellHolder.backgroundColor = iOrder_grayColor
                cell.playerCellHolder.textColor = UIColor.white
                
                break;
            case 3:         // キャンセル
                cell.playerCellHolder.backgroundColor = iOrder_grayColor
                cell.playerCellHolder.textColor = UIColor.white
                break;
            case 9:         // 予約
                cell.playerCellHolder.backgroundColor = UIColor.clear
                cell.playerCellHolder.textColor = UIColor.black
                cell.playerCellHolder.layer.borderColor = UIColor.black.cgColor
                cell.playerCellHolder.layer.borderWidth = 1.0
//                cell.playerCellHolder.backgroundColor = iOrder_grayColor
//                cell.playerCellHolder.textColor = UIColor.whiteColor()
                break;
            default:
                break;
            }
            
            if name == "" {
                cell.playerCellHolder.backgroundColor = UIColor.clear
                cell.playerCellHolder.textColor = UIColor.black
                cell.playerCellHolder.layer.borderColor = UIColor.black.cgColor
                cell.playerCellHolder.layer.borderWidth = 1.0
            }
            
        } else {
            cell.playerCellHolder.backgroundColor = UIColor.clear
            cell.playerCellHolder.textColor = UIColor.black
        }

        
        // メッセージエリアの点滅
        if message2 == "" {
            let button = FAKFontAwesome.commentingOIcon(withSize: iconSizeL)
            button?.addAttribute(NSForegroundColorAttributeName, value: iOrder_borderColor)
            let Image = button?.image(with: CGSize(width: iconSizeL, height: iconSizeL))
            cell.playerCellPopUp.setImage(Image, for: UIControlState())

            cell.playerCellPopUp.isEnabled = false
        } else {
            let button = FAKFontAwesome.commentingOIcon(withSize: iconSizeL)
            button?.addAttribute(NSForegroundColorAttributeName, value: iOrder_lightBrownColor)
            let Image = button?.image(with: CGSize(width: iconSizeL, height: iconSizeL))
            
            let button2 = FAKFontAwesome.commentingOIcon(withSize: iconSizeL)
            button2?.addAttribute(NSForegroundColorAttributeName, value: iOrder_borderColor)
            let Image2 = button2?.image(with: CGSize(width: iconSizeL, height: iconSizeL))
            
            let imageArray:[UIImage] = [Image!,Image2!]
            cell.playerCellPopUp.setImage(imageArray[0], for: UIControlState())
            cell.playerCellPopUp.imageView?.animationImages = imageArray
            cell.playerCellPopUp.imageView?.animationDuration = 1.0
            cell.playerCellPopUp.imageView?.animationRepeatCount = 0
            
            cell.playerCellPopUp.imageView?.startAnimating()
            cell.playerCellPopUp.isEnabled = true
        }
        
        // 単価区分ボタンにイベントをつける
        cell.playerCelltanka.addTarget(self, action: #selector(playerssetViewController.didTouchUpInside(_:)), for: .touchUpInside)
        
        // メッセージエリアボタンにイベントをつける
        cell.playerCellPopUp.addTarget(self, action: #selector(playerssetViewController.PopUp(_:)), for: .touchUpInside)
        
        // セルの背景色はなし
        cell.backgroundColor = UIColor.clear
        
        // 選択された背景色をピンクに設定
        let cellSelectedBgView = UIView()
        cellSelectedBgView.backgroundColor = iOrder_pink
        cell.selectedBackgroundView = cellSelectedBgView
        
        // 設定済みのセルを戻す
        return cell
    }
    
    // セクション数
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // セルの高さを返す（UITableViewDelegate）
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat{


        let cell = tableView.dequeueReusableCell(withIdentifier: "PlayersCell") as! playerTableViewCell
        
        var cell_height:CGFloat = cell.bounds.height
        
        if tableData.count == 5 {
            cell_height = self.tableViewMain.bounds.height / 5
        } else if tableData.count > 5 {
            cell_height = self.tableViewMain.bounds.height / 4.5
        } else if tableData.count <= 4 {
            cell_height = self.tableViewMain.bounds.height / 4
        }
        
        // セルの高さ
        return cell_height
    }

    // Cell が選択された場合
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath:IndexPath) {


        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        // メッセージが表示されていれば消す
        self.removeBalloon()

        // 選択された行のホルダ番号が入っていない時はホルダ番号入力画面に移動する
        if tableData[indexPath.row].holder == "" && selectRow == -1 {
            // ホルダNo入力画面に移動
            globals_select_seat_no = indexPath.row
            self.performSegue(withIdentifier: "toHolderNoInputViewSegue",sender: nil)
        } else {
            // 行入れ替え処理
            if selectRow == indexPath.row {
                tableView.deselectRow(at: indexPath, animated: false)
                selectRow = -1
                clearButton.isEnabled = false
                clearButton.alpha = 0.6
            } else {
                if selectRow == -1 {
                    selectRow = indexPath.row
                    clearButton.isEnabled = true
                    clearButton.alpha = 1.0
                } else {
                    // 移動先のセル情報をコピーする
                    let cellData = tableData[indexPath.row]
                    tableData[indexPath.row] = tableData[selectRow]
                    tableData[selectRow] = cellData
                
                    // シート名だけは変えない
                    for num in 0..<seatName.count {
                        tableData[num].seat = seatName[num]
                    }
                    
                    takeSeatPlayers_temp = []
                    for table_d in tableData {
                        var seat_no = 0
                        let idx = seat.index(where: {$0.seat_name == table_d.seat})
                        if idx != nil {
                            seat_no = seat[idx!].seat_no
                        }
                        takeSeatPlayers_temp.append(takeSeatPlayer(
                            seat_no: seat_no,
                            holder_no: table_d.holder
                            )
                        )
                    }

                    let db = FMDatabase(path: self._path)
                    // データベースをオープン
                    db.open()
                    let sql1 = "DELETE FROM seat_holder;"
                    let _ = db.executeUpdate(sql1, withArgumentsIn: [])
                    db.close()
                    
                    tableView.reloadData()
                    selectRow = -1
                    clearButton.isEnabled = false
                    clearButton.alpha = 0.6
                }
            }
        }
    }

    @IBAction func didTouchUpInside(_ sender: AnyObject){
        // メッセージが表示されていれば消す
        self.removeBalloon()
        

        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        let btn = sender as! UIButton
        
        let cell = btn.superview?.superview as! playerTableViewCell
        let point = self.tableViewMain.convert(sender.frame.origin, from: sender.superview)
        let indexPath = self.tableViewMain.indexPathForRow(at: point)
        
        if cell.playerCellName.text != "" && is_unit_price_kbn != 1 {
            // toast with a specific duration and position
            self.view.makeToast("単価区分変更機能はOFFです。", duration: 1.0, position: .top)
            return;
        }
        
        
        var p_kbn = 1
        let btn_name = cell.playerCelltanka.titleLabel?.text
        
        var index = price_kbn.index(where: {$0.1 == btn_name})
        
        if index != nil {
            if index!+1 == price_kbn.count {
                index = -1
            }
            
            cell.playerCelltanka.setTitle(price_kbn[index!+1].1, for: UIControlState())
            tableData[(indexPath?.row)!].tanka = price_kbn[index!+1].1
            p_kbn = price_kbn[index!+1].0
        }
        
        print(p_kbn)
        
        let db = FMDatabase(path: _path)
        db.open()
        
        var sql = "SELECT count(*) FROM players WHERE member_no = ?;"
        
        var data_count = 0
        
        let results = db.executeQuery(sql, withArgumentsIn: [tableData[indexPath!.row].holder])
        
        while (results?.next())! {
            // カラムのインデックスを指定して取得
            data_count = Int((results?.int(forColumnIndex:0))!)
        }
        
        var argumentArray:Array<Any> = []
        let now = Date() // 現在日時の取得
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
        dateFormatter.timeStyle = .medium
        dateFormatter.dateStyle = .medium
        
        let now_string = dateFormatter.string(from: now)
        
        if data_count > 0 {
            sql = "UPDATE players SET price_tanka = ? , created = ? WHERE member_no = ?;"
            argumentArray.append(p_kbn)
            argumentArray.append(now_string)
            argumentArray.append(tableData[indexPath!.row].holder)
        } else {
            sql = "INSERT INTO players (shop_code, member_no ,member_category,group_no,player_name_kana,player_name_kanji,price_tanka,created,modified) VALUES (?,?,?,?,?,?,?,?,?);"
            
            
            argumentArray.append(shop_code)
            argumentArray.append(tableData[indexPath!.row].holder)
            argumentArray.append(0)
            argumentArray.append(0)
            argumentArray.append("")
            argumentArray.append("")
            argumentArray.append(p_kbn)
            argumentArray.append(now_string)
            argumentArray.append(now_string)
        }
//        print(argumentArray)
        let success = db.executeUpdate(sql, withArgumentsIn: argumentArray)
        if !success {
            // エラー時
            print(success.description)
        }
        db.close()
        
    }

    @IBAction func PopUp(_ sender: AnyObject){
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        let btn = sender as! UIButton
        let cell = btn.superview?.superview?.superview as! playerTableViewCell
        
        let point = self.tableViewMain.convert(sender.frame.origin, from: sender.superview)
        let indexPath = self.tableViewMain.indexPathForRow(at: point)
        
        if msgTag == 100 + indexPath!.row {
            // メッセージが表示されていれば消す
            removeBalloon()
            return;
        } else {
            // メッセージが表示されていれば消す
            removeBalloon()
        }

        
        // viewとtextViewとのマージン
        let absolutePosition = btn.superview?.superview?.convert(tableViewMain.frame, to: nil)
        let x:CGFloat = absolutePosition!.origin.x
        let y:CGFloat = absolutePosition!.origin.y

        
        let popupViewWidth: CGFloat =  self.view.frame.width - btn.frame.width - 50
     
//        let balloon = BalloonView(frame: CGRectMake(point.x + btn.frame.width, point.y + 10 , popupViewWidth, cell.bounds.height  ))
        let balloon = BalloonView(frame: CGRect(x: x + btn.frame.width + 20, y: y , width: popupViewWidth, height: cell.bounds.height  ))
        BalloonView.permittedArrowDirections.arrow = .left
        
        // TextView生成する.
        let myTextView: UITextView = UITextView(frame: CGRect(x: 13.0, y: 0.0, width: popupViewWidth - 13.0, height: cell.bounds.height * 1.1))
        // TextViewの背景を白色に設定する.
        myTextView.backgroundColor = UIColor.white
        
        let cellData = tableData[indexPath!.row]
        
        // 表示させるテキストを設定する.
        var msg = ""
        var attrText:NSMutableAttributedString?

        if cellData.message3 != "" {
            let cnt = cellData.message3.characters.count
            msg = cellData.message3
            if cellData.message2 != "" {
                msg = msg + "\n" + cellData.message2
            }
            attrText = NSMutableAttributedString(string: msg)
            attrText!.addAttribute(NSForegroundColorAttributeName, value: UIColor.red, range: NSMakeRange(0, cnt))
        } else {
            if cellData.message2 != "" {
                msg = cellData.message2
                attrText = NSMutableAttributedString(string: msg)
            }
        }

        myTextView.attributedText = attrText
        // 角に丸みをつける.
        myTextView.layer.masksToBounds = true
        // 丸みのサイズを設定する.
        myTextView.layer.cornerRadius = 10.0
        // 枠線の太さを設定する.
        myTextView.layer.borderWidth = 3.0
        // 枠線の色を黒に設定する.
        myTextView.layer.borderColor = UIColor.darkGray.cgColor
        // フォントの設定をする.
        //        myTextView.font = UIFont.systemFontOfSize(CGFloat(20))
        myTextView.font = UIFont(name: "YuGo-Medium",size: CGFloat(16*size_scale))
        // フォントの色の設定をする.
//        myTextView.textColor = iOrder_blackColor
        // 左詰めの設定をする.
        myTextView.textAlignment = NSTextAlignment.left
        // リンク、日付などを自動的に検出してリンクに変換する.
//        myTextView.dataDetectorTypes = UIDataDetectorTypes.All
        // 影の濃さを設定する.
        //        myTextView.layer.shadowOpacity = 0.5
        // テキストを編集不可にする.
        myTextView.isEditable = false
        
        balloon.addSubview(myTextView)
        balloon.backgroundColor = UIColor.clear
        balloon.tag = 100 + indexPath!.row
        msgTag = 100 + indexPath!.row
        view.addSubview(balloon)
    }

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    // クリアボタンのタップ時
    @IBAction func clearButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        // メッセージが表示されていれば消す
        self.removeBalloon()

        // id から　座っていたシート名を取得
        var seat_name = ""
        let idx_seat = seat.index(where: {$0.seat_no == tableData[selectRow].id})
        if idx_seat != nil {
            seat_name = seat[idx_seat!].seat_name
        }
        
        let index = takeSeatPlayers_temp.index(where: {$0.seat_no == selectRow})
        if index != nil {
            takeSeatPlayers_temp[index!].holder_no = ""
        }
        tableData[selectRow].id = -1
        tableData[selectRow].holder = ""
        tableData[selectRow].price = ""
        tableData[selectRow].name = ""
        tableData[selectRow].kana = ""
        tableData[selectRow].message1 = ""
        tableData[selectRow].message2 = ""
        tableData[selectRow].message3 = ""
        tableData[selectRow].tanka = ""
        tableData[selectRow].pmStartTime = ""

        // ホルダNOが一件でも入っていれば、次へボタンを活かす
        let idx = tableData.index(where: {$0.holder != ""})
        if idx != nil {
            okButton.isEnabled = true
            okButton.alpha = 1.0
        } else {
            okButton.isEnabled = false
            okButton.alpha = 0.6
        }

        // シートホルダテーブルの中を消す
        let db = FMDatabase(path: _path)
        db.open()
        let sql = "DELETE FROM seat_holder where seat_no = ?;"
        let _ = db.executeUpdate(sql, withArgumentsIn: [selectRow])
        
        //メインメニュー、セレクトメニュー、オプションメニューの中を消す
//        // id から　座っていたシート名を取得
//        var seat_name = ""
//        let idx_seat = seat.indexOf({$0.seat_no == tableData[selectRow].id})
//        if idx_seat != nil {
//            seat_name = seat[idx_seat!].seat_name
//        }
        
//        MainMenu = MainMenu.filter({$0.seat != tableData[selectRow].seat})
//        SubMenu = SubMenu.filter({$0.seat != tableData[selectRow].seat})
//        SpecialMenu = SpecialMenu.filter({$0.seat != tableData[selectRow].seat})

        MainMenu = MainMenu.filter({$0.seat != seat_name})
        SubMenu = SubMenu.filter({$0.seat != seat_name})
        SpecialMenu = SpecialMenu.filter({$0.seat != seat_name})
        
        // 手書きデータ削除
        let sql_del = "DELETE FROM hand_image WHERE seat = ?;"
        let _ = db.executeUpdate(sql_del, withArgumentsIn: [seat_name])
        
        tableViewMain.reloadData()
        selectRow = -1
        
        // clearボタンはリスト選択時だけ押せるようにする。
        clearButton.isEnabled = false
        clearButton.alpha = 0.6
        
        db.close()
    }
    
    // 戻るボタンタップ時
    @IBAction func backButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        // メッセージが表示されていれば消す
        self.removeBalloon()

        if MainMenu.count > 0 {
            let alertController = UIAlertController(title: "確認", message: "現在入力中のオーダーが\nリセットされます。\nよろしいですか？", preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "はい", style: .default){
                action in
                print("Pushed OK")

                select_menu_categories = []
                MainMenu = []
                SubMenu = []
                SpecialMenu = []
                fmdb.remove_hand_image()
                
                // 新規
                if globals_is_new == 1 {
                    if is_timezone == 1 {
                        if (self.presentingViewController as? timezoneViewController) != nil {
                            self.performSegue(withIdentifier: "ToTimezoneSegue",sender: nil)
                        } else if (self.presentingViewController as? tablenoinputViewContoroller) != nil {
                            // 保留呼び出しの場合はこっちに戻る
                            self.performSegue(withIdentifier: "ToTableNoInputSegue",sender: nil)
                        }
                    } else {
                        self.performSegue(withIdentifier: "ToTableNoInputSegue",sender: nil)
                    }
                    
                    // 追加
                } else {
                    self.performSegue(withIdentifier: "ToTableNoInputSegue",sender: nil)
                }

                return;
            }
            
            let cancelAction = UIAlertAction(title: "いいえ", style: .cancel){
                action in
                // タップ音
                TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                print("Pushed いいえ")
            }
            alertController.addAction(OKAction)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)

        } else {
            select_menu_categories = []
            MainMenu = []
            SubMenu = []
            SpecialMenu = []
            fmdb.remove_hand_image()
            // 新規
            if globals_is_new == 1 {
                if is_timezone == 1 {
                    if (self.presentingViewController as? timezoneViewController) != nil {
                        self.performSegue(withIdentifier: "ToTimezoneSegue",sender: nil)
                    } else if (self.presentingViewController as? tablenoinputViewContoroller) != nil {
                        // 保留呼び出しの場合はこっちに戻る
                        self.performSegue(withIdentifier: "ToTableNoInputSegue",sender: nil)
                    }
                } else {
                    self.performSegue(withIdentifier: "ToTableNoInputSegue",sender: nil)
                }
                
                // 追加
            } else {
                self.performSegue(withIdentifier: "ToTableNoInputSegue",sender: nil)
            }
            
        }

    }
    
    // 次へボタンタップ時
    @IBAction func nextButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        // メッセージが表示されていれば消す
        self.removeBalloon()

        globals_price_kbn = []
        takeSeatPlayers = []

        
        // お客様設定がされているか？
        var is_playerSet = false
        print("てーぶる",tableData)
        
        
        for (num,tableDT) in tableData.enumerated() {
            if tableDT.holder != "" {
                is_playerSet = true
                
                var price_kbn_no : Int?
                let index = price_kbn.index(where: {$0.1 == tableDT.tanka})
                if index != nil {
                    price_kbn_no = price_kbn[index!].0
                }

                if price_kbn_no != nil {
                    let index1 = globals_price_kbn.index(where: {$0 == price_kbn_no! })
                    
                    if index1 == nil {
                        globals_price_kbn.append(price_kbn_no!)
                    }
                    
                }
                
            }
            takeSeatPlayers.append(takeSeatPlayer(
                seat_no     : num,
                holder_no   : tableDT.holder)
            )
            
            
        }

        var m_temp:[CellData] = []
        var s_temp:[SubMenuData] = []
        var o_temp:[SpecialMenuData] = []
//        var c_temp:[select_menu_category] = []
        
        
        struct hand_temp {
            var seat : String
            var holder_no : String
            var order_no : Int
            var branch_no : Int
            var order_count : Int
            var hand_image : Data
        }
        
        var hand_temps :[hand_temp] = []
        
        let db = FMDatabase(path: _path)
        
        db.open()
        
        if tableData_save.count > 0 {
            
        }
        
        
        if tableData_save.count > 0 {
            for (t_i,tbl) in tableData.enumerated() {
                let idx = tableData_save.index(where: {$0.id == tbl.id})
                if idx != nil {
                    if t_i != idx {
                        // メインメニュー
                        var main_filter = MainMenu.filter({$0.seat == tableData_save[idx!].seat})
                        for (m_i,m_filter) in main_filter.enumerated() {
                            main_filter[m_i].seat = tbl.seat
                            // 支払い者のシートNOからシート名を取得
                            let pay_seat_idx = seat.index(where: {$0.seat_no == m_filter.payment_seat_no})
                            var pay_seat = ""
                            var pay_seat_no = -1
                            if pay_seat_idx != nil {
                                pay_seat = seat[pay_seat_idx!].seat_name
                                let idx_pay = tableData_save.index(where: {$0.seat == pay_seat})
                                if idx_pay != nil {
                                    let iid = tableData_save[idx_pay!].id
                                    
                                    let idx_1 = tableData.index(where: {$0.id == iid})
                                    if idx_1 != nil {
                                        pay_seat = tableData[idx_1!].seat
                                        
                                        let idx_2 = seat.index(where: {$0.seat_name == pay_seat})
                                        if idx_2 != nil {
                                            pay_seat_no = seat[idx_2!].seat_no
                                        }
                                    }
                                    
                                }
                            }
                            main_filter[m_i].payment_seat_no = pay_seat_no
                            
                            m_temp.append(main_filter[m_i])
//                            c_temp.append(<#T##newElement: Element##Element#>)
                            
                            // セレクトメニュー
                            var select_filter = SubMenu.filter({$0.id == m_filter.id})
                            for (s_i,_) in select_filter.enumerated() {
                                select_filter[s_i].seat = tbl.seat
                                
                                s_temp.append(select_filter[s_i])
                                
                            }
                            
                            // オプションメニュー
                            var opt_filter = SpecialMenu.filter({$0.id == m_filter.id})
                            for (o_i,_) in opt_filter.enumerated() {
                                opt_filter[o_i].seat = tbl.seat
                                o_temp.append(opt_filter[o_i])
                            }
                            
                        }
                    } else {
                        var main_filter = MainMenu.filter({$0.seat == tableData_save[idx!].seat})
                        for (m_i,m_filter) in main_filter.enumerated() {
                            main_filter[m_i].seat = tbl.seat
                            // 支払い者のシートNOからシート名を取得
                            let pay_seat_idx = seat.index(where: {$0.seat_no == m_filter.payment_seat_no})
                            var pay_seat = -1
                            if pay_seat_idx != nil {
                                pay_seat = seat[pay_seat_idx!].seat_no
                            }
                            main_filter[m_i].payment_seat_no = pay_seat
                            
                            m_temp.append(main_filter[m_i])
                            
                            // セレクトメニュー
                            var select_filter = SubMenu.filter({$0.id == m_filter.id})
                            for (s_i,_) in select_filter.enumerated() {
                                select_filter[s_i].seat = tbl.seat
                                
                                s_temp.append(select_filter[s_i])
                                
                            }
                            
                            // オプションメニュー
                            var opt_filter = SpecialMenu.filter({$0.id == m_filter.id})
                            for (o_i,_) in opt_filter.enumerated() {
                                opt_filter[o_i].seat = tbl.seat
                                o_temp.append(opt_filter[o_i])
                            }
                            
                        }

                    }
                }
            }
        }

        // 手書きデータ
        let sql_select = "SELECT * FROM hand_image"
        let rs_sql_select = db.executeQuery(sql_select, withArgumentsIn: [])
        while (rs_sql_select?.next())! {
            hand_temps.append(hand_temp(
                seat : (rs_sql_select?.string(forColumn:"seat"))!,
                holder_no : (rs_sql_select?.string(forColumn:"holder_no"))!,
                order_no : Int((rs_sql_select?.int(forColumn:"order_no"))!),
                branch_no : Int((rs_sql_select?.int(forColumn:"branch_no"))!),
                order_count : (rs_sql_select?.columnIsNull("order_count"))! ? 0 : Int((rs_sql_select?.int(forColumn:"order_count"))!),
                hand_image : (rs_sql_select?.data(forColumn: "hand_image") != nil ? rs_sql_select?.data(forColumn: "hand_image") : Data())!
                )
            )
        }
        
        if hand_temps.count > 0 {
            fmdb.remove_hand_image()
            
            for (h_i,hand) in hand_temps.enumerated() {
                for (_,main) in MainMenu.enumerated() {
                    if main.seat == hand.seat && main.No == hand.holder_no && main.MenuNo == hand.order_no.description && main.BranchNo == hand.branch_no {
                        let idx = tableData_save.index(where: {$0.seat == main.seat})
                        if idx != nil {
                            let save_id = tableData_save[idx!].id
                            
                            let idx_after = tableData.index(where: {$0.id == save_id})
                            if idx_after != nil {
                                hand_temps[h_i].seat = tableData[idx_after!].seat
                            }
                            
                        }
                        
                    }
                }
            }
            
            let sql_insert = "INSERT INTO hand_image (hand_image,holder_no,order_no,branch_no,order_count,seat) VALUES(?,?,?,?,?,?);"
            for hand in hand_temps {
                var argumentArray:Array<Any> = []
                
                argumentArray.append(hand.hand_image)
                argumentArray.append(hand.holder_no)
                argumentArray.append(hand.order_no)
                argumentArray.append(hand.branch_no)
                argumentArray.append(hand.order_count)
                argumentArray.append(hand.seat)
                
                let rs2 = db.executeUpdate(sql_insert, withArgumentsIn: argumentArray)
                if !rs2 {
                    // エラー時
                    print(rs2.description)
                }
            }
            
            
        }
        
        for (i,td) in tableData.enumerated() {
            let idx_x = seat.index(where: {$0.seat_name == td.seat})
            if idx_x != nil {
                tableData[i].id = seat[idx_x!].seat_no
            }
        }
        
        print("main",MainMenu)
        print("main_new",m_temp)
        print("select",SubMenu)
        print("select_new",s_temp)
        print("option",SpecialMenu)
        print("option_new",o_temp)
        
        if m_temp.count > 0 {
//            select_menu_categories = []
            MainMenu = []
            SubMenu = []
            SpecialMenu = []
            
            MainMenu = m_temp
            SubMenu = s_temp
            SpecialMenu = o_temp
        }

        db.close()

        if is_playerSet == false {
            // エラーメッセージ
            // エラー表示
            let alertController = UIAlertController(title: "エラー！", message: "お客様を設定してください。", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "閉じる", style: .cancel){
                action in print("Pushed OK")
                return;
            }
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
            return;

        } else {
            // 残数取得
            if demo_mode == 0 {  // 本番モードのときだけ
                self.spinnerStart()
                
                dispatch_async_global{
                    // 残数情報取得
                    let json = JSON(url:urlString + "RemainNumSend?Store_CD=" + shop_code.description )
                    print(json)
                    if json.asError == nil {
                        let db = FMDatabase(path: self._path)
                        // データベースをオープン
                        db.open()
                        
                        var sql = "DELETE FROM items_remaining;"
                        let _ = db.executeUpdate(sql, withArgumentsIn: [])
                        
                        
                        sql = "INSERT INTO items_remaining (item_no , remaining_count, created , modified) VALUES (?,?,?,?);"
                        
                        for (_,remain) in json["t_remain_num"]{
                            var argumentArray:Array<Any> = []
                            
                            if remain["menu_cd"].type == "Int" && remain["remain_num"].type == "Int" {
                                argumentArray.append(NSNumber(value: remain["menu_cd"].asInt64! as Int64))
                                argumentArray.append(remain["remain_num"].asInt!)
                                
                                let now = Date() // 現在日時の取得
                                let dateFormatter = DateFormatter()
                                dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
                                dateFormatter.timeStyle = .medium
                                dateFormatter.dateStyle = .medium
                                
                                let created = dateFormatter.string(from: now)
                                let modified = created
                                argumentArray.append(created)
                                argumentArray.append(modified)
                                
                                db.beginTransaction()
                                let success = db.executeUpdate(sql, withArgumentsIn: argumentArray)
                                if !success {
                                    print("insert error!!")
                                }
                                db.commit()
                            }
                        }
                        db.close()
                        
                        self.dispatch_async_main{
                            self.spinnerEnd()
                            // 選択サブメニュー情報を消去
                            DecisionSubMenu = []
                            globals_pm_start_time = ""
                            var pm = self.tableData.filter({$0.pmStartTime != ""})
                            print(pm)
                            if pm.count > 0 {
                                pm = pm.sorted(by: {$0.pmStartTime < $1.pmStartTime})
                                globals_pm_start_time = (pm.first?.pmStartTime)!
                            }
                            
                            
                            // メニュー選択画面に移動
                            self.performSegue(withIdentifier: "toMenuSelectViewSegue",sender: nil)
                        }
                    } else {
                        self.dispatch_async_main{
                            self.spinnerEnd()
                            let e = json.asError
                            
                            // エラー音
                            TapSound.buttonTap(err_sound_file.sound_file, type: err_sound_file.file_type)
                            // 選択サブメニュー情報を消去
                            DecisionSubMenu = []
                            globals_pm_start_time = ""
                            var pm = self.tableData.filter({$0.pmStartTime != ""})
                            print(pm)
                            if pm.count > 0 {
                                pm = pm.sorted(by: {$0.pmStartTime < $1.pmStartTime})
                                globals_pm_start_time = (pm.first?.pmStartTime)!
                            }
                            
                            
                            // メニュー選択画面に移動
                            self.performSegue(withIdentifier: "toMenuSelectViewSegue",sender: nil)
                            
//                            self.jsonError()
                            print(e as Any)
                            
                        }
                    }
                }
            } else {
                // 選択サブメニュー情報を消去
                DecisionSubMenu = []
                globals_pm_start_time = ""
                var pm = self.tableData.filter({$0.pmStartTime != ""})
                print(pm)
                if pm.count > 0 {
                    pm = pm.sorted(by: {$0.pmStartTime < $1.pmStartTime})
                    globals_pm_start_time = (pm.first?.pmStartTime)!
                }
                
                // メニュー選択画面に移動
                self.performSegue(withIdentifier: "toMenuSelectViewSegue",sender: nil)
            }
        }
    }
    
    
    // MARK: - Long Press Reorder
    
    //
    // Important: Update your data source after the user reorders a cell.
    //
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        tableData.insert(tableData.remove(at: sourceIndexPath.row), at: destinationIndexPath.row)

        // メッセージが表示されていれば消す
        self.removeBalloon()
   
        print(tableData)
        
        // シート名だけは変えない
        for num in 0..<seatName.count {
            tableData[num].seat = seatName[num]
        }
        
        takeSeatPlayers_temp = []
        for table_d in tableData {
            var seat_no = 0
            let idx = seat.index(where: {$0.seat_name == table_d.seat})
            if idx != nil {
                seat_no = seat[idx!].seat_no
            }
            takeSeatPlayers_temp.append(takeSeatPlayer(
                seat_no: seat_no,
                holder_no: table_d.holder
                )
            )
            
        }

        let db = FMDatabase(path: self._path)
        // データベースをオープン
        db.open()
        let sql1 = "DELETE FROM seat_holder;"
        let _ = db.executeUpdate(sql1, withArgumentsIn: [])
        db.close()
        
        selectRow = -1
        clearButton.isEnabled = false
        clearButton.alpha = 0.6
        
    }
    
    //
    // Optional: Modify the cell (visually) before dragging occurs.
    //
    //    NOTE: Any changes made here should be reverted in `tableView:cellForRowAtIndexPath:`
    //          to avoid accidentally reusing the modifications.
    //
    func tableView(_ tableView: UITableView, draggingCell cell: UITableViewCell, atIndexPath indexPath: IndexPath) -> UITableViewCell {
        //		cell.backgroundColor = UIColor(red: 165.0/255.0, green: 228.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        
        // メッセージが表示されていれば消す
        self.removeBalloon()
        
        return cell
    }
    
    //
    // Optional: Called within an animation block when the dragging view is about to show.
    //
    func tableView(_ tableView: UITableView, showDraggingView view: UIView, atIndexPath indexPath: IndexPath) {
        print("The dragged cell is about to be animated!")
    }
    
    //
    // Optional: Called within an animation block when the dragging view is about to hide.
    //
    func tableView(_ tableView: UITableView, hideDraggingView view: UIView, atIndexPath indexPath: IndexPath) {
        print("The dragged cell is about to be dropped.")
    }

    func refresh() {
        print("refresh")
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
        playersClass.get(updateTime,error:true)
        
        //        playersClass.get(error:true)
        
        refreshControl.endRefreshing()
    }

    
    
    // 次の画面から戻ってくるときに必要なsegue情報
    @IBAction func unwindToplayersset(_ segue: UIStoryboardSegue) {
        // 席移動から戻ってきた時

        if segue.identifier == "toPlayerssetSegue2" {
            // シートNO順でソート
            seat.sort{$0.seat_no < $1.seat_no}
//            print(seat)
            self.seatName = []
            for s in seat {
                self.seatName.append(s.seat_name)
            }
            tableData = []
        }
    }

    func set_players_data(){
        
        // FMDatabaseクラスのインスタンスを作成
        // 引数にファイルまでのパスを渡す
        let db = FMDatabase(path: _path)
        
//        print(seat_holders)
        
        for num in 0..<seatName.count {
            for num2 in 0..<seat_holders.count {
                if num == seat_holders[num2].seat_no {
                    // テーブルに無くてもホルダ番号だけ表示するため
                    self.tableData[num].seat = seatName[num]
                    self.tableData[num].holder = seat_holders[num2].holder_no
                    self.tableData[num].price = ""
                    self.tableData[num].name = ""
                    self.tableData[num].kana = ""
                    self.tableData[num].message1 = ""
                    self.tableData[num].message2 = ""
                    self.tableData[num].message3 = ""
                    self.tableData[num].tanka = "一般"
                    self.tableData[num].pmStartTime = ""
                    self.tableData[num].status = 0

                    
                    takeSeatPlayers_temp[num].seat_no = seat_holders[num2].seat_no
                    takeSeatPlayers_temp[num].holder_no = seat_holders[num2].holder_no
                    
//                    print(takeSeatPlayers_temp[num])
                    // データベースをオープン
                    db.open()
//                    let sql = "select * from players where member_no in (?);"
//                    let results = db.executeQuery(sql, withArgumentsIn: [seat_holders[num2].holder_no])
                    
                    
                    let results = db.executeQuery(SELECT_PLAYERS, withArgumentsIn: [seat_holders[num2].holder_no,shop_code,globals_today + "%"])
                    
//                    self.seat_holders = []
                    while results!.next() {
                        let mn = (results!.string(forColumn: "member_no") != nil) ? results!.string(forColumn: "member_no") : ""
                        let mc = (results!.string(forColumn: "require_nm") != nil) ? results!.string(forColumn: "require_nm") : ""
                        
                        let pnkana = (results!.string(forColumn: "player_name_kana") != nil) ? results!.string(forColumn: "player_name_kana") : ""
                        let pnkanji = (results!.string(forColumn: "player_name_kanji") != nil) ? results!.string(forColumn: "player_name_kanji") : ""
                        let m1 = (results!.string(forColumn: "message1") != nil) ? results!.string(forColumn: "message1") : ""
                        let m2 = (results!.string(forColumn: "message2") != nil) ? results!.string(forColumn: "message2") : ""
                        let m3 = (results!.string(forColumn: "message3") != nil) ? results!.string(forColumn: "message3") : ""
                        var pk = ""
                        switch results!.int(forColumn: "price_tanka") {
                        case 1:
                            pk = "一般"
                        case 2:
                            pk = "従業員"
                        case 3:
                            pk = "その他"
                        default:
                            pk = "一般"
                        }
                        
                        let pm_start_time = (results!.string(forColumn: "pm_start_time") != nil) ? results!.string(forColumn: "pm_start_time") : ""
                        let status = Int(results!.int(forColumn: "status"))
                        
                        self.tableData[num].seat = seatName[num]
                        self.tableData[num].holder = mn!
                        self.tableData[num].price = mc!
                        self.tableData[num].name = pnkanji!
                        self.tableData[num].kana = pnkana!
                        self.tableData[num].message1 = m1!
                        self.tableData[num].message2 = m2!
                        self.tableData[num].message3 = m3!
                        self.tableData[num].tanka = pk
                        self.tableData[num].pmStartTime = pm_start_time!
                        self.tableData[num].status = status
                    }
                    db.close()
                }
            }
        }
//        print(tableData)
    }
    
    // ボタンを長押ししたときの処理
    @IBAction func pressedLong(_ sender: UILongPressGestureRecognizer!) {
        self.removeBalloon()
        
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

/*
    // 単体登録
    func set_folder_number(holderno:Int) -> Bool{
        let db = FMDatabase(path: _path)
        
        // データベースをオープン
        db.open()
        let url2 = urlString + "GetCustomer?Store_CD=" + shop_code.description + "&" + "Customer_NO=" + "\(holderno)"
        
//        print(url2)
        let json2 = JSON(url: url2)
        print(json2)
        if json2.asError == nil {
            
            let sql3 = "INSERT OR REPLACE INTO players (shop_code,member_no ,member_category,group_no,player_name_kana ,player_name_kanji ,birthday,require_nm,sex,message1,message2,message3 ,price_tanka,created ,modified) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,?);"
            
            var argumentArray:Array<Any> = []
            
            argumentArray.append(json2["store_cd"].asInt!)
            argumentArray.append("\(json2["customer_no"].asInt!)")
            argumentArray.append(json2["member_kbn"].asInt!)
            argumentArray.append(Int(json2["group_id"].asString!)!)
            argumentArray.append(json2["customer_kana"].asString!)
            argumentArray.append(json2["customer_nm"].asString!)
            argumentArray.append(json2["birthday"].asString!)
            argumentArray.append(json2["require_nm"].asString!)
            argumentArray.append(0)
            argumentArray.append(json2["message1"].asString!)
            argumentArray.append(json2["message2"].asString!)
            argumentArray.append(json2["message3"].asString!)
            argumentArray.append(json2["unit_price_kbn"].asInt!)
            
            let now = Date() // 現在日時の取得
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
            dateFormatter.timeStyle = .medium
            dateFormatter.dateStyle = .medium
            
            let created = dateFormatter.stringFromDate(now)
            let modified = created
            argumentArray.append(created)
            argumentArray.append(modified)
//            print(argumentArray)
            
            // INSERT文を実行
            let success3 = db.executeUpdate(sql3, withArgumentsIn: argumentArray)
            // INSERT文の実行に失敗した場合
            if !success3 {
                print(errno.description)
                // ループを抜ける
                return false
            }
            
        } else {
            return false
        }
        
        return true
    }
*/
    // バーボタンアイテム（テーブルNOの移動）のクリック時
    internal func onClickExchangeSeat(_ sender: UIButton){
        
        // オーダー数
        var orderCount = 0
        for m in MainMenu {
            orderCount = orderCount + Int(m.Count)!
        }

        if orderCount > 0 {
            // toast with a specific duration and position
            self.view.makeToast("オーダーがある場合は席移動出来ません。", duration: 1.0, position: .top)
            return;

        }
        
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        takeSeatPlayers = []
        // お客様設定がされているか？
        var is_playerSet = false
        for num in 0..<tableData.count {
            if tableData[num].holder != "" {
                is_playerSet = true
            }
            takeSeatPlayers.append(takeSeatPlayer(
                seat_no     : num,
                holder_no   : tableData[num].holder))
        }
        
        if is_playerSet == false {
            // エラーメッセージ
            // エラー表示
            let alertController = UIAlertController(title: "エラー！", message: "お客様が設定されていない場合は席移動出来ません。", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "閉じる", style: .cancel){
                action in print("Pushed OK")
                return;
            }
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
            return;
        } else {
           self.performSegue(withIdentifier: "toExchangeSeatNoInputViewSegue",sender: nil)
        }
        
    }
    
    // MARK: - Override methods
    
    override var canBecomeFirstResponder : Bool {
        return true
    }
    
    override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) {
        if event?.type == UIEventType.motion && event?.subtype == UIEventSubtype.motionShake {
            print("Motion began")
            
            // メッセージが表示されていれば消す
            self.removeBalloon()

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
        self.spinnerEnd()
        let alertController = UIAlertController(title: "エラー！", message: "残数取り込みに失敗しました。", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default){
            action in print("Pushed OK")
            return;
        }
        
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
        
    }

    func removeBalloon() {
        if msgTag > 0 {
            let fetchedView = view.viewWithTag(msgTag)
            fetchedView!.removeFromSuperview()
            msgTag = 0
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

