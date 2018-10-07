//
//  subMenuViewController.swift
//  iOrder
//
//  Created by 山尾守 on 2016/07/12.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit
import FontAwesomeKit
import FMDB
import Toast_Swift

class subMenuViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UINavigationBarDelegate {
    
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
    
//    var timezone:String?
    
    var checkImage:UIImage?
    
    var tableViewMain = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navBar.delegate = self
        navBar.barTintColor = iOrder_titleBlueColor

        // 背景色を白に設定する.
        self.view.backgroundColor = UIColor.white
        
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
        
        // チェックマーク
        let chkImage = FAKFontAwesome.checkIcon(withSize: iconSizeS)
        chkImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_subMenuColor)
        //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
        checkImage = chkImage?.image(with: CGSize(width: iconSizeS, height: iconSizeS))
        
        self.navBar.topItem?.title = (globals_select_menu_no.menu_name)
        
        self.loadData()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        dispatch_once(&self.onceTokenViewDidAppear) {
            DemoLabel.Show(self.view)
//        }
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
        let sql = "select * from sub_menus_master where menu_no = ?"
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
                    if (results?.int(forColumn:p[i]))! > 0 {
                        price[i] = Int((results?.int(forColumn:p[i]))!)
                    }
                }
                
                var is_Kubun = false
                if price[0] > 0 {
                    is_Kubun = true
                }
                
                self.tableData.append(CellData(subMenuKubun: subMenuKubun, subMenuNo: subMenuNo, subMenu: item!, tanka: price[0],tanka2: price[1],tanka3: price[2], isKubun: is_Kubun,isdefault: isdefault))
                
            } else {
                self.tableSection.append((subMenuKubun,item!))
            }
            
        }
        db.close()
//        print(tableSection)

        
        Disp = []
        for (num,kbn) in tableSection.enumerated() {
//        for num in 0..<tableSection.count {
            
            self.Disp.append([CellData]())
            
            for td in tableData {
//                print(td,kbn.0,num)
                if td.subMenuKubun == kbn.0 {
                    self.Disp[num].append(td)
                }
            }
        }
//        print(Disp)
        
        if DecisionSubMenu.count > 0 {
            // 今選ばれているメニューの情報があるかチェック
            var ck = false
            for d_sub in DecisionSubMenu {
                if d_sub.MenuNo == "\(globals_select_menu_no.menu_no)" {
                    ck = true
                    break
                }
            }
            
            if ck == true {
                // 選択情報クリア
                for (i, disp0) in Disp.enumerated() {
                    for (j, _) in disp0.enumerated() {
                        //                    print(i,j,disp1)
                        Disp[i][j].isdefault = false
                    }
                }
                
                for (i, disp0) in Disp.enumerated() {
                    for (j, disp1) in disp0.enumerated() {
                        for d_sub in DecisionSubMenu {
                            if (d_sub.Name == disp1.subMenu) {
                                //                            print(disp1.subMenu)
                                Disp[i][j].isdefault = true
                            }
                        }
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
        let xib = UINib(nibName: "subMenuTableViewCell", bundle: nil)
        self.tableViewMain.register(xib, forCellReuseIdentifier: "Cell")
        self.tableViewMain.reloadData()
        
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // 行数を返す（UITableViewDataSource）
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 行数はセルデータの個数
        return Disp[section].count
    }
    
    // セルにデータを設定する（UITableViewDataSource）
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セルを取り出す
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! subMenuTableViewCell
        // すべてのセルのアクセサリービューをまずは消去する
        cell.accessoryView = nil
        cell.accessoryType = .none
        
        let cellData = Disp[indexPath.section][indexPath.row]
        
        // ラベルにテキストを設定する
        let text = cellData.subMenu
        cell.subMenuName.text = text
        
        cell.subMenuPrice.text = ""
        if cellData.tanka != 0 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            cell.subMenuPrice.text = formatter.string(from: NSNumber(value: cellData.tanka))
        }
        
        if cellData.isKubun == true {
            
            // ボタン
            let iconImage = FAKIonIcons.iosArrowRightIcon(withSize: iconSizeS)
            iconImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_grayColor)
            //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
            let Image = iconImage?.image(with: CGSize(width: iconSizeS, height: iconSizeS))

            let addToAboveButton: UIButton = UIButton(frame: CGRect(x: 0, y: 0, width: iconSizeS, height: iconSizeS))
            addToAboveButton.setImage(Image, for: UIControlState())
            
            addToAboveButton.addTarget(self, action: #selector(subMenuViewController.checkButtonTapped(_:event:)), for: .touchUpInside)
            if cell.accessoryView == nil {
                cell.accessoryView = addToAboveButton
            }
            
            
//            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        }

        if cellData.isdefault == true {
            cell.subMenuImage.image = checkImage
        } else {
            cell.subMenuImage.image = nil
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
    }
 
    // セクションの高さ
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return tableViewHeaderHeight
    }
    
    
    // セクションのタイトル（UITableViewDataSource）
//    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        
//        let listTitle = tableSection[section]
//        //println(listTitle)
//        return listTitle
//    }

    // セクションのタイトルを詳細に設定
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        let headerView:UIView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: tableViewHeaderHeight))
        
        let posX:CGFloat = 0.0
        let posY:CGFloat = tableViewHeaderHeight / 2
        let betweenWidth:CGFloat = 10.0
     
        let fontName = "YuGo-Bold"    // "YuGo-Bold"

        // サブメニューヘッダーの設定
        let subMenuSectionLabel = UILabel()
        subMenuSectionLabel.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 30)
        //        holderNoLabel.backgroundColor = iOrder_grayColor
        subMenuSectionLabel.layer.position = CGPoint(x:posX + subMenuSectionLabel.frame.width / 2 + betweenWidth, y: posY)
        subMenuSectionLabel.font = UIFont(name: fontName,size: CGFloat(20))
        subMenuSectionLabel.text = tableSection[section].1
