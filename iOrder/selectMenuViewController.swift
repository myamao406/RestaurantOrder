//
//  selectMenuViewController.swift
//  iOrder2
//
//  Created by 山尾 守 on 2017/01/16.
//  Copyright © 2017年 山尾守. All rights reserved.
//

import UIKit
import FontAwesomeKit
import FMDB
import Toast_Swift

class selectMenuViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UINavigationBarDelegate {
    private lazy var __once: () = {
                self.loadData()
                DemoLabel.Show(self.view)
                DemoLabel.modeChange()
            }()
    fileprivate var onceTokenViewDidAppear: Int = 0
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var navBar: UINavigationBar!
  
    // セルデータの型
    struct CellData {
        var subMenuKubun:Int
        var subMenuNo:Int
        var subMenu:String
        var tanka:Int
        var tanka2:Int
        var tanka3:Int
        var isKubun:Bool
        var isdefault:Bool
    }
    
    struct TankaData {
        var seat_no:Int
        var holderNo:Int
        var tanakKubun:String
    }
    
    // セルデータの配列
    var tableData:[CellData] = []
    var tableTankas:[TankaData] = []
    var tableSection:[(Int,String)] = []
    var Disp:[[CellData]] = []
    
    
    
    var timezone:String?
    
    var checkImage:UIImage?
    
