//
//  selectMenuDetailViewController.swift
//  iOrder2
//
//  Created by 山尾 守 on 2017/01/16.
//  Copyright © 2017年 山尾守. All rights reserved.
//

import UIKit
import FontAwesomeKit
import FMDB
import Toast_Swift


class selectMenuDetailViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UINavigationBarDelegate {

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
        var subMenuNo:Int
        var tanakKubun:String
        var tanka:Int
    }
    
    // セルデータの配列
    var tableData:[CellData] = []
    var tableSubData:[TankaData] = []
    var tableSection:[(Int,String)] = []
    var Disp:[[CellData]] = []
    
    
    var prices_kbn:[Int] = []
    
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
//        let iconImage2 = FAKFontAwesome.chevronCircleRightIconWithSize(iconSize)
//        iconImage2.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor())
//        //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
//        let Image2 = iconImage2.imageWithSize(CGSizeMake(iconSize, iconSize))
//        okButton.setImage(Image2, forState: .Normal)
        
        // チェックマーク
        let chkImage = FAKFontAwesome.checkIcon(withSize: iconSizeS)
        chkImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_subMenuColor)
        //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
        checkImage = chkImage?.image(with: CGSize(width: iconSizeS, height: iconSizeS))
        
        self.navBar.topItem?.title = (globals_select_selectmenu_no.select_menu_name)
        
        self.loadData()

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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadData(){
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
        db.open()
        let sql = "select * from sub_menus_master where menu_no = ? AND sub_menu_group = ? ORDER BY sub_menu_no"
        let results = db.executeQuery(sql, withArgumentsIn:[NSNumber(value: globals_select_menu_no.menu_no as Int64),globals_select_selectmenu_no.select_menu_no])
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

        Disp = []
        for (num,kbn) in tableSection.enumerated() {
            
            self.Disp.append([CellData]())
            
            for td in tableData {
                if td.subMenuKubun == kbn.0 {
                    self.Disp[num].append(td)
                }
            }
        }

        
        if DecisionSubMenu.count > 0 {
            
            for (i, disp0) in Disp.enumerated() {
                for (j, disp1) in disp0.enumerated() {
                    if disp1.subMenu == DecisionSubMenu[globals_select_row].Name {
                        // 一旦フラグをすべてOFFにする
                        for k in 0..<disp0.count {
                            Disp[i][k].isdefault = false
                        }
                        Disp[i][j].isdefault = true
                    }
                }
            }
        }

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
        let xib = UINib(nibName: "selectMenuDitailTableViewCell", bundle: nil)
        self.tableViewMain.register(xib, forCellReuseIdentifier: "Cell")
        self.tableViewMain.reloadData()

    }
    
    // 行数を返す（UITableViewDataSource）
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 行数はセルデータの個数
        return Disp[section].count
    }

    // セルにデータを設定する（UITableViewDataSource）
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セルを取り出す
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! selectMenuDitailTableViewCell
        // すべてのセルのアクセサリービューをまずは消去する
        cell.accessoryView = nil
        cell.accessoryType = .none
        
        let cellData = Disp[indexPath.section][indexPath.row]