//        posX = posX + betweenWidth + holderNoLabel.frame.width

        headerView.backgroundColor = iOrder_greenColor
        
        headerView.addSubview(subMenuSectionLabel)

        return headerView
    }
    
    //    // アクセサリーボタンタップ時に呼ばれる
//    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
//        // toast with a specific duration and position
//        self.view.makeToast("タップで＋、\n左スライドで−", duration: 3.0, position: .center)
//
//        print("アクセサリーボタンタップ")
//    }
    

    func checkButtonTapped(_ sender: UIButton, event: UIEvent) {
        
        // toggle "tap to dismiss" functionality
        ToastManager.shared.tapToDismissEnabled = true
        
        // toggle queueing behavior
        ToastManager.shared.queueEnabled = true
        
        let point = self.tableViewMain.convert(sender.frame.origin, from: sender.superview)
        let indexPath = self.tableViewMain.indexPathForRow(at: point)!
        var msg = "　一般：" + "\(Disp[indexPath.section][indexPath.row].tanka)"
        msg = msg + "\n"
        msg = msg + "従業員：" + "\(Disp[indexPath.section][indexPath.row].tanka2)"
        msg = msg + "\n"
        msg = msg + "その他：" + "\(Disp[indexPath.section][indexPath.row].tanka3)"
        
        
        // toast with a specific duration and position
        self.view.makeToast(msg, duration: 5.0, position: .center)
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
                }
            }
            
            for i in 0..<Disp.count {
                var isCheck = false
                for j in 0..<Disp[i].count{
                    if Disp[i][j].isdefault == true {
                        isCheck = true
                        DecisionSubMenu.append(DecisionSubMenuData(
                            MenuNo: "\(globals_select_menu_no.menu_no)",
                            subMenuNo: Disp[i][j].subMenuNo,
                            subMenuGroup: Disp[i][j].subMenuKubun,
                            Name: Disp[i][j].subMenu )
                        )
                    }
                }
                if isCheck == false {
                    print("NO CHECK",i)
                    // toast with a specific duration and position
                    self.view.makeToast("セレクトメニューは必ず選んでください。", duration: 2.0, position: .top)

                    let lastPath:IndexPath = IndexPath(row:0, section:i)
                    tableViewMain.scrollToRow( at: lastPath , at: .top, animated: true)
                    return;
                }
            }
            print("DecisionSubMenu",DecisionSubMenu)
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
/*
            print("aaa",SubMenu)
            // サブメニューの削除
            if SubMenu.count > 0 {
                let sub_menu_b = SubMenu
                SubMenu = []
                for submenu0 in sub_menu_b {
                    if submenu0.No != globals_select_holder.holder || submenu0.MenuNo != "\(globals_select_menu_no.menu_no)" || submenu0.BranchNo != globals_select_menu_no.branch_no {
                        SubMenu.append(submenu0)
                    }
                }
                
            }
            
            // サブメニューの登録
            for submenu in DecisionSubMenu {
                if "\(globals_select_menu_no.menu_no)" == submenu.MenuNo {
                    SubMenu.append(SubMenuData(
                        seat:globals_select_holder.seat,
                        No: globals_select_holder.holder,
                        MenuNo: submenu.MenuNo,
                        BranchNo: globals_select_menu_no.branch_no,
                        Name: submenu.Name)
                    )
                }
            }
 */
            print("bbb",SubMenu)
            
            globals_select_holder.seat = ""
            globals_select_holder.holder = ""
            DecisionSubMenu = []
            
            self.performSegue(withIdentifier: "toOrderMakeSureView",sender: nil)
        }
    }
    
    // 戻るボタンタップ
    @IBAction func backButtonTap(_ sender: AnyObject) {
        
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        if (self.presentingViewController as? menuSelectViewController) != nil {
            self.performSegue(withIdentifier: "toMenuSelectWithSegue",sender: nil)
        } else if (self.presentingViewController as? orderMakeSureViewController) != nil {
            self.performSegue(withIdentifier: "toOrderMakeSureView",sender: nil)
        }
        
    }
    
    // 戻るボタンで戻ってくるためのおまじない
    @IBAction func unwindToSubMenu(_ segue: UIStoryboardSegue) {
        
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
