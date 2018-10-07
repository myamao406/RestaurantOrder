//
//  orderMakeSureViewController.swift
//  iOrder
//
//  Created by 山尾守 on 2016/07/15.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit
import FontAwesomeKit
import SWTableViewCell
import Toast_Swift
import FMDB
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}

//import Alamofire

class orderMakeSureViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UIPopoverPresentationControllerDelegate,UIToolbarDelegate,SWTableViewCellDelegate,UINavigationBarDelegate,UITextFieldDelegate{

    private lazy var __once: () = {
                // テーブルビューを作る
                // Status Barの高さを取得する.
                let barHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
                
                // Viewの高さと幅を取得する.
                let displayWidth: CGFloat = self.view.frame.width
                let displayHeight: CGFloat = self.view.frame.height - toolBarHeight
                
                // TableViewの生成する(status barの高さ分ずらして表示).
                self.tableViewMain = UITableView(frame: CGRect(x: 0, y: barHeight + NavHeight , width: displayWidth, height: displayHeight - barHeight - NavHeight ), style: UITableViewStyle.plain)
                
                let longPress2 = UILongPressGestureRecognizer(target: self, action: #selector(orderMakeSureViewController.pressedLongCell(_:)))
                
                self.tableViewMain.addGestureRecognizer(longPress2)
                
                // テーブルビューを追加する
                print("tableview addsubview")

                self.view.addSubview(self.tableViewMain)
                
                // テーブルビューのデリゲートとデータソースになる
                self.tableViewMain.delegate = self
                self.tableViewMain.dataSource = self
                
                // xibをテーブルビューのセルとして使う
                let xib = UINib(nibName: "orderMakeSureTableViewCell", bundle: nil)
                self.tableViewMain.register(xib, forCellReuseIdentifier: "Cell")
                
                // 今の状態を保存する。
                self.Section_Save = []
                self.Section_Save = Section

                self.loadData()
                DemoLabel.Show(self.view)
                DemoLabel.modeChange()
            }()

    fileprivate var onceTokenViewDidAppear: Int = 0

    // セルデータの型
    struct mainMenu_menuData {
        var id:Int
        var No:String           // ホルダNo
        var seat:String         // 座席名、支払座席名
        var MenuNo:String       // メニューNo
        var BranchNo:Int        // メニューNo枝番
        var Name:String         // メニュー名、ホルダNo＋お客様名
        var Count:String        // 注文数
        var Hand:Bool           // 手書き有無
        var MenuType:Int        // メニュー種別（１：メニュー　２：サブメニュー　３：スペシャルメニュー）
        var MenuName:String     // メニュー名＋サブメニュー名
        var payment_seat_no:Int
        
        init(id:Int,seat: String, No: String, Name: String, MenuNo: String, BranchNo:Int,Count: String, Hand: Bool, MenuType: Int,MenuName:String,payment_seat_no:Int){
            self.id = id
            self.seat = seat
            self.No = No
            self.Name = Name
            self.MenuNo = MenuNo
            self.BranchNo = BranchNo
            self.Count = Count
            self.Hand = Hand
            self.MenuType = MenuType
            self.MenuName = MenuName
            self.payment_seat_no = payment_seat_no
        }
    }

    let initVal = CustomProgressModel()
    
    // 大本の情報の保存用バッファ
    var Section_Save:[SectionData] = []             // セクションデータ
    var MainMenu_Save:[CellData] = []               // メインメニュー
    var SubMenu_Save:[SubMenuData] = []             // セレクトメニュー（サブメニュー）
    var SpecialMenu_Save:[SpecialMenuData] = []     // オプションメニュー（特殊メニュー）

    // ユーザー別表示用バッファ
    var Section_User:[SectionData] = []             // セクションデータ
    var MainMenu_User:[CellData] = []               // メインメニュー
    var SubMenu_User:[SubMenuData] = []             // セレクトメニュー（サブメニュー）
    var SpecialMenu_User:[SpecialMenuData] = []     // オプションメニュー（特殊メニュー）
    
    // メニュー別表示用バッファ
    var Section_Menu:[SectionData] = []             // セクションデータ
    var MainMenu_Menu:[mainMenu_menuData] = []      // メインメニュー
    var SubMenu_Menu:[SubMenuData] = []             // セレクトメニュー（サブメニュー）
    var SpecialMenu_Menu:[SpecialMenuData] = []     // オプションメニュー（特殊メニュー）

    // 画面表示用バッファ
    var Disp:[[CellData]] = []
    var Disp_Section:[SectionData] = []
    var Disp_Save:[[CellData]] = []
    var Disp_Temp:[[CellData]] = []
    
    var section_menu_seat:[String] = []             // メニュー別表示用の支払い者一括変更用
    
    var tableSection:[(sub_menu_no:Int,kubun:Int,name:String)] = []
    
//    var spAdd:[[Int]] = []
    
    // ユーザー別表示、メニュー別表示の切替フラグ
    var isDispChange: Bool = true                   // （true:ユーザー別,false:メニュー別）
    
    // テーブルビュー
    var tableViewMain = UITableView()
    
    // 時刻入力用デートpicker
    let dp:UIDatePicker = UIDatePicker()
    var toolBar:UIToolbar!
    
    lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        return dateFormatter
    }()
    
    var isObserving = false
    
    var isKeyboardType = false
    
    // ローカルで使用する行列
    var localSection = 0
    var localRow = 0
    let underScore = "_"
    
    
//    var sendData:NSData?
    
    @IBOutlet weak var timeTextField: UITextField!
    @IBOutlet weak var dispChangeButton: UIBarButtonItem!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var timeInputButton: UIButton!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var allChangeButton: UIButton!
    
    let iconSizeW:CGFloat = 50.0
    let iconSizeH:CGFloat = 50.0
    let topMargin:CGFloat = 10.0
    let betweenMargin:CGFloat = 5.0

    var orderImage:UIImage?
    var userImage:UIImage?
    var handImage:UIImage?
    var subMenuImage:UIImage?
    var speMenuImage:UIImage?
    
    // DBファイルパス
    var _path:String = ""
    
    var max_oeder_no : Int?
    
    // 文字数最大を決める.
    let maxLength: Int = 5

    var replacedIndex = 0
    var deleteIndex = 0
    
    // 送信日時
    var sendTime = ""
    
    var del_seat: String?
    var del_holder_no: String?
    var del_menu_no: String?
    var del_branch: Int = 0
    
    var is_not_send_alert_disp = false
    
//    var is_send_error_disp = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navBar.delegate = self
        navBar.barTintColor = iOrder_titleBlueColor
        
        timeTextField.delegate = self
        
        // 背景色を白に設定する.
        self.view.backgroundColor = UIColor.white
        
