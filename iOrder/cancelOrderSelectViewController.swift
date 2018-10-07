//
//  cancelOrderSelectViewController.swift
//  iOrder
//
//  Created by 山尾守 on 2016/07/27.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit
import FontAwesomeKit
import FMDB
import Toast_Swift

class cancelOrderSelectViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UINavigationBarDelegate,UIActionSheetDelegate {
    
    fileprivate var onceTokenViewDidAppear: Int = 0
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var okButton: UIButton!

    
    var tableViewMain = UITableView()

    
    var times:[cancel_cellData] = []
    var Section_User:[SectionData] = []
    var MainMenu_User:[CellData] = []
    var SubMenu_User:[SubMenuData] = []
    var SpecialMenu_User:[SpecialMenuData] = []
    
    var Disp:[[cancel_cellData]] = []
    var Disp_Section:[SectionData] = []
    
    var Disp_backup:[[cancel_cellData]] = []
    
    struct payment_data {
        var No:String
        var seat:String
    }
    var payment:[payment_data] = []
    
    var ck:[[Bool]] = []
    
    var check_on:UIImage = UIImage()
    var check_off:UIImage = UIImage()
    
    // DBファイルパス
    var _path:String = ""
    
    let jsonErrorMsg = "テーブル番号の取得に失敗しました。"
    
    //CustomProgressModelにあるプロパティが初期設定項目
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
        iconImage = FAKFontAwesome.checkIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
        //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
        Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        okButton.setImage(Image, for: UIControlState())
        
        // 選択されていないときは、送信ボタンを押せなくする。
        okButton.isEnabled = false
        okButton.alpha = 0.6
        
        let onImage = FAKIonIcons.checkmarkRoundIcon(withSize: iconSize)
        onImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
        check_on = (onImage?.image(with: CGSize(width: iconSize, height: iconSize)))!
        
