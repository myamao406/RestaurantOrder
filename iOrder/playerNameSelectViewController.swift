//
//  playerNameSelectViewController.swift
//  iOrder
//
//  Created by 山尾守 on 2016/07/07.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit
import FontAwesomeKit
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


class playerNameSelectViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UINavigationBarDelegate {

    fileprivate var onceTokenViewDidAppear: Int = 0
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var allOkButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var rightBarButton: UIBarButtonItem!
    @IBOutlet weak var navBar: UINavigationBar!
    
    // シートNOとホルダ番号（ホルダNO入力画面がら戻ってくる値）
    struct seat_holder {
        var seat_no:Int
        var holder_no:String
    }
    var seat_holders:[seat_holder] = []

    
    // セルデータの型
    struct CellData {
        var holderNo:String
        var playerName:String
        var playerNameKana:String
        var status:Int
    }
    
    // セルデータの配列
    var tableData:[CellData] = []
    var selectHolder:String?
    
    
    var tableViewMain = UITableView()
    
    // セクションのタイトル
    var sectionTitle:String?
    
    // リスト件数
    var count = -1
    
    // 50音対応行列
    var column_row = [-1,-1]
    
    // DBパス
    var _path = ""

    let initVal = CustomProgressModel()
    
    var cell : UITableViewCell?

    var cell_height : CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 背景色を白に設定する.
        self.view.backgroundColor = UIColor.white
        
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

        // 一括登録ボタン
        iconImage = FAKFontAwesome.checkCircleIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
        //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
        Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        allOkButton.setImage(Image, for: UIControlState())
       
        let selectedAttributes = [NSForegroundColorAttributeName : UIColor.white]
        
        let barItem = UIBarButtonItem(title: "テーブルNo: " + "\(globals_table_no)", style: .done, target: self, action: nil)
        
        barItem.setTitleTextAttributes(selectedAttributes, for: UIControlState())
        barItem.setTitleTextAttributes(selectedAttributes, for: .disabled)
        
        barItem.isEnabled = false
        navBar.topItem?.setRightBarButton(barItem, animated: false)

        
        column_row = [-1,-1]
        for i in 0..<aiueo.count{
            let index = aiueo[i].index(of: globals_select_kana)
            if index != nil {
                column_row[0] = i
                column_row[1] = index!
            }
        }
        
        if globals_select_kana.characters.count > 1 {
            sectionTitle = globals_select_kana
        } else {
            sectionTitle = globals_select_kana
        }

        allOkButton.isEnabled = false
        allOkButton.alpha = 0.6
        okButton.isEnabled = false
        okButton.alpha = 0.6
        
        // 使用DB
        var use_db = production_db
        if demo_mode != 0{
            use_db = demo_db
        }
        
        // /Documentsまでのパスを取得
        let paths = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask, true)
        _path = (paths[0] as NSString).appendingPathComponent(use_db)
        
        self.loadData()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
        
        let db = FMDatabase(path: _path)
        
        db.open()
 
        self.tableData = []
        
        count = 0
        var sql = ""
        var results:FMResultSet
        