    var tableViewMain = UITableView()

    
    override func viewDidLoad() {
        super.viewDidLoad()

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
        
        self.navBar.topItem?.title = (globals_select_menu_no.menu_name)
        
//        self.loadData()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 0秒遅延
        let delayTime = DispatchTime.now() + Double(Int64(0.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            _ = self.__once
        }
                
        DemoLabel.Show(self.view)
        DemoLabel.modeChange()
        
        tableViewMain.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        if let indexPathForSelectedRow = tableViewMain.indexPathForSelectedRow {
            tableViewMain.deselectRow(at: indexPathForSelectedRow, animated: true)
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

    func loadData(){
        // テーブルビューを作る
        
        // Viewの高さと幅を取得する.
        let displayWidth: CGFloat = self.view.frame.width
        let displayHeight: CGFloat = self.view.frame.height - toolBarHeight
        
        // TableViewの生成する(status barの高さ分ずらして表示).
        self.tableViewMain = UITableView(frame: CGRect(x: 0, y: barHeight + NavHeight, width: displayWidth, height: displayHeight - barHeight - NavHeight), style: UITableViewStyle.plain)
        
        // テーブルビューを追加する
        self.view.addSubview(self.tableViewMain)
        
        // テーブルビューのデリゲートとデータソースになる
        self.tableViewMain.delegate = self
        self.tableViewMain.dataSource = self
        
        // xibをテーブルビューのセルとして使う
        let xib = UINib(nibName: "selectMenuTableViewCell", bundle: nil)
        self.tableViewMain.register(xib, forCellReuseIdentifier: "Cell")

        self.makeDispData()

//        self.tableViewMain.reloadData()

    }
    
    // 表示用データ作成
    func makeDispData(){
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
        
        // FMDatabaseクラスのインスタンスを作成
        // 引数にファイルまでのパスを渡す
        let db = FMDatabase(path: _path)
        
        // メニューを取得する
        self.tableData = []
        self.tableSection = []
        
        db.open()
        let sql = "select * from sub_menus_master where menu_no = ? ORDER BY cast(item_short_name as integer)"
        let results = db.executeQuery(sql, withArgumentsIn:[NSNumber(value: globals_select_menu_no.menu_no as Int64)])
        let p = ["price1","price2","price3"]
        while (results?.next())! {
            let subMenuNo = Int((results?.int(forColumn:"sub_menu_no"))!)
            let subMenuKubun = Int((results?.int(forColumn:"sub_menu_group"))!)
            let item = (results?.string(forColumn:"item_name") != nil) ? results?.string(forColumn:"item_name") :""
            let isdefault = (results?.int(forColumn:"is_default") == 1) ? true :false
            
            if subMenuNo > 0 {
                var price = [0,0,0]
                for i in 0..<3 {
                    if !((results?.columnIsNull(p[i]))!) {
                        price[i] = Int((results?.int(forColumn:p[i]))!)
                    }
                }
                
                var is_Kubun = false
                if price[0] != 0 {
                    is_Kubun = true
                }
                
                self.tableData.append(CellData(
                    subMenuKubun: subMenuKubun,
                    subMenuNo: subMenuNo,
                    subMenu: item!,
                    tanka: price[0],
                    tanka2: price[1],
                    tanka3: price[2],
                    isKubun: is_Kubun,
                    isdefault: isdefault
                    )
                )
                
            } else {
                self.tableSection.append((subMenuKubun,item!))
            }
            
        }
        db.close()
        
        if DecisionSubMenu.count < 0 || DecisionSubMenu.count != tableSection.count {
            DecisionSubMenu = []
            for _ in tableSection {
                DecisionSubMenu.append(DecisionSubMenuData(
                    MenuNo: "",
                    subMenuNo: 0,
                    subMenuGroup: 0,
                    Name: ""
                    )
                )
            }
        } else {
            for i in 0..<tableSection.count {
                if DecisionSubMenu[i].MenuNo != "\(globals_select_menu_no.menu_no)" {
                    DecisionSubMenu[i].MenuNo = ""
                    DecisionSubMenu[i].Name = ""
                    DecisionSubMenu[i].subMenuNo = 0
                }
            }
        }
        
        
        Disp = []
        for (num,kbn) in tableSection.enumerated() {
            
            self.Disp.append([CellData]())
            
            for td in tableData {
                if td.subMenuKubun == kbn.0 {
                    self.Disp[num].append(td)
                }
            }
        }
        
        for i in 0..<DecisionSubMenu.count {
            if DecisionSubMenu[i].MenuNo != "" {
                for (j,disp0) in Disp[i].enumerated() {
                    if disp0.subMenu == DecisionSubMenu[i].Name {
                        Disp[i][j].isdefault = true
                    } else {
                        Disp[i][j].isdefault = false
                    }
                }
            }
        }
//        print("Disp",Disp)

        self.tableViewMain.reloadData()
    }
    
    
    // 行数を返す（UITableViewDataSource）
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 行数はセルデータの個数
        return tableSection.count
    }
   
    // セルにデータを設定する（UITableViewDataSource）
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セルを取り出す
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! selectMenuTableViewCell
        
        let cellData = tableSection[indexPath.row]
        
        // ラベルにテキストを設定する
        let text = cellData.1
        cell.selectMenuLabel.text = text

        cell.tankaButton.setTitle("", for: UIControlState())
        cell.tankaButton.backgroundColor = UIColor.clear
        cell.tankaButton.isEnabled = false
        
        for detail in Disp[indexPath.row] {
//            print(detail.subMenu,detail.isdefault)
            if detail.isdefault == true {
                cell.selectMenuDitailText.text = detail.subMenu
                if detail.tanka != 0 {
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .currency
                    // 単価区分が一つしかない場合はそれを表示させる。
                    var prices = ("",0)
                    if globals_price_kbn.count > 0 {
                        globals_price_kbn.sort(by: {$0 < $1})
                        
                        prices = fmdb.getTanka(detail.subMenuKubun, sub_menu_no: detail.subMenuNo, unit_price_kbn: globals_price_kbn[0])
                        
                    }
                    
                    cell.tankaButton.setTitle(formatter.string(from: NSNumber(value:prices.1)), for: UIControlState())
                    if globals_price_kbn.count > 1 {
                        cell.tankaButton.backgroundColor = iOrder_borderColor
                        cell.tankaButton.isEnabled = true
                        cell.tankaButton.addTarget(self, action: #selector(selectMenuViewController.checkButtonTapped(_:event:)), for: .touchUpInside)
                        
                    } else {
                        cell.tankaButton.backgroundColor = UIColor.clear
                        cell.tankaButton.isEnabled = false
//                        cell.tankaButton.addTarget(self, action: #selector(selectMenuViewController.checkButtonTapped(_:event:)), forControlEvents: .TouchUpInside)
                        
                    }
                }
            }
        }
        
        
        // 設定済みのセルを戻す
        return cell
    }

    // セクション数
    func numberOfSections(in tableView: UITableView) -> Int {
        
        
        return 1
    }

    // セルの高さを返す（UITableViewDelegate）
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat{
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! selectMenuTableViewCell
//        return (tableViewMain.bounds.height / table_row[disp_row_height])
        return cell.bounds.height
    }

    // Cell が選択された場合
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath:IndexPath) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        globals_select_selectmenu_no.select_menu_no = Disp[indexPath.row][0].subMenuKubun
        globals_select_selectmenu_no.select_menu_name = tableSection[indexPath.row].1
        globals_select_row = indexPath.row
        
        performSegue(withIdentifier: "toSelectMenuDitailViewSegue",sender: nil)
    }