        // 戻るボタン
        var iconImage = FAKFontAwesome.chevronCircleLeftIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_bargainsYellowColor)
        var Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        backButton.setImage(Image, for: UIControlState())
        
        // 長押し
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.pressedLong2(_:)))
        
        backButton.addGestureRecognizer(longPress)
        
        // 確定ボタン
        iconImage = FAKFontAwesome.checkIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
        Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        okButton.setImage(Image, for: UIControlState())

        // 時刻入力ボタン
        iconImage = FAKFontAwesome.clockOIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: iOrder_greenColor)
        Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        timeInputButton.setImage(Image, for: UIControlState())

        // オーダーイメージ
        iconImage = FAKFontAwesome.cutleryIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
        orderImage = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))

        // ユーザーイメージ
        iconImage = FAKFontAwesome.usersIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
        userImage = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        dispChangeButton.image = orderImage

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

        // テーブルNO
        self.navBar.topItem?.title = "テーブルNo：" + "\(globals_table_no)"
        
        
        // スタート時刻表示に枠をつける
        timeTextField.layer.borderWidth = 2.0
        // 枠の色を設定する
        timeTextField.layer.borderColor = iOrder_borderColor.cgColor
        // 角を丸くする
        timeTextField.layer.cornerRadius = 5
        timeTextField.text = "__:__"
        
        if globals_pm_start_time != "" {
            timeTextField.text = globals_pm_start_time
            timeTextField.isHidden = false
        } else {
            timeTextField.isHidden = true
        }
        
        // UIToolBarの設定
        toolBar = UIToolbar(frame: CGRect(x: 0, y: self.view.frame.size.height/6, width: self.view.frame.size.width, height: 50.0))
        toolBar.layer.position = CGPoint(x: self.view.frame.size.width/2, y: self.view.frame.size.height-20.0)
        toolBar.barStyle = .default
        toolBar.tintColor = iOrder_blackColor
        toolBar.backgroundColor = iOrder_borderColor

        let toolBarBtn  = UIBarButtonItem(title: "完了", style: .done , target: self, action: #selector(orderMakeSureViewController.tappedToolBarBtn(_:)))
        let toolBarBtn2 = UIBarButtonItem(title: "切替え", style: .done , target: self, action: #selector(orderMakeSureViewController.tappedToolBarChangedBtn(_:)))
        let toolBarBtn3 = UIBarButtonItem(title: "クリア", style: .done , target: self, action: #selector(orderMakeSureViewController.tappedToolBarClearBtn(_:)))
        
        // Flexible Space Bar Button Item
        let flexibleItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        
        let fixedItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: nil, action: nil)
        fixedItem.width = 20.0
        
        toolBarBtn.tag = 1
        toolBar.items = [flexibleItem,toolBarBtn3,fixedItem,toolBarBtn2,fixedItem,toolBarBtn]
        
        timeTextField.inputAccessoryView = toolBar
        
        deleteIndex = maxLength
        
        // 精算者振り替え機能OFFの場合
        if is_payer_allocation != 1 {
            // 全ボタンを使用不可にする
            self.allChangeButton.isEnabled = false
            self.allChangeButton.isHidden = true
        }

        
        if data_not_send_alert.sound_interval > 0 {
            updating()
            order_send_time = 0
            order_send_interval = 0
            is_not_send_alert_disp = true
        }

//        is_send_error_disp = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Viewの表示時にキーボード表示・非表示を監視するObserverを登録する
        super.viewWillAppear(animated)
        if(!isObserving) {
            let notification = NotificationCenter.default
            notification.addObserver(self, selector: #selector(orderMakeSureViewController.keyboardWillShow(_:))
                , name: NSNotification.Name.UIKeyboardWillShow, object: nil)
            notification.addObserver(self, selector: #selector(orderMakeSureViewController.keyboardWillHide(_:))
                , name: NSNotification.Name.UIKeyboardWillHide, object: nil)
            isObserving = true
        }
        // TableViewを編集可能にする
        tableViewMain.setEditing(isEditing, animated: true)
        
        self.SpecialMenu_Save = []
        self.SpecialMenu_Save = SpecialMenu
        
//        self.SpecialMenu_User = []
//        self.SpecialMenu_User = SpecialMenu
        
        
//        self.makeDispData()
//        tableViewMain.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // 画面を抜けるときに、元の設定に戻す
        if order_send_timer.isValid == true {
            // timerを破棄する
            order_send_timer.invalidate()
        }

    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 0秒遅延
        let delayTime = DispatchTime.now() + Double(Int64(0.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            _ = self.__once
        }
        self.loadData()
        tableViewMain.reloadData()

        DemoLabel.Show(self.view)
        DemoLabel.modeChange()
        

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Viewの表示時にキーボード表示・非表示時を監視していたObserverを解放する
        super.viewWillDisappear(animated)
        if(isObserving) {
            let notification = NotificationCenter.default
            notification.removeObserver(self)
            notification.removeObserver(self
                , name: NSNotification.Name.UIKeyboardWillShow, object: nil)
            notification.removeObserver(self
                , name: NSNotification.Name.UIKeyboardWillHide, object: nil)
            isObserving = false
        }
    }
    
    func keyboardWillShow(_ notification: Notification?) {
        // キーボード表示時の動作をここに記述する
        let rect = (notification?.userInfo?[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let duration:TimeInterval = notification?.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! Double
        UIView.animate(withDuration: duration, animations: {
            let transform = CGAffineTransform(translationX: 0, y: -rect.size.height)
            self.view.transform = transform
            },completion:nil)
    }
    func keyboardWillHide(_ notification: Notification?) {
        // キーボード消滅時の動作をここに記述する
        let duration = (notification?.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! Double)
        UIView.animate(withDuration: duration, animations:{
            self.view.transform = CGAffineTransform.identity
            },
                                   completion:nil)
    }
    
    // ステータスバーとナビゲーションバーの色を同じにする
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.topAttached
    }
    
    // ステータスバーの文字を白にする
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // 入力済みのテキストを取得

        
        // 削除キーを押された場合
        if (string.characters.count == 0 && range.length > 0) {
            let str = textField.text!
            
            // 数字が全て入力済みの場合
            if str.range(of: "_") == nil {
                if deleteIndex < 0 {
                   deleteIndex = maxLength
                }
                
                let startIndex = str.characters.index(str.startIndex, offsetBy: deleteIndex)
                let nextIndex = str.index(before: startIndex)
//                let nextIndex = <#T##String.CharacterView corresponding to `startIndex`##String.CharacterView#>.index(before: startIndex)    // 一つ前のIndexを取得する
                
                let replacedText = str.replacingCharacters(in: nextIndex..<startIndex, with: underScore)


                textField.text = replacedText.substring(to: replacedText.characters.index(replacedText.startIndex, offsetBy: maxLength))
                deleteIndex += -1
                if deleteIndex == 3 {
                    replacedIndex += -1
                }
                return false
            } else {
                deleteIndex = maxLength
                var startIndex = str.range(of: "_")!.lowerBound
                if startIndex > str.startIndex {
                    let coronIndex = str.index(before: startIndex)
//                    let coronIndex = <#T##Collection corresponding to `startIndex`##Collection#>.index(before: startIndex)
                    if str[coronIndex] == ":" {
                        startIndex = str.index(before: startIndex)
//                        startIndex = <#T##Collection corresponding to `startIndex`##Collection#>.index(before: startIndex)
                    }
                    let nextIndex = str.index(before: startIndex)    // 一つ前のIndexを取得する
//                    let nextIndex = <#T##Collection corresponding to `startIndex`##Collection#>.index(before: startIndex)    // 一つ前のIndexを取得する
                    
                    let replacedText = str.replacingCharacters(in: nextIndex..<startIndex, with: underScore)
                    
                    
                    // 文字数がmaxLength以下ならtrueを返す.
                    if str.characters.count <= maxLength {
                        textField.text = replacedText
                        return false
                    }
                }
            }
            
            return false
        }
        
//        print(string)
        // 入力済みの文字と入力された文字を合わせて取得.
        let str = textField.text!
        
        if str.range(of: "_") == nil {
            print("文字を超えています")
//            print(replacedIndex)
            if replacedIndex >= maxLength {
               replacedIndex = 0
            }
            let startIndex = str.characters.index(str.startIndex, offsetBy: replacedIndex)
            let nextIndex = str.index(after: startIndex)    // 次のIndexを取得する
//            let nextIndex = <#T##String.CharacterView corresponding to `startIndex`##String.CharacterView#>.index(after: startIndex)    // 次のIndexを取得する
            
            let replacedText = str.replacingCharacters(in: startIndex..<nextIndex, with: string)
//            print(startIndex,nextIndex,replacedText)
            
            textField.text = replacedText.substring(to: replacedText.characters.index(replacedText.startIndex, offsetBy: maxLength))
//            print(textField.text)
            replacedIndex += 1
            if replacedIndex == 2 {
                replacedIndex += 1
            }
            return false
        }
        
        replacedIndex = 0
        let startIndex = str.range(of: "_")!.lowerBound
        let nextIndex = str.index(after: startIndex)    // 次のIndexを取得する
//        let nextIndex = <#T##String.CharacterView corresponding to `startIndex`##String.CharacterView#>.index(after: startIndex)    // 次のIndexを取得する
//        print(startIndex,nextIndex)
        
        let replacedText = str.replacingCharacters(in: startIndex..<nextIndex, with: string)
//        print(replacedText)
        
        
        // 文字数がmaxLength以下ならtrueを返す.
//        print(str)
        
        if str.characters.count <= maxLength {
            textField.text = replacedText
            return false
        }
        print("\(maxLength)" + "文字を超えています")
        return false
        

    }
    
    // MARK - TableView
    
    func loadData(){

        // 今の状態を保存する。
//        self.Section_Save = []
        self.MainMenu_Save = []
        self.SubMenu_Save = []
        self.SpecialMenu_Save = []
        
        // ユーザー順データ
        self.Section_User = []
        self.MainMenu_User = []
        self.SubMenu_User = []
        self.SpecialMenu_User = []

        // 今の状態を保存する。
        
//        self.Section_Save = Section
        self.MainMenu_Save = MainMenu
        self.SubMenu_Save = SubMenu
        self.SpecialMenu_Save = SpecialMenu

        // ユーザー順データ
        self.Section_User = Section
        self.MainMenu_User = MainMenu
        self.SubMenu_User = SubMenu
        self.SpecialMenu_User = SpecialMenu

        section_menu_seat = []
        for _ in Section_Save {
            section_menu_seat.append(Section_Save[0].seat)
        }
        
        // メニュー順データ
        
        self.makeMenuSort()
        
        
        // 表示用データの作成
        self.makeDispData()
        
        // 表示データを一旦保持する
        Disp_Save = Disp
        Disp_Temp = Disp

        
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
        
        let db = FMDatabase(path: self._path)
        // データベースをオープン
        db.open()
        var price_kbn = 0
        // 来場者テーブルから単価区分を取得
//        let sql1 = "SELECT * FROM players WHERE member_no in (?);"
//        let results = db.executeQuery(sql1, withArgumentsIn: [Int(Disp_data.No)!])
        
        
        let results = db.executeQuery(SELECT_PLAYERS, withArgumentsIn: [Int(Disp_data.No)!,shop_code,globals_today + "%"])
        while results!.next() {
            price_kbn = Int(results!.int(forColumn: "price_tanka"))
        }
        
        db.close()

        
        // ボタンの設定
        // ラベルにテキストを設定する
        // まずすべてのアイテムを非表示にする
        cell.setButton.isHidden = true
        cell.orderCountLabel.isHidden = true
        cell.handWrightButton.isHidden = true
        cell.orderAddButton.isHidden = true
        cell.subOrderNameLabel.isHidden = true
        cell.subOrderNameLabel.baselineAdjustment = UIBaselineAdjustment.alignCenters
        cell.subOrderImage.isHidden = true
        cell.orderNameLabel.isHidden = true
        cell.orderNameLabel.baselineAdjustment = UIBaselineAdjustment.alignCenters
        cell.orderName2Label.isHidden = true
        cell.orderName2Label.baselineAdjustment = UIBaselineAdjustment.alignCenters
        cell.orderNameKanaLabel.isHidden = true
        
        cell.accessoryView = nil
        

        // メニュー名
        if Disp_data.MenuType == 1 {
            // 精算者振り替え機能OFFの場合は表示しない
            if is_payer_allocation == 1 {
                // 支払者の席番号
                var seat_name = ""
                let idx = seat.index(where: {$0.seat_no == Disp_data.payment_seat_no})
                if idx != nil {
                    seat_name = seat[idx!].seat_name
                }
                
                cell.setButton.isHidden = false
                cell.setButton.setTitle(seat_name, for: UIControlState())
                // 席ボタンにイベントをつける
                cell.setButton.addTarget(self, action: #selector(orderMakeSureViewController.payChange(_:)), for: .touchUpInside)
                // ホールド
                let longPress = UILongPressGestureRecognizer(target: self, action: #selector(orderMakeSureViewController.pressedLong(_:)))
                cell.setButton.addGestureRecognizer(longPress)
                
            }
            
            if furigana == 1 && isDispChange == false{
                cell.orderName2Label.isHidden = false
                cell.orderNameKanaLabel.isHidden = false
                
                cell.orderName2Label.text = Disp_data.Name
                cell.orderNameKanaLabel.text = fmdb.getNameKana(Disp_data.MenuNo)
            } else {
                cell.orderNameLabel.isHidden = false
                cell.orderNameLabel.text = Disp_data.Name
            }
            
        } else {
            
            var tanka = ""
            // セレクトメニューの場合
            if Disp_data.MenuType == 2 {
                let db = FMDatabase(path: self._path)
                // データベースをオープン
                db.open()
                
                // メニュー区分、サブメニューコード取得
                var sub_menu_kbn = 0
                var sub_menu_code = 0
                let sql = "SELECT * from sub_menus_master WHERE menu_no = ? AND item_name = ?;"
                let rs = db.executeQuery(sql, withArgumentsIn: [Disp_data.MenuNo,Disp_data.Name])
                while (rs?.next())! {
                    sub_menu_kbn = Int((rs?.int(forColumn: "sub_menu_group"))!)
                    sub_menu_code = Int((rs?.int(forColumn: "sub_menu_no"))!)
                }
                rs?.close()
                

                db.close()
                globals_select_menu_no.menu_no = Int64(Disp_data.MenuNo)!
                //            let sub_menu_g = "1"
                let prices = fmdb.getTanka(sub_menu_kbn, sub_menu_no: sub_menu_code, unit_price_kbn: price_kbn)

                tanka = prices.kbn_name != "" ? "(¥" + (prices.price).description + ")" : ""
                
            } else if Disp_data.MenuType == 3 {         // オプションメニューの場合
                let db = FMDatabase(path: self._path)
                // データベースをオープン
                db.open()
                
                // 特殊メニュー区分、特殊メニューコード取得
                var spe_menu_kbn = 0
                var spe_menu_code = 0
                let sql = "SELECT * from special_menus_master WHERE item_name = ?;"
                let rs = db.executeQuery(sql, withArgumentsIn: [Disp_data.Name])
                while (rs?.next())! {
                    spe_menu_kbn = Int((rs?.int(forColumn: "category_no"))!)
                    spe_menu_code = Int((rs?.int(forColumn: "item_no"))!)
                }

                db.close()
//                print(spe_menu_kbn,spe_menu_code)
                let prices = fmdb.getOptionTanka(spe_menu_kbn, spe_menu_no:spe_menu_code,unit_price_kbn: price_kbn)
//                print(prices)
                tanka = prices.kbn_name != "" ? "(¥" + (prices.price).description + ")" : ""
            }
            
            
            cell.orderNameLabel.text = "   ∟  " + Disp_data.Name
            cell.orderNameLabel.isHidden = true
            cell.subOrderNameLabel.text = Disp_data.Name + tanka
            cell.subOrderNameLabel.isHidden = false
            

        }

        // 注文数
//        if Int(Disp_data.Count) != 0 {
        if Disp_data.MenuType == 1 {
            cell.orderCountLabel.isHidden = false
            cell.orderCountLabel.text = Disp_data.Count
        }
        
        // 手書き表示有無ボタン
        if Disp_data.Hand == true {
            // ボタンに画像をセットする
            cell.handWrightButton.setImage(handImage, for: UIControlState())
            cell.handWrightButton.addTarget(self, action: #selector(orderMakeSureViewController.handWright_image_preview(_:)), for: .touchUpInside)
            cell.handWrightButton.isHidden = false
        }
        // 特殊メニュー追加ボタン
        if Disp_data.MenuType == 3 {
            if Int(Disp_data.Count) == -1 {
                let addButton = UIButton(type: UIButtonType.contactAdd)
                
//                cell.orderAddButton.hidden = false
                addButton.addTarget(self, action: #selector(orderMakeSureViewController.showSpecialMenuView(_:)), for: .touchUpInside)

                cell.accessoryView = addButton
                
            }
        }
        
        // cellの色を設定
        switch Disp_data.MenuType {
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
        
//        let directionList:[UISwipeGestureRecognizerDirection] = [.Up,.Down,.Left,.Right]
        let directionList:[UISwipeGestureRecognizerDirection] = [.left]
        
        for direction in directionList{
            let swipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(orderMakeSureViewController.swipeLabel(_:)))
            swipeRecognizer.direction = direction
            cell.addGestureRecognizer(swipeRecognizer)
        }
        
        // 設定済みのセルを戻す
        DemoLabel.modeChange()
        return cell
    }
    
    // セクション数
    func numberOfSections(in tableView: UITableView) -> Int {
//        return Section.count
        return Disp_Section.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as! orderMakeSureTableViewCell
//        return cell.bounds.height
//        return 44
        return tableViewHeaderHeight
    }
    
    
    // セクションのタイトルを詳細に設定
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView:UIView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: tableViewHeaderHeight))
        
        let fontName = "YuGo-Bold"    // "YuGo-Bold"
        
        var posX:CGFloat = 0.0
        let posY:CGFloat = tableViewHeaderHeight / 2
        let betweenWidth:CGFloat = 10.0
        
        // 席ボタンの設置
        let seatNameButton   = UIButton()
        seatNameButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
//        seatNameButton.backgroundColor = iOrder_orangeColor
        seatNameButton.backgroundColor = UIColor.clear
        
        seatNameButton.layer.position = CGPoint(x: posX + seatNameButton.frame.width / 2 + betweenWidth - 2 , y: posY  )
            
//        seatNameButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        seatNameButton.setTitleColor(UIColor.clear, for: UIControlState())
        // フォント名の指定はPostScript名
        seatNameButton.titleLabel!.font = UIFont(name: fontName,size: CGFloat(20))
            
        seatNameButton.setTitle(Disp_Section[section].seat, for: UIControlState())
        
        // 席ラベルの作成
        let seatNameLabel = UILabel()
        seatNameLabel.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        seatNameLabel.layer.position = CGPoint(x: posX + seatNameButton.frame.width / 2 + betweenWidth - 2 , y: posY  )
        seatNameLabel.font = UIFont(name: fontName,size: CGFloat(20))
        seatNameLabel.textColor = UIColor.white
        seatNameLabel.backgroundColor = iOrder_orangeColor
        seatNameLabel.textAlignment = .center
        
        // お客様表示順
        if isDispChange == true {
            seatNameLabel.text = Section_Save[section].seat
        } else {        // メニュー表示順
            seatNameLabel.text = Disp_Section[section].seat
        }
        
        seatNameButton.addTarget(self, action: #selector(orderMakeSureViewController.payChangeHeader(_:)), for: .touchUpInside)
        // 長押し
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(orderMakeSureViewController.pressedLong(_:)))
        
        seatNameButton.addGestureRecognizer(longPress)
        // タグ番号
        seatNameButton.tag = section + 1
        
        posX = betweenWidth + seatNameButton.frame.width
        
        
        // ホルダNOの設定
        let holderNoLabel = UILabel()
        holderNoLabel.frame = CGRect(x: 0, y: 0, width: 70, height: 30)
//        holderNoLabel.backgroundColor = iOrder_grayColor
        holderNoLabel.layer.cornerRadius = 5.0
        holderNoLabel.clipsToBounds = true
        holderNoLabel.textAlignment = .center
        holderNoLabel.backgroundColor = UIColor.clear
        holderNoLabel.layer.borderColor = UIColor.clear.cgColor
        holderNoLabel.layer.borderWidth = 0.0
        
        if isDispChange == true {
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
                holderNoLabel.layer.borderColor = UIColor.white.cgColor
                holderNoLabel.layer.borderWidth = 1.0
                
//                holderNoLabel.backgroundColor = iOrder_grayColor
                holderNoLabel.textColor = UIColor.white
                break;
            default:
                break;
            }

            
            
        } else {
            
        }
        
        
        holderNoLabel.layer.position = CGPoint(x:posX + holderNoLabel.frame.width / 2 + betweenWidth, y: posY)
        holderNoLabel.font = UIFont(name: fontName,size: CGFloat(20))
        holderNoLabel.text = Disp_Section[section].No
        holderNoLabel.textColor = UIColor.white
        posX = posX + betweenWidth + holderNoLabel.frame.width

        // プレイヤー名の設定
        let playerNameLabel = UILabel()
        playerNameLabel.frame = CGRect(x: 0, y: 0, width: headerView.frame.width - posX - (betweenWidth * 2), height: 30)
//        playerNameLabel.backgroundColor = iOrder_borderColor

        
        let marginY:CGFloat = (furigana == 1 && isDispChange == true) ? 7 : 0
        
//        var marginY:CGFloat = 0
//        if furigana == 1 && isDispChange == true{
//            marginY = 7
//        }
        
        playerNameLabel.layer.position = CGPoint(x:posX + playerNameLabel.frame.width / 2 + betweenWidth, y: posY + marginY)
        playerNameLabel.font = UIFont(name: fontName,size: CGFloat(20))
        playerNameLabel.numberOfLines = 0
        playerNameLabel.adjustsFontSizeToFitWidth = true
        playerNameLabel.minimumScaleFactor = 0.5
        playerNameLabel.lineBreakMode = .byTruncatingTail
        playerNameLabel.text = Disp_Section[section].Name
        playerNameLabel.textColor = UIColor.white

        if isDispChange == true {
            if Disp_Section[section].Name == "" {
                holderNoLabel.layer.borderColor = UIColor.white.cgColor
                holderNoLabel.layer.borderWidth = 1.0
            }
        }
        
        if furigana == 1 && isDispChange == true{
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
        
        headerView.addSubview(seatNameLabel)
        headerView.addSubview(seatNameButton)
        headerView.addSubview(holderNoLabel)
        headerView.addSubview(playerNameLabel)
            
        return headerView
    }
    
    
    // セルの高さを返す（UITableViewDelegate）
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat{
//        let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as! orderMakeSureTableViewCell
        // セルの高さ
//        return cell.bounds.height
        return (tableViewMain.bounds.height / table_row[disp_row_height])
    }

    // Cell が選択された場合
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath:IndexPath) {
        
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        let Disp_data = self.Disp[indexPath.section][indexPath.row]

        if Disp_data.MenuType == 1 && Disp_data.Count != "" {
            var iCount:Int = Int(Disp_data.Count)!
            
            let id = Disp_data.id
            
            iCount += 1
//            print(iCount,MainMenu,Disp_data,MainMenu_Menu)
            
            let idx = MainMenu.index(where: {$0.id == id})
            
            if idx != nil {
                MainMenu[idx!].Count = "\(iCount)"
            }
            
            let idx1 = MainMenu_User.index(where: {$0.id == id})
            
            if idx1 != nil {
                MainMenu_User[idx1!].Count = "\(iCount)"
            }
            
            let idx2 = MainMenu_Menu.index(where: {$0.id == id})
            
            if idx2 != nil {
                MainMenu_Menu[idx2!].Count = "\(iCount)"
            }
            
            
/*
            // お客様順表示
            if isDispChange == true {
             

                for i in 0..<MainMenu_Menu.count {
                    if Disp_data.No == MainMenu_Menu[i].MenuNo && Disp_data.MenuNo == MainMenu_Menu[i].No {
                        MainMenu_Menu[i].Count = "\(iCount)"
                        let index = MainMenu.indexOf({($0.seat == MainMenu_Menu[i].seat) && $0.MenuNo == MainMenu_Menu[i].No })
//                        print(MainMenu[index!])
                        if index != nil {
                            MainMenu[index!].Count = "\(iCount)"
                        }
                        
                    }
                }
                for i in 0..<MainMenu_User.count {
                    if Disp_data.No == MainMenu_User[i].No && Disp_data.MenuNo == MainMenu_User[i].MenuNo {
                        MainMenu_User[i].Count = "\(iCount)"
                        
                        let index = MainMenu.indexOf({($0.seat == MainMenu_User[i].seat) && $0.MenuNo == MainMenu_User[i].MenuNo })
//                        print(MainMenu[index])
                        if index != nil {
                            MainMenu[index!].Count = "\(iCount)"
                        }
                        
                    }
                }
            } else {
                for i in 0..<MainMenu_Menu.count {
                    if Disp_data.No == MainMenu_Menu[i].No && Disp_data.MenuNo == MainMenu_Menu[i].MenuNo {
                        MainMenu_Menu[i].Count = "\(iCount)"
                        
                        let index = MainMenu.indexOf({($0.seat == MainMenu_Menu[i].seat) && $0.MenuNo == MainMenu_Menu[i].MenuNo })
//                        print(MainMenu[index])
                        if index != nil {
                            MainMenu[index!].Count = "\(iCount)"
                        }
                    }
                }
                for i in 0..<MainMenu_User.count {
                    if Disp_data.No == MainMenu_User[i].MenuNo && Disp_data.MenuNo == MainMenu_User[i].No {
                        MainMenu_User[i].Count = "\(iCount)"
                        
                        let index = MainMenu.indexOf({($0.seat == MainMenu_User[i].seat) && $0.MenuNo == MainMenu_User[i].No })
//                        print(MainMenu[index])
                        if index != nil {
                            MainMenu[index!].Count = "\(iCount)"
                        }
                    }
                }
            }
*/

            self.makeDispData()
            self.tableViewMain.reloadRows(at: [indexPath], with: .none)
        } else {
            if Disp_data.MenuType == 2 {      // セレクトメニュー
                globals_select_holder.seat = Disp_data.seat
                globals_select_holder.holder = Disp_data.No
                globals_select_menu_no.menu_no = Int64(Disp_data.MenuNo)!
                globals_select_selectmenu_no.branch_no = Disp_data.BranchNo
                selectedID =  Disp_data.id
                DecisionSubMenu = []
                for D in Disp[indexPath.section] {
                    if D.MenuType == 2 && D.id == selectedID{
                        DecisionSubMenu.append(DecisionSubMenuData(
                            MenuNo      : "\(globals_select_menu_no.menu_no)",
                            subMenuNo   : Int(D.MenuNo)!,
                            subMenuGroup: 0,
                            Name        : D.Name
                            )
                        )
                    }
                }
                
                let db = FMDatabase(path: _path)
                
                // メニューを取得する
                self.tableSection = []
                
                db.open()
                let sql = "select * from sub_menus_master where menu_no = ? ORDER BY cast(item_short_name as integer)"
                let results = db.executeQuery(sql, withArgumentsIn:[NSNumber(value: globals_select_menu_no.menu_no as Int64)])
                while (results?.next())! {
                    let subMenuNo = Int((results?.int(forColumn:"sub_menu_no"))!)
                    let subMenuKubun = Int((results?.int(forColumn:"sub_menu_group"))!)
                    let item = (results?.string(forColumn: "item_name") != nil) ? results?.string(forColumn: "item_name") :""
                    self.tableSection.append((subMenuNo,subMenuKubun,item!))
                    
//                    if subMenuNo <= 0 {
//                        self.tableSection.append((subMenuKubun,item))
//                    }
                    
                }
                db.close()

                let idx = DecisionSubMenu.index(where: {$0.Name == Disp_data.Name})
                if idx != nil {
                    globals_select_row = idx!
                }
                
                
                let index = tableSection.index(where: {$0.name == Disp_data.Name})
                if index != nil {
                    globals_select_selectmenu_no.select_menu_no = tableSection[index!].kubun
                    
                    let idx2 = tableSection.index(where: {$0.sub_menu_no == 0 && $0.kubun == globals_select_selectmenu_no.select_menu_no})
                    if idx2 != nil {
                        globals_select_selectmenu_no.select_menu_name = tableSection[idx2!].name
                    }
                    
                    
                    self.performSegue(withIdentifier: "toSelectMenuDetailViewSegue",sender: nil)
                }
                
//                self.performSegue(withIdentifier:"toSelectMenuViewSegue",sender: nil)
                
            }
        }
    }
    
    
    // セルの編集モード設定
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        switch self.Disp[indexPath.section][indexPath.row].MenuType {
        case 1:             // メインメニュー
            return false
        case 2:             // サブメニュー
            return false
        case 3:             // 特殊メニュー
            return true
        default:
            return false
        }

    }
    
    // スワイプして右にボタンを出す
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        // cellの色を設定
        var myDeleteButton: UITableViewRowAction?

        // Deleteボタン.
        myDeleteButton = UITableViewRowAction(style: .normal, title: "削除") { (action, index) -> Void in
            
            // タップ音
            TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

            tableView.isEditing = false
            print("delete")
            let Disp_sr = self.Disp[indexPath.section][indexPath.row]

            let specialMenuName = Disp_sr.Name
            
            // お客様順表示
            print("SpecialMenu",SpecialMenu)
            print("SpecialMenu_Menu",self.SpecialMenu_Menu)
            print("SpecialMenu_User",self.SpecialMenu_User)
            print("Disp_sr",Disp_sr)
            
            SpecialMenu = SpecialMenu.filter({!($0.id == Disp_sr.id && $0.Name == Disp_sr.Name)})
            
            self.SpecialMenu_Menu = self.SpecialMenu_Menu.filter({!($0.id == Disp_sr.id && $0.Name == Disp_sr.Name)})
            
            self.SpecialMenu_User = self.SpecialMenu_User.filter({!($0.id == Disp_sr.id && $0.Name == Disp_sr.Name)})
            
            selectSPmenus = []
            let db = FMDatabase(path: self._path)
            db.open()
            
            for sp in SpecialMenu {
                
                var spe_menu_code = -1
                let sql = "SELECT * from special_menus_master WHERE item_name = ?;"
                let rs = db.executeQuery(sql, withArgumentsIn: [sp.Name])
                while (rs?.next())! {
                    spe_menu_code = Int((rs?.int(forColumn:"item_no"))!)
                }
                
                selectSPmenus.append(selectSPmenu(
                    seat: sp.seat,
                    holderNo: sp.No,
                    menuNo: Int64(sp.MenuNo)!,
                    BranchNo: sp.BranchNo,
                    spMenuNo: spe_menu_code,
                    spMenuName: sp.Name,
                    category:sp.category
                    )
                )
            }
            db.close()
            
            
//            if self.isDispChange == true{
//                selectSPmenus = selectSPmenus.filter({!($0.menuNo == Int(Disp_sr.MenuNo) && $0.holderNo == Disp_sr.No && $0.spMenuName == Disp_sr.Name)})
//                selectSPmenus = selectSPmenus.filter({!($0.seat == Disp_sr.seat)})
//            }else{
//                selectSPmenus = selectSPmenus.filter({!($0.menuNo == Int(self.Section_User[indexPath.section].No) && $0.seat == Disp_sr.seat && $0.spMenuName == Disp_sr.Name)})
//            }
            
/*
            if self.isDispChange == true {
                // 選択されたオプションメニュー（特殊メニュー）を検索する
                
                SpecialMenu = SpecialMenu.filter({!($0.id == Disp_sr.id && $0.Name == Disp_sr.Name)})
                
                self.SpecialMenu_Menu = self.SpecialMenu_Menu.filter({!($0.id == Disp_sr.id && $0.Name == Disp_sr.Name)})

/*
                var index = SpecialMenu.filter({!($0.MenuNo == Disp_sr.MenuNo && $0.No == Disp_sr.No && $0.Name == Disp_sr.Name)})
                index = index.filter({!($0.seat == Disp_sr.seat)})
                
                print(index)
                
                
                SpecialMenu = []
                if index.count != 0 {
                    SpecialMenu = index
                }
                
                let index1 = self.SpecialMenu_Menu.filter({!($0.MenuNo == Disp_sr.MenuNo && $0.No == Disp_sr.No && $0.Name == Disp_sr.Name)})
                print(index1)
                self.SpecialMenu_Menu = []
                if index1.count != 0 {
                    self.SpecialMenu_Menu = index1
                }
*/

                
                
                let index2 = self.SpecialMenu_User.filter({!($0.MenuNo == Disp_sr.MenuNo && $0.No == Disp_sr.No && $0.Name == Disp_sr.Name)})
                print(index2)
                self.SpecialMenu_User = []
                if index2.count != 0 {
                    self.SpecialMenu_User = index2
                }
                
                selectSPmenus = selectSPmenus.filter({!($0.menuNo == Int(Disp_sr.MenuNo) && $0.holderNo == Disp_sr.No && $0.spMenuName == Disp_sr.Name)})
                selectSPmenus = selectSPmenus.filter({!($0.seat == Disp_sr.seat)})
                
                print("SpecialMenu_after",SpecialMenu)
                print("SpecialMenu_Menu_after",self.SpecialMenu_Menu)
                print("SpecialMenu_User_after",self.SpecialMenu_User)
                
            } else {
                
                SpecialMenu = SpecialMenu.filter({!($0.id == Disp_sr.id && $0.Name == Disp_sr.Name)})
                
                self.SpecialMenu_Menu = self.SpecialMenu_Menu.filter({!($0.id == Disp_sr.id && $0.Name == Disp_sr.Name)})
                
                self.SpecialMenu_User = self.SpecialMenu_User.filter({!($0.id == Disp_sr.id && $0.Name == Disp_sr.Name)})
/*
                for i in 0..<self.SpecialMenu_Menu.count {
                    if self.Disp[indexPath.section][indexPath.row].No == self.SpecialMenu_Menu[i].No && self.Disp[indexPath.section][indexPath.row].MenuNo == self.SpecialMenu_Menu[i].MenuNo && self.Disp[indexPath.section][indexPath.row].Name == self.MainMenu_Menu[i].Name {
                        
                        
                        self.SpecialMenu_Menu.removeAtIndex(i)
                        break;
                    }
                }
                for i in 0..<self.SpecialMenu_User.count {
                    if self.Disp[indexPath.section][indexPath.row].No == self.SpecialMenu_User[i].MenuNo && self.Disp[indexPath.section][indexPath.row].MenuNo == self.SpecialMenu_User[i].No && self.Disp[indexPath.section][indexPath.row].Name == self.SpecialMenu_User[i].Name {
                        
                        for j in 0..<SpecialMenu.count {
                            if self.Disp[indexPath.section][indexPath.row].No == SpecialMenu[j].MenuNo && self.Disp[indexPath.section][indexPath.row].MenuNo == SpecialMenu[j].No && self.Disp[indexPath.section][indexPath.row].Name == SpecialMenu[j].Name{
                                SpecialMenu.removeAtIndex(j)
                                break;
                            }
                        }

                        self.SpecialMenu_User.removeAtIndex(i)
                        break;
                    }
                }
 */
            }
 */
            // toast with a specific duration and position
            self.view.makeToast(specialMenuName + "を削除しました", duration: 1.0, position: .top)

            self.loadData()
            self.tableViewMain.reloadData()

        }
        myDeleteButton!.backgroundColor = UIColor.red
        return [myDeleteButton!]
    }
    
    // エディット機能の提供に必要なメソッド
    func tableView(_ tableView: UITableView,commit editingStyle: UITableViewCellEditingStyle,forRowAt indexPath: IndexPath) {
    }
    
    // メニュー順、お客様順の変更
    @IBAction func dispChange(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        if isDispChange == true {
            isDispChange = !isDispChange
//            dispChangeButton.title = "メニュー順"
            dispChangeButton.image = userImage
            
        } else {
            isDispChange = !isDispChange
//            dispChangeButton.title = "お客様順"
            dispChangeButton.image = orderImage

        }
        self.makeDispData()
        
        self.tableViewMain.reloadData()

    }
    
    
    // 各セルの支払者変更ボタンが押された時
    @IBAction func payChange(_ sender: AnyObject){
        // 精算者振り替え機能OFFの場合
        if is_payer_allocation != 1 {
            // toast with a specific duration and position
//            self.view.makeToast("精算者振り替え機能はOFFです", duration: 1.0, position: .top)
            // ファンクションから抜ける
            return;
        }
        
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        let btn = sender as! UIButton
        let point = self.tableViewMain.convert(sender.frame.origin, from: sender.superview)
        let indexPath = self.tableViewMain.indexPathForRow(at: point)
        print(indexPath?.section as Any,indexPath?.row as Any)
        
        let Disp_data = self.Disp[indexPath!.section][indexPath!.row]
        
        let sn = btn.titleLabel?.text
        
        if sn != "" && sn != nil{
            var sn2:String?
            for i in 0..<Section_Save.count{
                if Section_Save[i].seat == sn {
                    if i == Section_Save.count - 1 {
                        sn2 = Section_Save[0].seat
                        break;
                    } else {
                        sn2 = Section_Save[i+1].seat
                        break;
                    }
                }
            }
            
            var seat_no = 0
            let idx = seat.index(where: {$0.seat_name == sn2})
            if idx != nil {
                seat_no = seat[idx!].seat_no
            }
            
            let id = Disp_data.id
            
            let idx0 = MainMenu.index(where: {$0.id == id})
            
            if idx0 != nil {
                MainMenu[idx0!].payment_seat_no = seat_no
            }
            
            let idx1 = MainMenu_User.index(where: {$0.id == id})
            
            if idx1 != nil {
                MainMenu_User[idx1!].payment_seat_no = seat_no
            }
            
            let idx2 = MainMenu_Menu.index(where: {$0.id == id})
            
            if idx2 != nil {
                MainMenu_Menu[idx2!].payment_seat_no = seat_no
            }

/*
            // お客様順表示
            if isDispChange == true {
                for i in 0..<MainMenu_Menu.count {
                    if Disp_data.No == MainMenu_Menu[i].MenuNo && Disp_data.MenuNo == MainMenu_Menu[i].No {
                        MainMenu_Menu[i].seat = sn2!
                        print("sn2",i,sn2!)
                        let index = MainMenu.indexOf({$0.No == Disp_data.No && $0.MenuNo == Disp_data.MenuNo})
                        if index != nil {
                            print("main",index!)
                            MainMenu[index!].seat = sn2!
                            MainMenu_Menu[index!].seat = sn2!
                        }

                    }
                }
                for i in 0..<MainMenu_User.count {
                    if Disp_data.No == MainMenu_User[i].No && Disp_data.MenuNo == MainMenu_User[i].MenuNo {
                        MainMenu_User[i].seat = sn2!
                        let index = MainMenu.indexOf({$0.No == Disp_data.MenuNo && $0.MenuNo == Disp_data.No})
                        if index != nil {
                            MainMenu_User[index!].seat = sn2!
//                            MainMenu[index!].seat = sn2!
                        }
                    }
                }
            
            // メニュー順表示
            } else {
                for i in 0..<MainMenu_Menu.count {
                    if Disp_data.No == MainMenu_Menu[i].No && Disp_data.MenuNo == MainMenu_Menu[i].MenuNo {
                        MainMenu_Menu[i].seat = sn2!
                        let index = MainMenu.indexOf({$0.No == Disp_data.MenuNo && $0.MenuNo == Disp_data.No})
                        if index != nil {
                            MainMenu_Menu[index!].seat = sn2!
                            MainMenu[index!].seat = sn2!
                        }

                    }
                }
                for i in 0..<MainMenu_User.count {
                    if Disp_data.No == MainMenu_User[i].MenuNo && Disp_data.MenuNo == MainMenu_User[i].No {
                        MainMenu_User[i].seat = sn2!
                        let index = MainMenu.indexOf({$0.MenuNo == Disp_data.MenuNo && $0.No == Disp_data.No})
                        if index != nil {
                            MainMenu_User[index!].seat = sn2!
                        }

                    }
                }
            }
*/
            self.makeDispData()
            print(indexPath as Any)
//            self.tableViewMain.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: .None)
            
            self.tableViewMain.reloadRows(at: [indexPath!], with: .automatic)
        }
        
    }

    // セクションの支払者変更ボタンが押された時
    @IBAction func payChangeHeader(_ sender: AnyObject){
        // 精算者振り分け機能OFFの場合
        if is_payer_allocation != 1 {
            // toast with a specific duration and position
//            self.view.makeToast("精算者振り替え機能はOFFです", duration: 1.0, position: .top)
            // ファンクションから抜ける
            return;
        }

        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        let btn = sender as! UIButton
        let sn = btn.titleLabel?.text
        
        if sn != "" && sn != nil{
            var sn2:String?
            
            // お客様順表示
            if isDispChange == true {
                for i in 0..<Section_Save.count{
                    if Section_Save[i].seat == sn {
                        if i == Section_Save.count - 1 {
                            sn2 = Section_Save[0].seat
                            break;
                        } else {
                            sn2 = Section_Save[i+1].seat
                            break;
                        }
                    }
                }
                
                Section[btn.tag - 1].seat = sn2!
//                Section_User[btn.tag - 1].seat = sn2!
                var seat_no = 0
                let idx = seat.index(where: {$0.seat_name == sn2})
                if idx != nil {
                    seat_no = seat[idx!].seat_no
                }
                
                for i in 0..<MainMenu.count {
                    if MainMenu[i].seat != "" && MainMenu[i].seat == Section_Save[btn.tag - 1].seat {
                        MainMenu[i].payment_seat_no = seat_no
                        print(MainMenu[i])
                    }
                }
                for i in 0..<MainMenu_User.count {
                    if self.MainMenu_User[i].seat != "" && self.MainMenu_User[i].seat == Section_Save[btn.tag - 1].seat {
                        MainMenu_User[i].payment_seat_no = seat_no
                    }
                }
                for i in 0..<MainMenu_Menu.count {
                    if self.MainMenu_Menu[i].seat != "" && self.MainMenu_Menu[i].seat == Section_Save[btn.tag - 1].seat {
                        MainMenu_Menu[i].payment_seat_no = seat_no
                    }
                }
                
                
/*
                for i in 0..<MainMenu_Menu.count {
                    if self.MainMenu_Menu[i].seat != "" && self.MainMenu_Menu[i].MenuNo == Section[btn.tag - 1].No {
                        MainMenu_Menu[i].seat = sn2!
                    }
                }
                
                for i in 0..<MainMenu_User.count {
                    if self.MainMenu_User[i].seat != "" && self.MainMenu_User[i].No == Section[btn.tag - 1].No {
                        MainMenu_User[i].seat = sn2!
                    }
                }
                
                for i in 0..<MainMenu.count {
                    if MainMenu[i].seat != "" && MainMenu[i].No == Section[btn.tag - 1].No {
                        MainMenu[i].seat = sn2!
                    }
                }
*/
                
            } else {        // メニュー順表示
                let pay_seat_no = section_menu_seat[btn.tag - 1]
                for (i,section) in Section_Save.enumerated() {
                    if section.seat == pay_seat_no {
                        if i == Section_Save.count - 1 {
                            sn2 = Section_Save[0].seat
//                            break;
                        } else {
                            sn2 = Section_Save[i+1].seat
//                            break;
                        }
                        section_menu_seat[btn.tag - 1] = sn2!
                    }
                }
                
                var seat_no = 0
                let idx = seat.index(where: {$0.seat_name == sn2})
                if idx != nil {
                    seat_no = seat[idx!].seat_no
                }
                
                for i in 0..<MainMenu_Menu.count {
                    if self.MainMenu_Menu[i].seat != "" && self.MainMenu_Menu[i].No == Section_Menu[btn.tag - 1].No {
                        MainMenu_Menu[i].payment_seat_no = seat_no
                    }
                }
                
                for i in 0..<MainMenu_User.count {
                    if self.MainMenu_User[i].seat != "" && self.MainMenu_User[i].MenuNo == Section_Menu[btn.tag - 1].No {
                        MainMenu_User[i].payment_seat_no = seat_no
                    }
                }
                
                for i in 0..<MainMenu.count {
                    if MainMenu[i].seat != "" && MainMenu[i].MenuNo == Section_Menu[btn.tag - 1].No {
                        MainMenu[i].payment_seat_no = seat_no
                    }
                }

                
//                for i in 0..<MainMenu_Menu.count {
//                    if self.MainMenu_Menu[i].seat != "" && self.MainMenu_Menu[i].No == Section_Menu[btn.tag - 1].No {
//                        MainMenu_Menu[i].seat = sn2!
//                    }
//                }
//                
//                for i in 0..<MainMenu_User.count {
//                    if self.MainMenu_User[i].seat != "" && self.MainMenu_User[i].MenuNo == Section_Menu[btn.tag - 1].No {
//                        MainMenu_User[i].seat = sn2!
//                    }
//                }
//                
//                for i in 0..<MainMenu.count {
//                    if MainMenu[i].seat != "" && MainMenu[i].MenuNo == Section_Menu[btn.tag - 1].No {
//                        MainMenu[i].seat = sn2!
//                    }
//                }
            }
            
            self.makeDispData()
            
            self.tableViewMain.reloadSections(IndexSet(integer: btn.tag-1), with: .none)
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    // 全振替ボタンがタップされた時
    @IBAction func allChangeButtonTap(_ sender: AnyObject) {
        // 精算者振り替え機能OFFの場合
        if is_payer_allocation != 1 {
            // toast with a specific duration and position
            self.view.makeToast("精算者振り替え機能はOFFです", duration: 1.0, position: .top)
            // ファンクションから抜ける
            return;
        }
        
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        let vc = UIViewController(nibName: "selectPayViewController", bundle: nil)
        
        var line = Int((Section.count - 1) / 4) + 1
        if (Section.count - 1) - (Int((Section.count-1)/4)*4) > 2 {
            line += 1
        }
        
        vc.preferredContentSize = CGSize(width: self.view.bounds.width - 20, height: (iconSizeH + topMargin + betweenMargin) * CGFloat(line))
        
        vc.modalPresentationStyle = .popover
        
        var posX:CGFloat?
        var posY:CGFloat?
        
        for num in 0..<Section_Save.count {
            // ボタンを作る
            let button = UIButton()
            // 表示されるテキスト
            button.setTitle(Section_Save[num].seat, for: UIControlState())
            // テキストの色
            button.setTitleColor(UIColor.white, for: UIControlState())
            // サイズ
            button.frame = CGRect(x: 0, y: 0,width: iconSizeW, height: iconSizeH)
            // tag番号
            button.tag = num + 1
            // 配置場所
            posX = (button.frame.width + 8) * CGFloat(num - (Int(num/4)*4)) + (button.frame.width / 2 + 10)
            posY = topMargin + (button.frame.height / 2) + ((button.frame.height + betweenMargin + betweenMargin) * CGFloat(Int(num / 4)))
            button.layer.position = CGPoint(x: posX! , y: posY!)

            // 背景色
            button.backgroundColor = UIColor(red: 0.7, green: 0.2, blue: 0.2, alpha: 1.0)
            // 角丸
            button.layer.cornerRadius = button.frame.height / 2
            // ボーダー幅
            //            button.layer.borderWidth = 1
            // タップした時に実行するメソッドを指定
            button.addTarget(self, action: #selector(orderMakeSureViewController.tapSeatAll(_:)), for: .touchUpInside)
            
            // viewにボタンを追加する
            vc.view.addSubview(button)
        }
        
        // ボタンを作る
        let buttonR = UIButton()
        // 表示されるテキスト
        buttonR.setTitle("もとに戻す", for: UIControlState())
        // テキストの色
        buttonR.setTitleColor(UIColor.white, for: UIControlState())
        // サイズ
        buttonR.frame = CGRect(x: 0, y: 0, width: 100, height: iconSizeW)
        // tag番号
        buttonR.tag = Section.count + 1
        // 配置場所
        
        var posX2:CGFloat?
        posX2 = posX! + (iconSizeW/2) + (buttonR.frame.width / 2 + 10)
        
        let sec = (Section.count - 1) - (Int((Section.count-1)/4)*4)
        if sec > 2 {
            posY = topMargin + (iconSizeH / 2) + ((iconSizeH + betweenMargin + betweenMargin) * CGFloat(line-1))
            posX2 = (buttonR.frame.width / 2 + 10)
        }

        let posY2 = posY
        buttonR.layer.position = CGPoint(x: posX2! , y: posY2!)
        // 背景色
        buttonR.backgroundColor = UIColor(red: 0.7, green: 0.2, blue: 0.2, alpha: 1.0)
        // 角丸
        buttonR.layer.cornerRadius = buttonR.frame.height / 2
        // ボーダー幅
        //            button.layer.borderWidth = 1
        // タップした時に実行するメソッドを指定
        buttonR.addTarget(self, action: #selector(orderMakeSureViewController.tapSeatAll(_:)), for: .touchUpInside)
        
        // viewにボタンを追加する
        vc.view.addSubview(buttonR)
        
        if let presentationController = vc.popoverPresentationController {
            presentationController.permittedArrowDirections = .up
            presentationController.sourceView = sender as? UIView
            presentationController.sourceRect = sender.bounds
            presentationController.backgroundColor = UIColor.clear
            presentationController.delegate = self
            
        }
        
        present(vc, animated: true, completion: nil);

    
    }
    
    // 午後スタート時刻入力ボタンタップ時
    @IBAction func pmStartTimeSet(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        
        timeTextField.isHidden = false
        
        isKeyboardType = false
        timeTextField.keyboardType = .numberPad
        
        if (timeTextField.inputView != nil) {
            isKeyboardType = !isKeyboardType
        }
        
        timeTextField.isEnabled = true
        timeTextField.becomeFirstResponder()
        
    }
    
    func updateDatePickerLabel(){
//        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateFormat = "HH:mm"
        
        let datestr = dateFormatter.string(from: self.dp.date)
        timeTextField.text = datestr
        globals_pm_start_time = timeTextField.text!
        print(datestr);//Oct 23, 2014, 7:58 PMな風に出力されます。
    }
    
    // 「完了」を押すと閉じる
    func tappedToolBarBtn(_ sender: UIBarButtonItem) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        // キーボードがdatepickerの場合
        if isKeyboardType {
            timeTextField.resignFirstResponder()
            timeTextField.isEnabled = false
            if timeTextField.text == "__:__" {
                timeTextField.isHidden = true
                return;
            }
            
        } else {
            var err = false
            let timeString = timeTextField.text
            
            if timeString == "__:__" {
                timeTextField.isHidden = true
                timeTextField.resignFirstResponder()
                timeTextField.isEnabled = false
                return;
            }
            
            let time = Int(timeString!.substringWithRange(0, end: 2))
            if time == nil || !(time >= 0 && time < 24) {
                err = true
            }
            
//            print(time)
            let min = Int(timeString!.substringWithRange(3, end: 5))
            if min == nil || !(min >= 0 && min < 60) {
                err = true
            }
//            print(min)
            if err == true {
                // エラー表示
                let alertController = UIAlertController(title: "エラー！", message: "時刻の指定が不正です。", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "閉じる", style: .cancel){
                    action in print("Pushed OK")
                }
                alertController.addAction(cancelAction)
                present(alertController, animated: true, completion: nil)

            } else {
                timeTextField.resignFirstResponder()
                timeTextField.isEnabled = false
                globals_pm_start_time = timeTextField.text!
            }
        }
    }
    
    // 時刻入力でクリアボタンタップされた時
    func tappedToolBarClearBtn(_ sender: UIBarButtonItem){
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        timeTextField.text = "__:__"
        globals_pm_start_time = ""
        replacedIndex = 0
        deleteIndex = maxLength
    }
    
    // 時刻入力で切り替えボタンタップされた時
    func tappedToolBarChangedBtn(_ sender: UIBarButtonItem){
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        if isKeyboardType {
            timeTextField.inputView = nil
            timeTextField.keyboardType = .numberPad
        } else {
            timeTextField.inputView = nil
            self.dp.datePickerMode = UIDatePickerMode.time;
            self.dp.addTarget(self, action: #selector(orderMakeSureViewController.updateDatePickerLabel), for: .valueChanged);
            timeTextField.inputView = self.dp
            timeTextField.isEnabled = true
            
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            
            let date = formatter.date(from: timeTextField.text!)
            print(date as Any)
            
            if date != nil {
                dp.date = date!
            } else {
                timeTextField.text! = "__:__"
                // 1時間後の時刻
                dp.date = Date(timeIntervalSinceNow: 1 * 60 * 60)
            }
            timeTextField.becomeFirstResponder()
        }
        timeTextField.reloadInputViews()
        isKeyboardType = !isKeyboardType
    }
    
    @IBAction func backButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        let main_filter = MainMenu.filter({$0.Count == "0"})
        for m_fil in main_filter {
            let m_id = m_fil.id
            
            MainMenu = MainMenu.filter({$0.id != m_id})
            SubMenu = SubMenu.filter({$0.id != m_id})
            SpecialMenu = SpecialMenu.filter({$0.id != m_id})
            
            let db = FMDatabase(path: self._path)
            // データベースをオープン
            db.open()

            let sql_del = "DELETE FROM hand_image WHERE seat = ? AND holder_no = ? AND order_no = ? AND branch_no = ?;"
            var argumentArray:Array<Any> = []
            
            argumentArray.append(m_fil.seat)
            argumentArray.append(m_fil.No)
            argumentArray.append(Int(m_fil.MenuNo)!)
            argumentArray.append(m_fil.BranchNo)

            let _ = db.executeUpdate(sql_del, withArgumentsIn: argumentArray)
            
            db.close()
            
        }
        

        self.performSegue(withIdentifier: "toMenuSelectSegue",sender: nil)
    }
    
    
    // 送信ボタンタップ時
    @IBAction func dataSend(_ sender: AnyObject) {
        
        // オーダー数が全て0の場合は送信しない
        let zero_order = MainMenu.filter({!($0.Count == "0")})
        if zero_order.count <= 0 {
            // toast with a specific duration and position
            self.view.makeToast("全員の注文数が0件です。", duration: 1.0, position: .top)
            return
        }
        
        // チェックアウト済みの人が支払い者になっていないかチェックする
        for sect in Section {
            let status = fmdb.getPlayerStatus(sect.No)
            switch status {
            case 0,1:       // チェックイン
                break;
            case 2:         // チェックアウト
                let idx = MainMenu.index(where: {$0.payment_seat_no == sect.seat_no})
                if idx != nil {
                    let message = "はチェックアウト済みです。"
                    let alertController = UIAlertController(title: "エラー！", message: "ホルダ番号「" + sect.No + "」" + message + "\n" + "支払い者を変更して下さい。" , preferredStyle: .alert)
                    
                    let okAction = UIAlertAction(title: "はい", style: .default){
                        action in print("Pushed OK")
                        // タップ音
                        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                        return;
                    }
                    alertController.addAction(okAction)
                    present(alertController, animated: true, completion: nil)
                    return;
                }
                
                break;
            case 3:         // キャンセル
                break;
            case 9:         // 予約
                break;
            default:
                break;
            }

        }
        
        
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        // 確認のアラート画面を出す
        // タイトル
        let alert: UIAlertController = UIAlertController(title: "確認", message: "送信します。よろしいですか？", preferredStyle: UIAlertControllerStyle.alert)
        // アクションの設定
        let defaultAction: UIAlertAction = UIAlertAction(title: "送信", style: UIAlertActionStyle.default, handler: {(action: UIAlertAction!) -> Void in
            print("OK")
            
            
            // タップ音
            TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

            // 本番モード
            if demo_mode == 0 {
                print("nain",MainMenu)
                print("Section_save",self.Section_Save)
                print("Section",Section)
                
                self.spinnerStart()
                
                
                // まずはデータ送信
                var params:[[String:Any]] = [[:]]
                
                let now = Date() // 現在日時の取得
                self.dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
                self.dateFormatter.timeStyle = .medium
                self.dateFormatter.dateStyle = .short
                
                self.sendTime = self.dateFormatter.string(from: now)
                
                params[0]["Process_Div"] = "1"
                
                var cnt = 0
                
                let db = FMDatabase(path: self._path)
                // データベースをオープン
                db.open()
                let sql2 = "SELECT * FROM staffs_now;"
//                let sql6 = "SELECT COUNT(*) FROM iOrder WHERE facility_cd = 1 AND store_cd = " + shop_code.description + " AND order_no > ?"
//
//                self.dateFormatter.locale = Locale.current
//                self.dateFormatter.dateFormat = "MMddyy"
//
//                // 2016/11/1 の場合 1101160000 にする
//                let datestr = self.dateFormatter.string(from: now)
//
//                let dateInt = Int(datestr)! * 10000
                var staff = ""

                // 担当者名を取得
                let rs2 = db.executeQuery(sql2, withArgumentsIn: [])
                while (rs2?.next())! {
                    staff = (rs2?.string(forColumn:"staff_no"))!
                }

                // 内部で保持しているオーダーNOの最大値取得
                self.max_oeder_no = fmdb.get_max_order_no()
                
                
//                let rs6 = db.executeQuery(sql6, withArgumentsIn: [dateInt])
//                while (rs6?.next())! {
//                    self.max_oeder_no = dateInt + Int((rs6?.int(forColumnIndex: 0))!) + 1
//                    print(self.max_oeder_no as Any)
//                }

                var pm_st = globals_pm_start_time
                
                if globals_pm_start_time == "" {
                    let sql_pm_start_time = "SELECT pm_start_time FROM players WHERE shop_code IN (0,?) AND member_no = ? AND created LIKE ?;"
                    var is_pm = false
                    for sec in self.Section_Save {
                        var argumentArray:Array<Any> = []
                        argumentArray.append(shop_code)
                        argumentArray.append(sec.No)
                        argumentArray.append(globals_today + "%")
                        let results = db.executeQuery(sql_pm_start_time, withArgumentsIn: argumentArray)
                        
                        while (results?.next())! {
                            if results?.string(forColumnIndex: 0) != "" { is_pm = true }
                        }
                    }
                    
                    if is_pm { pm_st = "99:99" }
                }
                
                var detail_kbn = ""
                // 新規・追加
                switch globals_is_new {
                case 1:
                    detail_kbn = "1"
                case 2:
                    detail_kbn = "2"
                case 9:
                    if globals_is_new_wait == 1 {
                        detail_kbn = "1"
                    } else {
                        detail_kbn = "2"
                    }
                default:
                    detail_kbn = "2"
                    break;
                }

                
                for (i,sec) in self.Section_Save.enumerated() {
//                for i in 0..<self.Section_Save.count {
                    // プライス区分取得
                    var price_kbn = "1" // 存在しないプレイヤーの時
                    
//                    let results = db.executeQuery(sql, withArgumentsIn: [Int(sec.No)!])
                    

                    let results = db.executeQuery(SELECT_PLAYERS, withArgumentsIn: [Int(sec.No)!,shop_code,globals_today + "%"])
                    while results!.next() {
                        
                        price_kbn = (results!.int(forColumn: "price_tanka")) <= 0 ? "1" :  "\(results!.int(forColumn: "price_tanka"))"
                    }
                    
                    // 注文数が０のオーダーは送らない
//                    let index = MainMenu.indexOf({$0.Count <= 0 && $0.})
                    
                    
                    let mm = MainMenu.filter({$0.No == sec.No})
                    // メニューNOが0の場合か、注文をしていない人の場合は空データを送信する。
                    if (mm.count == 1 && mm[0].MenuNo == "0") || mm.count <= 0 || (mm.count == 1 && mm[0].Count == "0"){
                        cnt += 1

//                        let detail_kbn = globals_is_new == 2 ? "2" : "1"
//                        let detail_kbn = globals_is_new == 1 ? "1" : "2"
                        
                        params.append([String:Any]())
                        params[cnt]["Store_CD"] = shop_code.description
                        params[cnt]["Table_NO"] = "\(globals_table_no)"
                        params[cnt]["Detail_KBN"] = detail_kbn
                        params[cnt]["Order_KBN"] = "1"
                        params[cnt]["Seat_NO"] = "\(sec.seat_no + 1)"
                        params[cnt]["Menu_CD"] = ""
                        params[cnt]["Menu_SEQ"] = ""
                        params[cnt]["Store_Menu_CD"] = "1"
                        params[cnt]["Sub_Menu_KBN"] = ""
                        params[cnt]["Sub_Menu_CD"] = ""
                        params[cnt]["Spe_Menu_KBN"] = ""
                        params[cnt]["Spe_Menu_CD"] = ""
                        params[cnt]["Category_CD1"] = ""
                        params[cnt]["Category_CD2"] = ""
                        params[cnt]["Timezone_KBN"] = "\(globals_timezone)"
                        params[cnt]["Qty"] = ""
                        params[cnt]["Serve_Customer_NO"] = sec.No
                        params[cnt]["Payment_Customer_NO"] = ""
                        params[cnt]["Employee_CD"] = staff
                        params[cnt]["Unit_Price_KBN"] = price_kbn
                        params[cnt]["Pm_Start_Time"] = pm_st
                        params[cnt]["Handwriting"] = ""
                        params[cnt]["SendTime"] = self.sendTime         // 送信日時（yyyy/mm/dd HH:mm:ss）（拡張用）
                        params[cnt]["Selling_Price"] = ""               // 金額（拡張用）
                        params[cnt]["TerminalID"] = TerminalID          // 端末ID（拡張用）
                        params[cnt]["Reference"] = ""
                        params[cnt]["Payment_Customer_Seat_No"] = ""    // 支払者のシートNO
                        params[cnt]["Slip_NO"] = ""                     // 伝票NO

                    } else {
                        MainMenu = MainMenu.filter({!($0.No == sec.No && $0.MenuNo == "0")})
                        MainMenu.sort(by: {$0.id < $1.id})   // id順にソート
                        
                        var pay_No = ""
                        var detail_id = 0
                        var main_slip = 0
                        // メインメニュー
                        
                        for (_,md) in MainMenu.enumerated() {
                            if sec.No == md.No && self.Section_Save[i].seat == md.seat && Int(md.Count) != 0 {
                                cnt += 1
                                
                                //                        let detail_kbn = globals_is_new == 2 ? "2" : "1"
//                                let detail_kbn = globals_is_new == 1 ? "1" : "2"
                                
                                params.append([String:Any]())
                                params[cnt]["Store_CD"] = shop_code.description
                                params[cnt]["Table_NO"] = "\(globals_table_no)"
                                params[cnt]["Detail_KBN"] = detail_kbn
                                params[cnt]["Order_KBN"] = "1"
                                params[cnt]["Seat_NO"] = "\(sec.seat_no + 1)"
                                params[cnt]["Menu_CD"] = md.MenuNo
                                params[cnt]["Menu_SEQ"] = (md.BranchNo).description
                                params[cnt]["Store_Menu_CD"] = "1"
                                params[cnt]["Sub_Menu_KBN"] = ""
                                params[cnt]["Sub_Menu_CD"] = ""
                                params[cnt]["Spe_Menu_KBN"] = ""
                                params[cnt]["Spe_Menu_CD"] = ""
                                
                                // カテゴリ番号取得
                                var cc1 = ""
                                var cc2 = ""
//                                let rs1 = db.executeQuery(sql1, withArgumentsIn: [NSNumber(longLong: Int64(md.MenuNo)!)])
//                                while rs1.next() {
//                                    cc1 = "\(rs1.int(forColumn:"category_no1"))"
//                                    cc2 = "\(rs1.int(forColumn:"category_no2"))"
//                                }
                                
                                let idx_cate = select_menu_categories.index(where: {$0.id == md.id})
                                if idx_cate != nil {
                                    cc1 = (select_menu_categories[idx_cate!].category1).description
                                    cc2 = (select_menu_categories[idx_cate!].category2).description
                                }
                                
                                params[cnt]["Category_CD1"] = cc1
                                params[cnt]["Category_CD2"] = cc2
                                params[cnt]["Timezone_KBN"] = "\(globals_timezone)"
                                params[cnt]["Qty"] = md.Count
                                params[cnt]["Serve_Customer_NO"] = sec.No
                                
                                // 支払い者のホルダ番号取得
                                var seat_nm = ""
                                let idx = seat.index(where: {$0.seat_no == md.payment_seat_no})
                                if idx != nil {
                                    seat_nm = seat[idx!].seat_name
                                }
                                
                                let index = self.Section_Save.index(where: {$0.seat == seat_nm})
                                if index != nil {
                                    pay_No = self.Section_Save[index!].No
                                }
                                
                                
                                params[cnt]["Payment_Customer_NO"] = pay_No
                                
                                params[cnt]["Employee_CD"] = staff
                                params[cnt]["Unit_Price_KBN"] = price_kbn
                                params[cnt]["Pm_Start_Time"] = pm_st
                                
                                // 手書き情報取得
                                var pngData:Data?
                                var image_string = ""
                                
                                pngData = fmdb.get_PngData(self.Section_Save[i].seat,holder_no: sec.No, menu_no: md.MenuNo,branch_no: md.BranchNo)
                                image_string = pngData!.base64EncodedString(options: .lineLength64Characters)
                                
                                let urlencodeString = image_string.replacingOccurrences(of: "+", with: "%2B")
                                params[cnt]["Handwriting"] = urlencodeString
                                params[cnt]["SendTime"] = self.sendTime     // 送信日時（yyyy/mm/dd HH:mm:ss）（拡張用）
                                params[cnt]["Selling_Price"] = ""           // 金額（拡張用）
                                params[cnt]["TerminalID"] = TerminalID      // 端末ID（拡張用）
                                params[cnt]["Reference"] = md.Name
                                params[cnt]["Payment_Customer_Seat_No"] = (md.payment_seat_no + 1).description    // 支払者のシートNO
                                params[cnt]["Slip_NO"] = ""                 // 伝票NO

                                detail_id += 1
                                main_slip += 1
                            }
                        }
                        
                        
                        // セレクトメニュー（サブメニュー）
                        for sd in SubMenu {
                            if sd.No == sec.No && sd.seat == self.Section_Save[i].seat{
                                
                                let index = MainMenu.index(where: {$0.id == sd.id})
                                var pay_seat_no = ""
                                var qty = ""
                                if index != nil {
                                    qty = MainMenu[index!].Count
                                    pay_seat_no = (MainMenu[index!].payment_seat_no + 1).description
                                }
                                
                                if qty != "" || qty != "0" {    // メインメニューの数量が０の場合は送信しない
                                    cnt += 1
                                    
                                    //                        let detail_kbn = globals_is_new == 2 ? "2" : "1"
//                                    let detail_kbn = globals_is_new == 1 ? "1" : "2"
                                    
                                    params.append([String:Any]())
                                    params[cnt]["Store_CD"] = shop_code.description
                                    params[cnt]["Table_NO"] = "\(globals_table_no)"
                                    params[cnt]["Detail_KBN"] = detail_kbn
                                    params[cnt]["Order_KBN"] = "2"
                                    params[cnt]["Seat_NO"] = "\(sec.seat_no + 1)"
                                    params[cnt]["Menu_CD"] = sd.MenuNo
                                    params[cnt]["Menu_SEQ"] = (sd.BranchNo).description
                                    params[cnt]["Store_Menu_CD"] = "1"
                                    
                                    // メニュー区分、サブメニューコード取得
                                    var menu_kbn = ""
                                    var sub_menu_code = ""
                                    var sub_menu_name = ""
                                    let sql = "SELECT * from sub_menus_master WHERE menu_no = ? AND item_name = ?;"
                                    let rs = db.executeQuery(sql, withArgumentsIn: [sd.MenuNo,sd.Name])
                                    while (rs?.next())! {
                                        menu_kbn = ((rs?.int(forColumn:"sub_menu_group"))?.description)!
                                        sub_menu_code = ((rs?.int(forColumn:"sub_menu_no"))?.description)!
                                        sub_menu_name = (rs?.string(forColumn: "item_name"))!
                                    }
                                    
                                    // 支払い者のホルダ番号取得
                                    var seat_nm = ""
                                    let idx = seat.index(where: {$0.seat_no == (Int(pay_seat_no)!-1)})
                                    if idx != nil {
                                        seat_nm = seat[idx!].seat_name
                                    }
                                    
                                    let index = self.Section_Save.index(where: {$0.seat == seat_nm})
                                    if index != nil {
                                        pay_No = self.Section_Save[index!].No
                                    }
                                    
                                    
                                    params[cnt]["Sub_Menu_KBN"]         = menu_kbn
                                    params[cnt]["Sub_Menu_CD"]          = sub_menu_code
                                    params[cnt]["Spe_Menu_KBN"]         = ""
                                    params[cnt]["Spe_Menu_CD"]          = ""
                                    params[cnt]["Category_CD1"]         = ""
                                    params[cnt]["Category_CD2"]         = ""
                                    params[cnt]["Timezone_KBN"]         = "\(globals_timezone)"
                                    params[cnt]["Qty"]                  = qty
                                    params[cnt]["Serve_Customer_NO"]    = sec.No
                                    params[cnt]["Payment_Customer_NO"]  = pay_No
                                    params[cnt]["Employee_CD"]          = staff
                                    params[cnt]["Unit_Price_KBN"]       = price_kbn
                                    params[cnt]["Pm_Start_Time"]        = pm_st
                                    params[cnt]["Handwriting"]          = ""
                                    params[cnt]["SendTime"]             = self.sendTime        // 送信日時（yyyy/mm/dd HH:mm:ss）（拡張用）
                                    params[cnt]["Selling_Price"]        = ""        // 金額（拡張用）
                                    params[cnt]["TerminalID"]           = TerminalID        // 端末ID（拡張用）
                                    params[cnt]["Reference"]            = sub_menu_name // メニュー名
                                    params[cnt]["Payment_Customer_Seat_No"] = pay_seat_no    // 支払者のシートNO
                                    params[cnt]["Slip_NO"] = ""             // 伝票NO
                                    
                                    detail_id += 1
                                    main_slip += 1
                                    
                                }
                            }
                            
                        }
                        
                        // オプションメニュー（特殊メニュー）
                        for spd in SpecialMenu {
                            if spd.No == sec.No && spd.seat == sec.seat{
                                
                                let index = MainMenu.index(where: {$0.id == spd.id})
                                var qty = ""
                                var pay_seat_no = ""
                                if index != nil {
                                    qty = MainMenu[index!].Count
                                    pay_seat_no = (MainMenu[index!].payment_seat_no + 1).description
                                }
                                
                                if qty != "" || qty != "0" {    // メインメニューの数量が０の場合は送信しない
                                    cnt += 1
                                    
                                    //                        let detail_kbn = globals_is_new == 2 ? "2" : "1"
//                                    let detail_kbn = globals_is_new == 1 ? "1" : "2"
                                    
                                    params.append([String:Any]())
                                    params[cnt]["Store_CD"] = shop_code.description
                                    params[cnt]["Table_NO"] = "\(globals_table_no)"
                                    params[cnt]["Detail_KBN"] = detail_kbn
                                    params[cnt]["Order_KBN"] = "3"
                                    params[cnt]["Seat_NO"] = "\(sec.seat_no + 1)"
                                    params[cnt]["Menu_CD"] = spd.MenuNo
                                    params[cnt]["Menu_SEQ"] = (spd.BranchNo).description
                                    params[cnt]["Store_Menu_CD"] = "1"
                                    
                                    // 特殊メニュー区分、特殊メニューコード取得
                                    var spe_menu_code = ""
                                    let sql = "SELECT * from special_menus_master WHERE item_name = ?;"
                                    let rs = db.executeQuery(sql, withArgumentsIn: [spd.Name])
                                    while (rs?.next())! {
                                        spe_menu_code = ((rs?.int(forColumn:"item_no"))?.description)!
                                    }
                                    
                                    // 支払い者のホルダ番号取得
                                    var seat_nm = ""
                                    let idx = seat.index(where: {$0.seat_no == (Int(pay_seat_no)!-1)})
                                    if idx != nil {
                                        seat_nm = seat[idx!].seat_name
                                    }
                                    
                                    let index = self.Section_Save.index(where: {$0.seat == seat_nm})
                                    if index != nil {
                                        pay_No = self.Section_Save[index!].No
                                    }
                                    
                                    params[cnt]["Sub_Menu_KBN"] = ""
                                    params[cnt]["Sub_Menu_CD"] = ""
                                    //                                params[cnt]["Spe_Menu_KBN"] = spe_menu_kbn
                                    //                                params[cnt]["Spe_Menu_CD"] = spe_menu_code
                                    params[cnt]["Spe_Menu_KBN"] = spd.category
                                    params[cnt]["Spe_Menu_CD"] = spe_menu_code
                                    params[cnt]["Category_CD1"] = ""
                                    params[cnt]["Category_CD2"] = ""
                                    params[cnt]["Timezone_KBN"] = "\(globals_timezone)"
                                    params[cnt]["Qty"] = qty
                                    params[cnt]["Serve_Customer_NO"] = sec.No
                                    params[cnt]["Payment_Customer_NO"] = pay_No
                                    params[cnt]["Employee_CD"] = staff
                                    params[cnt]["Unit_Price_KBN"] = price_kbn
                                    params[cnt]["Pm_Start_Time"] = pm_st
                                    params[cnt]["Handwriting"] = ""
                                    params[cnt]["SendTime"] = self.sendTime       // 送信日時（yyyy/mm/dd HH:mm:ss）（拡張用）
                                    params[cnt]["Selling_Price"] = ""       // 金額（拡張用）
                                    params[cnt]["TerminalID"] = TerminalID          // 端末ID（拡張用）
                                    params[cnt]["Reference"] = spd.Name     // メニュー名
                                    params[cnt]["Payment_Customer_Seat_No"] = pay_seat_no    // 支払者のシートNO
                                    params[cnt]["Slip_NO"] = ""             // 伝票NO
                                    
                                    detail_id += 1
                                    main_slip += 1
                                
                                }
                            }
                        }
                        
                    }
                    
                    
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
                
                let task = session.dataTask(with: request, completionHandler: {
                    (data, response, error) -> Void in
                    
                    do {

                        if error == nil {
                            let json2 = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.allowFragments ) as! NSDictionary
                            print(json2)
                            
                            let json_return = JSON(json2)
                            if json_return.asError == nil {
                                var return_value = ""
                                var return_msg = "not"
                                
                                for (key, value) in json_return {
                                    if key as! String == "Return" {
                                        return_value = value.toString()
                                        if value.toString() == "true" {
                                            // すべての情報をクリアする
                                            common.clear()
                                            selectSPmenus = []
                                            
                                            // 手書きイメージのテーブルの中身を削除
                                            let db = FMDatabase(path: self._path)
                                            db.open()
                                            
                                            fmdb.remove_hand_image()
                                            db.close()

                                            if order_timer.isValid == true {
                                                
                                                //timerを破棄する.
                                                order_timer.invalidate()
                                                
                                            }
                                            fmdb.db_save(self.sendTime,detail_kbn: globals_is_new)
                                            self.performSegue(withIdentifier: "toMainMenuViewController",sender: nil);
                                            
                                            self.spinnerEnd()
                                            return;
                                            
                                        } else {    // falseの時
                                            if return_msg == "" {
                                                let msg = "送信エラー"
                                                print(msg)
                                                self.return_error(msg)
                                                self.spinnerEnd()
                                                
                                                // 残数取得
                                                remining.get()
                                                // ボタン押下可とする。
                                                self.button_enable()
                                                return;
                                            }
                                        }
                                    }
                                    if key as! String == "Message" {
                                        return_msg = value.toString()
                                        if value.toString() != "" {
                                            let msg = value.toString()
                                            print(msg)
                                            self.return_error(msg)
                                            self.spinnerEnd()
                                            
                                            // 残数取得
                                            remining.get()
                                            // ボタン押下可とする。
                                            self.button_enable()
                                            return;
                                        } else {
                                            if return_value == "false" {
                                                let msg = "送信エラー"
                                                print(msg)
                                                self.return_error(msg)
                                                self.spinnerEnd()
                                                
                                                // 残数取得
                                                remining.get()
                                                // ボタン押下可とする。
                                                self.button_enable()
                                                return;
                                            }
                                        }
                                    }
                                }
                            }
                            
                        } else {
                            print(data as Any, response as Any, error as Any)
                            
                            print("ERROR",error as Any )
                            //エラー処理
                            self.send_error()
                            self.spinnerEnd()
                            
                            // ボタン押下可とする。
                            self.button_enable()
                            return;
                        }
                    } catch {
                        print(data as Any, response as Any, error)
                        print("ERROR",error )

                        self.send_error()
                        self.spinnerEnd()
                        
                        // ボタン押下可とする。
                        self.button_enable()
                        return;
                    }
                    
                })
                
                task.resume()
                
                db.close()

//                fmdb.db_save(self.sendTime,detail_kbn: globals_is_new)
 
            } else {        // デモモード
                let detail_kbn = globals_is_new == 1 ? 1 : 2
                fmdb.db_save(self.sendTime,detail_kbn: detail_kbn)
 
                // 同じテーブルの保留データは削除する。
                
                
                self.performSegue(withIdentifier: "toMainMenuViewController",sender: nil);

            }

        })
        // キャンセルボタン
        let cancelAction: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertActionStyle.cancel, handler: {(action: UIAlertAction!) -> Void in
            print("キャンセル")
            // タップ音
            TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
            
            // ボタン押下可とする。
            self.button_enable()
            
        })
        
        // UIAlertControllerにActionを追加
        alert.addAction(cancelAction)
        alert.addAction(defaultAction)
        
        // Alertを表示
        present(alert, animated: true, completion: nil)
        
        // 二重送信を防ぐためにOKを押したときは、ボタン押下不可とする。
        self.button_enable(false)        
    }
   
    // 長押しからのタップ
    func tapSeat(_ sender:AnyObject){
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        // セル
        if localRow != -1 {
            let Disp_data = self.Disp[localSection][localRow]
            
            let sn2 = sender.titleLabel?!.text
            
            
            if sn2 != "" && sn2 != nil{
                
                var seat_no = 0
                let idx = seat.index(where: {$0.seat_name == sn2})
                if idx != nil {
                    seat_no = seat[idx!].seat_no
                }
                
                let id = Disp_data.id
                
                let idx0 = MainMenu.index(where: {$0.id == id})
                
                if idx0 != nil {
                    MainMenu[idx0!].payment_seat_no = seat_no
                }
                
                let idx1 = MainMenu_User.index(where: {$0.id == id})
                
                if idx1 != nil {
                    MainMenu_User[idx1!].payment_seat_no = seat_no
                }
                
                let idx2 = MainMenu_Menu.index(where: {$0.id == id})
                
                if idx2 != nil {
                    MainMenu_Menu[idx2!].payment_seat_no = seat_no
                }

                
                self.makeDispData()
                let indexPath = IndexPath(row: localRow, section: localSection)
                self.tableViewMain.reloadRows(at: [indexPath], with: .none)
            }
            
        // セクション
        } else {
            let btn = sender as! UIButton
            let sn2 = btn.titleLabel?.text

            var seat_no = 0
            let idx = seat.index(where: {$0.seat_name == sn2})
            if idx != nil {
                seat_no = seat[idx!].seat_no
            }

            
            if sn2 != "" && sn2 != nil{
                Section[localSection].seat = sn2!
                // お客様順表示
                if isDispChange == true {
                    
                    for i in 0..<MainMenu.count {
                        if MainMenu[i].seat != "" && MainMenu[i].seat == Section_Save[localSection].seat {
                            MainMenu[i].payment_seat_no = seat_no
                            print(MainMenu[i])
                        }
                    }
                    for i in 0..<MainMenu_User.count {
                        if self.MainMenu_User[i].seat != "" && self.MainMenu_User[i].seat == Section_Save[localSection].seat {
                            MainMenu_User[i].payment_seat_no = seat_no
                        }
                    }
                    for i in 0..<MainMenu_Menu.count {
                        if self.MainMenu_Menu[i].seat != "" && self.MainMenu_Menu[i].seat == Section_Save[localSection].seat {
                            MainMenu_Menu[i].payment_seat_no = seat_no
                        }
                    }

                } else {
                    
                    for disp in Disp[localSection] {
                        let id = disp.id
                    
                        for i in 0..<MainMenu.count {
                            if MainMenu[i].id == id {
                                MainMenu[i].payment_seat_no = seat_no
                                print(MainMenu[i])
                            }
                        }
                        for i in 0..<MainMenu_User.count {
                            if self.MainMenu_User[i].id == id {
                                MainMenu_User[i].payment_seat_no = seat_no
                            }
                        }
                        for i in 0..<MainMenu_Menu.count {
                            if self.MainMenu_Menu[i].id == id {
                                MainMenu_Menu[i].payment_seat_no = seat_no
                            }
                        }
                    }
                    
                }
 
                self.makeDispData()
                
                self.tableViewMain.reloadSections(IndexSet(integer: localSection), with: .none)
            }

            
        }
        
        self.dismiss(animated: true, completion: nil)
    }

    // すべての中のボタンをタップした場合
    func tapSeatAll(_ sender:AnyObject){
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        let selectBtn = sender.tag
        let sn = sender.titleLabel?!.text
        
        // 座席名を選択
        if selectBtn! <= Section.count {
            var seat_no = 0
            let idx = seat.index(where: {$0.seat_name == sn})
            if idx != nil {
                seat_no = seat[idx!].seat_no
            }

            for i  in 0..<MainMenu_Menu.count {
                if MainMenu_Menu[i].seat != "" {
                    MainMenu_Menu[i].payment_seat_no = seat_no
                }
            }
            
            for i  in 0..<MainMenu.count {
                if MainMenu[i].seat != "" {
                    MainMenu[i].payment_seat_no = seat_no
                }
            }

            for i  in 0..<MainMenu_User.count {
                if MainMenu_User[i].seat != "" {
                    MainMenu_User[i].payment_seat_no = seat_no
                }
            }
            
/*
//            for i  in 0..<Section_Menu.count {
//                if Section_Menu[i].seat != "" {
//                    Section_Menu[i].seat = sn!
//                }
//            }
            
            for i  in 0..<Section.count {
                if Section[i].seat != "" {
                    Section[i].seat = sn!
                }
            }
            
            for i  in 0..<MainMenu_Menu.count {
                if MainMenu_Menu[i].seat != "" {
                    MainMenu_Menu[i].seat = sn!
                }
            }
            
            for i  in 0..<MainMenu.count {
                if MainMenu[i].seat != "" {
                    MainMenu[i].seat = sn!
                }
            }
            
            for i  in 0..<Section_User.count {
                if Section_User[i].seat != "" {
                    Section_User[i].seat = sn!
                }
            }
            
            for i  in 0..<MainMenu_User.count {
                if MainMenu_User[i].seat != "" {
                    MainMenu_User[i].seat = sn!
                }
            }
  */
        // 元に戻すを選択
        } else {
            // ユーザー別データ
            Section_User = []
//            MainMenu_User = []
            Section_User = Section_Save
//            MainMenu_User = MainMenu_Save

            
            
            for sect in Section_Save {
                for j in 0..<MainMenu_User.count {
                    if sect.seat == MainMenu_User[j].seat {
//                        MainMenu_User[j].seat = sect.seat
                        MainMenu_User[j].payment_seat_no = sect.seat_no
                    }
                }
                for j in 0..<MainMenu.count {
                    if sect.seat == MainMenu[j].seat {
//                        MainMenu[j].seat = sect.seat
                        MainMenu[j].payment_seat_no = sect.seat_no
                    }
                }
            }
            
            // メニュー順データ
            
            self.makeMenuSort()

/*
            
//            MainMenu.sortInPlace {$0.MenuNo < $1.MenuNo}
            // セクションデータを作成する
            self.Section_Menu = []
//            var menuNo_temp = ""
//            for tb in MainMenu {
//                if menuNo_temp != tb.MenuNo {
//                    menuNo_temp = tb.MenuNo
//                    let seatFirst = String(tb.Name[tb.Name.startIndex])
//                    Section_Menu.append(SectionData(seat: seatFirst, No: tb.MenuNo, Name: tb.Name))
//                }
//            }
//            
//            // メニューデータを作成
//            MainMenu_Menu = []
//            for tb in MainMenu {
//                for sc in Section {
//                    if tb.No == sc.No {
//                        MainMenu_Menu.append(mainMenu_menuData(seat: tb.seat, No: tb.MenuNo, Name: sc.Name, MenuNo: tb.No, Count: tb.Count, Hand: tb.Hand, MenuType: 1,MenuName: "1"))
//                    }
//                }
//            }
            
            MainMenu_Menu = []
            
            var menu_submenu = ""
            var menu_submenus:[String] = []
            
            for tb in MainMenu {
                menu_submenu = tb.MenuNo + "・" + tb.Name
                for sm in SubMenu {
                    if tb.No == sm.No && tb.MenuNo == sm.MenuNo{
                        menu_submenu = menu_submenu + "・" + sm.Name
                    }
                }
                menu_submenus.append(menu_submenu)
            }
            let menu_submenus2 = Set(menu_submenus)
            print(menu_submenus2)
            var seat_no = 0
            for Line in menu_submenus2 {
                let parts = Line.componentsSeparatedByString("・")
                var menu_no = ""
                var menu_sub = ""
                for i in 0..<parts.count {
                    if i == 0 {
                        menu_no = parts[i]
                    } else if i == 1 {
                        menu_sub = parts[i]
                    } else {
                        menu_sub = menu_sub + "・" + parts[i]
                    }
                }
                let seatFirst = String(menu_sub[menu_sub.startIndex])
                seat_no += 1
                Section_Menu.append(SectionData(
                    seat_no:seat_no,
                    seat: seatFirst,
                    No: menu_no,
                    Name: menu_sub)
                )
            }
            
            print(Section_Menu)
            
            // メニューデータを作成
            menu_submenu = ""
            menu_submenus = []
            for tb in MainMenu {
                var hand = ""
                if tb.Hand == true {
                    hand = "1"
                } else {
                    hand = "0"
                }
                
                menu_submenu = tb.seat + "・" + tb.No + "・" + tb.MenuNo + "・" + tb.Name + "・" + tb.Count + "・" + hand
                for sm in SubMenu {
                    if tb.No == sm.No && tb.MenuNo == sm.MenuNo{
                        menu_submenu = menu_submenu + "・" + sm.Name
                    }
                }
                menu_submenus.append(menu_submenu)
            }
            
            let menu_submenus3 = Set(menu_submenus)
            print(menu_submenus3)
            SpecialMenu_Menu = []
            for Line in menu_submenus3 {
                let parts = Line.componentsSeparatedByString("・")
                let seat_name = parts[0]
                let folder_no = parts[1]
                let menu_no = parts[2]
                let menu_count = parts[4]
                var isHand = false
                if parts[5] == "1" {
                    isHand = true
                } else {
                    isHand = false
                }
                
                var pName = ""
                for sc in Section {
                    if seat_name == sc.seat && folder_no == sc.No {
                        pName = sc.Name
                        break;
                    }
                }
                
                var menu_sub = ""
                for i in 0..<parts.count {
                    if i == 3 {
                        menu_sub = parts[i]
                    } else if i >= 6 {
                        menu_sub = menu_sub + "・" + parts[i]
                    }
                }

                
                //            Section_Menu.append(SectionData(seat: seatFirst, No: menu_no, Name: menu_sub))
                
                MainMenu_Menu.append(mainMenu_menuData(
                    seat    : seat_name,
                    No      : menu_no,
                    Name    : pName,
                    MenuNo  : folder_no,
                    BranchNo: 0,
                    Count   : menu_count,
                    Hand    : isHand,
                    MenuType: 1,
                    MenuName: menu_sub
                    )
                )
                
                for sp in SpecialMenu {
                    if menu_no == sp.MenuNo && folder_no == sp.No{
                        SpecialMenu_Menu.append(SpecialMenuData(
                            seat    :seat_name,
                            No      : folder_no,
                            MenuNo  : menu_no,
                            BranchNo: sp.BranchNo,
                            Name    :sp.Name,
                            category: sp.category
                            )
                        )
                    }
                }
            }
*/
        }

        self.makeDispData()
        self.tableViewMain.reloadData()
        self.dismiss(animated: true, completion: nil)
    }
    
    // ボタンを長押ししたときの処理
    @IBAction func pressedLong(_ sender: UILongPressGestureRecognizer!) {
        // 精算者振り替え機能OFFの場合
        if is_payer_allocation != 1 {
            // toast with a specific duration and position
            self.view.makeToast("精算者振り替え機能はOFFです", duration: 1.0, position: .top)
            // ファンクションから抜ける
            return;
        }
        
        let recognizer:UIGestureRecognizer = sender as UIGestureRecognizer
        let btn = recognizer.view! as! UIButton
        print("long press")
        let point: CGPoint = sender.location(in: tableViewMain)
        let indexPath = tableViewMain.indexPathForRow(at: point)
        
        if btn.titleLabel!.text != "" && btn.titleLabel!.text != nil{
            // ジェスチャーの状態に応じて処理を分ける
            switch sender.state {
            case .began:
                if btn.tag == 0 {
                    localSection = (indexPath?.section)!
                    localRow = (indexPath?.row)!
                } else {
                    localSection = btn.tag - 1
                    localRow = -1
                }

                let line = Int((Section.count - 1) / 4) + 1
                let vc = UIViewController(nibName: "selectPayViewController", bundle: nil)
                
                vc.modalPresentationStyle = .popover
                vc.preferredContentSize = CGSize(width: self.view.bounds.width - recognizer.view!.bounds.width - 40, height: (iconSizeH + topMargin + betweenMargin) * CGFloat(line))
                
                for num in 0..<Section_Save.count {
                    // ボタンを作る
                    let button = UIButton()
                    // 表示されるテキスト
                    button.setTitle(Section_Save[num].seat, for: UIControlState())
                    // テキストの色
                    button.setTitleColor(UIColor.white, for: UIControlState())
                    // サイズ
                    button.frame = CGRect(x: 0, y: 0, width: iconSizeW, height: iconSizeH)
                    // tag番号
                    button.tag = num + 1
                    // 配置場所
                    let posX = (button.frame.width + 8) * CGFloat(num - (Int(num/4)*4)) + (button.frame.width / 2 + 10)
                    let posY = topMargin + (button.frame.height / 2) + ((button.frame.height + betweenMargin + betweenMargin) * CGFloat(Int(num / 4)))
                    button.layer.position = CGPoint(x: posX , y: posY)
                    // 背景色
                    button.backgroundColor = UIColor(red: 0.7, green: 0.2, blue: 0.2, alpha: 1.0)
                    // 角丸
                    button.layer.cornerRadius = button.bounds.height / 2
                    // ボーダー幅
                    //            button.layer.borderWidth = 1
                    // タップした時に実行するメソッドを指定
                    button.addTarget(self, action: #selector(orderMakeSureViewController.tapSeat(_:)), for: .touchUpInside)
                    
                    // viewにボタンを追加する
                    vc.view.addSubview(button)
                    
                }
                
                if let presentationController = vc.popoverPresentationController {
                    presentationController.permittedArrowDirections = .left
                    presentationController.sourceView = recognizer.view! as UIView
                    presentationController.sourceRect = recognizer.view!.bounds
                    presentationController.backgroundColor = UIColor.clear
                    presentationController.delegate = self
                }
                
                present(vc, animated: true, completion: nil);
                
                break
            case .cancelled:
                break
            case .ended:
                break
            case .failed:
                break
            default:
                break
            }
        }
    }

    // セルを長押ししたときの処理
    @IBAction func pressedLongCell(_ sender: UILongPressGestureRecognizer!) {
//        let recognizer:UIGestureRecognizer = sender as UIGestureRecognizer
        print("long press　Cell")
        let point: CGPoint = sender.location(in: tableViewMain)
        let indexPath = tableViewMain.indexPathForRow(at: point)
//        print(indexPath)
        
        // ジェスチャーの状態に応じて処理を分ける
        switch sender.state {
        case .began:
            print("began")
            if indexPath != nil {
                // セルの種類がメインのメニューの場合
                let selectDisp = self.Disp[(indexPath?.section)!][(indexPath?.row)!]
                if selectDisp.MenuType == 1 {
                    // お客様順表示
                    if isDispChange == true {
                        globals_select_menu_no = (Int64(selectDisp.MenuNo)!,selectDisp.BranchNo,selectDisp.Name)
                        selectedID = selectDisp.id
                        var hn = ""
                        var mc = ""
                        var seat = ""
                        var branch = 0
                        var m_id = 0
                        for mm in MainMenu{
                            if mm.No == selectDisp.No && mm.MenuNo == selectDisp.MenuNo && mm.seat == selectDisp.seat && mm.BranchNo == selectDisp.BranchNo {
                                m_id = mm.id
                                seat = mm.seat
                                hn = mm.No
                                mc = mm.Count
                                branch = mm.BranchNo
                            }
                        }
                        
                        selectSP = []
                        selectSP.append(selectMenuCountData(
                            seat        : seat,
                            No          : hn,
                            MenuNo      : (globals_select_menu_no.menu_no).description,
                            BranchNo    : branch,
                            MenuCount   : Int(mc)!,
                            HandWrite   : globals_image!)
                        )
                        selectSPmenus = []
                        
                        let db = FMDatabase(path: self._path)
                        // データベースをオープン
                        db.open()
                        
                        let opt_filter = SpecialMenu.filter({$0.id == m_id})
                        for (_,opt) in opt_filter.enumerated() {
                            
                            var spe_menu_code = 0
                            let sql = "SELECT * from special_menus_master WHERE item_name = ?;"
                            let rs = db.executeQuery(sql, withArgumentsIn: [opt.Name])
                            while (rs?.next())! {
                                spe_menu_code = Int((rs?.int(forColumn:"item_no"))!)
                            }
                            
                            selectSPmenus.append(selectSPmenu(
                                seat: opt.seat,
                                holderNo: opt.No,
                                menuNo: (globals_select_menu_no.menu_no),
                                BranchNo: branch,
                                spMenuNo: spe_menu_code,
                                spMenuName: opt.Name,
                                category: opt.category
                                )
                            )
                            
                        }
                        
                        self.performSegue(withIdentifier: "toSpecialMenuViewSegue",sender: nil)

                    } else {    // メニュー表示順
                        globals_select_menu_no = (Int64(selectDisp.No)!,selectDisp.BranchNo,Section_Menu[(indexPath?.section)!].Name)
                        selectedID = selectDisp.id
                        var hn = ""
                        var mc = ""
                        var seat = ""
                        var branch = 0
                        for mm in MainMenu{
                            if mm.No == selectDisp.MenuNo && mm.MenuNo == selectDisp.No && mm.seat == selectDisp.seat && mm.BranchNo == selectDisp.BranchNo {
                                seat = mm.seat
                                hn = mm.No
                                mc = mm.Count
                                branch = mm.BranchNo
                            }
                        }
                        
                        selectSP = []
                        selectSP.append(selectMenuCountData(
                            seat        : seat,
                            No          : hn,
                            MenuNo      : (globals_select_menu_no.menu_no).description,
                            BranchNo    : branch,
                            MenuCount   : Int(mc)!,
                            HandWrite   : globals_image!)
                        )
                        self.performSegue(withIdentifier: "toSpecialMenuViewSegue",sender: nil)
                    }
                    
                    
                }
            }
                
            break
        case .cancelled:
            print("cancel")
            break
        case .ended:
            print("end")
            break
        case .failed:
            print("failed")
            break
        default:
            break
        }
    }

    // アクセサリボタンをタップされた場合
    func showSpecialMenuView(_ sender:AnyObject){
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        let point = self.tableViewMain.convert(sender.frame.origin, from: sender.superview)
        let indexPath = self.tableViewMain.indexPathForRow(at: point)!

        
        var hn = ""
        var mc = ""
        var seat = ""
        var m_id = 0
        var branch = 0
        let Disp_data = self.Disp[(indexPath.section)][(indexPath.row)]

        selectedID = Disp_data.id
        
        let index = MainMenu.index(where: {$0.id == Disp_data.id})
        if index != nil {
            seat = MainMenu[index!].seat
            hn = MainMenu[index!].No
            mc = MainMenu[index!].Count
            m_id = MainMenu[index!].id
            branch = MainMenu[index!].BranchNo
            globals_select_menu_no = (Int64(MainMenu[index!].MenuNo)!,MainMenu[index!].BranchNo,MainMenu[index!].Name)
            
        }
        
//        for mm in MainMenu{
//            if mm.No == self.Disp[(indexPath.section)][(indexPath.row)].No && mm.MenuNo == self.Disp[(indexPath.section)][(indexPath.row)].MenuNo {
//                seat = mm.seat
//                hn = mm.No
//                mc = mm.Count
//                globals_select_menu_no = (Int(mm.MenuNo)!,mm.BranchNo,mm.Name)
//            }
//        }
        
        selectSP = []
        selectSP.append(selectMenuCountData(
            seat        : seat,
            No          : hn,
            MenuNo      : (globals_select_menu_no.menu_no).description,
            BranchNo    : globals_select_menu_no.branch_no,
            MenuCount   : Int(mc)!,
            HandWrite   : globals_image!)
        )

        selectSPmenus = []
        
        let db = FMDatabase(path: self._path)
        // データベースをオープン
        db.open()
        
        let opt_filter = SpecialMenu.filter({$0.id == m_id})
        for (_,opt) in opt_filter.enumerated() {
            
            var spe_menu_code = 0
            let sql = "SELECT * from special_menus_master WHERE item_name = ?;"
            let rs = db.executeQuery(sql, withArgumentsIn: [opt.Name])
            while (rs?.next())! {
                spe_menu_code = Int((rs?.int(forColumn:"item_no"))!)
            }
            
            selectSPmenus.append(selectSPmenu(
                seat: opt.seat,
                holderNo: opt.No,
                menuNo: (globals_select_menu_no.menu_no),
                BranchNo: branch,
                spMenuNo: spe_menu_code,
                spMenuName: opt.Name,
                category: opt.category
                )
            )
            
        }

        
        self.performSegue(withIdentifier: "toSpecialMenuViewSegue",sender: nil)
    }

    func makeDispData(){
        // お客様順表示
        if isDispChange == true {
            // 表示用のデータを作成する
            Disp_Section = []
            Disp_Section = Section
            Disp = []

            for (num,sec) in Section_Save.enumerated() {
                let holderNo = sec.No
                let seat = sec.seat
                // 多次元の可変配列の初期化
                self.Disp.append([CellData]())
                
                // メニュー数
                for (i,table) in MainMenu_Save.enumerated() {
                    // メニューNOが0の場合は抜ける
                    if table.MenuNo != "0" {
                        if holderNo == table.No && seat == table.seat {
                            let addData = CellData(
                                id      : MainMenu_User[i].id,
                                seat    : MainMenu_User[i].seat,
                                No      : MainMenu_User[i].No,
                                Name    : MainMenu_User[i].Name,
                                MenuNo  : MainMenu_User[i].MenuNo,
                                BranchNo: MainMenu_User[i].BranchNo,
                                Count   : MainMenu_User[i].Count,
                                Hand    : MainMenu_User[i].Hand,
                                MenuType: MainMenu_User[i].MenuType,
                                payment_seat_no: MainMenu_User[i].payment_seat_no
                            )
                            self.Disp[num].append(addData)
                            
                            // サブメニュー数
                            for sub in SubMenu_User {
                                if sub.id == table.id {
                                    let addData = CellData(
                                        id      : table.id,
                                        seat    : seat,
                                        No      : sub.No,
                                        Name    : sub.Name,
                                        MenuNo  : sub.MenuNo,
                                        BranchNo: sub.BranchNo,
                                        Count   : "",
                                        Hand    : false,
                                        MenuType: 2,
                                        payment_seat_no: table.payment_seat_no
                                    )
                                    self.Disp[num].append(addData)
                                    
                                }

                            }
                            
                            // 特殊メニュー数
                            for special in SpecialMenu_User {
                                if special.id == table.id {
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
                                        payment_seat_no: table.payment_seat_no)
                                    self.Disp[num].append(addData)
                                }
                            }
                            // 特殊メニューの一番最後の行に -1 を入れる
                            if self.Disp[num].last?.MenuType == 3 {
                                let c = self.Disp[num].count - 1
                                self.Disp[num][c].Count = "-1"
                            }
                        }
                    }
                }
            }
            
        // メニュー順表示
        } else {
            // 表示用のデータを作成する
            Disp_Section = []
            Disp_Section = Section_Menu

            Disp = []
            
            Section_Menu.sort(by: {$0.seat_no < $1.seat_no})
            
            for num in 0..<Section_Menu.count {
                let menuNo = Section_Menu[num].No
                let menuName = Section_Menu[num].Name
                
                // 多次元の可変配列の初期化
                self.Disp.append([CellData]())
                
                // メニュー数
                let tables = MainMenu_Menu.filter({$0.No == menuNo && $0.MenuName == menuName})
                
                for table in tables {
                    let index = Disp[num].index(where: {$0.id == table.id})
                    if index == nil {
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
                        
                        // 特殊メニュー数
                        for special in SpecialMenu_Menu {
                            if table.id == special.id {
                                let addData = CellData(
                                    id: table.id,
                                    seat: table.seat,
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
                        // 特殊メニューの一番最後の行に -1 を入れる
                        if self.Disp[num].last?.MenuType == 3 {
                            let c = self.Disp[num].count - 1
                            self.Disp[num][c].Count = "-1"
                        }
                    }
                    
                }
                // ソート
                Disp[num].sort(by: {$0.seat < $1.seat})
            }
        }
        print("makeDispData",Disp)

    }
    
    func swipeLabel(_ sender:UISwipeGestureRecognizer){
        let cell = sender.view as! UITableViewCell
        let indexPath = self.tableViewMain.indexPath(for: cell)!
        
        switch(sender.direction){
        case UISwipeGestureRecognizerDirection.up:
            print("上")
            
        case UISwipeGestureRecognizerDirection.down:
            print("下")
            
        case UISwipeGestureRecognizerDirection.left:
            print("左")
            // 音
            TapSound.buttonTap("swish1", type: "mp3")
            
            let Disp_data = self.Disp[indexPath.section][indexPath.row]

            let id = Disp_data.id

            if Disp_data.MenuType == 1 && Disp_data.Count != "" {
                var iCount:Int = Int(Disp_data.Count)!
                
                if is_minus_qty != 0 {      // マイナス入力を許可する
                    iCount -= 1
                } else {
                    if iCount > 0 {
                        iCount -= 1
                    }
                }
                
                let idx = MainMenu.index(where: {$0.id == id})
                
                if idx != nil {
                    MainMenu[idx!].Count = "\(iCount)"
                }
                
                let idx1 = MainMenu_User.index(where: {$0.id == id})
                
                if idx1 != nil {
                    MainMenu_User[idx1!].Count = "\(iCount)"
                }
                
                let idx2 = MainMenu_Menu.index(where: {$0.id == id})
                
                if idx2 != nil {
                    MainMenu_Menu[idx2!].Count = "\(iCount)"
                }

            }
            
            self.makeDispData()
            self.tableViewMain.reloadRows(at: [indexPath], with: .none)

        case UISwipeGestureRecognizerDirection.right:
            print("右")
            
        default:
            break
        }
    }
    
    func parentViewHeight() -> CGFloat {
        return self.view.frame.height 
    }

    // 手書きイメージのプレビュー表示
    func handWright_image_preview(_ sender:AnyObject) {
        
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        let point = self.tableViewMain.convert(sender.frame.origin, from: sender.superview)
        let indexPath = self.tableViewMain.indexPathForRow(at: point)!
        
        let cell_data = self.Disp[indexPath.section][indexPath.row]
        
        // 削除用
        // お客様順表示
        if isDispChange == true{
            del_seat = cell_data.seat
            del_holder_no = cell_data.No
            del_menu_no = cell_data.MenuNo
            del_branch = cell_data.BranchNo
            
        } else {
            del_seat = cell_data.seat
            del_holder_no = cell_data.MenuNo
            del_menu_no = cell_data.No
            del_branch = cell_data.BranchNo
            
        }
        
        let handData: Data? = fmdb.get_PngData(del_seat!, holder_no: del_holder_no!, menu_no: del_menu_no!,branch_no: del_branch)
        let handImage: UIImage? = handData.flatMap(UIImage.init)
        
        // ビューの高さと幅を取得
        let width:CGFloat = tableViewMain.bounds.width * 0.9
        let height:CGFloat = tableViewMain.bounds.height * 0.9

        // 表示開始位置
        let x:CGFloat = (view.bounds.width - width) / 2
        let y:CGFloat = tableViewMain.frame.origin.y + ((tableViewMain.bounds.height - height) / 2)
        
        let frame:CGRect = CGRect(x: x, y: y, width: width, height: height)
        
        // ビューを生成
        let baseView = UIView(frame: frame)
        baseView.backgroundColor = iOrder_grayColor
        
        // イメージビューを作成
        let image_frame:CGRect = CGRect(x: 3, y: 3, width: width-6, height: height-80)
        let handimageView = UIImageView(image: handImage)
        handimageView.frame = image_frame
        
        //閉じるボタンを作成
        let fontName = "YuGo-Bold"    // "YuGo-Bold"
        let closeButton = UIButton()
        //表示させるテキスト
        closeButton.frame = CGRect(x: 3, y: 3+height-80, width: width-6, height: 80-6)
        closeButton.backgroundColor = UIColor.blue
        closeButton.setTitleColor(UIColor.white, for: UIControlState())
        // フォント名の指定はPostScript名
        closeButton.titleLabel!.font = UIFont(name: fontName,size: CGFloat(20))
        
        closeButton.setTitle("閉じる", for: UIControlState())
        let iconImage = FAKFontAwesome.timesCircleIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
        let Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        closeButton.setImage(Image, for: UIControlState())
        
        closeButton.addTarget(self, action: #selector(orderMakeSureViewController.closeTap), for: .touchUpInside)
        
        let clearView = UIView(frame: self.view.frame)
        clearView.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
        // alphaで透過を調整すると、上に乗っているsubviewがすべて、この設定になるよ。
//        clearView.alpha = 0.5
        clearView.tag = 999
        
        // 削除ボタン作成
        let deleteButton = UIButton()
        deleteButton.frame = CGRect(x: 0, y: 0, width: iconSizeL, height: iconSizeL)
        deleteButton.layer.position = CGPoint(x: width-(iconSizeL/2), y: height-80-(iconSizeL/2))
        let iconImage3 = FAKFontAwesome.trashOIcon(withSize: iconSize)
        iconImage3?.addAttribute(NSForegroundColorAttributeName, value: iOrder_greenColor)
        let Image3 = iconImage3?.image(with: CGSize(width: iconSize, height: iconSize))
        deleteButton.setImage(Image3, for: UIControlState())
        deleteButton.addTarget(self, action: #selector(orderMakeSureViewController.deleteTap), for: .touchUpInside)
        
        self.view.addSubview(clearView)
        clearView.addSubview(baseView)
        baseView.addSubview(handimageView)
        baseView.addSubview(closeButton)
    }
    
    func closeTap() {
        print("closeTap")
        view.viewWithTag(999)!.removeFromSuperview()
    }
    
    func deleteTap() {
        print("deleteTap")
        let alertController = UIAlertController(title: "削除", message: "手書きを削除します。\nよろしいですか？", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel){
            action in print("Pushed cancel")
            return;
        }
        
        let okAction = UIAlertAction(title: "OK", style: .default){
            action in
            print("Pushed OK")
            
            self.delete_PngData(self.del_seat!, holder_no: self.del_holder_no!, menu_no: self.del_menu_no!)

            for (i,table) in self.MainMenu_User.enumerated() {
                if table.seat == self.del_seat && table.No == self.del_holder_no && table.MenuNo == self.del_menu_no && table.BranchNo == self.del_branch {
                    self.MainMenu_User[i].Hand = false
                }
            }
            
            self.view.viewWithTag(999)!.removeFromSuperview()
            self.makeDispData()
            self.tableViewMain.reloadData()
            self.del_seat = ""
            self.del_holder_no = ""
            self.del_menu_no = ""
            return;
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
        
    }
    // 戻るボタンで戻ってくるためのおまじない
    @IBAction func unwindToOrderMakeSureView(_ segue: UIStoryboardSegue) {
        if segue.identifier == "toOrderMakeSureViewSegue" {
//            print(SubMenu)
            print(DecisionSubMenu)
            
            // SubMenuから同じシートNo同じメニュー番号のセレクトメニューを削除
            SubMenu = SubMenu.filter({!($0.id == selectedID)})
            
            // 確定したセレクトメニューを登録
            for submenu in DecisionSubMenu {
                SubMenu.append(SubMenuData(
                    id      : selectedID,
                    seat    : globals_select_holder.seat,
                    No      : globals_select_holder.holder,
                    MenuNo  : submenu.MenuNo,
                    BranchNo: globals_select_selectmenu_no.branch_no,
                    Name    : submenu.Name,
                    sub_menu_no: submenu.subMenuNo,
                    sub_menu_group: submenu.subMenuGroup)
                )
            }
            
            // 表示用データの作成
            self.makeDispData()
            self.tableViewMain.reloadData()
        }
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
            self.performSegue(withIdentifier: "toMainMenuViewController",sender: nil)
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
                self.performSegue(withIdentifier: "toMainMenuViewController",sender: nil)
                
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

    func delete_PngData(_ seat:String,holder_no:String,menu_no:String) {
        let db = FMDatabase(path: self._path)
        db.open()
        
        let sql = "DELETE FROM hand_image WHERE seat = ? AND holder_no = ? AND order_no = ?"
        let _ = db.executeUpdate(sql, withArgumentsIn: [seat,holder_no,menu_no])
    }

    func return_error(_ msg:String){
        let alertController = UIAlertController(title: "エラー！", message: msg , preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default){
            action in print("Pushed OK")
            self.spinnerEnd()
            return;
        }
        
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
        
    }
    
    func send_error(){
        
        let error_timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(error_beep), userInfo: nil, repeats: true)
        
        // エラー音
        let alertController = UIAlertController(title: "エラー！", message: "送信エラーが発生しました。\n再送信を行ってください。" , preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default){
            action in print("Pushed OK")
            
            // タイマー破棄
            error_timer.invalidate()
            fmdb.resend_db_save(self.max_oeder_no!,send_time:self.sendTime)
            fmdb.db_save(self.sendTime,detail_kbn: globals_is_new)
            order_time = 0
            order_resend_time = 0
            
            self.performSegue(withIdentifier: "toMainMenuViewController",sender: nil);
            self.spinnerEnd()
            return;
        }
        
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func error_beep(_ sender:Timer){
        // エラー音
        TapSound.buttonTap(err_sound_file.sound_file, type: err_sound_file.file_type)
    }
    
    @objc func updating()  {
        if order_send_timer.isValid {
            order_send_timer.invalidate()
        }
        order_send_timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updating), userInfo: nil, repeats: true)
        
        
        if order_send_time >= (data_not_send_alert.sound_interval) * 60 {
        
            if is_not_send_alert_disp == true {
                is_not_send_alert_disp = !is_not_send_alert_disp
                // 音をだす
                // エラー音
                TapSound.errorBeep(data_not_send_alert_file.sound_file, type: data_not_send_alert_file.file_type)
            
                print("この画面で" + (data_not_send_alert.sound_interval).description + "分経ちました。")
                
                let alertController = UIAlertController(title: "エラー！", message: "この画面で" + (data_not_send_alert.sound_interval).description + "分経ちました。\nオーダー送信を忘れていませんか？", preferredStyle: .alert)
                
                let okAction = UIAlertAction(title: "OK", style: .default){
                    action in print("Pushed OK")
                    if order_send_timer.isValid == true {
                        // timerを破棄する
                        order_send_timer.invalidate()
                        TapSound.errorBeep_stop()
                    }
                    
                    if data_not_send_alert.interval > 0 {       // 繰り返しあり
                        self.updating_interval()
                        order_send_interval = 0
                        self.is_not_send_alert_disp = true
                    }
                    return;
                }
                
                alertController.addAction(okAction)
                UIApplication.shared.topViewController()?.present(alertController, animated: true, completion: nil)
           
            }
            
        } else {
            order_send_time += 1
        }
        
    }
    
    @objc func updating_interval()  {
        if order_send_timer.isValid {
            order_send_timer.invalidate()
        }
        order_send_timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updating_interval), userInfo: nil, repeats: true)
        
        if order_send_interval >= (data_not_send_alert.interval * 60) {            
            if is_not_send_alert_disp == true {
                is_not_send_alert_disp = !is_not_send_alert_disp
                TapSound.errorBeep(data_not_send_alert_file.sound_file, type: data_not_send_alert_file.file_type)
                print("この画面" + (data_not_send_alert.interval).description + "分経ちました。")
                
                let alertController = UIAlertController(title: "エラー！", message: "この画面で" + (data_not_send_alert.interval).description + "分経ちました。\nオーダー送信を忘れていませんか？", preferredStyle: .alert)
                
                let okAction = UIAlertAction(title: "OK", style: .default){
                    action in print("Pushed OK")
                    if order_send_timer.isValid == true {
                        // timerを破棄する
                        order_send_timer.invalidate()
                        TapSound.errorBeep_stop()
                    }
                    
                    if data_not_send_alert.interval > 0 {       // 繰り返しあり
                        self.updating_interval()
                        order_send_interval = 0
                        self.is_not_send_alert_disp = true
                    }
                    return;
                }
                
                alertController.addAction(okAction)
                UIApplication.shared.topViewController()?.present(alertController, animated: true, completion: nil)
                
            }

        } else {
            order_send_interval += 1
        }
//        print("updating_interval:",order_send_interval)
    }
    
    func makeMenuSort() {
        // セクションデータを作成する
        self.Section_Menu = []
        
        var menu_submenu = ""
        var menu_submenus:[String] = []
        
        MainMenu.sort(by: {$0.seat < $1.seat})
        
        for tb in MainMenu {
            if tb.MenuNo != "0" {
                menu_submenu = tb.MenuNo + "$" + tb.Name
                for sm in SubMenu {
                    if tb.id == sm.id {
//                    if tb.No == sm.No && tb.MenuNo == sm.MenuNo{
                        menu_submenu = menu_submenu + "$" + sm.Name
                    }
                }
                menu_submenus.append(menu_submenu)
            }
        }
        let menu_submenus2 = Set(menu_submenus)
        //        print(menu_submenus2)
        var seat_no = 0
        for Line in menu_submenus2 {
            let parts = Line.components(separatedBy: "$")
            var menu_no = ""
            var menu_sub = ""
            for i in 0..<parts.count {
                if i == 0 {
                    menu_no = parts[i]
                } else if i == 1 {
                    menu_sub = parts[i]
                } else {
                    menu_sub = menu_sub + "・" + parts[i]
                }
            }
            let seatFirst = String(menu_sub[menu_sub.startIndex])
            seat_no += 1
            Section_Menu.append(SectionData(
                seat_no:seat_no,
                seat: seatFirst,
                No: menu_no,
                Name: menu_sub)
            )
        }
        
        Section_Menu.sort(by: {$0.seat_no < $1.seat_no})
                print(Section_Menu)
        
        
        // メニューデータを作成
        menu_submenu = ""
        menu_submenus = []
        for tb in MainMenu {
            var hand = ""
            if tb.Hand == true {
                hand = "1"
            } else {
                hand = "0"
            }
            
            menu_submenu = tb.seat + "$" + tb.No + "$" + tb.MenuNo + "$" + tb.Name + "$" + tb.Count + "$" + hand + "$" + (tb.id).description + "$" + (tb.payment_seat_no).description
            for sm in SubMenu {
                if tb.id == sm.id {
//                if tb.No == sm.No && tb.MenuNo == sm.MenuNo{
                    menu_submenu = menu_submenu + "$" + sm.Name
                }
            }
            menu_submenus.append(menu_submenu)
        }
        
        let menu_submenus3 = Set(menu_submenus)
                print("fjsklfsdfn;sdafd",MainMenu_Menu)
        MainMenu_Menu = []
        SpecialMenu_Menu = []
        for Line in menu_submenus3 {
            let parts = Line.components(separatedBy: "$")
            let seat_name = parts[0]
            let folder_no = parts[1]
            let menu_no = parts[2]
            //            let menu_name = parts[3]
            let menu_count = parts[4]
            let isHand = parts[5] == "1" ? true : false
            
            var pName = ""
            var seat_no = -1
            let index0 = seat.index(where: {$0.seat_name == seat_name})
            if index0 != nil {
                seat_no = seat[index0!].seat_no
            }
            let index = Section.index(where: {$0.seat_no == seat_no && $0.No == folder_no})
            if index != nil {
                pName = Section[index!].Name
            }
            let id = Int(parts[6])
            let pay_seat_no = Int(parts[7])
            
            var menu_sub = ""
            for i in 0..<parts.count {
                if i == 3 {
                    menu_sub = parts[i]
                } else if i >= 8 {
                    menu_sub = menu_sub + "・" + parts[i]
                }
            }
            
            
            let index2 = MainMenu_Menu.index(where: {$0.id == id })
            
            if index2 == nil {
                MainMenu_Menu.append(mainMenu_menuData(
                    id:id!,
                    seat: seat_name,
                    No: menu_no,
                    Name: pName,
                    MenuNo: folder_no,
                    BranchNo: 0,
                    Count: menu_count,
                    Hand: isHand,
                    MenuType: 1,
                    MenuName: menu_sub,
                    payment_seat_no: pay_seat_no!)
                )
            }
            
            for sp in SpecialMenu {
                if sp.id < 0 {
                    if menu_no == sp.MenuNo && folder_no == sp.No {
                        let index = SpecialMenu_Menu.filter{$0.MenuNo == menu_no && $0.Name == sp.Name && $0.No == folder_no}
                        if index.count == 0 {
                            SpecialMenu_Menu.append(SpecialMenuData(
                                id:-1,
                                seat:sp.seat,
                                No: folder_no,
                                MenuNo: menu_no,
                                BranchNo: sp.BranchNo,
                                Name:sp.Name,
                                category: sp.category)
                            )
                        }
                    }
                } else {
                    if id == sp.id {
                        SpecialMenu_Menu.append(SpecialMenuData(
                            id:sp.id,
                            seat:sp.seat,
                            No: folder_no,
                            MenuNo: menu_no,
                            BranchNo: sp.BranchNo,
                            Name:sp.Name,
                            category: sp.category)
                        )
                    }
                }
            }
            
            // id を振り分け
            for m in MainMenu {
                for (j,o) in SpecialMenu.enumerated() {
                    if o.id < 0 {
                        if (o.seat == m.seat && o.No == m.No && o.MenuNo == m.MenuNo && o.BranchNo == m.BranchNo) {
                            SpecialMenu[j].id = m.id
                        }
                        
                    }
                }
            }
            
        }
    }
    
    func dispatch_async_main(_ block: @escaping () -> ()) {
        DispatchQueue.main.async(execute: block)
    }
    
    func dispatch_async_global(_ block: @escaping () -> ()) {
        DispatchQueue.global().async (execute: block)
    }
    
    func spinnerStart() {
        CustomProgress.Instance.title = "送信中..."
        CustomProgress.Create(self.view,initVal: initVal,modeView: EnumModeView.uiActivityIndicatorView)
        
        //ネットワーク接続中のインジケータを表示
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func spinnerEnd() {
        CustomProgress.Instance.mrprogress.dismiss(true)
        //ネットワーク接続中のインジケータを消去
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    func button_enable(_ mode:Bool = true) {
        let alfa:CGFloat = mode ? 1.0 : 0.6

        self.okButton.isEnabled = mode
        self.okButton.alpha = alfa
        self.backButton.isEnabled = mode
        self.backButton.alpha = alfa
        self.timeInputButton.isEnabled = mode
        self.timeInputButton.alpha = alfa
        
    }
    
}

class timeTextField: UITextField{
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        // コピーやペーストなどのメニューを非表示にする
        UIMenuController.shared.isMenuVisible = false
        return false
    }
    // カーソルを非表示にする
    override func caretRect(for position: UITextPosition) -> CGRect {
        return CGRect.zero
    }
}