//        // 日時文字列をNSDate型に変換するためのDateFormatterを生成
//        let now = Date() // 現在日時の取得
//        let dateFormatter = DateFormatter()
//        dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
//        dateFormatter.dateFormat = "yyyy/MM/dd"
//        
//        let today = dateFormatter.stringFromDate(now)
        sql = "select * from players "
        var argumentArray:Array<Any> = []
        
        if globals_select_kana.characters.count == 1 {

            if globals_select_kana != "英" && globals_select_kana != "数"  {
                
                
                sql = sql + "where player_name_kana LIKE ? AND created LIKE ? AND shop_code IN (0,?) ORDER BY player_name_kana;"
                // StringのExtensionでカタカナにしてかた半角にしている
                argumentArray.append(globals_select_kana.katakana().transformFullwidthHalfwidth(transformTypes: [.katakana]) + "%")
            } else {
                if globals_select_kana == "英" {
                    sql = sql + "where player_name_kana GLOB '[A-Z]*' AND created LIKE ? AND shop_code IN (0,?) ORDER BY cast(member_no as integer);"
                } else {
                    sql = sql + "where player_name_kana GLOB '[0-9]*' AND created LIKE ? AND shop_code IN (0,?) ORDER BY cast(member_no as integer);"
                }
                
            }

        }else{
            if globals_select_kana == "英数" {
                sql = sql + "where player_name_kana GLOB '[0-9A-Z]*' AND created LIKE ? AND shop_code IN (0,?) ORDER BY cast(member_no as integer);"
                
            } else {
                sql = sql + "where player_name_kana GLOB '[^0-9A-Zｱ-ﾝ]*' AND created LIKE ? AND shop_code IN (0,?) ORDER BY cast(member_no as integer);"
                
            }
            
        }
        argumentArray.append(globals_today + "%")
        argumentArray.append(shop_code)
        
        results = db.executeQuery(sql, withArgumentsIn: argumentArray)!

        print(sql)
        print(globals_select_kana.katakana().transformFullwidthHalfwidth(transformTypes: [.katakana]) + "%")
        while results.next() {
            let mn = (results.string(forColumn: "member_no") != nil) ? results.string(forColumn: "member_no") : ""
            let pnk = (results.string(forColumn: "player_name_kanji") != nil) ? results.string(forColumn: "player_name_kanji") : ""
            let kana = (results.string(forColumn: "player_name_kana") != nil) ? results.string(forColumn: "player_name_kana") : ""
            let status = Int(results.int(forColumn: "status"))
            
            self.tableData.append (CellData(
                holderNo        : mn!,
                playerName      : pnk!,
                playerNameKana  : kana!,
                status          : status
                )
            )
            
            count += 1
        }
        
        // テーブルビューを作る
        // Status Barの高さを取得する.
        let barHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
        
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
        let xib = furigana == 1 ? UINib(nibName: "playerName_kanaSelectTableViewCell", bundle: nil) : UINib(nibName: "playerNameSelectTableViewCell", bundle: nil)
        self.tableViewMain.register(xib, forCellReuseIdentifier: "Cell")
        self.tableViewMain.reloadData()
        
        if tableData.count == 1 {
            let indexPath = IndexPath(item: 0, section: 0)
            self.tableViewMain.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            allOkButton.isEnabled = true
            allOkButton.alpha = 1.0
            okButton.isEnabled = true
            okButton.alpha = 1.0
            
            // 選択されているホルダNOを取り出す
            let cellData = tableData[indexPath.row]
            selectHolder = cellData.holderNo
            
        } else {
            allOkButton.isEnabled = false
            allOkButton.alpha = 0.6
            okButton.isEnabled = false
            okButton.alpha = 0.6
            
            // ホルダNOをクリア
            selectHolder = ""

        }

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

        // ステータス表示ラベル
        let badgeLabel = UILabel()
        
        badgeLabel.font = UIFont(name: "YuGo-Medium",size: CGFloat(20*size_scale))
        badgeLabel.adjustsFontSizeToFitWidth = true
        badgeLabel.minimumScaleFactor = 0.5 // 最小でも50%までしか縮小しない場合
        badgeLabel.textAlignment = .center
        // テキストの色
        badgeLabel.textColor = UIColor.white
        // サイズ
        badgeLabel.frame = CGRect(x: 0, y: 0,width: 30*size_scale, height: 30*size_scale)
        // 角丸
        badgeLabel.layer.cornerRadius = badgeLabel.frame.height / 2
        badgeLabel.clipsToBounds = true

        if furigana == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! playerName_kanaSelectTableViewCell
            // セルに表示するデータを取り出す
            let cellData = tableData[indexPath.row]
//            print(cellData)
            // ラベルにテキストを設定する
            let holderNo = cellData.holderNo
            let playerName = cellData.playerName
            let playerNameKana = cellData.playerNameKana
            let status = cellData.status

            cell.holderNoLabel.textColor = UIColor.darkGray
            cell.holderNoLabel.backgroundColor = UIColor.clear
            cell.holderNoLabel.textAlignment = .center
            cell.playerNameLabel.textColor = UIColor.darkGray
            cell.playerNameKanaLabel.textColor = UIColor.darkGray
            cell.holderNoLabel.layer.borderColor = UIColor.clear.cgColor
            cell.holderNoLabel.layer.borderWidth = 0.0
            cell.accessoryView = nil
            
            switch status {
            case 0,1:       // チェックイン
                break;
            case 2:         // チェックアウト
//                cell.holderNoLabel.textColor = iOrder_grayColor
//                cell.playerNameLabel.textColor = iOrder_grayColor
//                cell.playerNameKanaLabel.textColor = iOrder_grayColor
//
//                badgeLabel.text = "✕"
//                badgeLabel.backgroundColor = iOrder_noticeRedColor
//                cell.accessoryView = badgeLabel
                cell.holderNoLabel.backgroundColor = iOrder_grayColor
                cell.holderNoLabel.textColor = UIColor.white
                
                break;
            case 3:         // キャンセル
                badgeLabel.text = "キ"
                badgeLabel.backgroundColor = iOrder_bargainsYellowColor
                cell.accessoryView = badgeLabel
                
                cell.holderNoLabel.layer.borderColor = UIColor.black.cgColor
                cell.holderNoLabel.layer.borderWidth = 1.0
//                cell.holderNoLabel.backgroundColor = iOrder_grayColor
//                cell.holderNoLabel.textColor = UIColor.whiteColor()
                break;
            case 9:         // 予約
                badgeLabel.text = "予"
                badgeLabel.backgroundColor = iOrder_blueColor
                cell.accessoryView = badgeLabel
                
                cell.holderNoLabel.layer.borderColor = UIColor.black.cgColor
                cell.holderNoLabel.layer.borderWidth = 1.0

//                cell.holderNoLabel.backgroundColor = iOrder_grayColor
//                cell.holderNoLabel.textColor = UIColor.whiteColor()
                break;
            default:
                break;
            }
            
            cell.holderNoLabel.text = holderNo
            cell.playerNameLabel.text = playerName
            cell.playerNameKanaLabel.text = playerNameKana
            // 設定済みのセルを戻す
            return cell

        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! playerNameSelectTableViewCell
            // セルに表示するデータを取り出す
            let cellData = tableData[indexPath.row]
            
            // ラベルにテキストを設定する
            let holderNo = cellData.holderNo
            let playerName = cellData.playerName
            let status = cellData.status
            
            cell.holderNoLabel.textColor = UIColor.darkGray
            cell.playerNameLabel.textColor = UIColor.darkGray

            cell.holderNoLabel.backgroundColor = UIColor.clear
            cell.holderNoLabel.textAlignment = .center
            cell.playerNameLabel.textColor = UIColor.darkGray
            cell.accessoryView = nil

            
            switch status {
            case 0,1:       // チェックイン
                break;
            case 2:         // チェックアウト
//                cell.holderNoLabel.textColor = iOrder_grayColor
//                cell.playerNameLabel.textColor = iOrder_grayColor
//
//                badgeLabel.text = "✕"
//                badgeLabel.backgroundColor = iOrder_noticeRedColor
//                cell.accessoryView = badgeLabel
                
                cell.holderNoLabel.backgroundColor = iOrder_grayColor
                cell.holderNoLabel.textColor = UIColor.white
                cell.holderNoLabel.textAlignment = .center

                break;
            case 3:         // キャンセル
                badgeLabel.text = "キ"
                badgeLabel.backgroundColor = iOrder_bargainsYellowColor
                cell.accessoryView = badgeLabel
                
                cell.holderNoLabel.backgroundColor = iOrder_grayColor
                cell.holderNoLabel.textColor = UIColor.white
                cell.holderNoLabel.textAlignment = .center

                break;
            case 9:         // 予約
                badgeLabel.text = "予"
                badgeLabel.backgroundColor = iOrder_blueColor
                cell.accessoryView = badgeLabel
                cell.holderNoLabel.backgroundColor = iOrder_grayColor
                cell.holderNoLabel.textColor = UIColor.white
                cell.holderNoLabel.textAlignment = .center
                break;
            default:
                break;
            }
            
            cell.holderNoLabel.text = holderNo
            cell.playerNameLabel.text = playerName
            // 設定済みのセルを戻す
            return cell
        }
        
        // 設定済みのセルを戻す