    func checkButtonTapped(_ sender: UIButton, event: UIEvent) {
        
        // toggle "tap to dismiss" functionality
        ToastManager.shared.tapToDismissEnabled = true
        
        // toggle queueing behavior
        ToastManager.shared.queueEnabled = true
        
        let point = self.tableViewMain.convert(sender.frame.origin, from: sender.superview)
        let indexPath = self.tableViewMain.indexPathForRow(at: point)!
        
        let disp_data = Disp[indexPath.row]
        
        let tankas = disp_data.filter({$0.isdefault == true})
        if tankas.count > 0 {
            
            globals_price_kbn.sort(by: {$0 < $1})
            
            var msg = ""
            var prices = ("",0)
            for (i,kbn) in globals_price_kbn.enumerated() {
                prices = fmdb.getTanka(tankas[0].subMenuKubun, sub_menu_no: tankas[0].subMenuNo, unit_price_kbn: kbn)
                if i == 0 {
                    msg = prices.0 + ":" + (prices.1).description
                } else {
                    msg = msg + "\n"
                    msg = msg + prices.0 + ":" + (prices.1).description
                }
                
            }
            
//            var msg = "　一般：" + "\(tankas[0].tanka)"
//            msg = msg + "\n"
//            msg = msg + "従業員：" + "\(tankas[0].tanka2)"
//            msg = msg + "\n"
//            msg = msg + "その他：" + "\(tankas[0].tanka3)"
            
            // toast with a specific duration and position
            self.view.makeToast(msg, duration: 5.0, position: .center)
        }
        
    }