        let offImage = FAKIonIcons.checkmarkRoundIcon(withSize: iconSize)
        offImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.clear)

        check_off = (offImage?.image(with: CGSize(width: iconSize, height: iconSize)))!

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

        Disp_backup = []
        
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
    
    /*
    // MARK: - Navigation

    */

    func loadData(){
        common.clear()
//        select_menu_categories = []
//        Section = []
//        MainMenu = []
//        SubMenu = []
        times = []

        // 本番モード
        if demo_mode == 0 {
            self.spinnerStart()
            dispatch_async_global {
                
                // 取消
                let url = urlString + "CheckTable?Store_CD=" + shop_code.description + "&" + "Table_NO=" + "\(globals_table_no)" + "&" + "Process_Div=4"
                print(url)
                let json = JSON(url: url)
                print("json", json)
                if json.asError == nil {                    
                    for (key, value) in json {
                        if key as! String == "Return" {
                            if value.toString() == "false" {
                                self.dispatch_async_main {
                                    self.spinnerEnd()
                                    self.jsonError("取消データはありません。",back_flag: false)
                                    return;
                                }
                            }
                        } else {
                            self.payment = []
                            for (_,custmer) in json["t_order_seat"]{
                                let seat_name = custmer["seat_nm"].asString
                                let custmer_no = custmer["serve_customer_no"].asInt
                                let index = self.payment.index(where: {$0.No == "\(custmer_no!)"})
                                if index == nil {
                                    self.payment.append(payment_data(
                                        No: "\(custmer_no!)",
                                        seat: seat_name!
                                        )
                                    )
                                }
                            }
                            
                            for (_,custmer) in json["t_order_seat"]{
                                let seat_no = custmer["seat_no"].asInt! - 1
                                let seat_name = custmer["seat_nm"].asString
                                let custmer_no = custmer["serve_customer_no"].asInt
                                let custmer_name = custmer["serve_customer_nm"].asString
                                let pay_seat = custmer["payment_seat_nm"].asString
                                let menu_no = custmer["menu_cd"].asInt64!
                                let menu_name = fmdb.getMenuName(menu_no)
//                                let menu_name = custmer["menu_nm"].asString
                                let qty = custmer["qty"].asInt!
                                let timezone_kbn = custmer["timezone_kbn"].asInt
                                let payment_seat_no = custmer["payment_customer_seat_no"].asInt! - 1
                                let payment_customer_no = custmer["payment_customer_no"].asInt
                                let Slip_NO = custmer["slip_no"].asInt64
                                let category1 = custmer["category_cd1"].asInt!
                                let category2 = custmer["category_cd2"].asInt!
                                // セクションデータ
                                let index = Section.index(where: {$0.seat_no == seat_no && $0.No == "\(custmer_no!)"})
                                if index == nil {
                                    Section.append(SectionData(
                                        seat_no: seat_no,
                                        seat: seat_name!,
                                        No: "\(custmer_no!)",
                                        Name: custmer_name!)
                                    )
                                }
                                let branchNo = Int(custmer["menu_seq"].asString!)
                                
                                // webサービスの修正が終わればコメント
//                                var branchNo = 0
//                                if MainMenu.count > 0 {
//                                    let branch = MainMenu.filter({$0.seat == seat_name && $0.No == custmer_no?.description && $0.MenuNo == menu_no.description})
//                                    if branch.count > 0 {
//                                        // ブランチNOの最大値を取得
//                                        branchNo = branch.reduce(branch[0].BranchNo, combine: {max($0,$1.BranchNo)}) + 1
//                                    }
//                                }
                                // webサービスの修正が終わればコメント

                                let id = MainMenu.count
                                
                                MainMenu.append(CellData(
                                    id:id,
                                    seat: pay_seat!,
                                    No: "\(custmer_no!)",
                                    Name: menu_name,
                                    MenuNo: "\(menu_no)",
                                    BranchNo: branchNo!,
                                    Count: "\(qty)",
                                    Hand: false,
                                    MenuType: 1,
                                    payment_seat_no: payment_seat_no
                                    )
                                )
                                
                                select_menu_categories.append(select_menu_category(
                                    id: id,
                                    category1: category1,
                                    category2: category2
                                    )
                                )

                                
                                // 経過時間を計算する
                                let time = self.getTime(custmer["ins_dt"].asString!)
                                
                                self.times.append(cancel_cellData(
                                    id:id,
                                    seat: pay_seat!,
                                    serve_seat: seat_name!,
                                    No: "\(custmer_no!)",
                                    Name: menu_name,
                                    MenuNo: "\(menu_no)",
                                    BranchNo: branchNo!,
                                    timezone_kbn: timezone_kbn!,
                                    Count: "\(qty)",
                                    Hand: false,
                                    MenuType: 1,
                                    time: time,
                                    payment_customer_no: (payment_customer_no?.description)!,
                                    payment_seat_no:payment_seat_no,
                                    Slip_NO: (Slip_NO?.description)!,
                                    order_no:0,
                                    order_branch:0
                                    )
                                )
                            }
                            self.dispatch_async_main{
                                self.spinnerEnd()
                                
                                // ユーザー順データ
                                let Section_temp = Section.sorted(by: {$0.seat_no < $1.seat_no})
                                self.Section_User = Section_temp
                                self.MainMenu_User = MainMenu
                                self.SubMenu_User = SubMenu
                                self.SpecialMenu_User = SpecialMenu
                                
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
                                let xib = UINib(nibName: "cancelOrderSelectTableViewCell", bundle: nil)
                                self.tableViewMain.register(xib, forCellReuseIdentifier: "Cell")

                            }
                            
                        }
                    }
                } else {
                    self.dispatch_async_main{
                        self.spinnerEnd()
                        let e = json.asError
                        self.jsonError(self.jsonErrorMsg,back_flag: false)
                        print(e as Any)
                    }
                }
            }

        } else {    // デモモード
//            let sql1 = "SELECT * ,iorder_detail.order_no AS as_order_no, iorder_detail.branch_no FROM ((iorder INNER JOIN iorder_detail ON iorder.facility_cd = iorder_detail.facility_cd AND iorder.order_no = iorder_detail.order_no ) INNER JOIN seat_master ON iorder_detail.serve_customer_no = seat_master.holder_no AND iorder_detail.seat_no = seat_master.seat_no) WHERE seat_master.table_no = ? AND iorder_detail.qty != 0 AND iorder_detail.detail_kbn != 9;"
            
            let sql1 = "SELECT * ,iorder_detail.order_no AS as_order_no, iorder_detail.branch_no FROM ((iorder INNER JOIN iorder_detail ON iorder.facility_cd = iorder_detail.facility_cd AND iorder.order_no = iorder_detail.order_no ) INNER JOIN seat_master ON iorder_detail.serve_customer_no = seat_master.holder_no AND iorder_detail.seat_no = seat_master.seat_no AND iorder.table_no = seat_master.table_no ) WHERE seat_master.table_no = ? AND iorder_detail.qty != 0 AND iorder_detail.detail_kbn != 9;"
            
            let db = FMDatabase(path: _path)
            
            // データベースをオープン
            db.open()
            let results = db.executeQuery(sql1, withArgumentsIn: [globals_table_no])
            while (results?.next())! {
                if results?.int(forColumn:"parent_menu_cd") == 0 {
                    let seat_no = Int((results?.int(forColumn:"seat_no"))!)
                    let seat_name = getSeatName(globals_table_no,seat_no: Int((results?.int(forColumn:"seat_no"))!))
                    let custmer_name = fmdb.getPlayerName(((results?.int(forColumn:"serve_customer_no"))?.description)!)
                    let menu_name = fmdb.getMenuName((results?.longLongInt(forColumn:"menu_cd"))!)
                    let payment_seat_no = Int((results?.int(forColumn:"payment_customer_seat_no"))!)
                    let pay_seat = getSeatName(globals_table_no,seat_no: payment_seat_no)
                    let menu_cd = Int((results?.int(forColumn:"menu_cd"))!)
                    let payment_customer_no = Int((results?.int(forColumn:"payment_customer_no"))!)
                    
                    if Section.count > 0 {
                        
                        let index = Section.index(where: {$0.seat_no == seat_no})
                        if index == nil {
                            Section.append(SectionData(
                                seat_no: Int((results?.int(forColumn:"seat_no"))!),
                                seat: seat_name,
                                No: "\(Int((results?.int(forColumn:"serve_customer_no"))!))",
                                Name: custmer_name)
                            )
                        }
                        
                    } else {
                        Section.append(SectionData(
                            seat_no: Int((results?.int(forColumn:"seat_no"))!),
                            seat: seat_name,
                            No: "\(Int((results?.int(forColumn:"serve_customer_no"))!))",
                            Name: custmer_name)
                        )
                    }
                    
                    let id = MainMenu.count
                    
                    // メニューNOが0以上のもの
                    if menu_cd > 0 {
                        MainMenu.append(CellData(
                            id:id,
                            seat: pay_seat,
                            No: ((results?.int(forColumn:"serve_customer_no"))?.description)!,
                            Name: menu_name,
                            MenuNo: menu_cd.description,
                            BranchNo:Int((results?.int(forColumn:"menu_branch"))!),
                            Count: ((results?.int(forColumn:"qty"))?.description)! ,
                            Hand: false,
                            MenuType: 1,
                            payment_seat_no:payment_seat_no
                            )
                        )
                        
                        // 経過時間を計算する
//                        let time = getTime(results?.string(forColumn:"modified"))
                        let time = getTime((results?.string(forColumn:"entry_date"))!)
                        
                        times.append(cancel_cellData(
                            id:id,
                            seat: pay_seat,
                            serve_seat: seat_name,
                            No: ((results?.int(forColumn:"serve_customer_no"))?.description)!,
                            Name: menu_name,
                            MenuNo: ((results?.int(forColumn:"menu_cd"))?.description)! ,
                            BranchNo: Int((results?.int(forColumn:"menu_branch"))!),
                            timezone_kbn: Int((results?.int(forColumn:"Timezone_KBN"))!),
                            Count: ((results?.int(forColumn:"qty"))?.description)! ,
                            Hand: false,
                            MenuType: 1,
                            time: time,
                            payment_customer_no:payment_customer_no.description,
                            payment_seat_no:payment_seat_no,
                            Slip_NO:"",
                            order_no:Int((results?.int(forColumn:"as_order_no"))!),
                            order_branch:Int((results?.int(forColumn:"branch_no"))!)
                            )
                        )
                    }
                }
                
            }
            
            // ユーザー順データ
            self.Section_User = Section
            self.MainMenu_User = MainMenu
            self.SubMenu_User = SubMenu
            self.SpecialMenu_User = SpecialMenu
            
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
            let xib = UINib(nibName: "cancelOrderSelectTableViewCell", bundle: nil)
            self.tableViewMain.register(xib, forCellReuseIdentifier: "Cell")
            
        }

    }
    // 行数を返す（UITableViewDataSource）
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 行数はセルデータの個数
        return self.Disp[section].count
        
    }
    // セルにデータを設定する（UITableViewDataSource）
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // セルを取り出す
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! cancelOrderSelectTableViewCell
        
        // 選択時に色を変えない
        cell.selectionStyle = UITableViewCellSelectionStyle.none

        