//        return cell!
    }
    
    // セクション数
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // セクションのタイトルを詳細に設定
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        // あいおうおボタンの設置
        let imageButton   = UIButton()
        imageButton.setTitle(sectionTitle, for: UIControlState())
        imageButton.setTitleColor(UIColor.white, for: UIControlState())
        imageButton.backgroundColor = UIColor.orange
        imageButton.frame = CGRect(x: 10*size_scale, y: 2*size_scale, width: 80*size_scale, height: 40*size_scale)
        
        let descriptor = UIFontDescriptor(name: "YuGo-Bold", size: CGFloat(20*size_scale))
        imageButton.titleLabel!.font = UIFont(descriptor: descriptor, size: CGFloat(20*size_scale))
        imageButton.addTarget(self, action: #selector(playerNameSelectViewController.tapSectionHeader(_:)), for:.touchUpInside)

        let headerView = UITableViewHeaderFooterView()
        headerView.backgroundView?.backgroundColor = UIColor.green
        headerView.addSubview(imageButton)
        
        let sortAtoZButton = UIButton()
        sortAtoZButton.frame = CGRect(x: 0, y: 0, width: sort_iconSize*size_scale, height: sort_iconSize*size_scale)
        sortAtoZButton.layer.position = CGPoint(x: 10*size_scale + 80*size_scale + 10*size_scale + ((sort_iconSize*size_scale)/2), y: (44*size_scale) / 2)
        
        // AtoZボタン
        let iconImage = FAKFontAwesome.sortAlphaAscIcon(withSize: sort_iconSize*size_scale)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.black)
        //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
        let Image = iconImage?.image(with: CGSize(width: sort_iconSize*size_scale, height: sort_iconSize*size_scale))
        sortAtoZButton.setImage(Image, for: UIControlState())
        
        sortAtoZButton.addTarget(self, action: #selector(playerNameSelectViewController.tapAtoZ), for:.touchUpInside)
        
        headerView.addSubview(sortAtoZButton)
        
        
        let sort1to9Button = UIButton()
        sort1to9Button.frame = CGRect(x: 0, y: 0, width: sort_iconSize*size_scale, height: sort_iconSize*size_scale)
        sort1to9Button.layer.position = CGPoint(x: sortAtoZButton.frame.origin.x + sortAtoZButton.frame.width + 10*size_scale + ((sort_iconSize*size_scale)/2), y: (44*size_scale) / 2)
        
        // 1to9ボタン
        let iconImage1 = FAKFontAwesome.sortNumericAscIcon(withSize: sort_iconSize*size_scale)
        iconImage1?.addAttribute(NSForegroundColorAttributeName, value: UIColor.black)
        //        cutlery.addAttribute(NSBackgroundColorAttributeName, value: UIColor.brownColor())
        let Image1 = iconImage1?.image(with: CGSize(width: sort_iconSize*size_scale, height: sort_iconSize*size_scale))
        sort1to9Button.setImage(Image1, for: UIControlState())

        sort1to9Button.addTarget(self, action: #selector(playerNameSelectViewController.tap1to9), for:.touchUpInside)
        
        headerView.addSubview(sort1to9Button)
        
        
        let countLabel = UILabel()
        
        countLabel.font = UIFont(descriptor: descriptor, size: CGFloat(20*size_scale))
        countLabel.frame = CGRect(x: self.view.bounds.width - 110*size_scale, y: 2*size_scale, width: 100*size_scale, height: 40*size_scale)
//        countLabel.backgroundColor = iOrder_greenColor
        countLabel.textAlignment = .right
        countLabel.textColor = iOrder_blackColor
        if count >= 0 {
            countLabel.text = "\(count)件"
        }
        headerView.addSubview(countLabel)
        return headerView

    }
    
    // セクションのタイトル（UITableViewDataSource）
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return "*"
    }
    
    // セクションヘッダーの高さ
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44 * size_scale
    }
    
    // セルの高さを返す（UITableViewDelegate）
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat{
        
        if furigana == 1 {
//            let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as! playerName_kanaSelectTableViewCell
            // セルの高さ
            let h = 67.0*size_scale
//            print("ふりがなあり",cell.bounds.height*size_scale,size_scale)
            return h
            
        } else {
//            let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as! playerNameSelectTableViewCell
            // セルの高さ
            let h = 44.0*size_scale
//            print("ふりがななし",cell.bounds.height*size_scale)
            return h
            
        }
    }
    
    // なまえの頭文字タップ
    func tapSectionHeader(_ sender: UIButton){
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        if column_row[0] != -1 && column_row[1] != -1 {
            for _ in 0..<5{
                column_row[1] += 1
                if column_row[1] > 4 {
                    column_row[1] = 0
                    if aiueo[column_row[0]][column_row[1]] != "" {
                        break;
                    }
                }
                if aiueo[column_row[0]][column_row[1]] != "" {
                    break;
                }
            }
            sectionTitle = aiueo[column_row[0]][column_row[1]]
            globals_select_kana = sectionTitle!
            self.loadData()
            DemoLabel.Show(self.view)
            DemoLabel.modeChange()

        }
    }
    
    
    // Cell が選択された場合
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath:IndexPath) {
        
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)

        allOkButton.isEnabled = true
        allOkButton.alpha = 1.0
        okButton.isEnabled = true
        okButton.alpha = 1.0

        // 選択されているホルダNOを取り出す
        let cellData = tableData[indexPath.row]
        selectHolder = cellData.holderNo
    }
    
    // 一括ボタンタップ
    @IBAction func allOkButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        // 入力確認
        // 数字未入力の時
        if (selectHolder!.characters.count) <= 0 {
            // UIAlertController を作成
            let alertController2 = UIAlertController(title: "エラー！", message: "リストを選択してください", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel){
                action in print("Pushed OK")
                return;
            }
            alertController2.addAction(cancelAction)
            present(alertController2, animated: true, completion: nil)
            return;
        }
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
        
        db.open()
        