    // 次へボタンタップ
    @IBAction func okButtonTap(_ sender: AnyObject) {
        
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        if (self.presentingViewController as? menuSelectViewController) != nil {
            // 同じメニューNOのデータを消す
            let DecisionSub_back = DecisionSubMenu
            DecisionSubMenu = []
            for DecisionSub_0 in DecisionSub_back {
                if DecisionSub_0.MenuNo != "\(globals_select_menu_no.menu_no)" {
                    DecisionSubMenu.append(DecisionSub_0)
                } else {
                    DecisionSubMenu.append(DecisionSubMenuData(
                        MenuNo: "",
                        subMenuNo: 0,
                        subMenuGroup: 0,
                        Name: ""
                        )
                    )
                }
            }
            var isCheck = true
            for i in 0..<Disp.count {
                
                let index = Disp[i].index(where: {$0.isdefault == true})
                if index != nil {
                    
                } else {
                    print("NO CHECK",i)
                    isCheck = false
                    
                }
                
                for j in 0..<Disp[i].count{
                    if Disp[i][j].isdefault == true {
                        DecisionSubMenu[i].MenuNo = "\(globals_select_menu_no.menu_no)"
                        DecisionSubMenu[i].subMenuNo = Disp[i][j].subMenuNo
                        DecisionSubMenu[i].Name = Disp[i][j].subMenu
                    }
                }
            }
            print("DecisionSubMenu",DecisionSubMenu)
            if isCheck == false {
                print("NO CHECK")
                // toast with a specific duration and position
                self.view.makeToast("セレクトメニューは必ず選んでください。", duration: 2.0, position: .top)
                
                return;
            }
            
            performSegue(withIdentifier: "toOrderInputViewSegue",sender: nil)
        
        } else if (self.presentingViewController as? orderMakeSureViewController) != nil {
            // 同じメニューNOのデータを消す
            let DecisionSub_back = DecisionSubMenu
            DecisionSubMenu = []
            for DecisionSub_0 in DecisionSub_back {
                if DecisionSub_0.MenuNo != "\(globals_select_menu_no.menu_no)" {
                    DecisionSubMenu.append(DecisionSub_0)
                }
            }
            
            for i in 0..<Disp.count {
                for j in 0..<Disp[i].count{
                    if Disp[i][j].isdefault == true {
                        DecisionSubMenu.append(DecisionSubMenuData(
                            MenuNo: "\(globals_select_menu_no.menu_no)",
                            subMenuNo: Disp[i][j].subMenuNo,
                            subMenuGroup: Disp[i][j].subMenuKubun,
                            Name: Disp[i][j].subMenu )
                        )
                    }
                }
            }
            
            print(DecisionSubMenu)
            
            print("aaa",SubMenu)
            // サブメニューの削除
            if SubMenu.count > 0 {
                // id の検索
                SubMenu = SubMenu.filter({!($0.id == selectedID)})
                
//                let sub_menu_b = SubMenu
//                SubMenu = []
//                for submenu0 in sub_menu_b {
//                    if submenu0.No != globals_select_holder.holder || submenu0.MenuNo != "\(globals_select_menu_no.menu_no)" || submenu0.BranchNo != globals_select_menu_no.branch_no {
//                        SubMenu.append(submenu0)
//                    }
//                }
                
            }

            // サブメニューの登録
//            for submenu in DecisionSubMenu {
//                SubMenu.append(SubMenuData(
//                    id: selectedID,
//                    select_menu_group: submenu.subMenuGroup,
//                    select_menu_no: submenu.subMenuNo
//                    )
//                )
//            }

            // サブメニューの登録
            for submenu in DecisionSubMenu {
                if "\(globals_select_menu_no.menu_no)" == submenu.MenuNo {
                    SubMenu.append(SubMenuData(
                        id:-1,
                        seat:globals_select_holder.seat,
                        No: globals_select_holder.holder,
                        MenuNo: submenu.MenuNo,
                        BranchNo: globals_select_menu_no.branch_no,
                        Name: submenu.Name,
                        sub_menu_no: submenu.subMenuNo,
                        sub_menu_group: submenu.subMenuGroup
                        )
                    )
                }
            }
            print("bbb",SubMenu)
            
            globals_select_holder.seat = ""
            globals_select_holder.holder = ""
            DecisionSubMenu = []
            selectMenuCount = []
            selectSPmenus = []

            self.performSegue(withIdentifier: "toOrderMakeSureView",sender: nil)

        }
    }
    
    // 戻るボタンタップ
    @IBAction func backButtonTap(_ sender: AnyObject) {
        
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        if (self.presentingViewController as? menuSelectViewController) != nil {
            self.performSegue(withIdentifier: "toMenuSelectViewSegue",sender: nil)
        } else if (self.presentingViewController as? orderMakeSureViewController) != nil {
            self.performSegue(withIdentifier: "toOrderMakeSureView",sender: nil)
        }
        
    }

    
    // 戻るボタンで戻ってくるためのおまじない
    @IBAction func unwindToSelectMenu(_ segue: UIStoryboardSegue) {
        
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

}