//        cell.setButton.setTitle(self.Disp[indexPath.section][indexPath.row].seat  , forState: .Normal)

        let cell_data = self.Disp[indexPath.section][indexPath.row]
        
        // メニュー名、精算者の席名
        if cell_data.MenuType == 1 {
            cell.orderNameLabel.baselineAdjustment = UIBaselineAdjustment.alignCenters
            cell.orderNameLabel.text = cell_data.Name
            cell.orderSeat.text = cell_data.seat
        } else {
            cell.orderNameLabel.text = "   ∟  " + cell_data.Name
        }
        
        if self.ck[indexPath.section][indexPath.row] == true {
            cell.setButton.setImage(check_on, for: UIControlState())
        } else {
            cell.setButton.setImage(check_off,for: UIControlState())
        }
        
        // 注文数
//        if Int(cell_data.Count) >= 0 {
//            cell.orderCountLabel.hidden = false
//            cell.orderCountLabel.text = cell_data.Count
//        }
        cell.orderCountLabel.text = cell_data.Count

        // 経過時間
        cell.orderMin.text = cell_data.time + "分"
        
        // cellの色を設定
        switch cell_data.MenuType {
        case 1:
            //            cell.backgroundColor = UIColor.clearColor()
            cell.orderNameLabel.textColor = iOrder_blackColor
        case 2:
            //            cell.backgroundColor = iOrder_bargainsYellowColor
            cell.orderNameLabel.textColor = iOrder_bargainsYellowColor
        case 3:
            //            cell.backgroundColor = iOrder_lightBrownColor
            cell.orderNameLabel.textColor = iOrder_lightBrownColor
        default:
            break
        }

        let directionList:[UISwipeGestureRecognizerDirection] = [.up,.down,.left,.right]
        
        for direction in directionList{
            let swipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(cancelOrderSelectViewController.swipeLabel(_:)))
            swipeRecognizer.direction = direction
            cell.addGestureRecognizer(swipeRecognizer)
        }

        // キャンセルセレクトボタンにイベントをつける
        cell.setButton.addTarget(self, action: #selector(cancelOrderSelectViewController.didTouchUpInside(_:)), for: .touchUpInside)
        
        // ボタンのタップ領域を増やす
//        cell.setButton.insets = UIEdgeInsetsMake(50, 50, 50, 50)
        
        return cell
    }

    // セクション数
    func numberOfSections(in tableView: UITableView) -> Int {
        //        return Section.count
        return Disp_Section.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as! cancelOrderSelectTableViewCell
//        return cell.bounds.height
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
        
        seatNameButton.setTitle(Disp_Section[section].seat, for: UIControlState())
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
        holderNoLabel.text = Disp_Section[section].No
        holderNoLabel.textColor = UIColor.white
        
        let status = fmdb.getPlayerStatus(Disp_Section[section].No)
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
            playerNameKanaLabel.text = fmdb.getNameKana(Disp_Section[section].No)
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
//        let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as! cancelOrderSelectTableViewCell
        // セルの高さ
//        return cell.bounds.height
        return (tableViewMain.bounds.height / table_row[disp_row_height])
    }

    // Cell が選択された場合
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath:IndexPath) {


//        ck[indexPath.section][indexPath.row] = !ck[indexPath.section][indexPath.row]
//        self.tableViewMain.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
    
        if self.Disp[indexPath.section][indexPath.row].Count != "" {
            var iCount:Int = Int(self.Disp[indexPath.section][indexPath.row].Count)!
            let iCount_back = Int(self.Disp_backup[indexPath.section][indexPath.row].Count)!
            
            var iCountAbs = abs(iCount)     // カウントの絶対値
            let iCount_back_abs = abs(iCount_back)
            
            // 注文数以上の数字入力抑止
            if (iCount_back < 0 && iCountAbs <= iCount_back_abs && iCountAbs > 0 ) || (iCount_back > 0 && iCountAbs < iCount_back_abs) {
//            if iCount < Int(self.Disp_backup[indexPath.section][indexPath.row].Count) {
                // タップ音
                TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                if (iCount_back < 0 && iCount < 0) || (iCount_back > 0 && iCount >= 0){
                    iCount += 1
                    iCountAbs = abs(iCount)
                }
                
                let idx = MainMenu_User.index(where: {$0.id == Disp[indexPath.section][indexPath.row].id})
                if idx != nil {
                    MainMenu_User[idx!].Count = "\(iCount)"
                }
                
//                for i in 0..<MainMenu_User.count {
//                    if self.Disp[indexPath.section][indexPath.row].No == MainMenu_User[i].No && self.Disp[indexPath.section][indexPath.row].MenuNo == MainMenu_User[i].MenuNo {
//                        MainMenu_User[i].Count = "\(iCount)"
//                    }
//                }
                self.makeDispData()
                self.tableViewMain.reloadRows(at: [indexPath], with: .none)
            } else {
                if iCount_back > 0 {
                    // toast with a specific duration and position
                    self.view.makeToast("注文数以上のキャンセルは出来ません", duration: 1.0, position: .top)
                    
                }
            }
            
        }
        
//        self.makeDispData()
//        self.tableViewMain.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)

    }
    
    // 戻るボタンタップ
    @IBAction func backButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        self.performSegue(withIdentifier: "toCancelTableNoInputViewSegue",sender: nil)
    }
    
    // 送信ボタンタップ時
    @IBAction func dataSend(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        cancel_Disp = []
        
        for (i,ck_section) in self.ck.enumerated() {
            // 多次元の可変配列の初期化
            cancel_Disp.append([cancel_cellData]())
            
            for (j,ck_row) in ck_section.enumerated() {
                
                if ck_row {
                    print(self.Disp[i][j])
                    cancel_Disp[i].append(self.Disp[i][j])
                }
            }
        }
        
        self.performSegue(withIdentifier: "toCancelOederCheckViewSegue",sender: nil)
        return;

    }

    
    func makeDispData(){
        // 表示用のデータを作成する
        Disp_Section = []
        Disp_Section = Section_User
        Disp = []
        for num in 0..<Section_User.count {
            let holderNo = Section_User[num].No
            let seat = Section_User[num].seat
            
            // 多次元の可変配列の初期化
            self.Disp.append([cancel_cellData]())
            
            self.ck.append([Bool]())
            
            // メニュー数
//            MainMenu_User = MainMenu_User.sort({$0})
            
            for (i,table) in MainMenu_User.enumerated() {
//                if holderNo == table.No && seat == table.seat{
                if holderNo == table.No {
                    if seat == times[i].serve_seat{
                        var menu_name = table.Name
                        
                        // サブメニュー数
                        var subMenu_name = ""
                        for sub in SubMenu_User {
                            if holderNo == sub.No {
                                if table.seat == seat && table.MenuNo == sub.MenuNo {
                                    if subMenu_name != "" {
                                        subMenu_name = subMenu_name + "・" + sub.Name
                                    } else {
                                        subMenu_name = sub.Name
                                    }
                                }
                            }
                        }
                        if subMenu_name != "" {
                            menu_name = menu_name + "(" + subMenu_name + ")"
                        }
                        //                    print(times[i].time)
                        
//                        var payment_no = ""
                        
                        let payment_no = times[i].payment_customer_no
                        
//                        let idx = Section_User.indexOf({$0.seat_no == table.payment_seat_no})
//                        if idx != nil {
//                            payment_no = Section_User[idx!].No
//                        }
                        
                        let addData = cancel_cellData(
                            id:table.id,
                            seat: table.seat,
                            serve_seat: seat,
                            No: table.No,
                            Name: menu_name,
                            MenuNo: table.MenuNo,
                            BranchNo: table.BranchNo,
                            timezone_kbn: times[i].timezone_kbn,
                            Count: table.Count,
                            Hand: table.Hand,
                            MenuType:
                            table.MenuType,
                            time: times[i].time,
                            payment_customer_no: payment_no,
                            payment_seat_no: table.payment_seat_no,
                            Slip_NO: times[i].Slip_NO,
                            order_no: times[i].order_no,
                            order_branch: times[i].order_branch
                        )
                        self.Disp[num].append(addData)
                        self.ck[num].append(false)

                    }
                }
            }
        }
        
        // 表示用データをソートさせる
        for i in 0..<Disp.count {
            Disp[i] = Disp[i].sorted(by: {$0.time < $1.time})
        }
        
        print(Disp)
        
        // 表示データを一回だけ保存する。
        if Disp_backup.count <= 0 {
           Disp_backup = Disp
        }
  
    }
    
    func swipeLabel(_ sender:UISwipeGestureRecognizer){
        let cell = sender.view as! UITableViewCell
        let indexPath = self.tableViewMain.indexPath(for: cell)!
        //        print(indexPath)
        
        switch(sender.direction){
        case UISwipeGestureRecognizerDirection.up:
            print("上")
            
        case UISwipeGestureRecognizerDirection.down:
            print("下")
            
        case UISwipeGestureRecognizerDirection.left:
            print("左1")
            if self.Disp[indexPath.section][indexPath.row].Count != "" {
                // 音
                TapSound.buttonTap("swish1", type: "mp3")

                var iCount:Int = Int(self.Disp[indexPath.section][indexPath.row].Count)!
                let iCount_back = Int(self.Disp_backup[indexPath.section][indexPath.row].Count)!
                
                var iCountAbs = abs(iCount)     // カウントの絶対値
                let iCount_back_abs = abs(iCount_back)
                
                if (iCount_back > 0 && iCountAbs > 0) || (iCount_back < 0 && iCountAbs < iCount_back_abs) {
//                if iCount > 0 {
                    iCount -= 1
                    iCountAbs = abs(iCount)
                } else {
                    if iCount_back < 0 {
                        // toast with a specific duration and position
                        self.view.makeToast("注文数以上のキャンセルは出来ません", duration: 1.0, position: .top)
                    }
                }
                
                let idx = MainMenu_User.index(where: {$0.id == Disp[indexPath.section][indexPath.row].id})
                
                if idx != nil {
                    MainMenu_User[idx!].Count = "\(iCount)"
                }
                
//                for i in 0..<MainMenu_User.count {
//                    if self.Disp[indexPath.section][indexPath.row].No == MainMenu_User[i].No && self.Disp[indexPath.section][indexPath.row].MenuNo == MainMenu_User[i].MenuNo {
//                        MainMenu_User[i].Count = "\(iCount)"
//                    }
//                }

            }
            
            self.makeDispData()
            self.tableViewMain.reloadRows(at: [indexPath], with: .none)
            
        case UISwipeGestureRecognizerDirection.right:
            print("右1")
//            if self.Disp[indexPath.section][indexPath.row].Count != "" {
//                // タップ音
//                TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
//
//                var iCount:Int = Int(self.Disp[indexPath.section][indexPath.row].Count)!
//                if iCount >= 0 {
//                    iCount += 1
//                }
//                
//                for i in 0..<MainMenu_User.count {
//                    if self.Disp[indexPath.section][indexPath.row].No == MainMenu_User[i].No && self.Disp[indexPath.section][indexPath.row].MenuNo == MainMenu_User[i].MenuNo {
//                        MainMenu_User[i].Count = "\(iCount)"
//                    }
//                }
//
//                
//            }
//            
//            self.makeDispData()
//            self.tableViewMain.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
            
        default:
            break
        }
    }

    // セレクトボタンタップ
    func didTouchUpInside(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

//        let btn = sender as! UIButton

//        let cell = btn.superview as! playerTableViewCell
        let point = self.tableViewMain.convert(sender.frame.origin, from: sender.superview)
        let indexPath = self.tableViewMain.indexPathForRow(at: point)

        if indexPath != nil {
            ck[indexPath!.section][indexPath!.row] = !ck[indexPath!.section][indexPath!.row]
            self.tableViewMain.reloadRows(at: [indexPath!], with: .none)
            
            var isCheck = false
            for i in 0..<self.ck.count {
                let index = ck[i].index(where: {$0 == true})
                if index != nil {
                    isCheck = true
                    break;
                }
            }
            if isCheck == true {
                self.okButton.isEnabled = true
                self.okButton.alpha = 1.0
            }else{
                okButton.isEnabled = false
                okButton.alpha = 0.6
            }            
        }
        
        
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

    // 戻るボタンで戻ってくるためのおまじない
    @IBAction func unwindToCencelOrderSelect(_ segue: UIStoryboardSegue) {
        for (i,disp_section) in Disp.enumerated() {
            for (j,disp_row) in disp_section.enumerated() {
                for cancel_section in cancel_Disp {
                    for cancel_row in cancel_section {
                        if disp_row.seat == cancel_row.seat && disp_row.No == cancel_row.No && cancel_row.MenuNo == disp_row.MenuNo && cancel_row.BranchNo == disp_row.BranchNo {
                            Disp[i][j].Count = cancel_row.Count
                        }
                    }
                }
            }
        }
        
        self.tableViewMain.reloadData()
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

//    // ホルダNOから名前を取得する
//    func getPlayerName(holder:Int) -> String {
//        
//        let db = FMDatabase(path: _path)
//        
//        // データベースをオープン
//        db.open()
//        let x = holder
//        
//        let sql = "select * from players where member_no in (?);"
//        let results = db.executeQuery(sql, withArgumentsIn: [x])
//        
//        var name = ""
//        while results?.next() {
//            name = results?.string(forColumn:"player_name_kanji")
//        }
//        db.close()
//        
//        return name
//    }

    // 席情報を取得する
    func getSeatName(_ table_no:Int,seat_no:Int) -> String {
        let db = FMDatabase(path: _path)
        
        // データベースをオープン
        db.open()
        
        let sql = "select * from seat_master where table_no = ? and seat_no = ?;"
        let results = db.executeQuery(sql, withArgumentsIn: [table_no,seat_no])
        
        var seat_name = ""
        while (results?.next())! {
            seat_name = (results?.string(forColumn:"seat_name"))!
        }
        db.close()
        
        return seat_name
    }

    
    func getTime(_ t1:String) -> String {
        var t2 = ""
        
        // 日時文字列をNSDate型に変換するためのDateFormatterを生成
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        
        // DateFormatterを使って日時文字列 "dateStr" をNSDate型 "date" に変換
        let date: Date? = formatter.date(from: t1)
        if date != nil {
            let time = Date().timeIntervalSince(date!) // 現在時刻と開始時刻の差
            let minutesSpan = Int(time/60)
            
            t2 = "\(minutesSpan)"
        }
//        print(date,Date(),t1,t2)
        
        return t2
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