//        // 日時文字列をNSDate型に変換するためのDateFormatterを生成
//        let now = Date() // 現在日時の取得
//        let dateFormatter = DateFormatter()
//        dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
//        dateFormatter.dateFormat = "yyyy/MM/dd"
//        
//        let today = dateFormatter.stringFromDate(now)
        
//        let sql = "SELECT * FROM players WHERE member_no = ? AND created LIKE ? ORDER BY cast(member_no as integer)"
        
        let rs = db.executeQuery(SELECT_PLAYERS, withArgumentsIn: [selectHolder!,shop_code,globals_today + "%"])
        
        var is_entity = false
        var status:Int = 0
        var g_no = -1
        while rs!.next() {
            is_entity = true
            
            status = Int(rs!.int(forColumn: "status"))
             g_no = Int(rs!.int(forColumn: "group_no"))
        }

        // データがない場合
        if is_entity == false {
            let alertController = UIAlertController(title: "エラー！", message: "ホルダ番号「" + "\(selectHolder!)" + "」" + "は存在しません。" , preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "OK", style: .default){
                action in print("Pushed OK")
                
                let sql2 = "INSERT INTO seat_holder (seat_no,holder_no) VALUES (?,?);"
                let success = db.executeUpdate(sql2, withArgumentsIn: [globals_select_seat_no,self.selectHolder!])
                if !success {
                    print("insert error!!")
                }
                
                
                self.spinnerEnd()
                return;
            }
            
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
        } else {
            switch status {
            case -1,3:    // -1:存在しない 2:チェックアウト済み　3:キャンセル　9:予約
                var message = ""
                switch status {
                case -1:
                    message = "は\n存在しません。"
                    break
                case 2:
                    message = "は\nチェックアウト済みです。"
                    break
                case 3:
                    message = "は\nキャンセルされています。"
                    break
                case 9:
                    message = "は\n予約されています。"
                    break
                default:
                    message = "は\n存在しません。"
                    break
                }
                
                let alertController = UIAlertController(title: "エラー！", message: "ホルダ番号「" + "\(selectHolder!)" + "」" + message , preferredStyle: .alert)
                
                let okAction = UIAlertAction(title: "OK", style: .default){
                    action in print("Pushed OK")
                    
                    let sql2 = "INSERT INTO seat_holder (seat_no,holder_no) VALUES (?,?);"
                    let success = db.executeUpdate(sql2, withArgumentsIn: [globals_select_seat_no,self.selectHolder!])
                    if !success {
                        print("insert error!!")
                    }
                    
                    return;
                }
                
                alertController.addAction(okAction)
                present(alertController, animated: true, completion: nil)
                return;
                
            case 0,1:     // チェックイン
                if g_no == -1 {     // グループNOがない場合
                    if self.set_folder_number(Int(self.selectHolder!)!) == false {
                        print("error")
                    } else {
                        self.performSegue(withIdentifier: "toPlayerssetSegue",sender: nil)
                    }
                } else {
                    
                    set_folder_numbers(Int(self.selectHolder!)!, success: {() -> Void in
                        self.performSegue(withIdentifier: "toPlayerssetSegue",sender: nil)
                        
                    }) {() -> Void in
                        print("error")
                        
                    }
                }
                
                break
            case 2,9:     // チェックアウト済み,9:予約
                spinnerEnd()
                
                // 精算者振替がOFFの場合はオーダー登録させない
                if status == 2 && is_payer_allocation != 1 {
                    let message = "は\nチェックアウト済みです。(精算者振替機能OFF)"
                    let alertController = UIAlertController(title: "エラー！", message: "ホルダ番号「" + "\(selectHolder!)" + "」" + message , preferredStyle: .alert)
                    
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

                
                var message = ""
                switch status {
                case 2:
                    message = "は\nチェックアウト済みです。"
                    break
                case 9:
                    message = "は\n予約されています。"
                    break
                default:
                    break
                }

                let alertController = UIAlertController(title: "エラー！", message: "ホルダ番号「" + "\(selectHolder!)" + "」" + message + "\nそれでもオーダー登録しますか？", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "いいえ", style: .cancel){
                    action in
                    // タップ音
                    TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                    print("Pushed cancel")
                }
                
                let okAction = UIAlertAction(title: "はい", style: .default){
                    action in print("Pushed OK")
                    // タップ音
                    TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                    if g_no == -1 {     // グループNOがない場合
                        if self.set_folder_number(Int(self.selectHolder!)!) == false {
                            print("error")
                        } else {
                            self.performSegue(withIdentifier: "toPlayerssetSegue",sender: nil)
                        }
                    } else {
                        
                        self.set_folder_numbers(Int(self.selectHolder!)!, success: {() -> Void in
                            self.performSegue(withIdentifier: "toPlayerssetSegue",sender: nil)
                            
                        }) {() -> Void in
                            print("error")
                            
                        }
                    }
                    
                    return;
                }
                
                alertController.addAction(cancelAction)
                alertController.addAction(okAction)
                present(alertController, animated: true, completion: nil)
                return;
                
            default:
                break
            }
            
        }

/*
        /////////////////////////////////////////////
        // 本番モード
        if demo_mode == 0 {
            // 存在チェック
            let url = urlString + "CheckCustomer?Store_CD=1" + "&" + "Customer_NO=" + "\(selectHolder!)"

            var status:Int = 0

            let json = JSON(url: url)
            if json.asError == nil {
                for(_,custmer) in json{
                    status = Int(custmer.toString())!
//                    print("status",status)
                }
                
                let db = FMDatabase(path: _path)
                
                // データベースをオープン
                db.open()
                
                switch status {
                case -1,3,9:    // -1:存在しない 2:チェックアウト済み　3:キャンセル　9:予約
                    spinnerEnd()
                    var message = ""
                    switch status {
                    case -1:
                        message = "は存在しません。"
                        break
                    case 2:
                        message = "はチェックアウト済みです。"
                        break
                    case 3:
                        message = "はキャンセルされています。"
                        break
                    case 9:
                        message = "は予約されています。"
                        break
                    default:
                        message = "は存在しません。"
                        break
                    }
                    
                    let alertController = UIAlertController(title: "エラー！", message: "ホルダ番号「" + "\(selectHolder!)" + "」" + message , preferredStyle: .Alert)
                    
                    let okAction = UIAlertAction(title: "OK", style: .Default){
                        action in print("Pushed OK")
                        
                        let sql2 = "INSERT INTO seat_holder (seat_no,holder_no) VALUES (?,?);"
                        let success = db.executeUpdate(sql2, withArgumentsIn: [globals_select_seat_no,self.selectHolder!])
                        if !success {
                            print("insert error!!")
                        }
                        
                        self.allOkButton.enabled = false
                        self.allOkButton.alpha = 0.6
                        self.okButton.enabled = false
                        self.okButton.alpha = 0.6
                        
                        self.spinnerEnd()
                        return;
                    }
                    
                    alertController.addAction(okAction)
                    presentViewController(alertController, animated: true, completion: nil)
                    return;
                    
                case 1:     // チェックイン
                    if set_folder_numbers(Int(selectHolder!)!) == false {
                        self.spinnerEnd()
                        self.jsonError()
                        
                    } else {
                        spinnerEnd()
                        self.performSegue(withIdentifier:"toPlayerssetSegue",sender: nil)
                        
                        self.allOkButton.enabled = false
                        self.allOkButton.alpha = 0.6
                        self.okButton.enabled = false
                        self.okButton.alpha = 0.6
                        
                    }
                    
                    break
                case 2:     // チェックアウト済み
                    spinnerEnd()
                    let message = "はチェックアウト済みです。"
                    let alertController = UIAlertController(title: "エラー！", message: "ホルダ番号「" + "\(selectHolder!)" + "」" + message + "\nそれでもオーダー登録しますか？", preferredStyle: .Alert)
                    let cancelAction = UIAlertAction(title: "いいえ", style: .Cancel){
                        action in print("Pushed cancel")
                        self.allOkButton.enabled = false
                        self.allOkButton.alpha = 0.6
                        self.okButton.enabled = false
                        self.okButton.alpha = 0.6
                        
                        //                        self.spinnerEnd()
                        //                        return;
                    }
                    
                    let okAction = UIAlertAction(title: "はい", style: .Default){
                        action in
                        // タップ音
                        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                        print("Pushed OK")
                        
                        if self.set_folder_numbers(Int(self.selectHolder!)!) == false {
                            self.spinnerEnd()
                            self.jsonError()
                            
                        } else {
                            self.spinnerEnd()
                            self.performSegue(withIdentifier:"toPlayerssetSegue",sender: nil)
                            self.allOkButton.enabled = false
                            self.allOkButton.alpha = 0.6
                            self.okButton.enabled = false
                            self.okButton.alpha = 0.6
                        }
                        self.spinnerEnd()
                        return;
                    }
                    
                    alertController.addAction(cancelAction)
                    alertController.addAction(okAction)
                    presentViewController(alertController, animated: true, completion: nil)
                    return;
                    
                    
                    
                    //                    break
                    //                case 3:     // キャンセル
                    //                    break
                    //                case 9:     // 予約状態
                //                    break
                default:
                    break
                }
                
                db.close()
            

            } else {
                spinnerEnd()
                let e = json.asError
                print(e)
                self.jsonError()
            }
            spinnerEnd()

            
        } else {        // デモモード
            let db = FMDatabase(path: _path)
            // データベースをオープン
            db.open()
            var sql = "select count(*) from players where member_no = ?;"
            var results = db.executeQuery(sql, withArgumentsIn: [selectHolder!])
            // ホルダNoがない場合
            while results?.next() {
                if results?.int(forColumnIndex:0) <= 0 {
                    // エラー表示
                    let alertController = UIAlertController(title: "エラー！", message: "ホルダ番号「" + "\(selectHolder!)" + "」は存在しません", preferredStyle: .Alert)
                    let cancelAction = UIAlertAction(title: "OK", style: .Cancel){
                        action in print("Pushed OK")
                        return;
                    }
                    alertController.addAction(cancelAction)
                    presentViewController(alertController, animated: true, completion: nil)
                    return;
                }
            }
            
            sql = "select * from players where member_no = ?;"
            results = db.executeQuery(sql, withArgumentsIn:[selectHolder!])
            var seatno = 0
            var gn = 0
            while results?.next() {
                // グループ番号を取得
                gn = Int(results?.int(forColumn:"group_no"))
            }
            
            
            seat_holders = []
            
            sql = "select * from players where group_no = ? ORDER BY cast(member_no as integer);"
            results = db.executeQuery(sql, withArgumentsIn: [gn])
            while results?.next() {
                let mn = (results?.string(forColumn:"member_no") != nil) ? results?.string(forColumn:"member_no") : ""
                
                var is_update = false
                
                let seats = takeSeatPlayers_temp.filter({$0.holder_no == ""})
                if seats.count > 0 {
                    for seat in seats {
                        if seat.seat_no == globals_select_seat_no {
                            if mn == self.selectHolder! {
                                seatno = seat.seat_no
                                is_update = true
                                break;
                            }
                        } else {
                            if mn != self.selectHolder! {
                                seatno = seat.seat_no
                                is_update = true
                                break;
                            }
                        }
                    }
                    if is_update == true {
                        self.seat_holders.append(seat_holder(seat_no: seatno, holder_no: mn))
                        let index = takeSeatPlayers_temp.indexOf({$0.seat_no == seatno})
                        if index != nil {
                            takeSeatPlayers_temp[index!].holder_no = mn
                        }
                        
                    }
//                seatno += 1
                }
            }
            
            sql = "INSERT INTO seat_holder (seat_no,holder_no) VALUES (?,?);"
            db.beginTransaction()
            for num in 0..<seat_holders.count {
                let success = db.executeUpdate(sql, withArgumentsIn: [seat_holders[num].seat_no,seat_holders[num].holder_no])
                if !success {
                    print("insert error!!")
                }
            }
            db.commit()
            db.close()
            
            // お客様設定画面に移動
            self.performSegue(withIdentifier:"toPlayerssetSegue",sender: nil)
        }
*/
    }
    
    // 確定ボタンタップ
    @IBAction func okButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        // 入力確認
        // 数字未入力の時
        if (selectHolder!.characters.count) <= 0 {
            // UIAlertController を作成
            let alertController2 = UIAlertController(title: "エラー！", message: "リストを選択してください", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel){
                action in print("Pushed OK")
                return;
            }
            alertController2.addAction(cancelAction)
            present(alertController2, animated: true, completion: nil)
            return;
        }
        
        
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
        
        // データベースをオープン
        db.open()
        