//        print(cellData)
        
        // ラベルにテキストを設定する
        let text = cellData.subMenu
        cell.selectMenuName.baselineAdjustment = .alignCenters
        cell.selectMenuName.text = text
        
        if cellData.isKubun == true {
            
            // ボタン
            let button = UIButton()
            // 表示されるテキスト
            var text = ""

            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            // 単価区分が一つしかない場合はそれを表示させる。
            var prices = ("",0)
            if globals_price_kbn.count > 0 {
                globals_price_kbn.sort(by: {$0 < $1})
                
                prices = fmdb.getTanka(cellData.subMenuKubun, sub_menu_no: cellData.subMenuNo, unit_price_kbn: globals_price_kbn[0])
            }

//            text = formatter.string(from: NSNumber(prices.1))!
            text = formatter.string(from: NSNumber(value:prices.1))!
            
            button.contentHorizontalAlignment = .right
            button.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 10)
            button.setTitle(text, for: UIControlState())
            // テキストの色
            button.setTitleColor(UIColor.black, for: UIControlState())
            // サイズ
            button.frame = CGRect(x: 0, y: 0, width: 70, height: 30)
            button.layer.cornerRadius = 15
            button.clipsToBounds = true
            
            if globals_price_kbn.count > 1 {
                button.backgroundColor = iOrder_borderColor
                button.addTarget(self, action: #selector(subMenuViewController.checkButtonTapped(_:event:)), for: .touchUpInside)
            } else {
                button.backgroundColor = UIColor.clear
            }
            if cell.accessoryView == nil {
                cell.accessoryView = button
            }

            
            
        }
        
        if cellData.isdefault == true {
            cell.selectMenuImage.image = checkImage
        } else {
            cell.selectMenuImage.image = nil
        }
        
        // 設定済みのセルを戻す
        return cell
    }
    
    // セクション数
    func numberOfSections(in tableView: UITableView) -> Int {
        
        
        return tableSection.count
    }
    
    // セルの高さを返す（UITableViewDelegate）
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat{
        //        let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as! subMenuTableViewCell
        // セルの高さ
        //        return cell.bounds.height
        return (tableViewMain.bounds.height / table_row[disp_row_height])
    }

    // Cell が選択された場合
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath:IndexPath) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        for i in 0..<Disp[indexPath.section].count {
            Disp[indexPath.section][i].isdefault = false
        }
        
        Disp[indexPath.section][indexPath.row].isdefault = true
        
        tableView.reloadSections(IndexSet(integer: indexPath.section), with: .none)
        
        DecisionSubMenu[globals_select_row].MenuNo = "\(globals_select_menu_no.menu_no)"
        DecisionSubMenu[globals_select_row].Name = Disp[indexPath.section][indexPath.row].subMenu
        DecisionSubMenu[globals_select_row].subMenuNo = Disp[indexPath.section][indexPath.row].subMenuNo
        DecisionSubMenu[globals_select_row].subMenuGroup = globals_select_selectmenu_no.select_menu_no

        if (presentingViewController as? selectMenuViewController) != nil {
            let parentVC = presentingViewController as! selectMenuViewController
            parentVC.makeDispData()
            performSegue(withIdentifier: "toSelectMenuViewSegue",sender: nil)
            
        } else if (presentingViewController as? orderMakeSureViewController) != nil {
            performSegue(withIdentifier: "toOrderMakeSureViewSegue",sender: nil)
        }
    }

    func checkButtonTapped(_ sender: UIButton, event: UIEvent) {
        
        // toggle "tap to dismiss" functionality
        ToastManager.shared.tapToDismissEnabled = true
        
        // toggle queueing behavior
        ToastManager.shared.queueEnabled = true
        
        let point = self.tableViewMain.convert(sender.frame.origin, from: sender.superview)
        let indexPath = self.tableViewMain.indexPathForRow(at: point)!
        
        let disp_data = Disp[indexPath.section][indexPath.row]
        
        globals_price_kbn.sort(by: {$0 < $1})
        
        var msg = ""
        var prices = ("",0)
        for (i,kbn) in globals_price_kbn.enumerated() {
            prices = fmdb.getTanka(disp_data.subMenuKubun, sub_menu_no: disp_data.subMenuNo, unit_price_kbn: kbn)
            if i == 0 {
                msg = prices.0 + ":" + (prices.1).description
            } else {
                msg = msg + "\n"
                msg = msg + prices.0 + ":" + (prices.1).description
            }
            
        }

        // toast with a specific duration and position
        self.view.makeToast(msg, duration: 3.0, position: .center)
    }

    // 確定ボタンタップ
    @IBAction func okButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        for (_, disp0) in Disp.enumerated() {
            let index = disp0.index(where: {$0.isdefault == true})
            if index != nil {
                DecisionSubMenu[globals_select_row].MenuNo = "\(globals_select_menu_no.menu_no)"
                DecisionSubMenu[globals_select_row].Name = disp0[index!].subMenu
                DecisionSubMenu[globals_select_row].subMenuNo = disp0[index!].subMenuNo
            } else {
                // toast with a specific duration and position
                self.view.makeToast("セレクトメニューは必ず選んでください。", duration: 2.0, position: .top)
                
                return;

            }
        }
        
        print("DecisionSubMenu",DecisionSubMenu)
        let parentVC = presentingViewController as! selectMenuViewController
        parentVC.makeDispData()
        performSegue(withIdentifier: "toSelectMenuViewSegue",sender: nil)
    
    }
    
    // 戻るボタンタップ
    @IBAction func backButtonTap(_ sender: AnyObject) {
        
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        if (presentingViewController as? orderMakeSureViewController) != nil {
            self.performSegue(withIdentifier: "toOrderMakeSureViewSegue",sender: nil)
        } else {
            self.performSegue(withIdentifier: "toSelectMenuViewSegue",sender: nil)
        }
    }

    // 戻るボタンで戻ってくるためのおまじない
    @IBAction func unwindToSelectMenuDitail(_ segue: UIStoryboardSegue) {
        
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

}