//        // 日時文字列をNSDate型に変換するためのDateFormatterを生成
//        let now = Date() // 現在日時の取得
//        let dateFormatter = DateFormatter()
//        dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
//        dateFormatter.dateFormat = "yyyy/MM/dd"
//        
//        let today = dateFormatter.stringFromDate(now)
        
//        let sql = "SELECT * FROM players WHERE member_no = ? AND created LIKE ? ORDER BY cast(member_no as integer)"
        
        let rs = db.executeQuery(SELECT_PLAYERS, withArgumentsIn: [selectHolder!,shop_code,globals_today + "%"])
        
        var is_entity = false
        
        var status:Int = 0
        
        while rs!.next() {
            is_entity = true
            
            status = Int(rs!.int(forColumn: "status"))
        }
        
        db.close()
        
        // データがない場合
        if is_entity == false {
            let alertController = UIAlertController(title: "エラー！", message: "ホルダ番号「" + "\(selectHolder!)" + "」" + "は\n存在しません。" + "\nそれでもオーダー登録しますか？", preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "いいえ", style: .cancel){
                action in
                // タップ音
                TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                print("Pushed cancel")
            }
            
            let okAction = UIAlertAction(title: "OK", style: .default){
                action in print("Pushed OK")
                // タップ音
                TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                if self.set_folder_number(Int(self.selectHolder!)!) == false {
                    print("error")
                } else {
                    self.performSegue(withIdentifier: "toPlayerssetSegue",sender: nil)
                }
                return;
            }
            
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
        } else {
            switch status {
            case -1,9:    // -1:存在しない 2:チェックアウト済み　3:キャンセル　9:予約
                var message = ""
                switch status {
                case -1:
                    message = "は\n存在しません。"
                    break
                case 2:
                    message = "は\nチェックアウト済みです。"
                    break
                case 3:
                    message = "は\nキャンセルされています。"
                    break
                case 9:
                    message = "は\n予約されています。"
                    break
                default:
                    message = "は\n存在しません。"
                    break
                }
                
                let alertController = UIAlertController(title: "エラー！", message: "ホルダ番号「" + "\(selectHolder!)" + "」" + message + "\nそれでもオーダー登録しますか？", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "いいえ", style: .cancel){
                    action in
                    // タップ音
                    TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                    
                    print("Pushed cancel")
                    
                    return;
                }
                
                let okAction = UIAlertAction(title: "はい", style: .default){
                    action in
                    // タップ音
                    TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                    
                    print("Pushed OK")
                    
                    if self.set_folder_number(Int(self.selectHolder!)!) == false {
                        print("error")
                    } else {
                        self.performSegue(withIdentifier: "toPlayerssetSegue",sender: nil)
                    }
                    return;
                }
                
                alertController.addAction(cancelAction)
                alertController.addAction(okAction)
                present(alertController, animated: true, completion: nil)
                return;
                
            case 0,1:     // チェックイン
                if self.set_folder_number(Int(selectHolder!)!) == false {
                    print("error")
                } else {
                    self.performSegue(withIdentifier: "toPlayerssetSegue",sender: nil)
                }
                
                break
            case 2:     // チェックアウト済み
                spinnerEnd()
                
                // 精算者振替がOFFの場合はオーダー登録させない
                if is_payer_allocation != 1 {
                    let message = "は\nチェックアウト済みです。(精算者振替機能OFF)"
                    let alertController = UIAlertController(title: "エラー！", message: "ホルダ番号「" + "\(selectHolder!)" + "」" + message , preferredStyle: .alert)
                    
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

                let message = "は\nチェックアウト済みです。"
                let alertController = UIAlertController(title: "エラー！", message: "ホルダ番号「" + "\(selectHolder!)" + "」" + message + "\nそれでもオーダー登録しますか？", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "いいえ", style: .cancel){
                    action in
                    // タップ音
                    TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                    print("Pushed cancel")
                }
                
                let okAction = UIAlertAction(title: "はい", style: .default){
                    action in print("Pushed OK")
                    // タップ音
                    TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
                    if self.set_folder_number(Int(self.selectHolder!)!) == false {
                        print("error")
                    } else {
                        self.performSegue(withIdentifier: "toPlayerssetSegue",sender: nil)
                    }
                    return;
                }
                
                alertController.addAction(cancelAction)
                alertController.addAction(okAction)
                present(alertController, animated: true, completion: nil)
                return;
            case 3:    // 3:キャンセル
                let message = "は\nキャンセルされています。"
                let alertController = UIAlertController(title: "エラー！", message: "ホルダ番号「" + "\(selectHolder!)" + "」" + message , preferredStyle: .alert)
                
                let okAction = UIAlertAction(title: "OK", style: .default){
                    action in print("Pushed OK")
                    
                    let sql2 = "INSERT INTO seat_holder (seat_no,holder_no) VALUES (?,?);"
                    let success = db.executeUpdate(sql2, withArgumentsIn: [globals_select_seat_no,self.selectHolder!])
                    if !success {
                        print("insert error!!")
                    }
                    
                    return;
                }
                
                alertController.addAction(okAction)
                present(alertController, animated: true, completion: nil)
                return;
    
            default:
                break
            }
            
        }

    }

    // 戻るボタンタップ
    @IBAction func backButtonTap(_ sender: AnyObject) {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
//        AVAudioPlayerUtil.play()

        // 名前検索画面に移動
        self.performSegue(withIdentifier: "toNameSearchViewSegue",sender: nil)
    }

    // ボタンを長押ししたときの処理
    @IBAction func pressedLong(_ sender: UILongPressGestureRecognizer!) {
        let alertController = UIAlertController(title: "戻るが長押しされました", message: "メインメニューに戻りますか？\n入力中の内容がすべて消去されます！", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel){
            action in print("Pushed cancel")
            return;
        }
        
        let okAction = UIAlertAction(title: "削除", style: .default){
            action in print("Pushed OK")
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
 
    // 単体登録
    func set_folder_number(_ holderno:Int) -> Bool{
        let db2 = FMDatabase(path: _path)
        
        // データベースをオープン
        db2.open()
        let sql2 = "INSERT INTO seat_holder (seat_no,holder_no) VALUES (?,?);"
        let success = db2.executeUpdate(sql2, withArgumentsIn: [globals_select_seat_no,"\(selectHolder!)"])
        if !success {
            print("insert error!!",success.description)
            db2.close()
            return false
        }
        db2.close()
        return true
    }

    
    // グループ一括登録
    func set_folder_numbers(_ holderno:Int,success: (() -> Void)? , cancel: (() -> Void)?) {
//    func set_folder_numbers(holderno:Int) -> Bool{
        let db = FMDatabase(path: _path)
        
        // データベースをオープン
        db.open()

        // 日時文字列をNSDate型に変換するためのDateFormatterを生成
        let now = Date() // 現在日時の取得
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP") // ロケールの設定
        dateFormatter.dateFormat = "yyyy/MM/dd"
        
        _ = dateFormatter.string(from: now)
        
        let sql = "SELECT * FROM players WHERE group_no IN (SELECT group_no FROM players WHERE member_no = ?) AND created LIKE ? ORDER BY cast(member_no as integer);"
        
        let rs = db.executeQuery(sql, withArgumentsIn: [holderno,globals_today + "%"])
        
        seat_holders = []
        var seatno = 0
        var is_status = false
        var mn3 = ""
        
        while (rs?.next())! {
            let mn = rs?.string(forColumn:"member_no")
            let status = Int((rs?.int(forColumn:"status"))!)
            if (status == 3) || (status == 2 && is_payer_allocation != 1) {
                mn3 = mn!
                is_status = true
            } else {
                var is_update = false
                
                let seats = takeSeatPlayers_temp.filter({$0.holder_no == ""})
                
                if seats.count > 0 {
                    for seat in seats {
                        if seat.seat_no == globals_select_seat_no {
                            if mn == "\(selectHolder!)" {
                                seatno = seat.seat_no
                                is_update = true
                                break;
                            }
                        } else {
                            if mn != "\(selectHolder!)" {
                                seatno = seat.seat_no
                                is_update = true
                                break;
                            }
                        }
                    }
                    
                    if is_update == true {
                        self.seat_holders.append(seat_holder(seat_no: seatno, holder_no: mn!))
                        let index = takeSeatPlayers_temp.index(where: {$0.seat_no == seatno})
                        if index != nil {
                            takeSeatPlayers_temp[index!].holder_no = mn!
                        }
                        is_update = false
                    }
                    
                }
                
            }
            
        }
        
        if is_status == true {
            let message = "はキャンセルもしくはチェックアウト(精算者振替機能OFF)されていますので一括登録の対象外です。"
            
            let alertController = UIAlertController(title: "情報", message: "ホルダ番号「" + mn3 + "」" + message , preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "OK", style: .default){
                action  in
                print("Pushed OK")
                
                
                let sql1 = "INSERT INTO seat_holder (seat_no,holder_no) VALUES (?,?);"
                db.beginTransaction()
                for num in 0..<self.seat_holders.count {
                    let success = db.executeUpdate(sql1, withArgumentsIn: [self.seat_holders[num].seat_no,self.seat_holders[num].holder_no])
                    if !success {
                        print("insert error!!")
                        db.rollback()
                        cancel?()
                        //                    return false
                    }
                }
                db.commit()
                
                success?()
            }
            
            alertController.addAction(okAction)
            UIApplication.shared.topViewController()?.present(alertController, animated: true, completion: nil)
            
        } else {
        
        
            let sql1 = "INSERT INTO seat_holder (seat_no,holder_no) VALUES (?,?);"
            db.beginTransaction()
            for num in 0..<seat_holders.count {
                let success = db.executeUpdate(sql1, withArgumentsIn: [seat_holders[num].seat_no,seat_holders[num].holder_no])
                if !success {
                    print("insert error!!")
                    db.rollback()
                    cancel?()
                }
            }
            db.commit()
        
            success?()
        }

    }

    func tapAtoZ() {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        tableData.sort(by: {$0.playerNameKana < $1.playerNameKana })
        tableViewMain.reloadData()
    }
    
    func tap1to9() {
        // タップ音
        TapSound.buttonTap(tap_sound_file.0, type: tap_sound_file.1)
        
        tableData.sort(by: {Int($0.holderNo) < Int($1.holderNo)})
        tableViewMain.reloadData()
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
        CustomProgress.Instance.mrprogress.dismiss(true)
        //        self.spinnerEnd()
        let alertController = UIAlertController(title: "エラー！", message: "お客様情報の取り込みに失敗しました。\n再度実行してください。", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default){
            action in print("Pushed OK")
            return;
        }
        
        
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
        
    }

    
}
